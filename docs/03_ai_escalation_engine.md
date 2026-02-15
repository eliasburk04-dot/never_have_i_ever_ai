# 3. AI Escalation Engine Design

## Overview

The AI Escalation Engine is the brain of the game. It operates per-lobby-session with **no persistent memory**. Its job:

1. **Observe** — Analyze how the group answers each round
2. **Score** — Calculate a boldness metric
3. **Decide** — Determine the appropriate tone level
4. **Select** — Pick or generate the next question
5. **Adapt** — Modify question phrasing for group context

---

## Boldness Score Formula

The **boldness score** `B` is a rolling weighted average that represents how "bold" the group is behaving.

### Per-Round Boldness Delta

```
δ(r) = (have_count / total_players) × intensity_weight(tone_r)
```

Where `intensity_weight` maps the current tone to a multiplier:

| Tone | intensity_weight |
|------|-----------------|
| safe | 0.5 |
| deeper | 1.0 |
| secretive | 1.5 |
| freaky | 2.0 |

### Cumulative Boldness Score

```
B(r) = α × δ(r) + (1 - α) × B(r-1)
```

Where:
- `B(r)` = boldness score after round `r`
- `B(0)` = 0.0 (start conservative)
- `α` = 0.3 (smoothing factor — prevents wild swings)
- `δ(r)` = boldness delta for current round

### Score Range

| B Range | Interpretation |
|---------|---------------|
| 0.00–0.25 | Conservative group |
| 0.25–0.50 | Warming up |
| 0.50–0.75 | Bold group |
| 0.75–1.00 | Very bold / adventurous |

---

## Tone Level Thresholds

The current tone is derived from `B` plus a **round progression modifier** `P(r)`:

```
P(r) = min(0.2, r / max_rounds × 0.4)
```

