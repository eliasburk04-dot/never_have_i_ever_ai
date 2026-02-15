# 4. Groq Prompt Template

## Model Configuration

| Parameter | Value |
|-----------|-------|
| Model | `llama-3.3-70b-versatile` |
| Temperature | 0.7 (creative but controlled) |
| Max Tokens | 300 |
| Top P | 0.9 |
| Frequency Penalty | 0.3 (reduce repetition) |

---

## System Prompt (Constant)

```
You are a game question engine for "Never Have I Ever", a party game.

RULES:
1. You MUST respond ONLY with valid JSON. No other text.
2. You select the best question from the provided candidate pool, or generate one if instructed.
3. You may slightly rephrase a pool question to match the group's tone — but preserve the core meaning.
4. You MUST respect the tone_level and intensity_range provided.
5. If NSFW is disabled, NEVER include sexual, explicit, or adult content.
6. Even with NSFW enabled: NO minors, NO illegal activities, NO explicit pornography, NO violence.
7. Questions must always start with "Never have I ever..."
8. Keep questions under 100 characters.
9. Be culturally sensitive across German, English, and Spanish audiences.

RESPONSE FORMAT:
{
    "selected_question_id": "uuid-or-null",
    "question_text": "Never have I ever ...",
    "was_modified": true/false,
    "was_generated": true/false,
    "reasoning": "brief explanation of choice"
}
```

---

## User Prompt Template (Per Round)

```
GAME STATE:
- Language: {language}
- Round: {current_round} / {max_rounds}
- Players: {player_count}
- NSFW Mode: {nsfw_enabled}
- Current Tone: {current_tone}
- Boldness Score: {boldness_score} (0.0 = conservative, 1.0 = bold)
- Target Intensity Range: {min_intensity} - {max_intensity}

RECENT HISTORY (last 3 rounds):
{recent_history_json}

CANDIDATE QUESTIONS FROM POOL:
{candidates_json}

INSTRUCTIONS:
{instruction_variant}

Select the best question for this group right now. If you modify a pool question, set was_modified=true. If no candidates fit and you generate a new one, set was_generated=true and selected_question_id=null.

Respond ONLY with the JSON object.
```

---

## Instruction Variants

### Variant A: Pool Selection (default, >3 candidates)

```
Choose the best candidate from the pool that matches the current tone and group energy. You may slightly rephrase it to better fit the group dynamic. Prefer questions that will reveal interesting group differences.
```

### Variant B: Generation Required (<3 candidates)

```
The question pool has insufficient candidates for this tone/intensity. Generate a NEW "Never have I ever" question that:
- Fits intensity {target_intensity} (1=innocent, 10=bold)
- Matches tone: {current_tone}
- Is in {language}
- Respects NSFW setting: {nsfw_enabled}
Set was_generated=true and selected_question_id=null.
```

### Variant C: De-escalation Active

```
The group showed discomfort in recent rounds (high "I have not" ratio on bold questions). Select a LIGHTER question than the target intensity suggests. Aim for intensity {target_intensity - 2} to give the group breathing room. Keep it fun and inclusive.
```

---

## Example API Call (Edge Function → Groq)

```typescript
const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
        'Authorization': `Bearer ${GROQ_API_KEY}`,
        'Content-Type': 'application/json',
    },
    body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: [
            {
                role: 'system',
                content: SYSTEM_PROMPT,
            },
            {
                role: 'user',
                content: buildUserPrompt(gameState, candidates),
            },
        ],
        temperature: 0.7,
        max_tokens: 300,
        top_p: 0.9,
        frequency_penalty: 0.3,
        response_format: { type: 'json_object' },
    }),
});

const result = await response.json();
const aiDecision = JSON.parse(result.choices[0].message.content);
```

---

## Fallback Logic

```
GROQ CALL
    │
    ├─ SUCCESS → Parse JSON → Validate → Use question
    │
    ├─ PARSE ERROR → Retry once with stricter prompt
    │     │
    │     ├─ SUCCESS → Use question
    │     └─ FAIL → Fall to POOL FALLBACK
    │
    ├─ RATE LIMITED (429) → Fall to POOL FALLBACK
    │
    ├─ TIMEOUT (>5s) → Fall to POOL FALLBACK
    │
    └─ API ERROR (5xx) → Fall to POOL FALLBACK


POOL FALLBACK:
    1. Select random question from pool matching:
       - intensity range
       - nsfw filter
       - not in used_question_ids
    2. Use as-is (no AI adaptation)
    3. Mark round as "fallback_used": true
    
ULTIMATE FALLBACK:
    If pool also empty → use hardcoded emergency questions
    (50 pre-written questions per language embedded in Edge Function)
```

---

## Rate Limiting for Groq Calls

```
Per lobby:
    - Max 1 Groq call per round (enforced in Edge Function)
    - Max 100 calls per lobby session

Per user (free tier):
    - Max 10 AI-generated questions per day
    - Pool-only questions are unlimited

Per user (premium):
    - Unlimited AI-generated questions
    - No daily cap
```

---

## Response Validation Schema

Every Groq response MUST pass this validation before use:

```typescript
interface GroqResponse {
    selected_question_id: string | null;
    question_text: string;
    was_modified: boolean;
    was_generated: boolean;
    reasoning: string;
}

function validateGroqResponse(data: any): boolean {
    if (!data.question_text) return false;
    if (typeof data.question_text !== 'string') return false;
    if (data.question_text.length > 200) return false;
    if (!data.question_text.toLowerCase().includes('never have i ever')) return false;
    if (typeof data.was_modified !== 'boolean') return false;
    if (typeof data.was_generated !== 'boolean') return false;
    
    // Safety check on generated content
    if (data.was_generated) {
        if (!passesSafetyFilter(data.question_text)) return false;
    }
    
    return true;
}
```
