import 'package:equatable/equatable.dart';

import '../../../core/constants/creator_packs.dart';
import '../../../core/constants/game_setup_config.dart';
import '../../../domain/entities/offline_session.dart';

enum OfflineGamePhase { idle, showingQuestion, complete }

enum OfflineQuestionSource { localPool, aiGenerated, emergencyFallback }

const _unsetOfflineSelectedPackId = Object();

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
    this.categories = GameSetupConfig.defaultCategories,
    this.selectedPackId = CreatorPacks.defaultSelectionId,
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
  final List<String> categories;
  final String? selectedPackId;

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
    List<String>? categories,
    Object? selectedPackId = _unsetOfflineSelectedPackId,
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
      categories: categories ?? this.categories,
      selectedPackId: selectedPackId == _unsetOfflineSelectedPackId
          ? this.selectedPackId
          : selectedPackId as String?,
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
    categories,
    selectedPackId,
  ];
}
