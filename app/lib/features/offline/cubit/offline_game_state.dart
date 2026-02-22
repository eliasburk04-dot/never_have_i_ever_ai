import 'package:equatable/equatable.dart';

import '../../../domain/entities/offline_session.dart';

/// Phases of an offline game.
enum OfflineGamePhase {
  /// Initial — no game running.
  idle,

  /// A question is being displayed. Players discuss + count hands.
  showingQuestion,

  /// All rounds finished — final summary.
  complete,
}

/// Source of the currently displayed question.
enum OfflineQuestionSource { localPool, aiGenerated, emergencyFallback }

/// State for the offline pass-and-play game.
class OfflineGameState extends Equatable {
  const OfflineGameState({
    this.phase = OfflineGamePhase.idle,
    this.session,
    this.currentQuestionText,
    this.currentQuestionRecycled = false,
    this.currentIntensity = 1,
    this.currentQuestionSource = OfflineQuestionSource.localPool,
    this.currentCategory,
    this.currentSubcategory,
    this.errorMessage,
  });

  final OfflineGamePhase phase;
  final OfflineSession? session;
  final String? currentQuestionText;
  final bool currentQuestionRecycled;
  final int currentIntensity;
  final OfflineQuestionSource currentQuestionSource;
  final String? currentCategory;
  final String? currentSubcategory;
  final String? errorMessage;

  int get roundNumber => session?.currentRound ?? 0;
  int get maxRounds => session?.maxRounds ?? 0;
  int get playerCount => session?.playerCount ?? 0;
  String get currentTone => session?.currentTone ?? 'safe';
  bool get isAiGenerated =>
      currentQuestionSource == OfflineQuestionSource.aiGenerated;

  OfflineGameState copyWith({
    OfflineGamePhase? phase,
    OfflineSession? session,
    String? currentQuestionText,
    bool? currentQuestionRecycled,
    int? currentIntensity,
    OfflineQuestionSource? currentQuestionSource,
    String? currentCategory,
    String? currentSubcategory,
    String? errorMessage,
  }) {
    return OfflineGameState(
      phase: phase ?? this.phase,
      session: session ?? this.session,
      currentQuestionText: currentQuestionText ?? this.currentQuestionText,
      currentQuestionRecycled:
          currentQuestionRecycled ?? this.currentQuestionRecycled,
      currentIntensity: currentIntensity ?? this.currentIntensity,
      currentQuestionSource:
          currentQuestionSource ?? this.currentQuestionSource,
      currentCategory: currentCategory ?? this.currentCategory,
      currentSubcategory: currentSubcategory ?? this.currentSubcategory,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    session,
    currentQuestionText,
    currentQuestionRecycled,
    currentIntensity,
    currentQuestionSource,
    currentCategory,
    currentSubcategory,
    errorMessage,
  ];
}
