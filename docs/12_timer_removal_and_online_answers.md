# 12 — Timer Removal & Online Answer Sync

> **Note (Feb 2026):** This document was written when the backend used Supabase.
> The app has since been fully migrated to a self-hosted Raspberry Pi backend
> (Fastify + Socket.IO + PostgreSQL). All Supabase references below are historical.
> The design principles still apply — only the infrastructure layer changed.

> Implementation blueprint for removing all timers, adding per-player answer
> visibility in online mode, and streamlining round transitions in both modes.

---

## 1. Game State Machine Changes

### 1.1 Offline — `OfflineGamePhase`

**Current phases:** `idle → showingQuestion → roundResults → complete`

**New phases:** `idle → showingQuestion → complete`

`roundResults` is **removed entirely**. After the host taps "Next", the cubit
calls `advanceRound()` which directly emits `showingQuestion` with the new
question. The `submitHaveCount()` method still records the round data for the
final summary but no longer transitions to `roundResults`.

```
idle ─── startGame() ──▶ showingQuestion ◀─── advanceRound() ───┐
                              │                                   │
                              │── submitAndAdvance() ─────────────┘
                              │
                              └── endGame() ──▶ complete
```

**Key change:** `submitHaveCount()` is renamed/refactored to `submitAndAdvance()`
which atomically:
1. Records the OfflineRound to session history
2. Calls `advanceRound()` to load the next question
3. Never emits `roundResults` — goes straight to new `showingQuestion`

### 1.2 Online — `GamePhase`

**Current phases:** `loading | waitingForRound | showingQuestion | answering | results | complete`

**New phases:** `loading | playing | complete`

The `playing` phase is the single active state. Within it, the state carries:
- `currentRound` — the active round
- `answers` — `Map<String, bool>` mapping `userId → answer` for current round
- `players` — `List<Player>` for the lobby
- `hasAnswered` / `myAnswer` — local client state
- `allAnswered` — computed: `answers.length == activePlayers.length`

```
loading ─── GameStarted ──▶ playing ◀─── HostAdvanced ───┐
                              │                            │
                              │── AnswerSubmitted ───(no phase change, just updates myAnswer)
                              │── AnswerReceived ───(no phase change, just updates answers map)
                              │── HostAdvanced ────────────┘
                              │
                              └── GameEnded ──▶ complete
```

No `results`, no `waitingForRound`, no `answering`. The question + player
status list + answer buttons all coexist on one screen in the `playing` phase.

---

## 2. Supabase Schema Adjustments

### 2.1 `answers` table — add `updated_at` and UPSERT support

```sql
-- Migration: 005_answer_upsert_and_cleanup.sql

-- Add updated_at column for answer-change tracking
ALTER TABLE public.answers
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- Create index for fast "answers for this round" queries
CREATE INDEX IF NOT EXISTS idx_answers_round_lobby
  ON public.answers(round_id, lobby_id);
```

No other table changes needed. The existing schema already has:
- `lobbies` with `current_round`, `host_id`, `status`
- `rounds` with `lobby_id`, `round_number`, `status`, `question_text`
- `answers` with `round_id`, `user_id`, `lobby_id`, `answer`
- `lobby_players` with `lobby_id`, `user_id`, `status`, `is_host`

### 2.2 Remove `round_timeout_seconds` from lobbies

```sql
-- Optional cleanup (non-breaking — just stop using it)
-- ALTER TABLE public.lobbies DROP COLUMN IF EXISTS round_timeout_seconds;
-- For safety, just ignore it; remove in a future migration.
```

### 2.3 New RPC: `advance_round`

This replaces the host calling the `next-round` Edge Function directly for
the "advance" action. It enforces the invariant that all active players must
have answered before advancing.

```sql
-- Migration: 005_answer_upsert_and_cleanup.sql (continued)

CREATE OR REPLACE FUNCTION public.advance_round_check(
  p_lobby_id UUID,
  p_round_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_active_count INT;
  v_answer_count INT;
  v_host_id UUID;
BEGIN
  -- Verify caller is host
  SELECT host_id INTO v_host_id
  FROM public.lobbies WHERE id = p_lobby_id;
  
  IF v_host_id != auth.uid() THEN
    RAISE EXCEPTION 'Only the host can advance the round';
  END IF;

  -- Count active (connected) players
  SELECT COUNT(*) INTO v_active_count
  FROM public.lobby_players
  WHERE lobby_id = p_lobby_id AND status = 'connected';

  -- Count answers for this round
  SELECT COUNT(*) INTO v_answer_count
  FROM public.answers
  WHERE round_id = p_round_id AND lobby_id = p_lobby_id;

  RETURN v_answer_count >= v_active_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 3. RLS Policies for Answers

### 3.1 Current policies (already exist)

```sql
-- SELECT: players in same lobby can read answers
CREATE POLICY answers_select ON public.answers FOR SELECT USING (
  lobby_id IN (SELECT lobby_id FROM public.lobby_players lp WHERE lp.user_id = auth.uid())
);