This ensures natural escalation even with conservative groups (game shouldn't stay "safe" for 50 rounds).

### Effective Score

```
E(r) = B(r) + P(r)
```

### Tone Mapping

| E(r) Range | Tone Level | Allowed Intensity |
|------------|-----------|-------------------|
| 0.00–0.30 | `safe` | 1–3 |
| 0.30–0.55 | `deeper` | 3–5 |
| 0.55–0.80 | `secretive` | 5–7 |
| 0.80–1.20 | `freaky` | 7–10 (only if NSFW enabled) |

**Critical rule**: If `nsfw_enabled = false`, clamp tone to `secretive` max and intensity to 7 max.

---

## Risk Coefficient (De-escalation)

To detect when the group becomes uncomfortable:

```
R(r) = (have_not_count / total_players) at intensity > 5
```

If `R(r) > 0.75` for 2 consecutive rounds:
- **Forcibly de-escalate one tone level**
- Reduce `B(r)` by 0.15
- Log de-escalation event in `escalation_history`

This is the **safety valve** — if most people say "I have not" on edgy questions, the group is uncomfortable.

---

## Question Selection Algorithm

```
FUNCTION select_next_question(lobby):

    1. Determine target_tone from E(r)
    2. Calculate allowed_intensity_range from tone mapping
    3. If NSFW disabled: cap intensity at 7, exclude nsfw questions
    
    4. Query question_pool:
       SELECT * FROM question_pool
       WHERE intensity BETWEEN {min} AND {max}
         AND is_nsfw <= {nsfw_enabled}
         AND id NOT IN (lobby.used_question_ids)
         AND active = true
       ORDER BY
         -- Prefer questions close to target intensity
         ABS(intensity - target_intensity) ASC,
         -- Prefer less-used questions
         times_used ASC,
         -- Add randomness
         RANDOM()
       LIMIT 5;
    
    5. Send top 5 candidates to Groq API with context:
       - Current boldness score
       - Current tone
       - Round number / max rounds
       - Language
       - Group size
       - Recent answer patterns
    
    6. Groq selects best question and optionally adapts phrasing
    
    7. If pool returns < 3 candidates:
       - Ask Groq to generate a new question
       - Apply safety filter before use
    
    8. Return final question text
    
    9. Add question_id to used_question_ids
```

---

## AI Decision Flowchart

```
START ROUND (r)
    │
    ▼
Calculate δ(r-1) from previous round answers
    │
    ▼
Update B(r) = α × δ(r-1) + (1-α) × B(r-1)
    │
    ▼
Calculate P(r) = min(0.2, r/max_rounds × 0.4)
    │
    ▼
E(r) = B(r) + P(r)
    │
    ▼
┌─────────────────────────────────────────┐
│ Check de-escalation trigger:            │
│ R(r-1) > 0.75 AND R(r-2) > 0.75        │
│ at intensity > 5?                        │
├─────────┬───────────────────────────────┤
│  YES    │           NO                   │
│  │      │            │                   │
│  ▼      │            ▼                   │
│ Drop    │     Map E(r) → tone_level      │
│ tone    │            │                   │
│ by 1    │            │                   │
│ B -= 0.15           │                   │
│  │      │            │                   │
│  ▼      │            ▼                   │
│  └──────┴──► Determine intensity range   │
└─────────────────────┬───────────────────┘
                      │
                      ▼
            ┌─────────────────┐
            │ NSFW enabled?   │
            ├────YES──┬──NO───┤
            │         │       │
            │ Allow   │ Cap   │
            │ full    │ at 7  │
            │ range   │       │
            └────┬────┴───┬───┘
                 │        │
                 ▼        ▼
            Query question_pool
                 │
                 ▼
            ┌──────────────────────┐
            │ >= 3 candidates?     │
            ├────YES───┬────NO─────┤
            │          │           │
            │ Send to  │ Ask Groq  │
            │ Groq for │ to gen    │
            │ selection│ new Q     │
            │          │           │
            └────┬─────┴─────┬─────┘
                 │           │
                 ▼           ▼
            Safety filter check
                 │
                 ▼
            ┌──────────────────┐
            │ Passes filter?   │
            ├────YES───┬──NO───┤
            │          │       │
            │ Use Q    │ Fall  │
            │          │ back  │
            │          │ to    │
            │          │ pool  │
            │          │ only  │
            └────┬─────┴───┬───┘
                 │         │
                 ▼         ▼
            Deliver question to lobby
                 │
                 ▼
            Wait for answers (timeout: 30s)
                 │
                 ▼
            Aggregate results → next round
```

---

## Example Progression Path (20-round game, 6 players, NSFW ON)

| Round | B(r) | P(r) | E(r) | Tone | Intensity | Question Example |
|-------|-------|------|------|------|-----------|-----------------|
| 1 | 0.00 | 0.01 | 0.01 | safe | 1 | "Never have I ever eaten pizza for breakfast" |
| 2 | 0.12 | 0.02 | 0.14 | safe | 2 | "Never have I ever pretended to be sick to skip school" |
| 3 | 0.18 | 0.03 | 0.21 | safe | 2 | "Never have I ever sung in the shower" |
| 5 | 0.28 | 0.05 | 0.33 | deeper | 4 | "Never have I ever stalked an ex on social media" |
| 8 | 0.42 | 0.08 | 0.50 | deeper | 5 | "Never have I ever lied to a partner about where I was" |
| 10 | 0.55 | 0.10 | 0.65 | secretive | 6 | "Never have I ever read someone's diary" |
| 13 | 0.63 | 0.13 | 0.76 | secretive | 7 | "Never have I ever kept a major secret from my best friend" |
| 16 | 0.72 | 0.16 | 0.88 | freaky | 8 | "Never have I ever had a dream about a friend's partner" |
| 18 | 0.78 | 0.18 | 0.96 | freaky | 9 | "Never have I ever sent a risky text to the wrong person" |
| 20 | 0.82 | 0.20 | 1.02 | freaky | 10 | "Never have I ever done something I'd never tell my friends about" |

---

## Session Memory Structure (JSONB in `lobbies.escalation_history`)

```json
[
    {
        "round": 1,
        "tone": "safe",
        "intensity": 1,
        "boldness": 0.0,
        "have_ratio": 0.67,
        "de_escalated": false
    },
    {
        "round": 2,
        "tone": "safe",
        "intensity": 2,
        "boldness": 0.12,
        "have_ratio": 0.83,
        "de_escalated": false
    }
]
```

**Memory lifecycle**: Created on lobby start → Updated each round → Deleted when `lobby.status = 'finished'`.

The `ended_at` timestamp triggers cleanup. A background cron deletes `escalation_history` and resets `used_question_ids` for finished lobbies after 1 hour.
