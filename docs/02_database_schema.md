# 2. Database Schema (PostgreSQL)

## Entity Relationship Diagram (Text)

```
users ──1:N──► lobby_players ◄──N:1── lobbies
                    │
                    │ 1:N
                    ▼
                 answers ◄──N:1── rounds ──N:1──► lobbies
                                     │
                                     │ references
                                     ▼
                               question_pool

users ──1:1──► premium_status
```

---

## Table: `users`

Stores anonymous user profiles.

```sql
CREATE TABLE public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_name TEXT NOT NULL DEFAULT 'Player',
    avatar_emoji TEXT NOT NULL DEFAULT '😎',
    preferred_language TEXT NOT NULL DEFAULT 'en' CHECK (preferred_language IN ('en', 'de', 'es')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

---

## Table: `lobbies`

Each game session is a lobby.

```sql
CREATE TYPE lobby_status AS ENUM ('waiting', 'playing', 'finished', 'cancelled');
CREATE TYPE tone_level AS ENUM ('safe', 'deeper', 'secretive', 'freaky');

CREATE TABLE public.lobbies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE, -- 6-char alphanumeric join code
    host_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    status lobby_status NOT NULL DEFAULT 'waiting',
    language TEXT NOT NULL DEFAULT 'en' CHECK (language IN ('en', 'de', 'es')),
    max_rounds INTEGER NOT NULL DEFAULT 20 CHECK (max_rounds BETWEEN 10 AND 100),
    current_round INTEGER NOT NULL DEFAULT 0,
    nsfw_enabled BOOLEAN NOT NULL DEFAULT false,
    
    -- AI Session Memory (ephemeral, deleted on lobby end)
    boldness_score REAL NOT NULL DEFAULT 0.0,          -- range: 0.0 (conservative) to 1.0 (bold)
    current_tone tone_level NOT NULL DEFAULT 'safe',
    escalation_history JSONB NOT NULL DEFAULT '[]',     -- [{round, tone, boldness}]
    used_question_ids UUID[] NOT NULL DEFAULT '{}',     -- prevent repeats
    
    -- Timing
    round_timeout_seconds INTEGER NOT NULL DEFAULT 30,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT valid_round CHECK (current_round >= 0 AND current_round <= max_rounds)
);

-- Index for lobby code lookups
CREATE INDEX idx_lobbies_code ON public.lobbies(code);
CREATE INDEX idx_lobbies_status ON public.lobbies(status) WHERE status IN ('waiting', 'playing');
```

### Lobby Code Generation (API Route)

```typescript
function generateLobbyCode(): string {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no I/O/0/1 (ambiguity)
    let code = '';
    for (let i = 0; i < 6; i++) {
        code += chars[Math.floor(Math.random() * chars.length)];
    }
    return code;
}
```

---

## Table: `lobby_players`

Players in a lobby.

```sql
CREATE TYPE player_status AS ENUM ('connected', 'disconnected', 'left');

CREATE TABLE public.lobby_players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lobby_id UUID NOT NULL REFERENCES public.lobbies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL DEFAULT 'Player',
    avatar_emoji TEXT NOT NULL DEFAULT '😎',
    status player_status NOT NULL DEFAULT 'connected',
    is_host BOOLEAN NOT NULL DEFAULT false,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    UNIQUE(lobby_id, user_id)
);

CREATE INDEX idx_lobby_players_lobby ON public.lobby_players(lobby_id);
CREATE INDEX idx_lobby_players_user ON public.lobby_players(user_id);
```

---

## Table: `rounds`

Each round of gameplay.

```sql
CREATE TYPE round_status AS ENUM ('pending', 'active', 'completed');

CREATE TABLE public.rounds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lobby_id UUID NOT NULL REFERENCES public.lobbies(id) ON DELETE CASCADE,
    round_number INTEGER NOT NULL,
    question_text TEXT NOT NULL,
    question_source_id UUID REFERENCES public.question_pool(id), -- NULL if AI-generated
    tone tone_level NOT NULL DEFAULT 'safe',
    status round_status NOT NULL DEFAULT 'pending',
    
    -- Analytics
    total_players INTEGER NOT NULL DEFAULT 0,
    have_count INTEGER NOT NULL DEFAULT 0,
    have_not_count INTEGER NOT NULL DEFAULT 0,
    boldness_delta REAL NOT NULL DEFAULT 0.0,   -- change in boldness this round
    
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    
    UNIQUE(lobby_id, round_number)
);