-- INSERT: only own answers
CREATE POLICY answers_insert ON public.answers FOR INSERT WITH CHECK (user_id = auth.uid());
```

### 3.2 New: UPDATE policy for answer changes

```sql
-- Migration: 005 (continued)

-- Allow players to update their own answer (change answer before host advances)
CREATE POLICY answers_update ON public.answers
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
```

### 3.3 Rounds — add INSERT policy for host

The `next-round` Edge Function uses the service role key, so it bypasses RLS.
No change needed. But if we ever move round creation client-side:

```sql
-- Not needed now (Edge Function uses service_role), but documented for reference:
-- CREATE POLICY rounds_insert ON public.rounds
--   FOR INSERT WITH CHECK (
--     EXISTS (
--       SELECT 1 FROM public.lobbies
--       WHERE id = lobby_id AND host_id = auth.uid()
--     )
--   );
```

---

## 4. Realtime Subscription Strategy

### 4.1 Current subscriptions

| Channel Key | Table | Filter | Events |
|---|---|---|---|
| `lobby:{id}` | `lobbies` | `id = lobbyId` | UPDATE |
| `lobby_players:{id}` | `lobby_players` | `lobby_id = lobbyId` | INSERT, UPDATE, DELETE |
| `rounds:{id}` | `rounds` | `lobby_id = lobbyId` | INSERT, UPDATE |

### 4.2 New subscription: answers for current round

```
answers:{roundId}  →  table: answers  →  filter: round_id = roundId  →  INSERT, UPDATE
```

**Lifecycle:**
1. When a new round starts (via `RoundUpdated` event from rounds subscription),
   unsubscribe from the previous round's answers channel.
2. Subscribe to `answers:{newRoundId}` for INSERT + UPDATE events.
3. On each event, update `answers` map in GameState.

### 4.3 Scoping

- **Rounds subscription** stays lobby-scoped (one channel for entire game).
- **Answers subscription** is round-scoped (re-created each round). This keeps
  the payload small and avoids accumulating stale listeners.
- **Players subscription** stays lobby-scoped.

### 4.4 `RealtimeService` additions

Add a new method `subscribeAnswers` that supports both INSERT and UPDATE:

```dart
// Already exists but only listens to INSERT. Modify to also handle UPDATE.
RealtimeChannel subscribeAnswers({
  required String roundId,
  required void Function(Map<String, dynamic> payload, String eventType) onChange,
})
```

---

## 5. Host-Advance Implementation

### 5.1 Flow (online)

```
Host taps "Next Question"
  │
  ├── Client-side guard: allAnswered == true? If not, button is disabled.
  │
  ├── 1. Call Supabase RPC `advance_round_check(lobby_id, round_id)`
  │      Returns true/false. If false → show error toast, abort.
  │
  ├── 2. Call Edge Function `next-round` with { lobby_id }
  │      This atomically:
  │        a. Processes previous round answers → updates boldness
  │        b. Selects next question (AI/pool)
  │        c. Creates new round record (status: 'active')
  │        d. Updates lobby (current_round, boldness, tone, history)
  │
  ├── 3. Realtime broadcast triggers:
  │        - rounds subscription → RoundUpdated event → all clients see new question
  │        - lobby subscription → LobbyUpdated event → all clients see new current_round
  │
  └── 4. GameBloc handles RoundUpdated:
           - Resets local answer state (hasAnswered=false, myAnswer=null)
           - Clears answers map
           - Resubscribes answers channel to new round_id
           - Emits updated GameState with new question
