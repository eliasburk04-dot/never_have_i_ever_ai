# SERVER_PLATFORM_AUDIT

Audit timestamp: 2026-02-17 (Europe/Berlin)
Scope: Raspberry Pi backend (`/opt/neverhavei`) + local project alignment (`/Users/eliasburk/Developer/never_have_i_ever_ai`)
Mode: Read-heavy audit (no architecture changes, no production mutations)

## 1) Backend Functionality Status

- `docker compose ps`: both `api` and `db` are `healthy`.
- API health endpoint: `GET http://127.0.0.1:3000/health` => `{"ok":true,"db":true}`.
- Platform endpoint: `GET http://127.0.0.1:3000/v1/games` => `{"games":[{"key":"never_have_i_ever"}]}`.
- Host uptime: ~2 days.
- Host resources snapshot:
  - RAM: ~7.9 GiB total, ~910 MiB used, ~7.0 GiB available.
  - Disk (`/`): 5% used.
  - CPU: 4 cores (Cortex-A76).
- Container stats command returns CPU but `mem=0B/0B` for both containers (runtime reporting gap, not service outage).
- API version endpoint: no explicit `/version` endpoint found.

Status: ✔ Functional

## 2) Security Status

### Network & exposure

- `ss -lntp` findings:
  - `0.0.0.0:22` / `[::]:22` (SSH)
  - `127.0.0.1:3000` (API loopback only)
  - `127.0.0.1:631` and `[::1]:631` (loopback-only local service)
- UFW: active, default `deny (incoming)`, only `22/tcp` allowed from `192.168.178.0/24`.
- Fail2ban: active (`sshd` jail present).
- Postgres 5432 externally exposed: no.

Security marks:
- ✔ SSH restricted by firewall to LAN CIDR
- ✔ API not publicly bound (loopback only)
- ✔ Postgres not exposed
- ⚠ Loopback-only API means external app access requires proxy/tunnel layer that is currently not active

### Docker hardening

- `restart: unless-stopped`: present on `api` and `db`.
- `security_opt: no-new-privileges:true`: present on both services.
- Healthchecks: configured on both services.
- Internal network: backend network is `internal: true`.
- Published `5432`: none.

Security marks:
- ✔ Baseline hardening controls present
- ⚠ No CPU/memory/pids limits on containers

### Fastify/API security

- Rate limiting present globally and per-route; `/auth/anon` returns `429` under burst.
- CORS wildcard blocked by config (`*` rejected), and disallowed origin probe returned no ACAO header.
- Security headers via Helmet are present.
- Input validation is present (`zod` parsing on request bodies/settings).
- JWT enforced on protected REST endpoints and Socket.IO namespace middleware.
- Stack traces not leaked to client (generic `Internal server error`).
- Body limit configured (`BODY_LIMIT_BYTES`), but oversized-body runtime probe returned `500` (not `413`) due error-handler mapping.

Security marks:
- ✔ Strong auth/rate-limit/cors/header baseline
- ⚠ Oversized request status handling should be corrected (`500` -> explicit `413`)

## 3) Platform Architecture Consistency

Verified on Pi backend:
- `src/platform/*` structure exists (`auth`, `db`, `middleware`, `rate-limit`, `validation`, `logger`).
- `src/games/index.ts` registry exists and registers `never_have_i_ever`.
- `src/games/never_have_i_ever/` module exists (`engine.ts`, `routes.ts`, `ws.ts`, `selectors.ts`, `escalation.ts`).
- REST scoping under `/v1/games/:gameKey/...` is implemented.
- WS strategy:
  - one namespace: `/ws`
  - room naming: `game:<gameKey>:lobby:<LOBBYCODE>`
- Compatibility routes (`/lobby/*`, `/round/*`) are still present for legacy clients.

Consistency with architecture doc:
- `/opt/neverhavei/PLATFORM_ARCHITECTURE.md` exists.
- Doc mentions Cloudflare Tunnel -> Caddy edge flow, but no active `cloudflared` or `caddy` service was found on host.

