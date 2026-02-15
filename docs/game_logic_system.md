# Game Logic System — Detailed Design

## Round Lifecycle

```
┌─────────────────────────────────────────────────────┐
│                    ROUND LIFECYCLE                    │
├─────────────────────────────────────────────────────┤
│                                                     │
│   IDLE ──► PENDING ──► ACTIVE ──► COMPLETED ──► IDLE│
│              │            │           │              │
│         Host starts   Question    All answers       │
│         next round    delivered   or timeout        │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### State Machine

| State | Description | Trigger to Next |
|-------|-------------|-----------------|
| **IDLE** | Between rounds. Lobby is in `playing` status. | Host taps "Next Question" |
| **PENDING** | Fastify API called. AI processing question. | Question returned and inserted into `rounds` table |
| **ACTIVE** | Question visible to all players. All players answer. | All connected players answered |
| **COMPLETED** | Answers aggregated. Next round auto-created. | Broadcast via Socket.IO, then back to ACTIVE |

### Sequence Diagram

```
Host Client          Fastify API             Groq API          All Clients
    │                      │                    │                    │
    │──"Advance Round"────►│                    │                    │
    │                      │──Get lobby state───│                    │
    │                      │──Query pool────────│                    │
    │                      │──Call Groq────────►│                    │
    │                      │                    │──Select/Generate──►│
    │                      │◄──AI Response──────│                    │
    │                      │                    │                    │
    │                      │──INSERT round──────│                    │
    │                      │──Socket.IO emit────────────────────────►│
    │                      │                    │                    │
    │◄─Round data──────────│                    │    Round data─────►│
    │                      │                    │                    │
    │   [Players answer]   │                    │                    │
    │──POST /answer───────►│                    │                    │
    │                      │──Socket.IO emit────────────────────────►│
    │                      │                    │                    │
    │   [All answered]     │                    │                    │
    │──"Advance Round"────►│                    │                    │
    │                      │──Validate──────────│                    │
    │                      │──Complete round────│                    │
    │                      │──Create next round─│                    │
    │                      │──Socket.IO emit────────────────────────►│
    │                      │                    │                    │
    │◄─New round───────────│                    │    New round──────►│
```

---

## Host Authority Logic

The **host** is the authoritative controller of game flow:

### Host Responsibilities
1. **Start Game** — Transitions lobby from `waiting` → `playing`
2. **Trigger Rounds** — Calls `POST /round/:id/advance` API route
3. **End Game** — Can end game early

### Why Host-Driven (Not Server-Driven)

- **Simplicity**: No background timer process needed on server
- **Flexibility**: Host controls pacing (party conversations between rounds)
- **Cost**: No persistent server process running
- **Reliability**: If host disconnects, auto-migrate to new host

### Auto-Advance Mode (Optional)

Host can enable auto-advance:
- After results display (3s), automatically trigger next round
- Implemented client-side with `Timer` in game BLoC
- If host disconnects mid-auto, new host resumes

```dart
// In GameBloc
void _onRoundCompleted(RoundCompleted event, Emitter<GameState> emit) {
    emit(state.copyWith(phase: GamePhase.results));
    
    if (state.autoAdvance && state.isHost) {
        Future.delayed(const Duration(seconds: 3), () {
            add(const StartNextRound());
        });
    }
}
```

---

## Reconnect Handling

### Player Reconnect Protocol

```dart
class ReconnectService {
    static const maxRetries = 10;
    static const baseDelay = Duration(seconds: 1);
    static const maxDelay = Duration(seconds: 30);

    Future<void> handleDisconnect(String lobbyId) async {
        int retries = 0;
        
        while (retries < maxRetries) {
            final delay = Duration(
                milliseconds: min(
                    baseDelay.inMilliseconds * pow(2, retries).toInt(),
                    maxDelay.inMilliseconds,
                ),
            );
            
            await Future.delayed(delay);
            
            try {
                // 1. Re-establish Realtime subscription
                await realtimeService.reconnect(lobbyId);
                
                // 2. Fetch current game state via REST
                final lobby = await lobbyRepo.getLobby(lobbyId);
                final currentRound = await gameRepo.getCurrentRound(lobbyId);
                
                // 3. Update player status
                await lobbyRepo.updatePlayerStatus(lobbyId, 'connected');
                
                // 4. Reconcile local state
                if (currentRound != null) {
                    gameBloc.add(ReconcileState(
                        round: currentRound,
                        lobbyStatus: lobby.status,
                    ));
                }
                
                return; // Success
            } catch (e) {
                retries++;
            }
        }
        
        // Max retries exceeded
        gameBloc.add(const ConnectionLost());
    }
}
```

### State Reconciliation on Reconnect

| Scenario | Action |
|----------|--------|
| Same round, not yet answered | Show question, allow answer |
| Same round, already answered | Show waiting state |
| Round advanced | Fast-forward to current round |
| Game ended | Navigate to results screen |
| Lobby cancelled | Navigate to home |

---

## Player Leave Handling

### Voluntary Leave
1. Player taps "Leave Game"
2. `lobby_players.status` → `'left'`
3. Other players see "{Name} left" notification
4. Player navigated to Home screen

### Involuntary Disconnect
1. Realtime heartbeat lost (60s timeout)
2. `lobby_players.status` → `'disconnected'`
3. Other players see "{Name} disconnected"
4. If player reconnects within game, status → `'connected'`

### Impact on Game State

```
Player leaves/disconnects
    │
    ▼