```

### 5.2 Pseudocode

```dart
// In GameBloc
Future<void> _onHostAdvanceRequested(
  HostAdvanceRequested event,
  Emitter<GameState> emit,
) async {
  if (state.currentRound == null || state.lobbyId == null) return;
  if (!state.allAnswered) return; // guard

  emit(state.copyWith(isAdvancing: true));

  try {
    // Step 1: server-side check
    final canAdvance = await _gameRepo.checkCanAdvance(
      lobbyId: state.lobbyId!,
      roundId: state.currentRound!.id,
    );
    if (!canAdvance) {
      emit(state.copyWith(
        isAdvancing: false,
        errorMessage: 'Not all players have answered yet',
      ));
      return;
    }

    // Step 2: trigger next round via Edge Function
    final nextRound = await _gameRepo.triggerNextRound(state.lobbyId!);

    if (nextRound == null) {
      // Game over — edge function returned status: 'game_over'
      emit(state.copyWith(phase: GamePhase.complete, isAdvancing: false));
      return;
    }

    // Step 3: round will arrive via realtime subscription.
    // The _onRoundUpdated handler will reset answers and emit new state.
    // isAdvancing will be cleared there.
  } catch (e) {
    emit(state.copyWith(
      isAdvancing: false,
      errorMessage: 'Failed to advance: $e',
    ));
  }
}
```

### 5.3 Invariants enforced

1. **Client-side:** "Next Question" button disabled until `allAnswered == true`.
2. **Server-side (RPC):** `advance_round_check` verifies answer count ≥ active player count.
3. **Edge Function:** `next-round` only the host calls it (JWT contains host's user_id; Edge Function
   can verify `lobby.host_id == caller` if needed, though currently it uses service role).

---

## 6. Flutter UI Changes

### 6.1 Online Round Screen — Complete Redesign

**File:** `lib/features/game/view/game_round_screen.dart`

One screen, one phase (`playing`). Layout top-to-bottom:

```
┌─────────────────────────────────────┐
│  Round 3/20              SECRETIVE  │  ← header bar
├─────────────────────────────────────┤
│                                     │
│         NEVER HAVE I EVER           │
│    "eaten pizza for breakfast"      │  ← question card (dominant)
│                                     │
├─────────────────────────────────────┤
│  ┌──────────┐    ┌──────────────┐   │
│  │  I HAVE  │    │  I HAVE NOT  │   │  ← answer buttons (GREEN / RED)
│  │  (green) │    │    (red)     │   │
│  └──────────┘    └──────────────┘   │
├─────────────────────────────────────┤
│  Players                            │
│  ┌─────────────────────────────────┐│
│  │ 😎 Alex         ██████ I HAVE  ││  ← green row
│  │ 🙂 Sam       ─── waiting ───   ││  ← gray row
│  │ 😎 Jordan   ██████ I HAVE NOT  ││  ← red row
│  └─────────────────────────────────┘│
├─────────────────────────────────────┤
│  ┌─────────────────────────────────┐│
│  │       NEXT QUESTION  →         ││  ← host-only, disabled until all answered
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

### 6.2 New Widget: `PlayerStatusList`

```dart
class PlayerStatusList extends StatelessWidget {
  const PlayerStatusList({
    super.key,
    required this.players,
    required this.answers,
    required this.currentUserId,
  });

  final List<Player> players;
  final Map<String, bool> answers; // userId → true/false
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final activePlayers = players.where((p) => p.isConnected).toList();

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Players', style: AppTypography.overline),
          SizedBox(height: AppSpacing.sm),
          ...activePlayers.map((player) {
            final answer = answers[player.userId];
            return _PlayerRow(
              player: player,
              answer: answer,
              isCurrentUser: player.userId == currentUserId,
            );
          }),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  // answer == null → not answered (gray)
  // answer == true → "I Have" (green)
  // answer == false → "I Have Not" (red)
  
  Color get _backgroundColor {
    if (answer == null) return AppColors.surface;
    return answer! ? Color(0xFF0D2818) : Color(0xFF2A0D0D);
  }
  
  Color get _indicatorColor {
    if (answer == null) return AppColors.textTertiary;
    return answer! ? Color(0xFF22C55E) : Color(0xFFEF4444);
  }
  
  String get _statusText {
    if (answer == null) return 'waiting...';
    return answer! ? 'I Have' : 'I Have Not';
  }
}
```

### 6.3 Answer Button Styles

**"I Have" button:** 
- Background: `Color(0xFF166534)` (deep green) → pressed: `Color(0xFF14532D)`
- Border: `Color(0xFF22C55E)` with 0.3 opacity
- Text: White
- Glow: `Color(0xFF22C55E)` at 0.15 opacity, 16 blur

**"I Have Not" button:**
- Background: `Color(0xFF7F1D1D)` (deep red) → pressed: `Color(0xFF991B1B)`  
- Border: `Color(0xFFEF4444)` with 0.3 opacity
- Text: White
- Glow: `Color(0xFFEF4444)` at 0.15 opacity, 16 blur