Status: ✔ Platform refactor exists and is coherent, with one environment/doc drift noted.

## 4) Database Integrity

Schema and data checks:
- Required platform tables present (`games`, `questions`, `lobbies`, `rounds`, `answers`).
- Questions populated for `never_have_i_ever`: `de=50`, `en=50`, `es=50`.
- UTF-8/umlaut sanity: German rows with umlauts are present.
- Indexes present on key paths:
  - `questions`: `idx_questions_lookup`, unique text key per game/lang
  - `lobbies`: includes `idx_lobbies_game_code`
  - `rounds`: includes `idx_rounds_game_lobby_round`
  - `answers`: includes `idx_answers_round`, `idx_answers_round_lobby`
- Referential integrity spot checks:
  - null `game_key` in `lobbies`/`rounds`: `0`
  - round/lobby game-key mismatch: `0`
  - orphan answers (round/user): `0`
  - answer/lobby mismatch: `0`

Finding:
- `rounds_without_question_source = 5` (all current rounds have `question_source_id` null).

Status: ✔ Structurally healthy, with traceability gap.

## 5) WebSocket & Realtime Health

Protocol/structure checks:
- Socket.IO path + namespace: `/ws`.
- Auth on connect: JWT required (`connect_error unauthorized` without token).
- Room join event supports platform payload (`gameKey`, `lobbyCode`) and compatibility payload (`lobbyId`).

Live functional checks:
- End-to-end lobby flow succeeded:
  - create lobby (`never_have_i_ever`)
  - join with second player
  - auto-start first round
  - submit two answers
  - host advance succeeded
  - next round created
- Escalation state changed (`boldness_score` rose to `0.075`, history length increased).
- Anti-repetition in sampled flow: round1 question != round2 question.
- WS smoke via container script emitted `lobby:state`, `answer:state`, `ok`.

Constraint checks:
- Intensity/NSFW behavior sampled as expected for safe rounds.
- Premium filtering cannot be guaranteed: engine query currently does not filter `is_premium` in candidate selection SQL.

Status: ✔ Realtime functional, with one logic risk.

## 6) Backup & Restore Validation

- Backup script exists: `/opt/neverhavei/scripts/backup.sh`.
- Restore script exists: `/opt/neverhavei/scripts/restore.sh`.
- Scheduler present via cron (`/etc/cron.d/neverhavei-backup`) at `04:00`.
- `neverhavei-backup.timer` (systemd): not found.
- Backup mountpoint configured as `/mnt/neverhavei_usb` but currently not mounted.
- Backup destination files/logs currently absent:
  - `/mnt/neverhavei_usb/neverhavei` missing
  - `/var/log/neverhavei-backup.log` missing
- Dry-run simulation (`BACKUP_MOUNT=/tmp/not_a_mount`) safely exits with skip message.
- Overwrite behavior confirmed in script (`mv -f` latest artifacts).
- Restore script has mount/file prechecks and explicit abort behavior.

Status: ❌ Backup system not currently producing recoverable artifacts.

## 7) Deployment Stability

- Containers are healthy, with zero restart count observed.
- Restart policy (`unless-stopped`) and healthchecks are in place.
- API logs (recent tail) showed no recurring fatal/unhandled crash pattern during audit.
- Node/DB container runtime limits are unset (`Memory=0`, `NanoCpus=0`, no pids limit).

Status: ✔ Stable at current load, ⚠ missing resource guardrails.

## 8) Project (Flutter) Alignment Check

Project checked: `/Users/eliasburk/Developer/never_have_i_ever_ai`

Alignment results:
- API base URL:
  - `app/lib/core/constants/env.dart` default is hardcoded LAN IP (`http://192.168.178.143`).
  - `app/.env.json` currently also points to LAN IP.
  - Backend is loopback-bound + UFW restricted, so this URL is not currently reachable from the dev host (`curl` => `000`).
- REST contract usage:
  - App still uses legacy routes (`/lobby/create`, `/lobby/join`, `/lobby/:code/state`, `/round/:roundId/*`).
  - App does not use `/v1/games/never_have_i_ever/...` yet.