CREATE INDEX idx_rounds_lobby ON public.rounds(lobby_id, round_number);
```

---

## Table: `answers`

Player responses per round.

```sql
CREATE TABLE public.answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    round_id UUID NOT NULL REFERENCES public.rounds(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    lobby_id UUID NOT NULL REFERENCES public.lobbies(id) ON DELETE CASCADE,
    answer BOOLEAN NOT NULL, -- true = "I have", false = "I have not"
    answered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    UNIQUE(round_id, user_id)
);

CREATE INDEX idx_answers_round ON public.answers(round_id);
```

---

## Table: `question_pool`

Pre-authored, curated questions.

```sql
CREATE TYPE question_category AS ENUM (
    'social', 'travel', 'food', 'relationships', 
    'embarrassing', 'wild', 'nsfw_light', 'nsfw_heavy'
);

CREATE TABLE public.question_pool (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    text_en TEXT NOT NULL,
    text_de TEXT NOT NULL,
    text_es TEXT NOT NULL,
    category question_category NOT NULL,
    intensity INTEGER NOT NULL CHECK (intensity BETWEEN 1 AND 10),
    -- 1-3: safe, 4-5: deeper, 6-7: secretive, 8-10: freaky
    is_nsfw BOOLEAN NOT NULL DEFAULT false,
    is_premium BOOLEAN NOT NULL DEFAULT false,
    times_used INTEGER NOT NULL DEFAULT 0,
    avg_have_ratio REAL, -- historical "I have" percentage (for calibration)
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    active BOOLEAN NOT NULL DEFAULT true
);

CREATE INDEX idx_question_pool_intensity ON public.question_pool(intensity, is_nsfw, active);
CREATE INDEX idx_question_pool_category ON public.question_pool(category, intensity);
```

### Intensity → Tone Mapping

| Intensity | Tone Level | Example |
|-----------|-----------|---------|
| 1–3 | `safe` | "Never have I ever eaten breakfast for dinner" |
| 4–5 | `deeper` | "Never have I ever ghosted someone I was dating" |
| 6–7 | `secretive` | "Never have I ever read my partner's messages" |
| 8–10 | `freaky` | "Never have I ever had a crush on a friend's partner" |

---

## Table: `premium_status`

In-app purchase tracking.

```sql
CREATE TABLE public.premium_status (
    user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    is_premium BOOLEAN NOT NULL DEFAULT false,
    purchased_at TIMESTAMPTZ,
    receipt_data TEXT, -- App Store receipt for validation
    expires_at TIMESTAMPTZ, -- NULL for lifetime
    platform TEXT DEFAULT 'ios',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

---

## Table: `ai_rate_limits`

Prevents abuse of AI-generated questions.

```sql
CREATE TABLE public.ai_rate_limits (
    user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    daily_ai_calls INTEGER NOT NULL DEFAULT 0,
    last_reset_date DATE NOT NULL DEFAULT CURRENT_DATE,
    lifetime_ai_calls INTEGER NOT NULL DEFAULT 0
);

-- Reset daily counter function
CREATE OR REPLACE FUNCTION reset_daily_ai_limits()
RETURNS void AS $$
BEGIN
    UPDATE public.ai_rate_limits
    SET daily_ai_calls = 0, last_reset_date = CURRENT_DATE
    WHERE last_reset_date < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Access Control

> **Note:** Row-Level Security (RLS) is no longer used. Access control is enforced
> in the Fastify API layer via JWT authentication and route-level authorization.
> The server connects to Postgres with a service role — all policy enforcement
> happens in application code.

---

## Realtime Configuration

Realtime state broadcasting is handled by Socket.IO in the Fastify API.
The server pushes lobby/round/answer state to connected clients via rooms.

| Event | Payload | Purpose |
|-------|---------|---------|
| `lobby:state` | `{ lobby, players, round, answers }` | Full lobby state sync |
| `round:state` | `{ round }` | New round or round completion |
| `answer:state` | `{ answers }` | Live answer updates |
| `player:joined` | `{ player }` | Player join notification |
| `player:left` | `{ player }` | Player leave notification |

---

## Cleanup & Maintenance

```sql
-- Auto-cleanup lobbies older than 24 hours
CREATE OR REPLACE FUNCTION cleanup_stale_lobbies()
RETURNS void AS $$
BEGIN
    UPDATE public.lobbies
    SET status = 'cancelled', ended_at = now()
    WHERE status IN ('waiting', 'playing')
    AND created_at < now() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule via pg_cron or external cron job
-- Example: every 6 hours for lobby cleanup, daily for AI limits
```