**Selected state (after answering):**
- The chosen button stays highlighted with a glow ring
- The other button dims to 0.3 opacity
- Both buttons remain tappable (allowing answer change)

### 6.4 Host "Next Question" Button

```dart
// Only shown if isHost
AppButton(
  label: allAnswered ? 'Next Question' : 'Waiting for answers...',
  onPressed: allAnswered ? () => bloc.add(HostAdvanceRequested()) : null,
  icon: allAnswered ? Icons.arrow_forward_rounded : Icons.hourglass_top_rounded,
  isLoading: state.isAdvancing,
)
```

Disabled state: 0.4 opacity, no glow, gray text.
Enabled state: full accent glow, white text, arrow icon.

---

## 7. Offline UI Changes

### 7.1 Remove Timer

**In `_QuestionPhase`:**
- Remove `CountdownTimer` widget from the header Row
- Remove `onComplete: _confirm` timer callback
- Remove `import countdown_timer.dart`

### 7.2 Remove Intermediate Results Screen

**In `OfflineGameScreen`:**
- Remove `_ResultsPhase` widget entirely
- Remove `OfflineGamePhase.roundResults` case from the switch

**In `_QuestionPhase`:**
- Replace `_confirm()` with `_submitAndAdvance()`:
  ```dart
  void _submitAndAdvance() {
    HapticFeedback.mediumImpact();
    context.read<OfflineGameCubit>().submitAndAdvance(_selectedHaveCount);
  }
  ```

### 7.3 Rename "Confirm" → "Next"

The button at the bottom changes from "Confirm" (which submitted to results)
to "Next" (which submits the count AND immediately shows the next question).

```dart
AppButton(
  label: 'Next',
  onPressed: _submitAndAdvance,
  icon: Icons.arrow_forward_rounded,
)
```

### 7.4 New flow

```
Host sees question → group discusses → host sets "I Have" count →
host taps "Next" → INSTANTLY shows next question (no intermediate screen)
```

The round data (haveCount, etc.) is still saved for the final summary screen.

---

## 8. Edge Cases

### 8.1 Player disconnects mid-round (online)

**Detection:** `lobby_players` subscription fires UPDATE with `status: 'disconnected'`.

**Handling:**
- Remove disconnected player from the "active players" count.
- `allAnswered` recalculates: `answers.length >= connectedPlayers.length`.
- If they had already answered, their answer stays. If not, they're excluded
  from the requirement.
- UI: Show their row as dimmed/grayed with "disconnected" label.
- If all remaining connected players have answered, host can advance.

### 8.2 Player leaves lobby mid-round (online)

**Detection:** `lobby_players` subscription fires UPDATE/DELETE with `status: 'left'`.

**Handling:**
- Remove from active players list entirely.
- Their answers (if any) are ignored for the "all answered" check.
- If only 1 player remains, show "Not enough players" and navigate to results.

### 8.3 Late joiners

**Policy:** Players can only join during `status: 'waiting'`. Once the game
starts (`status: 'playing'`), no new joins are allowed.

The `join_lobby` flow already checks `lobby.status == 'waiting'`. No change.

### 8.4 Answer changes (online)

**Policy:** Players can change their answer until the host advances.

**Implementation:**
- Use UPSERT (`ON CONFLICT (round_id, user_id) DO UPDATE SET answer = $1, updated_at = now()`)
  in the `submitAnswer` repository method.
- Realtime: subscribe to both INSERT and UPDATE on answers table.
- UI: The selected button shows the current answer. Tapping the other button
  sends the update. The player status list updates in realtime.

```dart
// In GameRepository
Future<void> submitAnswer({
  required String roundId,
  required String lobbyId,
  required bool answer,
}) async {
  await _supabase.client.from('answers').upsert(
    {
      'round_id': roundId,
      'user_id': _supabase.currentUserId,
      'lobby_id': lobbyId,
      'answer': answer,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    },
    onConflict: 'round_id,user_id',
  );
}
```

### 8.5 Host disconnect / host migration

**Detection:** `lobby_players` subscription shows host's `status: 'disconnected'`.

**Handling:**
1. Start a 15-second grace period. If the host reconnects, continue.
2. After grace period, any connected player can call `migrate_host` RPC
   (already exists in `003_rpc_functions.sql`).
