# 1. High-Level Architecture Overview

## System Diagram (Text)

```
┌─────────────────────────────────────────────────────────┐
│                    FLUTTER CLIENT (iOS)                  │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐            │
│  │  UI Layer │  │  BLoC /  │  │  Repos /  │            │
│  │ (Screens) │→ │  Cubits  │→ │  Services │            │
│  └──────────┘  └──────────┘  └─────┬─────┘            │
│                                     │                   │
└─────────────────────────────────────┼───────────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 ▼                  │
                    │     SELF-HOSTED BACKEND (Pi)       │
                    │                                    │
                    │  ┌────────────────────────┐       │
                    │  │   PostgreSQL Database   │       │
                    │  │  (lobbies, rounds,      │       │
                    │  │   answers, players,     │       │
                    │  │   question_pool)        │       │
                    │  └────────────────────────┘       │
                    │                                    │
                    │  ┌────────────────────────┐       │
                    │  │  Socket.IO (Realtime)   │       │
                    │  │  (Lobby/Round/Answer    │       │
                    │  │   state broadcast)      │       │
                    │  └────────────────────────┘       │
                    │                                    │
                    │  ┌────────────────────────┐       │
                    │  │   Fastify API Routes    │       │
                    │  │  (AI orchestration,     │       │
                    │  │   lobby management,     │       │
                    │  │   answer submission,    │       │
                    │  │   round advancement)    │       │
                    │  └───────────┬────────────┘       │
                    │              │                     │
                    │  ┌────────────────────────┐       │
                    │  │   Caddy Reverse Proxy   │       │
                    │  │  (HTTPS termination)    │       │
                    │  └────────────────────────┘       │
                    │                                    │
                    └──────────────┼─────────────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────┐
                    │        GROQ API          │
                    │   (LLaMA 3.3 70B)        │
                    │                          │
                    │  - Question selection     │
                    │  - Tone adaptation        │
                    │  - Escalation analysis    │
                    │  - Fallback generation    │
                    └──────────────────────────┘
```

## Data Flow Per Round

```
1. Host starts round N
2. Fastify API route handler:
   a. Reads session memory (boldness score, history)
   b. Calls Groq API with context
   c. Groq selects/adapts question from pool
   d. If pool insufficient → Groq generates new question
   e. Question written to `rounds` table in Postgres
3. Socket.IO broadcasts new round to all lobby participants
4. Players see question, tap "I have" / "I have not"
5. Answers written to `answers` table via POST /round/:id/answer
6. Socket.IO broadcasts answer state to all players
7. When all answered, host taps "Next Question":
   a. POST /round/:id/advance
   b. Server validates all answered, creates next round
   c. Broadcasts new round state
8. Repeat until max_rounds reached
```

## Key Architectural Decisions

| Decision | Rationale |
|----------|-----------|
| **Self-hosted Fastify on Raspberry Pi** | Zero recurring cost, full control, no vendor lock-in. Groq API key never exposed to client. |
| **Anonymous Auth (JWT)** | Zero friction onboarding. No email/password. `POST /auth/anon` → stable device UUID + JWT. |
| **Hybrid question system** | Prevents AI hallucination. Ensures quality. Reduces API calls. |
| **BLoC state management** | Battle-tested for complex state flows. Separation of UI/logic. Testable. |
| **Socket.IO for realtime** | Low-latency multiplayer sync. Auto-reconnect. Room-based broadcast per lobby. |
| **Docker Compose deployment** | Postgres + Fastify + Caddy in containers. Reproducible, easy to update. |
| **Caddy reverse proxy** | Automatic HTTPS via Let's Encrypt. Zero-config TLS. |

## Authentication Flow

```
App Launch
    │
    ▼
Check flutter_secure_storage for existing JWT
    │
    ├─ Found → Use cached JWT (refresh on 401)
    │
    └─ Not found → POST /auth/anon { userId: <device-uuid> }
         │
         ▼
    Receive { jwt, userId }
         │
         ▼
    Store JWT in flutter_secure_storage, userId in SharedPreferences
         │
         ▼
    User gets stable UUID → used as player identity across sessions
```

## Network Architecture

- **Primary**: Socket.IO WebSocket for real-time game state (lobby, rounds, answers, players)
- **Secondary**: HTTP REST API (Fastify) for mutations (create lobby, join, submit answer, advance round)
- **AI Pipeline**: Client → Fastify API → Groq API → Postgres → Socket.IO broadcast
- **Offline mode**: Local pass-and-play with 150-question JSON pool (no network required)

## Infrastructure

| Component | Technology | Runs On |
|-----------|-----------|---------|
| API Server | Node.js + Fastify | Docker on Raspberry Pi |
| Realtime | Socket.IO (integrated with Fastify) | Same container |
| Database | PostgreSQL 16 | Docker on Raspberry Pi |
| Reverse Proxy | Caddy | Docker on Raspberry Pi |
| AI Provider | Groq API (external) | Cloud (only external dependency) |

## External Dependencies

| Service | Purpose | Cost |
|---------|---------|------|
| Groq API | AI question selection/generation | Free tier |
| Apple App Store | Distribution + StoreKit 2 IAP | $99/yr |
| Let's Encrypt (via Caddy) | TLS certificates | Free |