Remaining connected players >= 2?
    │
    ├─ YES → Game continues
    │         - Player excluded from current round
    │         - Boldness calculation uses active player count
    │         - If host left → migrate host
    │
    └─ NO → Game auto-ends
              - Status → 'finished'
              - Show partial results
              - "Not enough players" message
```

---

## Minimum Player Enforcement

| Phase | Minimum | Enforcement |
|-------|---------|-------------|
| Lobby waiting | 1 (host) | Game can't start until 2+ |
| Game start | 2 | "Start Game" disabled until 2 connected |
| During game | 2 | Auto-end if < 2 connected |
| Round active | 1 answer | Round can complete with 1+ answers |

---

## Game End Summary

### Group Profile Calculation

At game end, calculate a group profile based on final `boldness_score`:

```dart
enum GroupProfile {
    conservative(0.0, 0.25, '😇', 'Conservative'),
    warming(0.25, 0.50, '😏', 'Adventurous'),
    bold(0.50, 0.75, '🔥', 'Wild'),
    fearless(0.75, 1.0, '💀', 'Fearless');

    final double min;
    final double max;
    final String emoji;
    final String label;
    
    const GroupProfile(this.min, this.max, this.emoji, this.label);
    
    static GroupProfile fromScore(double score) {
        for (final profile in values) {
            if (score >= profile.min && score < profile.max) return profile;
        }
        return fearless;
    }
}
```

### Summary Statistics

```dart
class GameSummary {
    final GroupProfile groupProfile;
    final double finalBoldnessScore;
    final int totalRounds;
    final int totalAnswers;
    final ToneLevel highestToneReached;
    final int deEscalationCount;
    final double avgHaveRatio;        // Group average "I have" percentage
    final String mostHonestEmoji;     // Player with highest "I have" ratio
    final String mostSecretiveEmoji;  // Player with lowest "I have" ratio
    final List<RoundSummary> rounds;
}

class RoundSummary {
    final int roundNumber;
    final String questionText;
    final ToneLevel tone;
    final int haveCount;
    final int haveNotCount;
    final double haveRatio;
}
```

### Results Screen Layout

```
┌──────────────────────────────────────────┐
│                                          │
│            🔥 Your Group is              │
│               WILD                       │
│                                          │
│        Boldness: ████████░░ 72%          │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  📊 Stats                          │  │
│  │  Rounds played: 20                 │  │
│  │  Highest tone: Secretive           │  │
│  │  De-escalations: 1                 │  │
│  │  Avg "I have": 61%                 │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  🏆 Superlatives                   │  │
│  │  Most Honest: 😎 Alex              │  │
│  │  Most Secretive: 🦊 Sam            │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  📜 Round-by-Round                 │  │
│  │  (scrollable list)                 │  │
│  └────────────────────────────────────┘  │
│                                          │
│    [🔄 Play Again]   [🏠 Home]          │
│                                          │
└──────────────────────────────────────────┘
```

---

## Timing & Timeout System

### Round Timer (Client-Side, Host-Authoritative)

```dart
class RoundTimer {
    static const defaultTimeout = Duration(seconds: 30);
    Timer? _timer;
    int _remaining = 30;
    
    void start({
        required int seconds,
        required VoidCallback onTick,
        required VoidCallback onExpire,
    }) {
        _remaining = seconds;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            _remaining--;
            onTick();
            if (_remaining <= 0) {
                _timer?.cancel();
                onExpire(); // Host calls complete-round
            }
        });
    }
    
    void cancel() => _timer?.cancel();
}
```

### Answer Timeout Policy

| Scenario | Behavior |
|----------|----------|
| All players answered before timeout | Complete round immediately |
| Timeout with some answers | Complete round with available answers |
| Timeout with zero answers | Skip round, reuse question next round |
| Player answers after timeout | Rejected (round already completed) |

### Grace Period

After all players answer, wait 1 second before completing (handles network race conditions):

```dart
void _onAllPlayersAnswered() {
    // Grace period for late-arriving answers
    Future.delayed(const Duration(seconds: 1), () {
        add(const CompleteRound());
    });
}
```
