# Language Quality Specification

> **Scope**: Every user-facing string in `app/assets/questions.json` (question pool)
> and `app/lib/l10n/app_{en,de,es}.arb` (UI localization).
>
> **Enforcement**: Automated scripts in `/scripts/` run pre-commit and in CI.
> Non-zero exit = build blocked.

---

## 1  Universal Rules (All Languages)

| # | Rule | Enforced By |
|---|------|-------------|
| U1 | UTF-8 encoding — no Latin-1, no Windows-1252, no BOM. | `validate_content` |
| U2 | No trailing whitespace inside any string value. | `validate_content` |
| U3 | No leading whitespace inside any string value. | `validate_content` |
| U4 | No doubled spaces (`"  "`) inside any string value. | `validate_content` |
| U5 | No ASCII control characters (0x00–0x1F except `\n`). | `validate_content` |
| U6 | Max length: question text ≤ 150 characters. | `validate_content` |
| U7 | No duplicate question text within the same language. | `validate_content` |
| U8 | Every question MUST have non-empty `text_en`, `text_de`, `text_es`. | `validate_content` |
| U9 | `id` format: `q` + 3-digit zero-padded integer (e.g. `q001`). No gaps in sequence allowed. | `validate_content` |
| U10 | `intensity` must be integer 1–10. | `validate_content` |
| U11 | `is_nsfw` and `is_premium` must be boolean. | `validate_content` |
| U12 | `shock_factor` and `vulnerability_level` must be number 0.0–1.0. | `validate_content` |
| U13 | `energy` must be one of: `light`, `medium`, `heavy`. | `validate_content` |
| U14 | `category` must be one of the canonical set (see §5). | `validate_content` |
| U15 | If `is_nsfw` is true, `is_premium` MUST also be true. | `validate_content` |
| U16 | No HTML tags or Markdown in question text. | `validate_content` |

---

## 2  English (EN) Rules

| # | Rule | Enforced By |
|---|------|-------------|
| EN1 | Must start with `"Never have I ever "` (capital N, space after "ever"). | `validate_content` |
| EN2 | Must NOT end with a period or question mark. | `validate_content` |
| EN3 | No British-only spellings in the canonical list (use US English: `favorite` not `favourite`). | `validate_content` |
| EN4 | No contractions of "Never have I ever" (e.g. ~~"Never've I ever"~~). | `validate_content` |

---

## 3  German (DE) Rules

| # | Rule | Enforced By |
|---|------|-------------|
| DE1 | Must start with `"Ich hab noch nie "` (lowercase after Ich, space after "nie"). | `validate_content` |
| DE2 | Must NOT end with a period or question mark. | `validate_content` |
| DE3 | Must use proper Umlauts: `ä ö ü Ä Ö Ü ß`. No ASCII transliterations (`ae` for `ä`, `oe` for `ö`, `ue` for `ü`, `ss` for `ß`). | `validate_content` + `fix_de_transliteration` |
| DE4 | Exception to DE3: compound words where `ue`/`ae`/`oe` are naturally adjacent morphemes are allowed (e.g. `abenteuer`, `Abenteuer`). The allow-list is maintained in `fix_de_transliteration.ts`. | `fix_de_transliteration` |
| DE5 | No English loanwords where a natural German equivalent exists, UNLESS the English word is standard in German youth slang (allowed: `Crush`, `Hookup`, `One-Night-Stand`, `Guilty Pleasure`, `Walk of Shame`, `Stalken`, `Ghosten`). | manual review |
| DE6 | Gender-neutral or masculine default — no mixed gendering within a single question. | manual review |

---

## 4  Spanish (ES) Rules

| # | Rule | Enforced By |
|---|------|-------------|
| ES1 | Must start with `"Yo nunca nunca "` (capital Y, space after second "nunca"). | `validate_content` |
| ES2 | Must NOT end with a period or question mark. | `validate_content` |
| ES3 | Must use proper accented characters: `á é í ó ú ñ ü ¿ ¡`. No ASCII approximations (`n` for `ñ`). | `validate_content` |
| ES4 | No Spanglish — no English words in the Spanish text (allowed loan: `OK`). | manual review |
| ES5 | Verbs after "Yo nunca nunca" must be in first-person compound past (pretérito perfecto compuesto): `he + participio` (e.g. `he comido`, `me he despertado`). | `validate_content` |

---

## 5  Canonical Category Set

All questions must use one of these categories:

```
food, embarrassing, social, moral_gray, risk_behavior,
relationships, confessions, secrets, alcohol, sexual,
drugs, party, power_dynamics, taboo
```

All questions must use one of these energy values:

```
light, medium, heavy
```

---

## 6  ARB (i18n) File Rules

| # | Rule | Enforced By |
|---|------|-------------|
| ARB1 | Every key in `app_en.arb` must exist in `app_de.arb` and `app_es.arb`. | `validate_i18n` |
| ARB2 | No extra keys in `app_de.arb` or `app_es.arb` that are missing from `app_en.arb` (metadata keys `@@locale` and `@`-prefixed excluded). | `validate_i18n` |
| ARB3 | Placeholder syntax `{name}` must appear identically in all three files per key. | `validate_i18n` |
| ARB4 | No ASCII transliterations of Umlauts in `app_de.arb` values. | `validate_i18n` |
| ARB5 | No missing accents in `app_es.arb` for words that require them (best-effort via known word list). | `validate_i18n` |
| ARB6 | All ARB files must be valid JSON. | `validate_i18n` |
| ARB7 | `@@locale` key must match filename (`en`, `de`, `es`). | `validate_i18n` |

---

## 7  AI-Generated Content Rules (Groq)

| # | Rule | Enforced By |
|---|------|-------------|
| AI1 | System prompt MUST include per-language prefix constraints (EN: `"Never have I ever "`, DE: `"Ich hab noch nie "`, ES: `"Yo nunca nunca "`). | prompt template |
| AI2 | System prompt MUST include character set constraints (DE: require ä/ö/ü/ß, ES: require á/é/í/ó/ú/ñ). | prompt template |
| AI3 | Post-generation validation: response text must pass the same rules as static content (§2–§4). | server-side validator |
| AI4 | On validation failure: retry ONCE with error-feedback prompt. If second attempt fails, fall back to local pool. | server-side fallback |
| AI5 | AI-generated questions must not exceed 150 characters. | server-side validator |
| AI6 | AI-generated German text must not contain ASCII transliterations (ae/oe/ue/ss). | server-side validator |

---

## 8  Script Interface

### npm scripts (run from `/scripts/`)

| Command | Script | Exit Code |
|---------|--------|-----------|
| `npm run validate:content` | `validate_content.ts` | 0 = pass, 1 = violations found |
| `npm run validate:i18n` | `validate_i18n.ts` | 0 = pass, 1 = violations found |
| `npm run fix:de` | `fix_de_transliteration.ts` | 0 = clean / fixes applied, produces diff report |
| `npm run validate` | runs `validate:content` + `validate:i18n` | 0 = all pass |

### Reports

All reports are written to `/scripts/reports/` (git-ignored).

| File | Content |
|------|---------|
| `content_violations.json` | Array of `{id, field, rule, message, value}` |
| `i18n_violations.json` | Array of `{file, key, rule, message}` |
| `de_fixes.json` | Array of `{id, field, before, after, rule}` |
| `summary.txt` | Human-readable counts and status |