- WebSocket contract usage:
  - Uses `/ws` path correctly.
  - Sends legacy join payload `{ lobbyId }`, not canonical `{ gameKey, lobbyCode }`.
  - Backend compatibility path currently makes this work.
- `gameKey` propagation:
  - Not sent in REST paths or WS payload by current client implementation.
- Offline mode:
  - Uses local question pool/Hive and remains independent of backend reachability.
- NSFW/premium behavior in app:
  - Online create flow passes `nsfwEnabled`.
  - Offline mode currently has temporary premium bypass for NSFW (`isPremium: true` hardcoded in offline setup/cubit).
- Player persistence:
  - Stable anonymous `userId` persisted (SharedPreferences) + JWT in secure storage; refresh on `401` implemented.
- Debug-only configs:
  - `Bloc.observer` always enabled.
  - Temporary testing bypasses for premium gating remain in offline code.

Status: ⚠ Partially aligned via compatibility layer, not platform-contract aligned.

## 9) Critical Issues (if any)

1. High: Backup chain currently non-operational in practice.
- Mountpoint not mounted, no backup artifacts, no backup log file.
- Impact: restore point may not exist when needed.

2. High: Client/backend connectivity mismatch for current Flutter config.
- App points at LAN URL while backend is not reachable on LAN HTTP from client host.
- Impact: online mode can fail outside host-local context.

3. Medium: Premium content gating risk in engine selection.
- Candidate SQL does not filter `questions.is_premium`.
- Impact: potential premium question leakage to non-premium lobbies.

4. Medium: Round traceability gap.
- `rounds.question_source_id` remains null in active data.
- Impact: weaker analytics/auditability and harder content forensics.

5. Low/Medium: Oversized request returns `500` instead of explicit `413`.
- Impact: weaker client semantics/monitoring clarity.

## 10) Recommended Improvements

1. Restore backup reliability first.
- Ensure `/mnt/neverhavei_usb` mounts persistently at boot.
- Run and verify one successful scheduled backup; confirm files and log output.
- Keep cron or migrate to systemd timer, but ensure one scheduler path is authoritative.

2. Align Flutter to platform contract.
- Move client routes to `/v1/games/never_have_i_ever/...`.
- Send WS join payload as `{ gameKey, lobbyCode }`.
- Replace hardcoded LAN default with environment-specific URL (tunnel/proxy endpoint).

3. Enforce premium filter in question selection SQL.
- Add `is_premium` gating based on host/account premium entitlement.

4. Persist `question_source_id` on round creation/advance.
- Use selected question UUID when selection comes from DB pool.

5. Improve API error mapping.
- Preserve Fastify status codes for known framework errors (e.g., body too large -> `413`).

6. Add runtime guardrails for scale.
- Set Docker memory/cpu/pids limits.
- Tune Socket.IO `pingInterval`/`pingTimeout` explicitly.
- Add a small load test for ~300 concurrent sockets.

7. Remove temporary offline premium bypass and always-on debug observer in production builds.

## 11) Overall Health Score (0–100)

Weighted model:
- Infrastructure security (20%): 88
- API security (20%): 78
- Data integrity (15%): 84
- Realtime robustness (15%): 82
- Deployment hygiene (10%): 80
- Code modularity (10%): 92
- Backup safety (10%): 45

Final weighted score: **80/100**

Executive summary:
- Core backend is up, healthy, and structurally platform-ready for multi-game expansion.
- Security posture is solid at baseline (UFW, fail2ban, JWT, rate limits, CORS constraints, no public DB exposure).
- Realtime and game flow are functional under the new `/ws` + game-scoped room model.
- Database integrity is good overall, with no orphaned relational data detected.
- Two major operational risks remain: backup execution is not currently producing artifacts, and client runtime URL alignment is broken for current host exposure.
- Client is still running on legacy endpoint conventions and only works via server compatibility routes.
- Premium gating and round source traceability need tightening before broader rollout.
- For ~300 users, current settings are plausible but unproven without explicit socket/load tuning and resource limits.
