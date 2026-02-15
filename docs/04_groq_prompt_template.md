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
7. Keep questions under 150 characters per language.
8. Be culturally sensitive across German, English, and Spanish audiences.

LANGUAGE CONSTRAINTS (STRICT — violations cause rejection and re-prompt):

  ENGLISH:
  - question_text_en MUST begin with exactly "Never have I ever " (capital N).
  - Must NOT end with . ? or !

  GERMAN:
  - question_text_de MUST begin with exactly "Ich hab noch nie "
    (accepted variants: "Ich hab mich noch nie ", "Ich war noch nie ").
  - MUST use proper Umlauts: ä ö ü ß. NEVER use ASCII transliterations
    (ae for ä, oe for ö, ue for ü, ss for ß).
  - Must NOT end with . ? or !

  SPANISH:
  - question_text_es MUST begin with exactly "Yo nunca nunca "
  - After prefix use pretérito perfecto compuesto: "he" + participio
    (e.g. "he comido", "me he despertado").
  - MUST use proper accented characters: á é í ó ú ñ.
  - Must NOT end with . ? or !

RESPONSE FORMAT:
{
    "selected_question_id": "uuid-or-null",
    "question_text_en": "Never have I ever ...",
    "question_text_de": "Ich hab noch nie ...",
    "question_text_es": "Yo nunca nunca he ...",
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
    question_text_en: string;
    question_text_de: string;
    question_text_es: string;
    was_modified: boolean;
    was_generated: boolean;
    reasoning: string;
}

function validateGroqResponse(data: any, language: string): boolean {
    // Structural checks
    if (typeof data.was_modified !== 'boolean') return false;
    if (typeof data.was_generated !== 'boolean') return false;

    // Per-language quality checks
    const en = data.question_text_en;
    const de = data.question_text_de;
    const es = data.question_text_es;

    if (!en || typeof en !== 'string') return false;
    if (!de || typeof de !== 'string') return false;
    if (!es || typeof es !== 'string') return false;

    // EN: prefix + length + no trailing punctuation
    if (!en.startsWith('Never have I ever ')) return false;
    if (en.length > 150) return false;
    if (/[.?!]$/.test(en)) return false;

    // DE: prefix + Umlauts + no ASCII transliterations + no trailing punctuation
    if (!de.startsWith('Ich hab noch nie ') &&
        !de.startsWith('Ich hab mich noch nie ') &&
        !de.startsWith('Ich war noch nie ')) return false;
    if (de.length > 150) return false;
    if (/[.?!]$/.test(de)) return false;
    // Reject if German text contains common transliterations
    // (simplified — server-side uses full exception list from QUALITY_SPEC)
    if (/(?<![a-z])(?:ae|oe|ue)(?![a-z]*(?:uer|uer|uen|auer))/.test(de.toLowerCase())) {
        // Use the full detectGermanTransliterations() from validate_content
        // This is a simplified check; the server imports the full validator
    }

    // ES: prefix + verb form + no trailing punctuation
    if (!es.startsWith('Yo nunca nunca ')) return false;
    if (es.length > 150) return false;
    if (/[.?!]$/.test(es)) return false;
    const afterPrefix = es.replace(/^Yo nunca nunca /, '');
    if (!/^(he |me he |me ha |me han |le he |les he |se me |nos |te he |se ha )/.test(afterPrefix)) {
        return false;
    }

    // Safety check on generated content
    if (data.was_generated) {
        if (!passesSafetyFilter(en)) return false;
        if (!passesSafetyFilter(de)) return false;
        if (!passesSafetyFilter(es)) return false;
    }

    return true;
}
```

### Post-Generation Retry Flow

When `validateGroqResponse()` fails:

```
GROQ CALL #1
    │
    ├─ validateGroqResponse() PASS → Use question
    │
    └─ validateGroqResponse() FAIL → Build error-feedback prompt:
        │
        │  "Your previous response was rejected because:
        │   - [specific rule violations, e.g. 'DE text used ae instead of ä']
        │   Re-generate following the LANGUAGE CONSTRAINTS exactly."
        │
        ├─ GROQ CALL #2 (retry with error feedback)
        │   │
        │   ├─ validateGroqResponse() PASS → Use question
        │   └─ validateGroqResponse() FAIL → POOL FALLBACK
        │
        └─ (max 1 retry per round)
```