3. The new host gets the "Next Question" button. Non-hosts lose it.
4. Realtime: `lobbies` subscription fires UPDATE with new `host_id`.
   GameBloc checks `lobby.hostId == currentUserId` to determine host status.

**Implementation in GameBloc:**
```dart
bool get isHost => state.lobby?.hostId == _supabase.currentUserId;
```

### 8.6 Stale answer subscription after round change

When a new round arrives via the rounds realtime channel:
1. Unsubscribe from `answers:{oldRoundId}` 
2. Clear `answers` map in state
3. Subscribe to `answers:{newRoundId}`
4. Fetch existing answers for the new round (in case of race condition)

---

## 9. Test Plan

### 9.1 Unit Tests — "All Answered" Logic

**File:** `test/features/game/all_answered_test.dart`

```dart
group('allAnswered', () {
  test('returns false when no answers', () {
    final state = GameState(
      players: [player1, player2, player3],
      answers: {},
    );
    expect(state.allAnswered, false);
  });

  test('returns false when partial answers', () {
    final state = GameState(
      players: [player1, player2, player3],
      answers: {player1.userId: true},
    );
    expect(state.allAnswered, false);
  });

  test('returns true when all connected players answered', () {
    final state = GameState(
      players: [player1, player2, player3],
      answers: {
        player1.userId: true,
        player2.userId: false,
        player3.userId: true,
      },
    );
    expect(state.allAnswered, true);
  });

  test('excludes disconnected players', () {
    final state = GameState(
      players: [player1, player2, disconnectedPlayer3],
      answers: {
        player1.userId: true,
        player2.userId: false,
      },
    );
    expect(state.allAnswered, true);
  });

  test('handles answer change (same count, different value)', () {
    final state = GameState(
      players: [player1, player2],
      answers: {player1.userId: false, player2.userId: true},
    );
    expect(state.allAnswered, true);
    
    // Player 1 changes answer
    final updated = state.copyWith(
      answers: {player1.userId: true, player2.userId: true},
    );
    expect(updated.allAnswered, true);
  });
});
```

### 9.2 Unit Tests — Offline Instant Advance

```dart
group('OfflineGameCubit submitAndAdvance', () {
  test('records round and immediately advances to next question', () async {
    // Start game with 3 rounds
    await cubit.startGame(players: [...], maxRounds: 3, ...);
    expect(cubit.state.phase, OfflineGamePhase.showingQuestion);
    expect(cubit.state.roundNumber, 1);
    
    // Submit and advance
    await cubit.submitAndAdvance(2); // 2 out of N said "I have"
    expect(cubit.state.phase, OfflineGamePhase.showingQuestion); // NOT roundResults!
    expect(cubit.state.roundNumber, 2);
    expect(cubit.state.session!.rounds.length, 1); // round 1 recorded
  });
  
  test('last round transitions to complete', () async {
    await cubit.startGame(players: [...], maxRounds: 1, ...);
    await cubit.submitAndAdvance(1);
    expect(cubit.state.phase, OfflineGamePhase.complete);
  });
});
```

### 9.3 Unit Tests — GameBloc Answer Handling

```dart
group('GameBloc online answers', () {
  test('AnswerReceived updates answers map', () {
    bloc.add(AnswerReceived(userId: 'u1', answer: true));
    expect(bloc.state.answers, {'u1': true});
  });
  
  test('AnswerReceived handles answer change via UPDATE', () {
    bloc.add(AnswerReceived(userId: 'u1', answer: true));
    bloc.add(AnswerReceived(userId: 'u1', answer: false)); // changed
    expect(bloc.state.answers, {'u1': false});
  });
  
  test('HostAdvanceRequested blocked when not all answered', () {
    // Only 1 of 3 answered
    bloc.add(HostAdvanceRequested());
    expect(bloc.state.errorMessage, isNull); // silently ignored
    expect(bloc.state.phase, GamePhase.playing); // no change
  });
});
```

### 9.4 Integration Tests — Realtime Updates

```dart
// These test the actual Supabase realtime behavior.
// Run against a local Supabase instance or staging.

group('Realtime answer sync', () {
  test('answer INSERT triggers callback', () async {
    final completer = Completer<Map<String, dynamic>>();
    realtimeService.subscribeAnswers(
      roundId: testRoundId,
      onChange: (data, event) => completer.complete(data),
    );
    
    // Insert answer from another client
    await supabase.from('answers').insert({...});
    
    final data = await completer.future.timeout(Duration(seconds: 5));
    expect(data['answer'], true);
  });
  
  test('answer UPDATE triggers callback', () async {
    // Similar test for UPSERT / UPDATE events
  });
});
```

