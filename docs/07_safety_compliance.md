# 7. Safety & Compliance Layer

## Apple App Store Compliance

### Age Rating: 17+
Required because NSFW mode exists (even though it's behind a toggle).

### App Store Guidelines Adherence

| Guideline | Implementation |
|-----------|---------------|
| 1.1 Objectionable Content | NSFW mode gated, content filtered, no explicit sexual content |
| 1.2 User-Generated Content | Questions are curated pool + AI-filtered. No user-submitted content in v1 |
| 3.1.1 In-App Purchase | Lifetime unlock via StoreKit 2 + server-side receipt verification |
| 5.1.1 Data Collection | Anonymous auth, minimal data, privacy policy required |
| 5.1.2 Data Use | No data sold, no tracking, no ads |

---

## NSFW Content Policy

### Allowed (Suggestive, App Store Compliant)

✅ Romantic/dating scenarios
✅ Embarrassing personal stories
✅ Mild innuendo
✅ "Crush" or "attraction" themes
✅ Party/drinking references
✅ "Sent a risky text" type scenarios

### Forbidden (Hard Blocks)

❌ Explicit sexual descriptions
❌ References to minors in any sexual/romantic context
❌ Illegal drug manufacturing/distribution
❌ Violence or self-harm
❌ Hate speech or discrimination
❌ Non-consensual scenarios
❌ Explicit pornographic language

---

## Safety Filter Implementation

### Three-Layer Defense

```
Layer 1: Question Pool Curation (Human Review)
    │
    ▼
Layer 2: AI Output Validation (Keyword + Pattern)
    │
    ▼
Layer 3: Groq System Prompt Constraints
```

### Layer 1: Pool Curation

All questions in `question_pool` are pre-reviewed by humans before insertion.
- Each question has explicit `intensity` and `is_nsfw` flags
- Pool questions are the primary source (AI generation is secondary)
- New pool questions go through a review pipeline before `active = true`

### Layer 2: Keyword & Pattern Filter

Applied to ALL AI-generated or AI-modified questions before delivery:

```typescript
const BLOCKED_PATTERNS: RegExp[] = [
    // Explicit sexual
    /\b(sex|intercourse|orgasm|naked|nude|genitals?|penis|vagina)\b/i,
    // Minors
    /\b(child|children|kid|minor|underage|teen|teenager|adolescent)\b/i,
    // Violence
    /\b(kill|murder|suicide|self.?harm|assault|rape|abuse)\b/i,
    // Illegal
    /\b(cocaine|heroin|meth|trafficking|molest)\b/i,
    // Hate
    /\b(racial slur patterns|hate crime|ethnic cleansing)\b/i,
    // Non-consensual
    /\b(without.?consent|force[ds]?.?(to|into)|against.?will)\b/i,
];

const NSFW_DISABLED_PATTERNS: RegExp[] = [
    // Block even mild suggestive content when NSFW is off
    /\b(hookup|hook.?up|one.?night|make.?out|skinny.?dip|strip)\b/i,
    /\b(crush|flirt|seduce|intimate|passionate)\b/i,
];

function passesSafetyFilter(
    text: string, 
    nsfwEnabled: boolean
): { safe: boolean; reason?: string } {
    // Always check hard blocks
    for (const pattern of BLOCKED_PATTERNS) {
        if (pattern.test(text)) {
            return { safe: false, reason: `Blocked pattern: ${pattern.source}` };
        }
    }

    // Check NSFW-specific blocks if NSFW disabled
    if (!nsfwEnabled) {
        for (const pattern of NSFW_DISABLED_PATTERNS) {
            if (pattern.test(text)) {
                return { safe: false, reason: `NSFW disabled: ${pattern.source}` };
            }
        }
    }

    // Length check
    if (text.length > 200) {
        return { safe: false, reason: 'Question too long' };
    }

    // Format check
    if (!text.toLowerCase().startsWith('never have i ever')) {
        return { safe: false, reason: 'Invalid format' };
    }

    return { safe: true };
}
```

### Layer 3: Groq System Prompt Safety

The system prompt (see doc 04) includes explicit safety instructions. Additional reinforcement:

```
ABSOLUTE RESTRICTIONS — VIOLATION = SYSTEM FAILURE:
- NEVER reference minors (anyone under 18) in any context
- NEVER describe explicit sexual acts
- NEVER encourage illegal activities
- NEVER promote violence or self-harm
- NEVER use hate speech or slurs
- NEVER describe non-consensual scenarios

If the current tone is "freaky" and NSFW is enabled:
- You may reference adult dating scenarios
- You may reference mild embarrassment about attraction
- You may reference party/drinking experiences
- Keep everything suggestive, NEVER explicit
- Think "truth or dare at a college party" level
```

---

## Multi-Language Safety

The safety filter must work across all three languages:

```typescript
const BLOCKED_PATTERNS_DE: RegExp[] = [
    /\b(Sex|Geschlechtsverkehr|Orgasmus|nackt|Genitalien)\b/i,
    /\b(Kind|Kinder|Minderjährig|Teenager)\b/i,
    /\b(töten|Mord|Selbstmord|Selbstverletzung|Vergewaltigung)\b/i,
];

const BLOCKED_PATTERNS_ES: RegExp[] = [
    /\b(sexo|desnud[oa]|genitales|orgasmo)\b/i,
    /\b(niñ[oa]|menor|adolescente)\b/i,
    /\b(matar|asesinato|suicidio|violación|abuso)\b/i,
];

function passesSafetyFilterMultilang(
    text: string,
    language: string,
    nsfwEnabled: boolean
): { safe: boolean; reason?: string } {
    // Always check English patterns (catch-all)
    const enResult = passesSafetyFilter(text, nsfwEnabled);
    if (!enResult.safe) return enResult;

    // Check language-specific patterns
    const langPatterns = language === 'de' ? BLOCKED_PATTERNS_DE
                       : language === 'es' ? BLOCKED_PATTERNS_ES
                       : [];
    
    for (const pattern of langPatterns) {
        if (pattern.test(text)) {
            return { safe: false, reason: `Blocked (${language}): ${pattern.source}` };
        }
    }

    return { safe: true };
}
```

---

## Privacy & Data Handling

### Data Collected

| Data | Purpose | Retention |
|------|---------|-----------|
| Anonymous UUID | Player identity | Until app uninstalled |
| Display name | In-game identity | Until app uninstalled |
| Game answers | Round results | Deleted with lobby (24h max) |
| Purchase receipt | Premium validation | Indefinite (required by Apple) |
| Preferred language | Localization | Until app uninstalled |

### Data NOT Collected

- ❌ Real names
- ❌ Email addresses
- ❌ Phone numbers
- ❌ Location data
- ❌ Device identifiers (beyond anonymous auth)
- ❌ Browsing history
- ❌ Contact lists
- ❌ Photos or media

### GDPR Compliance

- No personal data collected (anonymous auth)
- Game data auto-deleted within 24h
- No data shared with third parties (Groq receives only game context, no user identifiers)
- Privacy policy URL required in App Store listing

### Data Sent to Groq API

**ONLY** the following is sent to Groq:
- Game language
- Round number / max rounds  
- Player count (number only)
- NSFW toggle state
- Boldness score (number)
- Answer ratios (numbers)
- Candidate question texts

**NEVER** sent:
- User IDs
- Display names
- Individual answer attribution
- Device information
