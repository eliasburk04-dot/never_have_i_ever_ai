# Never Have I Ever — AI-Powered Party Game

> Multiplayer. Adaptive. Localized. App Store Ready.

| Platform | Stack | AI | Backend | Monetization |
|----------|-------|-----|---------|--------------|
| iOS (Flutter) | Dart 3.x, Flutter 3.24+ | Groq API (LLaMA 3.3 70B) | Self-hosted (Raspberry Pi) | Free + Lifetime Premium ($4.99) |

---

## Table of Contents

1. [High-Level Architecture Overview](#1-high-level-architecture-overview)
2. [Database Schema](#2-database-schema)
3. [AI Escalation Engine Design](#3-ai-escalation-engine-design)
4. [Groq Prompt Template](#4-groq-prompt-template)
5. [Flutter App Structure](#5-flutter-app-structure)
6. [Monetization Logic](#6-monetization-logic)
7. [Safety & Compliance Layer](#7-safety--compliance-layer)
8. [Scaling Strategy](#8-scaling-strategy)
9. [Potential Failure Points + Mitigation](#9-potential-failure-points--mitigation)
10. [Future Expansion Possibilities](#10-future-expansion-possibilities)

Each section has its own detailed document in the [`docs/`](docs/) folder.

---

## Quick Start

### Prerequisites
- Flutter 3.24+ / Dart 3.x
- Self-hosted backend (Raspberry Pi or any Linux server with Docker)
- Groq API key (free tier)
- Apple Developer account ($99/yr)

### Project Structure

```
├── docs/                              # Architecture documentation
│   ├── 01_architecture_overview.md
│   ├── 02_database_schema.md
│   ├── 03_ai_escalation_engine.md
│   ├── 04_groq_prompt_template.md
│   ├── 05_flutter_app_structure.md
│   ├── 06_monetization_logic.md
│   ├── 07_safety_compliance.md
│   ├── 08_scaling_strategy.md
│   ├── 09_failure_points_mitigation.md
│   ├── 10_future_expansion.md
│   └── game_logic_system.md
│
└── app/                               # Flutter app
    ├── lib/
    │   ├── core/                      # Constants, theme, DI, engine
    │   ├── data/repositories/         # HTTP + WebSocket implementations
    │   ├── domain/                    # Entities, interfaces
    │   ├── features/                  # BLoC/Cubit per feature
    │   ├── services/                  # BackendApiService, RealtimeService (Socket.IO), etc.
    │   └── l10n/                      # Localization (EN/DE/ES)
    └── test/                          # Unit + widget tests
```

### Setup Steps

1. **Backend (Pi)**: Deploy Docker Compose (Postgres + Fastify API + Caddy reverse proxy)
2. **Groq**: Get free API key → Add as backend env var
3. **Flutter**: Set `API_URL` in `.env.json` → `flutter run --dart-define-from-file=.env.json`
4. **Deploy**: `flutter build ios`

---

## Architecture Summary

```
Flutter App ←──Socket.IO WebSocket──→ Self-hosted Backend (Raspberry Pi)
    │                                        │
    └──REST API (HTTP + JWT)───────→ Fastify API ──→ Groq API
                                        │
                                        └──→ PostgreSQL
```

- **Anonymous auth** — zero-friction onboarding (JWT-based, self-hosted)
- **Hybrid AI system** — curated question pool + Groq AI selection/generation
- **Adaptive escalation** — mathematical boldness scoring with de-escalation safety
- **3-layer safety filter** — human curation → keyword filter → AI prompt constraints
- **$0 infrastructure cost** (self-hosted on Raspberry Pi)

---

## Key Design Decisions

| Decision | Why |
|----------|-----|
| Groq (not OpenAI) | Free tier, fast inference (LPU), sufficient for question selection |
| Self-hosted Pi (not BaaS) | Full control, zero recurring cost, no vendor lock-in |
| Socket.IO (not polling) | Low-latency multiplayer sync for real-time game state |
| BLoC (not Riverpod) | Event-driven architecture fits game state machines perfectly |
| Hybrid questions (not pure AI) | Quality control, reduced API calls, faster response, safety |
| Lifetime IAP (not subscription) | Higher conversion for party games, simpler for users |
| Anonymous auth (not social login) | Party game = instant play. No friction. |

---

## Localization

| Language | App Title | Status |
|----------|-----------|--------|
| 🇬🇧 English | Never Have I Ever | ✅ |
| 🇩🇪 German | Ich hab noch nie | ✅ |
| 🇪🇸 Spanish | Yo Nunca Nunca | ✅ |

All 50 seed questions are pre-translated. AI generates in the lobby's language.

---

## Question Engine (2026 Update)

### Escalation logic

- Boldness is still tracked with EMA (`alpha = 0.3`) using prior `HAVE` ratio.
- New YES/NO trend signal (`last 4 rounds`) adjusts effective intensity pressure:
  - YES-heavy: higher chance of stronger intensity + higher shock weighting.
  - NO-heavy: stabilizes/de-escalates to avoid abrupt pressure.
- Intensity jumps are smoothed relative to previous round (bounded step changes).
- Early rounds (`1-20`) are clamped to intensity `1-4`.

### Diversity logic

- First 20 rounds enforce early-session variety:
  - target at least 5 distinct categories
  - target at least 3 distinct energies
- Hard cap on consecutive repetition:
  - no same subcategory back-to-back.
- Diversity bonuses prefer not-recent categories/energies.

### Selection weight formula

Current weighted pick formula (offline + backend parity):

```
weight =
  base_weight
  + (shock_factor * escalation_multiplier)
  + (vulnerability_level * vulnerability_bias)
  + diversity_bonus
  - repetition_penalty
```

Recycling controls:

- only after 70% pool exhaustion
- never within first 10 rounds
- when recycling, low `shock_factor` candidates are preferred.

### Randomization

- Session-specific seed originates from secure randomness.
- Debug mode can set deterministic seed for reproducible sequences.

### Data expansion + sync

- Source seed file (stable baseline): `app/assets/questions.seed.json`
- Generated expanded pool: `app/assets/questions.json` (1600 entries)
- DB schema migration: `backend/sql/2026_02_21_questions_expansion.sql`
- DB seed output: `backend/sql/questions_seed.sql`

### Add / regenerate questions

From `scripts/`:

```bash
npm run generate:questions
npm run validate:content
npm run validate:pool
npm run seed:questions:sql
```

### Validation + tests

From `scripts/`:

```bash
npm run validate
npm test
```

From `app/`:

```bash
flutter test test/engine/question_selector_test.dart \
  test/engine/escalation_engine_test.dart \
  test/engine/question_pool_simulation_test.dart
```

---