### 9.5 Manual QA Checklist — iOS

| # | Test | Expected | Pass? |
|---|------|----------|-------|
| **Offline Mode** | | | |
| O1 | Start offline game, verify NO timer visible | No countdown anywhere | |
| O2 | Submit "I Have" count, tap Next | Instantly shows next question, no results screen | |
| O3 | Play to last round, tap Next | Navigates to final summary/results screen | |
| O4 | Check final summary shows all round data | All rounds with have/have not counts visible | |
| O5 | Background app during game, return | Game state preserved, continues from same question | |
| **Online Mode** | | | |
| N1 | Create lobby, start game | No timer visible anywhere | |
| N2 | Tap "I Have" (green button) | Button highlighted green, player row turns green | |
| N3 | Tap "I Have Not" (red button) to change | Button switches to red, row updates to red | |
| N4 | Other player answers | Their row updates in realtime (< 1 sec) | |
| N5 | Host sees "Next Question" disabled | Button grayed out while waiting for answers | |
| N6 | All players answer | "Next Question" button becomes enabled with glow | |
| N7 | Host taps "Next Question" | All clients instantly see new question, answer state resets | |
| N8 | Non-host player sees no "Next Question" button | Button hidden or explicitly marked host-only | |
| N9 | Player disconnects mid-round | Remaining players can still play; host can advance | |
| N10 | Host disconnects for >15s | Host migrates to next player; new host gets button | |
| N11 | Play to final round | All clients navigate to results screen | |
| N12 | Check results screen | Shows all rounds with per-round stats | |
| **Edge Cases** | | | |
| E1 | Kill app, reopen during online game | Reconnects, sees current round state | |
| E2 | Airplane mode during answer submit | Error toast, can retry when reconnected | |
| E3 | Two players submit simultaneously | Both answers recorded correctly, no conflicts | |
| E4 | 3+ players in lobby, one leaves mid-game | Game continues with remaining players | |

---

## Appendix A: Files to Modify

### Dart (app/lib/)

| File | Changes |
|------|---------|
| `features/offline/cubit/offline_game_state.dart` | Remove `roundResults` phase |
| `features/offline/cubit/offline_game_cubit.dart` | Add `submitAndAdvance()`, remove `submitHaveCount()` result phase |
| `features/offline/view/offline_game_screen.dart` | Remove `_ResultsPhase`, remove `CountdownTimer`, rename Confirm→Next |
| `features/game/bloc/game_event_state.dart` | Rewrite phases, add `answers` map, `players` list, `allAnswered`, `isAdvancing`, new events |
| `features/game/bloc/game_bloc.dart` | Rewrite handlers, add answer tracking, answer subscription, host advance |
| `features/game/view/game_round_screen.dart` | Full redesign: single screen, player list, green/red buttons, host button |
| `domain/repositories/i_game_repository.dart` | Add `checkCanAdvance()`, change `submitAnswer` to upsert |
| `data/repositories/game_repository.dart` | Implement upsert, add `checkCanAdvance` RPC call |
| `services/realtime_service.dart` | Extend `subscribeAnswers` for INSERT + UPDATE |
| `core/constants/app_constants.dart` | Remove `roundTimeoutSeconds`, `resultsDisplaySeconds` |
| `core/theme/app_colors.dart` | Add `answerGreen`, `answerRed`, row background colors |

### SQL (supabase/migrations/)

| File | Changes |
|------|---------|
| `005_answer_upsert_and_cleanup.sql` | New migration: `updated_at` column, answer UPDATE policy, `advance_round_check` RPC |

### Edge Functions (supabase/functions/)

| File | Changes |
|------|---------|
| `next-round/index.ts` | No changes needed (already handles round creation correctly) |
| `complete-round/index.ts` | No changes needed (still used for finalizing round stats) |

---

## Appendix B: Execution Order

1. **SQL migration** — deploy `005_answer_upsert_and_cleanup.sql` to Supabase
2. **Offline changes** — state machine + cubit + UI (can test independently)
3. **Online state/bloc** — rewrite GamePhase, events, state
4. **Online realtime** — extend RealtimeService answer subscription
5. **Online repository** — upsert + checkCanAdvance
6. **Online UI** — new round screen with player list + green/red buttons
7. **Theme updates** — new answer colors
8. **Tests** — unit + integration
9. **QA on device** — manual checklist
