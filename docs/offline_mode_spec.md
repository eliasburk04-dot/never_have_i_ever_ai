# 🎮 Solo Device / Offline Pass-and-Play Mode — Full Design Spec

> **Version:** 1.0  
> **Status:** Design Complete — Ready for Implementation  
> **Last Updated:** 2025-01-XX

---

## Table of Contents

- [A. Feature Specification](#a-feature-specification)
- [B. Updated Architecture Diagram](#b-updated-architecture-diagram)
- [C. New/Changed Folder Structure](#c-newchanged-folder-structure)
- [D. Data Models (Dart Classes)](#d-data-models-dart-classes)
- [E. Hive Box Design](#e-hive-box-design)
- [F. EscalationEngine Formulas](#f-escalationengine-formulas)
- [G. Question Selection Rules](#g-question-selection-rules)
- [H. UI Flow](#h-ui-flow)
- [I. Implementation Plan](#i-implementation-plan)
- [J. Test Plan](#j-test-plan)
- [K. Migration Plan](#k-migration-plan)

---

## A. Feature Specification

### A.1 — Summary

Add a **Solo Device / Offline Pass-and-Play** mode that allows a group of friends to play "Never Have I Ever" on **one phone** with **no internet required**. Players physically pass the device to each other (or all look at the same screen and tap together). All game logic, question selection, and escalation run 100% on-device using a **bundled question pool** stored locally.

### A.2 — Core Rules

| Rule | Detail |
|------|--------|
| **Player count** | 2–20 (same as online). Names entered at setup. |
| **Rounds** | 5–50 (Free), 5–100 (Premium) — same limits. |
| **NSFW toggle** | Respected. Filters questions with `is_nsfw == true`. |
| **Language** | EN / DE / ES — uses the appropriate text column. |
| **Question source** | Bundled JSON derived from `002_seed_questions.sql` (50 questions). |
| **Escalation** | Pure on-device `EscalationEngine` — a Dart port of the Edge Function's boldness / tone / progression logic. No AI calls. |
| **Timer** | Same 30 s countdown per round. All players see the question simultaneously and vote on the same screen. |
| **Pass-and-Play UX** | All players are in the same physical space. They see the question, everyone answers (tally on-screen), then results. No phone-passing needed for answers — it's a "show of hands" digital style. |
| **Premium gating** | NSFW (intensity 8-10) questions still require `is_premium && nsfw_enabled`. Max rounds still capped per tier. |
| **No auth required** | Offline mode skips backend authentication entirely. |
| **History** | Game history stored locally in Hive. Viewable from home screen. |

### A.3 — Edge Cases

| Edge Case | Handling |
|-----------|----------|
| **Question pool exhausted** | Reshuffle already-used questions with a "🔄 Recycled!" badge on the card. Track `usedQuestionIds` and only recycle when pool is empty for the current intensity range. |
| **All players answer "I have not"** | Normal — boldness stays flat or decreases. De-escalation may trigger. |
| **All players answer "I have"** | Big boldness jump, escalation continues normally. |
| **App killed mid-game** | Hive persists `OfflineGameSession`. On next launch, offer "Resume Game?" dialog. |
| **Player leaves mid-game** | Host can remove player from the player list. Round results recalculate. Minimum 2 players to continue. |
| **No NSFW + high boldness** | Intensity capped at 7 (same as online). Tone cannot exceed `secretive`. |
| **Airplane mode ON** | Entire flow works. Backend is never called. Network check at startup sets `isOfflineMode` flag. |
| **Switch from offline setup back to home** | OfflineSetupScreen has a back button. No state is saved until "Start Game" is pressed. |
| **Premium check offline** | Cache premium status in `SharedPreferences` on last known check. If cached `true`, allow premium features offline. If never checked (fresh install), treat as free. |

### A.4 — What Offline Mode Does NOT Have

- ❌ AI-generated questions (no Groq calls)
- ❌ Realtime multiplayer sync
- ❌ Per-player anonymous device tracking
- ❌ Remote question pool updates (future: sync when online)

---

## B. Updated Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION                              │
│                                                                  │
│  HomeScreen ─────┬──── "Create Lobby" ──→ CreateLobbyScreen     │
│                  ├──── "Join Lobby"   ──→ JoinLobbyScreen       │
│                  └──── "Play Offline" ──→ OfflineSetupScreen    │
│                                             │                    │
│                                             ▼                    │
│                                     OfflineGameScreen            │
│                                     (question + voting)          │
│                                             │                    │
│                                             ▼                    │
│                                     OfflineResultsScreen         │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                         BLoC LAYER                               │
│                                                                  │
│  ┌──────────────┐        ┌───────────────────┐                  │
│  │  GameBloc     │        │ OfflineGameCubit   │                 │
│  │  (online)     │        │ (offline)          │                 │
│  │  uses Realtime│        │ uses local engine  │                 │
│  └──────────────┘        └───────────────────┘                  │
│                                    │                             │
│                            ┌───────┴────────┐                   │
│                            │  Shared Domain  │                   │
│                            │  EscalationEngine│                  │
│                            │  QuestionSelector│                  │
│                            └────────────────┘                   │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                         DOMAIN / DATA                            │
│                                                                  │
│  ┌──────────────────┐   ┌──────────────────────┐                │
│  │ IQuestionRepo     │   │ OfflineSessionRepo    │               │
│  │   ├─ Backend API  │   │   (Hive persistence)  │              │
│  │   └─ Local JSON   │   └──────────────────────┘               │
│  └──────────────────┘                                           │
│                                                                  │
│  ┌──────────────────┐                                           │
│  │ LocalQuestionPool │  ← assets/questions.json                 │
│  │ (loaded once)     │                                          │
│  └──────────────────┘                                           │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                      LOCAL STORAGE                               │
│                                                                  │
│  ┌────────────┐  ┌──────────────────┐  ┌──────────────────┐    │
│  │ Hive       │  │ SharedPreferences │  │ FlutterSecure    │    │
│  │ (sessions) │  │ (premium cache)   │  │ Storage (keys)   │    │
│  └────────────┘  └──────────────────┘  └──────────────────┘    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Key Architectural Decisions

1. **OfflineGameCubit** (not BLoC) — Offline mode is simpler: no Realtime streams, no server events. A Cubit with explicit method calls is cleaner.
2. **EscalationEngine** — Pure Dart class, no dependencies. Portable between online (Edge Function) and offline (Cubit). The Edge Function remains the source-of-truth for online mode; the Dart port mirrors its math exactly.
3. **LocalQuestionPool** — A service that loads `assets/questions.json` once, indexes by intensity/category/nsfw, and provides O(1) filtered lookups.
4. **Hive** — Lightweight, no-SQL, works offline. One box for game sessions, one for settings.

---

## C. New/Changed Folder Structure

```
app/lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart              ← ADD offline constants
│   └── engine/                             ← NEW folder
│       ├── escalation_engine.dart          ← Pure Dart escalation math
│       └── question_selector.dart          ← Question filtering + selection
│
├── data/
│   └── repositories/
│       └── offline_session_repository.dart ← NEW: Hive CRUD for sessions
│
├── domain/
│   ├── entities/
│   │   ├── offline_player.dart             ← NEW: name-only player
│   │   └── offline_session.dart            ← NEW: full session state
│   └── repositories/
│       └── i_offline_session_repository.dart ← NEW: interface
│
├── features/
│   └── offline/                            ← NEW feature folder
│       ├── cubit/
│       │   ├── offline_game_cubit.dart
│       │   └── offline_game_state.dart
│       └── view/
│           ├── offline_setup_screen.dart
│           ├── offline_game_screen.dart
│           └── offline_results_screen.dart
│
├── services/
│   └── local_question_pool.dart            ← NEW: load + index questions
│
app/assets/
│   └── questions.json                      ← NEW: bundled question data

CHANGED FILES (minimal edits):
├── core/router/app_router.dart             ← Add 3 offline routes
├── core/service_locator.dart               ← Register new services
├── features/home/view/home_screen.dart     ← Add "Play Offline" button
├── app.dart                                ← Add OfflineGameCubit provider
└── pubspec.yaml                            ← Add hive, hive_flutter, path_provider
```

**Total: 10 new files, 5 changed files. Zero existing files rewritten.**

---

## D. Data Models (Dart Classes)

### D.1 — `OfflinePlayer`

```dart
// lib/domain/entities/offline_player.dart
import 'package:equatable/equatable.dart';

class OfflinePlayer extends Equatable {
  const OfflinePlayer({
    required this.name,
    required this.emoji,
    this.haveCount = 0,
    this.totalRoundsPlayed = 0,
  });

  final String name;
  final String emoji; // random avatar emoji assigned at setup
  final int haveCount;
  final int totalRoundsPlayed;

  double get haveRatio =>
      totalRoundsPlayed > 0 ? haveCount / totalRoundsPlayed : 0.0;

  OfflinePlayer copyWith({
    int? haveCount,
    int? totalRoundsPlayed,
  }) {
    return OfflinePlayer(
      name: name,
      emoji: emoji,
      haveCount: haveCount ?? this.haveCount,
      totalRoundsPlayed: totalRoundsPlayed ?? this.totalRoundsPlayed,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'emoji': emoji,
    'haveCount': haveCount,
    'totalRoundsPlayed': totalRoundsPlayed,
  };

  factory OfflinePlayer.fromMap(Map<String, dynamic> map) => OfflinePlayer(
    name: map['name'] as String,
    emoji: map['emoji'] as String,
    haveCount: map['haveCount'] as int? ?? 0,
    totalRoundsPlayed: map['totalRoundsPlayed'] as int? ?? 0,
  );

  @override
  List<Object?> get props => [name, emoji, haveCount, totalRoundsPlayed];
}
```

### D.2 — `OfflineRound`

```dart
// Part of OfflineSession — lightweight round record
class OfflineRound {
  const OfflineRound({
    required this.roundNumber,
    required this.questionText,
    required this.questionId,
    required this.tone,
    required this.intensity,
    required this.haveCount,
    required this.haveNotCount,
    required this.totalPlayers,
    this.recycled = false,
  });

  final int roundNumber;
  final String questionText;
  final String? questionId; // null if recycled/emergency
  final String tone;        // 'safe' | 'deeper' | 'secretive' | 'freaky'
  final int intensity;
  final int haveCount;
  final int haveNotCount;
  final int totalPlayers;
  final bool recycled;

  double get haveRatio =>
      totalPlayers > 0 ? haveCount / totalPlayers : 0.0;

  Map<String, dynamic> toMap() => {
    'roundNumber': roundNumber,
    'questionText': questionText,
    'questionId': questionId,
    'tone': tone,
    'intensity': intensity,
    'haveCount': haveCount,
    'haveNotCount': haveNotCount,
    'totalPlayers': totalPlayers,
    'recycled': recycled,
  };

  factory OfflineRound.fromMap(Map<String, dynamic> map) => OfflineRound(
    roundNumber: map['roundNumber'] as int,
    questionText: map['questionText'] as String,
    questionId: map['questionId'] as String?,
    tone: map['tone'] as String,
    intensity: map['intensity'] as int,
    haveCount: map['haveCount'] as int,
    haveNotCount: map['haveNotCount'] as int,
    totalPlayers: map['totalPlayers'] as int,
    recycled: map['recycled'] as bool? ?? false,
  );
}
```

### D.3 — `OfflineSession`

```dart
// lib/domain/entities/offline_session.dart
import 'package:equatable/equatable.dart';
import 'offline_player.dart';

class OfflineSession extends Equatable {
  const OfflineSession({
    required this.id,
    required this.players,
    required this.maxRounds,
    required this.currentRound,
    required this.language,
    required this.nsfwEnabled,
    required this.boldnessScore,
    required this.currentTone,
    this.rounds = const [],
    this.usedQuestionIds = const [],
    this.isComplete = false,
    this.createdAt,
  });

  final String id;                  // UUID generated locally
  final List<OfflinePlayer> players;
  final int maxRounds;
  final int currentRound;
  final String language;            // 'en' | 'de' | 'es'
  final bool nsfwEnabled;
  final double boldnessScore;       // 0.0 – 1.0
  final String currentTone;         // matches ToneLevel.name
  final List<OfflineRound> rounds;
  final List<String> usedQuestionIds;
  final bool isComplete;
  final DateTime? createdAt;

  OfflineSession copyWith({
    List<OfflinePlayer>? players,
    int? currentRound,
    double? boldnessScore,
    String? currentTone,
    List<OfflineRound>? rounds,
    List<String>? usedQuestionIds,
    bool? isComplete,
  }) {
    return OfflineSession(
      id: id,
      players: players ?? this.players,
      maxRounds: maxRounds,
      currentRound: currentRound ?? this.currentRound,
      language: language,
      nsfwEnabled: nsfwEnabled,
      boldnessScore: boldnessScore ?? this.boldnessScore,
      currentTone: currentTone ?? this.currentTone,
      rounds: rounds ?? this.rounds,
      usedQuestionIds: usedQuestionIds ?? this.usedQuestionIds,
      isComplete: isComplete ?? this.isComplete,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'players': players.map((p) => p.toMap()).toList(),
    'maxRounds': maxRounds,
    'currentRound': currentRound,
    'language': language,
    'nsfwEnabled': nsfwEnabled,
    'boldnessScore': boldnessScore,
    'currentTone': currentTone,
    'rounds': rounds.map((r) => r.toMap()).toList(),
    'usedQuestionIds': usedQuestionIds,
    'isComplete': isComplete,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory OfflineSession.fromMap(Map<String, dynamic> map) {
    return OfflineSession(
      id: map['id'] as String,
      players: (map['players'] as List)
          .map((p) => OfflinePlayer.fromMap(p as Map<String, dynamic>))
          .toList(),
      maxRounds: map['maxRounds'] as int,
      currentRound: map['currentRound'] as int,
      language: map['language'] as String,
      nsfwEnabled: map['nsfwEnabled'] as bool,
      boldnessScore: (map['boldnessScore'] as num).toDouble(),
      currentTone: map['currentTone'] as String,
      rounds: (map['rounds'] as List)
          .map((r) => OfflineRound.fromMap(r as Map<String, dynamic>))
          .toList(),
      usedQuestionIds: List<String>.from(map['usedQuestionIds'] as List),
      isComplete: map['isComplete'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id, players, maxRounds, currentRound, language,
    nsfwEnabled, boldnessScore, currentTone, rounds,
    usedQuestionIds, isComplete, createdAt,
  ];
}
```

### D.4 — `LocalQuestion` (for the bundled JSON pool)

```dart
// Used by LocalQuestionPool service
class LocalQuestion {
  const LocalQuestion({
    required this.id,
    required this.textEn,
    required this.textDe,
    required this.textEs,
    required this.category,
    required this.intensity,
    required this.isNsfw,
    required this.isPremium,
  });

  final String id;
  final String textEn;
  final String textDe;
  final String textEs;
  final String category;
  final int intensity;
  final bool isNsfw;
  final bool isPremium;

  String textForLanguage(String lang) {
    switch (lang) {
      case 'de': return textDe;
      case 'es': return textEs;
      default: return textEn;
    }
  }

  factory LocalQuestion.fromJson(Map<String, dynamic> json) => LocalQuestion(
    id: json['id'] as String,
    textEn: json['text_en'] as String,
    textDe: json['text_de'] as String,
    textEs: json['text_es'] as String,
    category: json['category'] as String,
    intensity: json['intensity'] as int,
    isNsfw: json['is_nsfw'] as bool,
    isPremium: json['is_premium'] as bool,
  );
}
```

---

## E. Hive Box Design

### E.1 — Why Hive?

- Zero native dependencies on iOS (pure Dart implementation)
- Works fully offline — no SQLite binary compilation issues
- Sub-millisecond reads for small datasets (< 1 MB)
- Already has `hive_flutter` for Flutter integration

### E.2 — Box Definitions

| Box Name | Type | Key | Value | Purpose |
|----------|------|-----|-------|---------|
| `offlineSessions` | `Box<String>` | Session UUID | JSON string of `OfflineSession.toMap()` | Persist in-progress and completed game sessions |
| `appSettings` | `Box<dynamic>` | String keys (see below) | Various | Cache app-level settings |

### E.3 — `offlineSessions` Box Keys

```
Key:    "a1b2c3d4-..."   (UUID)
Value:  '{"id":"a1b2c3d4-...","players":[...],"rounds":[...],...}'
```

Operations:
- **Save session:** `box.put(session.id, jsonEncode(session.toMap()))`
- **Load session:** `OfflineSession.fromMap(jsonDecode(box.get(id)!))`
- **List all:** `box.keys.map((k) => OfflineSession.fromMap(jsonDecode(box.get(k)!)))`
- **Delete:** `box.delete(id)`

### E.4 — `appSettings` Box Keys

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `cachedIsPremium` | `bool` | `false` | Cached premium status for offline premium gating |
| `lastPremiumCheck` | `String` | `null` | ISO 8601 timestamp of last server premium check |
| `activeOfflineSessionId` | `String?` | `null` | ID of an in-progress session (for resume prompt) |

### E.5 — Initialization

```dart
// In main.dart, before runApp:
await Hive.initFlutter();
await Hive.openBox<String>('offlineSessions');
await Hive.openBox('appSettings');
```

### E.6 — Data Retention

- **Completed sessions:** Keep last 20. On save, if count > 20, delete oldest.
- **In-progress sessions:** Only 1 allowed at a time. Starting a new game overwrites.
- **Total storage:** ~50 KB per session × 20 = ~1 MB max. Negligible.

---

## F. EscalationEngine Formulas

### F.1 — Constants (mirrored from Edge Function)

```dart
class EscalationEngine {
  EscalationEngine._();

  /// Boldness smoothing factor (EMA alpha)
  static const double alpha = 0.3;

  /// Tone thresholds — maps effective score ranges to tones
  static const Map<String, ToneConfig> toneThresholds = {
    'safe':      ToneConfig(min: 0.0,  max: 0.3,  intensityMin: 1, intensityMax: 3),
    'deeper':    ToneConfig(min: 0.3,  max: 0.55, intensityMin: 3, intensityMax: 5),
    'secretive': ToneConfig(min: 0.55, max: 0.8,  intensityMin: 5, intensityMax: 7),
    'freaky':    ToneConfig(min: 0.8,  max: 1.2,  intensityMin: 7, intensityMax: 10),
  };

  /// Intensity weight per tone for boldness delta
  static const Map<String, double> intensityWeights = {
    'safe': 0.5,
    'deeper': 1.0,
    'secretive': 1.5,
    'freaky': 2.0,
  };
}

class ToneConfig {
  const ToneConfig({
    required this.min,
    required this.max,
    required this.intensityMin,
    required this.intensityMax,
  });
  final double min, max;
  final int intensityMin, intensityMax;
}
```

### F.2 — Boldness Delta

How much the boldness shifts after one round:

```
boldnessDelta = haveRatio × intensityWeight[currentTone]
```

Where:
- `haveRatio = haveCount / totalPlayers`  (0.0 – 1.0)
- `intensityWeight` = `{ safe: 0.5, deeper: 1.0, secretive: 1.5, freaky: 2.0 }`

**Example:** 4/5 players said "I have" in `deeper` tone →  
`delta = 0.8 × 1.0 = 0.8`

```dart
static double calculateBoldnessDelta(
  int haveCount,
  int totalPlayers,
  String currentTone,
) {
  if (totalPlayers == 0) return 0.0;
  final haveRatio = haveCount / totalPlayers;
  final weight = intensityWeights[currentTone] ?? 0.5;
  return haveRatio * weight;
}
```

### F.3 — Boldness Update (Exponential Moving Average)

```
newBoldness = clamp(0.0, 1.0,  α × delta + (1 − α) × currentBoldness)
```

Where `α = 0.3`.

**Example:** Current boldness = 0.4, delta = 0.8 →  
`new = 0.3 × 0.8 + 0.7 × 0.4 = 0.24 + 0.28 = 0.52`

```dart
static double updateBoldnessScore(double currentBoldness, double delta) {
  return (alpha * delta + (1 - alpha) * currentBoldness).clamp(0.0, 1.0);
}
```

### F.4 — Progression Modifier

Natural escalation as the game progresses:

```
progressionModifier = min(0.2, (currentRound / maxRounds) × 0.4)
```

**Example:** Round 10 of 20 → `min(0.2, 0.5 × 0.4) = min(0.2, 0.2) = 0.2`

```dart
static double calculateProgressionModifier(int currentRound, int maxRounds) {
  if (maxRounds == 0) return 0.0;
  return (currentRound / maxRounds * 0.4).clamp(0.0, 0.2);
}
```

### F.5 — Effective Score

```
effectiveScore = newBoldness + progressionModifier
```

### F.6 — De-escalation Check

If the last 2 rounds BOTH had:
- `(1 - haveRatio) > 0.75` (i.e., ≥75% said "I have not")
- `intensity > 5`

Then: `newBoldness = max(0, newBoldness - 0.15)`

```dart
static double applyDeEscalation(
  double boldness,
  List<OfflineRound> recentRounds,
) {
  if (recentRounds.length < 2) return boldness;
  final last = recentRounds[recentRounds.length - 1];
  final secondLast = recentRounds[recentRounds.length - 2];

  if ((1 - last.haveRatio) > 0.75 &&
      (1 - secondLast.haveRatio) > 0.75 &&
      last.intensity > 5 &&
      secondLast.intensity > 5) {
    return (boldness - 0.15).clamp(0.0, 1.0);
  }
  return boldness;
}
```

### F.7 — Tone Determination

```dart
static String determineTone(double effectiveScore, bool nsfwEnabled) {
  if (effectiveScore >= 0.8 && nsfwEnabled) return 'freaky';
  if (effectiveScore >= 0.55) return 'secretive';
  if (effectiveScore >= 0.3) return 'deeper';
  return 'safe';
}
```

### F.8 — Intensity Range

```dart
static (int min, int max) getIntensityRange(String tone, bool nsfwEnabled) {
  final config = toneThresholds[tone]!;
  final maxI = nsfwEnabled ? config.intensityMax : config.intensityMax.clamp(0, 7);
  return (config.intensityMin, maxI);
}
```

### F.9 — Full Round Orchestration (Pseudocode)

```
function advanceRound(session):
  nextRound = session.currentRound + 1
  if nextRound > session.maxRounds → return GAME_OVER

  // 1. Process previous round
  boldness = session.boldnessScore
  if session.rounds.isNotEmpty:
    prevRound = session.rounds.last
    delta = calculateBoldnessDelta(prevRound.haveCount, prevRound.totalPlayers, prevRound.tone)
    boldness = updateBoldnessScore(boldness, delta)

  // 2. De-escalation check
  boldness = applyDeEscalation(boldness, session.rounds)

  // 3. Calculate effective score and tone
  progMod = calculateProgressionModifier(nextRound, session.maxRounds)
  effectiveScore = boldness + progMod
  tone = determineTone(effectiveScore, session.nsfwEnabled)
  (intensityMin, intensityMax) = getIntensityRange(tone, session.nsfwEnabled)

  // 4. Select question
  question = questionSelector.select(
    language: session.language,
    intensityMin: intensityMin,
    intensityMax: intensityMax,
    nsfwEnabled: session.nsfwEnabled,
    isPremium: cachedIsPremium,
    usedIds: session.usedQuestionIds,
  )

  // 5. Return updated session + question for display
  return (boldness, tone, question)
```

---

## G. Question Selection Rules

### G.1 — Pool Loading

On `LocalQuestionPool.initialize()`:
1. Load `assets/questions.json` via `rootBundle.loadString()`
2. Parse into `List<LocalQuestion>`
3. Build indexes:
   - `Map<int, List<LocalQuestion>> byIntensity` — key = intensity (1-10)
   - `Map<String, List<LocalQuestion>> byCategory` — key = category

### G.2 — Selection Algorithm

```dart
LocalQuestion? select({
  required String language,
  required int intensityMin,
  required int intensityMax,
  required bool nsfwEnabled,
  required bool isPremium,
  required List<String> usedIds,
}) {
  // Step 1: Filter by intensity range
  List<LocalQuestion> candidates = [];
  for (int i = intensityMin; i <= intensityMax; i++) {
    candidates.addAll(byIntensity[i] ?? []);
  }

  // Step 2: Filter NSFW
  if (!nsfwEnabled) {
    candidates = candidates.where((q) => !q.isNsfw).toList();
  }

  // Step 3: Filter premium
  if (!isPremium) {
    candidates = candidates.where((q) => !q.isPremium).toList();
  }

  // Step 4: Exclude already used
  final unused = candidates.where((q) => !usedIds.contains(q.id)).toList();

  // Step 5: If unused is non-empty, pick random
  if (unused.isNotEmpty) {
    unused.shuffle();
    return unused.first;
  }

  // Step 6: FALLBACK — expand intensity ±1
  final expanded = <LocalQuestion>[];
  for (int i = (intensityMin - 1).clamp(1, 10);
       i <= (intensityMax + 1).clamp(1, 10); i++) {
    expanded.addAll(byIntensity[i] ?? []);
  }
  if (!nsfwEnabled) expanded.removeWhere((q) => q.isNsfw);
  if (!isPremium) expanded.removeWhere((q) => q.isPremium);
  final expandedUnused = expanded.where((q) => !usedIds.contains(q.id)).toList();
  if (expandedUnused.isNotEmpty) {
    expandedUnused.shuffle();
    return expandedUnused.first;
  }

  // Step 7: RECYCLE — pick from original candidates (already used)
  if (candidates.isNotEmpty) {
    candidates.shuffle();
    return candidates.first; // Cubit sets recycled = true
  }

  // Step 8: null → Cubit uses hardcoded emergency question
  return null;
}
```

### G.3 — Recycling UX

When a question is recycled:
- The `OfflineRound.recycled` flag is `true`
- UI shows a small "🔄 Recycled" badge on the question card
- The same question can be recycled multiple times (no limit)

### G.4 — Category Distribution (Nice-to-have)

To avoid consecutive questions from the same category:

```dart
// Optional enhancement: penalize recently used categories
final recentCategories = session.rounds
    .reversed.take(3)
    .map((r) => r.category)
    .toSet();

// Sort candidates: not-recently-used categories first
unused.sort((a, b) {
  final aRecent = recentCategories.contains(a.category) ? 1 : 0;
  final bRecent = recentCategories.contains(b.category) ? 1 : 0;
  return aRecent.compareTo(bRecent);
});
```

---

## H. UI Flow

### H.1 — Home Screen (Modified)

```
┌──────────────────────────────┐
│  ⚙️               💎        │
│                              │
│      🃏                      │
│   Never Have                 │
│   I Ever                     │
│   The AI-powered party game  │
│                              │
│   ┌──────────────────────┐   │
│   │   🌐 Create Lobby    │   │  ← existing
│   └──────────────────────┘   │
│   ┌──────────────────────┐   │
│   │   🔑 Join Lobby      │   │  ← existing
│   └──────────────────────┘   │
│   ┌──────────────────────┐   │
│   │   📱 Play Offline    │   │  ← NEW: tertiary style
│   └──────────────────────┘   │
│                              │
└──────────────────────────────┘
```

If `activeOfflineSessionId != null`, show a "Resume Game?" banner above the buttons.

### H.2 — Offline Setup Screen (`/offline/setup`)

```
┌──────────────────────────────┐
│  ← Back     Offline Mode     │
│                              │
│  Players (tap + to add)      │
│  ┌──────────────────────┐   │
│  │ 😎 Player 1: [Alice]  │×  │
│  │ 🤩 Player 2: [Bob  ]  │×  │
│  │ 🥳 Player 3: [_____]  │×  │
│  │       ➕ Add Player     │  │
│  └──────────────────────┘   │
│                              │
│  Rounds           [15] ◀─▶  │
│  Language          [EN] ▼   │
│  NSFW              [OFF] 🔒 │  ← locked if not premium
│                              │
│  ┌──────────────────────┐   │
│  │    🚀 Start Game      │   │
│  └──────────────────────┘   │
│                              │
└──────────────────────────────┘
```

- **Player names:** TextFields. Random emoji auto-assigned. Min 2, max 20.
- **NSFW toggle:** Only enabled if `cachedIsPremium`. Shows 🔒 lock icon → tapping navigates to Premium screen.
- **Rounds slider:** 5–50 (free) or 5–100 (premium).
- **Language dropdown:** EN / DE / ES.
- **Start Game:** Validates ≥2 players with names, creates `OfflineSession`, navigates to `/offline/game`.

### H.3 — Offline Game Screen (`/offline/game`)

**Phase: Showing Question**
```
┌──────────────────────────────┐
│  Round 3 / 15          ⏱ 27 │
│  ┌─ 🟢 safe ────────────┐   │
│  └───────────────────────┘   │
│                              │
│  ┌───────────────────────┐   │
│  │                       │   │
│  │  Never have I ever    │   │
│  │  eaten pizza for      │   │
│  │  breakfast             │   │
│  │                       │   │
│  │              🔄 Recycled│  │  ← only if recycled
│  └───────────────────────┘   │
│                              │
│  How many said "I have"?     │
│                              │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐  │
│  │ 0│ │ 1│ │ 2│ │ 3│ │ 4│   │  ← tap to select count
│  └──┘ └──┘ └──┘ └──┘ └──┘  │
│  (out of 4 players)          │
│                              │
│  ┌──────────────────────┐   │
│  │    ✅ Confirm          │   │
│  └──────────────────────┘   │
│                              │
└──────────────────────────────┘
```

**Key UX decision:** Instead of per-player pass-and-play (tedious), we use a **"show of hands" model**:
1. Everyone sees the question.
2. Players physically raise hands (or verbally count).
3. One person taps the count of "I have" responses.
4. This is faster and more fun for party settings.

**Phase: Round Results**
```
┌──────────────────────────────┐
│  Round 3 Results             │
│                              │
│  ┌───────────────────────┐   │
│  │  ████████░░░░  62%    │   │  ← green = I have
│  │  ✋ 3        🙅 2     │   │
│  └───────────────────────┘   │
│                              │
│  "Most of you have done      │
│   this! Getting bold... 😏"  │  ← fun flavor text
│                              │
│  ┌──────────────────────┐   │
│  │    ➡️ Next Round       │   │
│  └──────────────────────┘   │
│                              │
│  ┌──────────────────────┐   │
│  │    🏁 End Game         │   │  ← always visible
│  └──────────────────────┘   │
│                              │
└──────────────────────────────┘
```

Auto-advance after `resultsDisplaySeconds` (3s) OR tap "Next Round".

### H.4 — Offline Results Screen (`/offline/results`)

```
┌──────────────────────────────┐
│  🎉                         │
│  Game Over!                  │
│  15 rounds played            │
│                              │
│  ┌───────────────────────┐   │
│  │ R1  Eaten pizza...     │   │
│  │     ████████░░  80%   │   │
│  ├───────────────────────┤   │
│  │ R2  Sung in shower...  │   │
│  │     ██████░░░░  60%   │   │
│  ├───────────────────────┤   │
│  │ R3  ...                │   │
│  └───────────────────────┘   │
│                              │
│  🏆 Most Adventurous: Alice  │
│  🛡️ Most Innocent: Bob       │
│                              │
│  ┌──────────────────────┐   │
│  │   🏠 Back to Home     │   │
│  └──────────────────────┘   │
│                              │
│  ┌──────────────────────┐   │
│  │   🔄 Play Again       │   │  ← same settings, new game
│  └──────────────────────┘   │
│                              │
└──────────────────────────────┘
```

"Most Adventurous" = player with highest overall `haveRatio` across all rounds (tracked per-player is a V2 nice-to-have — V1 just shows group stats).

---

## I. Implementation Plan

### Phase 1 — Foundation (Day 1)

- [ ] **I.1** Add dependencies to `pubspec.yaml`: `hive: ^2.2.3`, `hive_flutter: ^1.1.0`, `path_provider: ^2.1.5`
- [ ] **I.2** Create `assets/questions.json` — export from `002_seed_questions.sql` data
- [ ] **I.3** Create `LocalQuestion` model
- [ ] **I.4** Create `LocalQuestionPool` service (load, index, `select()`)
- [ ] **I.5** Create `EscalationEngine` (pure Dart, static methods, all formulas from §F)
- [ ] **I.6** Create `QuestionSelector` wrapper (uses `LocalQuestionPool` + `EscalationEngine`)
- [ ] **I.7** Write unit tests for `EscalationEngine` (10+ cases)
- [ ] **I.8** Write unit tests for `QuestionSelector` (8+ cases)

### Phase 2 — Data Layer (Day 1–2)

- [ ] **I.9** Create `OfflinePlayer` entity
- [ ] **I.10** Create `OfflineRound` model
- [ ] **I.11** Create `OfflineSession` entity with `toMap` / `fromMap`
- [ ] **I.12** Create `IOfflineSessionRepository` interface
- [ ] **I.13** Create `OfflineSessionRepository` (Hive implementation)
- [ ] **I.14** Initialize Hive in `main.dart`
- [ ] **I.15** Register new services in `service_locator.dart`
- [ ] **I.16** Write unit tests for `OfflineSession` serialization

### Phase 3 — State Management (Day 2)

- [ ] **I.17** Create `OfflineGameState` (phases: setup, playing, roundResults, complete)
- [ ] **I.18** Create `OfflineGameCubit` (methods: `startGame`, `advanceRound`, `submitHaveCount`, `endGame`)
- [ ] **I.19** Wire `OfflineGameCubit` into `app.dart` BlocProvider
- [ ] **I.20** Write unit tests for `OfflineGameCubit` (12+ cases)

### Phase 4 — UI Screens (Day 2–3)

- [ ] **I.21** Create `OfflineSetupScreen` (player names, settings, start)
- [ ] **I.22** Create `OfflineGameScreen` (question display, "I have" count picker, results phase)
- [ ] **I.23** Create `OfflineResultsScreen` (round history, stats, play again)
- [ ] **I.24** Add 3 routes to `app_router.dart`
- [ ] **I.25** Add "Play Offline" button to `HomeScreen`
- [ ] **I.26** Add "Resume Game?" banner logic

### Phase 5 — Polish (Day 3)

- [ ] **I.27** Add haptic feedback to offline vote confirmation
- [ ] **I.28** Add animations (question card, results bar, tone indicator)
- [ ] **I.29** Add localization keys for offline mode strings (~20 new keys per language)
- [ ] **I.30** Cache premium status in Hive on every online premium check
- [ ] **I.31** Widget tests for `OfflineSetupScreen` and `OfflineGameScreen`
- [ ] **I.32** Full manual QA on device (airplane mode)

### Estimated LOC

| Component | New Lines |
|-----------|-----------|
| Data models | ~250 |
| EscalationEngine | ~120 |
| QuestionSelector / LocalQuestionPool | ~150 |
| OfflineSessionRepository | ~80 |
| OfflineGameCubit + State | ~200 |
| 3 Screens | ~500 |
| Tests | ~400 |
| Assets (questions.json) | ~200 |
| Router/DI/pubspec changes | ~50 |
| **Total** | **~1,950** |

---

## J. Test Plan

### J.1 — Unit Tests

| Test File | Cases | What's Tested |
|-----------|-------|---------------|
| `test/engine/escalation_engine_test.dart` | 12 | `calculateBoldnessDelta` (0 players, all "I have", all "I have not", mixed), `updateBoldnessScore` (clamp 0, clamp 1, normal), `progressionModifier` (early, mid, late, cap), `determineTone` (each threshold), `applyDeEscalation` (triggers, doesn't trigger) |
| `test/engine/question_selector_test.dart` | 10 | Filter by intensity, filter NSFW off, filter premium off, exclude used IDs, expanded fallback, recycle fallback, empty pool returns null, category distribution |
| `test/cubit/offline_game_cubit_test.dart` | 14 | `startGame` (creates session, phase=playing), `advanceRound` (selects question, updates boldness), `submitHaveCount` (stores result, advances to roundResults), `endGame` (marks complete, saves to Hive), full game cycle (5 rounds), resume from Hive, pool exhaustion/recycle, de-escalation triggers tone drop |
| `test/entities/offline_session_test.dart` | 6 | `toMap`/`fromMap` roundtrip, `copyWith` correctness, `OfflinePlayer` serialization, `OfflineRound` serialization, equatable props |
| `test/services/local_question_pool_test.dart` | 5 | Load from JSON string, index by intensity, filter NSFW, filter premium, `textForLanguage` |

**Total new unit tests: ~47**

### J.2 — Widget Tests

| Test File | Cases | What's Tested |
|-----------|-------|---------------|
| `test/widget/offline_setup_screen_test.dart` | 6 | Add/remove players, name validation (empty rejected), NSFW locked when not premium, rounds slider, start button disabled with <2 players, navigates on start |
| `test/widget/offline_game_screen_test.dart` | 5 | Displays question text, "I have" count picker works, confirm button submits, results phase shows bar, next round button advances |

**Total new widget tests: ~11**

### J.3 — Manual QA Checklist

| # | Scenario | Steps | Expected |
|---|----------|-------|----------|
| 1 | Airplane mode full game | Enable airplane mode → Play Offline → 2 players → 5 rounds → complete | No crashes, no network calls, game completes |
| 2 | Resume after kill | Start offline game → Force-kill app → Relaunch | "Resume Game?" banner appears, tapping resumes at correct round |
| 3 | Question pool exhaustion | Set 50 rounds, 2 players → Play through | After ~30 unique questions in target range, recycled badge appears |
| 4 | De-escalation | Play until `secretive` tone → Answer "I have not" with high majority for 2 rounds | Tone drops back to `deeper` or `safe` |
| 5 | NSFW lock (free) | Non-premium → Offline Setup → Try to enable NSFW | Toggle is disabled, shows lock icon |
| 6 | Premium offline | Purchase premium while online → Go offline → Play Offline | NSFW toggle available, 100-round max available |
| 7 | Player management | Add 5 players → Remove 1 → Start game | Game starts with 4 players, count picker shows 0-4 |
| 8 | Language switch | Set language to DE → Play Offline | All questions show German text, UI labels in German |
| 9 | Play Again | Complete game → "Play Again" | New session with same settings, fresh questions |
| 10 | Back navigation | Mid-game → System back button | Confirmation dialog: "End game? Progress will be saved." |

---

## K. Migration Plan

### K.1 — Principle: Additive, Non-Breaking

Every change follows this rule: **existing online mode code paths must not be touched except for trivial routing/DI additions**. The offline feature is a parallel branch of functionality that shares only:

1. Domain entities (`ToneLevel` enum — already exists)
2. UI primitives (theme, widgets like `AppButton`, `CountdownTimer`)
3. Constants from `AppConstants`

### K.2 — Shared Code Extraction

The `EscalationEngine` is a Dart port of the backend's math. Both exist in parallel:

| Context | Escalation Source |
|---------|-------------------|
| Online game | Fastify API route handler (TypeScript, server-side) |
| Offline game | `lib/core/engine/escalation_engine.dart` (Dart, on-device) |

If escalation formulas change in the future, both must be updated. A comment in each file references the other.

### K.3 — File-by-File Change Impact

| File | Change Type | Risk | Details |
|------|-------------|------|---------|
| `pubspec.yaml` | Add 3 deps | ⚪ None | `hive`, `hive_flutter`, `path_provider` — no conflicts with existing deps |
| `main.dart` | Add 2 lines | ⚪ None | `Hive.initFlutter()` + `openBox` calls before `runApp` |
| `app.dart` | Add 1 BlocProvider | ⚪ None | `BlocProvider(create: (_) => OfflineGameCubit())` |
| `service_locator.dart` | Add 3 registrations | ⚪ None | `LocalQuestionPool`, `IOfflineSessionRepository`, `OfflineSessionRepository` |
| `app_router.dart` | Add 3 GoRoutes | ⚪ None | `/offline/setup`, `/offline/game`, `/offline/results` |
| `home_screen.dart` | Add 1 button + resume banner | 🟡 Low | Adds a third button below "Join Lobby". Layout tested to not overflow. |
| `premium_repository.dart` | Add 1 line in `checkPremium` | 🟡 Low | After checking server, cache result: `Hive.box('appSettings').put('cachedIsPremium', isPremium)` |
| All other existing files | **NO CHANGES** | ⚪ None | — |

### K.4 — Dependency Safety

```yaml
# New dependencies — compatibility verified:
hive: ^2.2.3           # Pure Dart, no native deps
hive_flutter: ^1.1.0   # Flutter adapter for Hive
path_provider: ^2.1.5  # Already a transitive dep of flutter_secure_storage
```

`path_provider` is already in the dependency tree (via `flutter_secure_storage`), so no new native plugin is added.

### K.5 — Feature Flag (Optional)

For gradual rollout, add to `AppConstants`:

```dart
static const bool offlineModeEnabled = true; // Set to false to hide the button
```

`HomeScreen` checks this flag before showing "Play Offline".

### K.6 — Rollback Plan

If offline mode causes any issue:
1. Set `offlineModeEnabled = false` — hides the entry point
2. No existing code was modified (except the 5 minimal additions above), so online mode is unaffected
3. Hive boxes are isolated — deleting the app clears them

### K.7 — Future Online ↔ Offline Sync (Out of Scope, Noted)

In a future version, when the device comes back online:
- Upload offline session stats to backend for analytics
- Sync question pool updates (new questions added server-side)
- This is NOT part of V1 offline mode.

---

## Summary

| Deliverable | Status |
|-------------|--------|
| A. Feature Spec | ✅ Complete |
| B. Architecture Diagram | ✅ Complete |
| C. Folder Structure | ✅ 10 new files, 5 changed files |
| D. Data Models | ✅ 4 classes with full serialization |
| E. Hive Design | ✅ 2 boxes, key schema, retention policy |
| F. Escalation Formulas | ✅ 8 formulas with pseudocode + examples |
| G. Question Selection | ✅ 8-step algorithm with fallback chain |
| H. UI Flow | ✅ 4 screen wireframes with interaction details |
| I. Implementation Plan | ✅ 32 tasks across 5 phases |
| J. Test Plan | ✅ ~58 test cases (47 unit + 11 widget) + 10 manual QA |
| K. Migration Plan | ✅ Additive-only, rollback plan, dep safety |
