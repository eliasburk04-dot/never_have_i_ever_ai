# 9. Potential Failure Points + Mitigation

## Critical Path Analysis

```
Client → JWT Auth → Lobby Join → Socket.IO Sub → Game Start →
Fastify API → Groq API → Question Delivery → Answer Collection →
Score Update → Next Round → ... → Game End
```

Every link in this chain is a potential failure point.

---

## Failure Matrix

### F1: Groq API Unavailable

| Aspect | Detail |
|--------|--------|
| **Probability** | Medium (free tier, rate limits) |
| **Impact** | High (no AI questions) |
| **Detection** | HTTP 429, 500, or timeout > 5s |
| **Mitigation** | Pool-only fallback mode. Fastify route selects random matching question from pool. Game continues without AI adaptation. |
| **User experience** | Seamless — player never knows AI failed. Questions still match tone/intensity. |
| **Recovery** | Auto-retry Groq on next round. If 3 consecutive failures, stay in pool-only mode for rest of game. |

### F2: Socket.IO Disconnection

| Aspect | Detail |
|--------|--------|
| **Probability** | Medium (mobile networks) |
| **Impact** | High (player desynced from game) |
| **Detection** | Socket.IO disconnect event, heartbeat timeout |
| **Mitigation** | Auto-reconnect with exponential backoff (1s, 2s, 4s, 8s, max 30s). On reconnect, re-join lobby room, fetch full game state via REST API. |
| **User experience** | Brief "Reconnecting..." overlay. Resume game at current round. |
| **Edge case** | If disconnected during answer window → answer not submitted → counted as timeout (see F6). |

### F3: Player Leaves Mid-Game

| Aspect | Detail |
|--------|--------|
| **Probability** | High (mobile app, human behavior) |
| **Impact** | Medium (game can continue) |
| **Detection** | `lobby_players` status change to 'disconnected' or 'left'. Heartbeat timeout (60s). |
| **Mitigation** | Game continues with remaining players. Min 2 players to continue. Leaving player's pending answer skipped. Boldness calculation adjusts `total_players` dynamically. |
| **User experience** | "{Player} left the game" toast. Game continues. |
| **Edge case** | Host leaves → automatic host migration to next player in join order. |

### F4: Host Leaves

| Aspect | Detail |
|--------|--------|
| **Probability** | Medium |
| **Impact** | High (host controls game flow) |
| **Detection** | Host's `lobby_players.status` → 'disconnected'/'left' |
| **Mitigation** | Auto-migrate host to next connected player. Update `lobbies.host_id`. New host gets host UI. |
| **Implementation** | Edge Function trigger on host disconnect: `UPDATE lobbies SET host_id = (SELECT user_id FROM lobby_players WHERE lobby_id = X AND status = 'connected' AND is_host = false ORDER BY joined_at LIMIT 1)` |

### F5: Below Minimum Players

| Aspect | Detail |
|--------|--------|
| **Probability** | Medium |
| **Impact** | Game must end |
| **Detection** | Connected player count < 2 after leave event |
| **Mitigation** | Game auto-ends. Show results for completed rounds. Partial game summary displayed. |
| **User experience** | "Not enough players to continue. Here's your game summary!" |

### F6: Answer Timeout

| Aspect | Detail |
|--------|--------|
| **Probability** | High (distracted players) |
| **Impact** | Low (round can complete without all answers) |
| **Detection** | Round timer expires (30s default). Tracked server-side. |
| **Mitigation** | Round completes with available answers. Non-responding players excluded from that round's calculation. If NO answers received → skip round, use same question next round. |
| **User experience** | Timer visual. "Time's up!" animation. Results shown for answered players. |

### F7: Backend API Timeout

| Aspect | Detail |
|--------|--------|
| **Probability** | Low |
| **Impact** | High (round can't start) |
| **Detection** | Client-side timeout (10s) waiting for round data |
| **Mitigation** | Client retries once. If second failure, fallback to pool-only question selection. |
| **User experience** | Brief loading extension. "Taking a moment..." |

### F8: Duplicate Answer Submission

| Aspect | Detail |
|--------|--------|
| **Probability** | Low (double-tap) |
| **Impact** | Low (data integrity) |
| **Detection** | UNIQUE constraint on (round_id, user_id) |
| **Mitigation** | Database rejects duplicate. Client disables button after first tap. Optimistic UI. |

### F9: Lobby Code Collision

| Aspect | Detail |
|--------|--------|
| **Probability** | Very low (32^6 = 1B combinations) |
| **Impact** | Medium (wrong lobby join) |
| **Detection** | UNIQUE constraint on `lobbies.code` |
| **Mitigation** | Retry code generation (max 5 attempts). Only active lobbies occupy codes. Finished lobbies release codes. |

### F10: Purchase Validation Failure

| Aspect | Detail |
|--------|--------|
| **Probability** | Low |
| **Impact** | High (user paid but no premium) |
| **Detection** | verify-receipt Edge Function returns error, or premium_status check fails |
| **Mitigation** | Server-side Apple receipt verification with retry. Client checks premium_status on every app launch. Manual restore available in Settings. Receipts stored in purchase_receipts audit table for dispute resolution. |

---

## Reconnect Protocol

```
Client detects disconnect
    │
    ▼
Show "Reconnecting..." overlay (non-blocking)
    │
    ▼
Attempt Realtime reconnect (exponential backoff)
    │
    ├─ Connected within 30s
    │     │
    │     ▼
    │   Fetch current game state via REST:
    │   GET /lobbies/{id}, /rounds?lobby_id={id}&order=round_number.desc&limit=1
    │     │
    │     ▼
    │   Reconcile local state with server state
    │     │
    │     ├─ Same round → Resume
    │     ├─ Advanced rounds → Fast-forward to current
    │     └─ Game ended → Show results
    │
    └─ Not connected after 30s
          │
          ▼
        Show "Connection lost" dialog
          │
          ├─ "Retry" → Reset backoff, try again
          └─ "Leave" → Navigate to Home
```

---

## Error Reporting

All failures logged with:
- Timestamp
- Error type (enum)
- Lobby ID (if applicable)
- Round number (if applicable)
- User ID (anonymous)
- Network status (connected/disconnected)
- Groq response (if applicable, redacted)

Logs sent to Sentry for monitoring and alerting.
