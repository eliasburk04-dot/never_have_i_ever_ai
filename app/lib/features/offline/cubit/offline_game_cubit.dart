import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/engine/escalation_engine.dart';
import '../../../core/service_locator.dart';
import '../../../domain/entities/offline_player.dart';
import '../../../domain/entities/offline_session.dart';
import '../../../domain/repositories/i_offline_session_repository.dart';
import '../../../services/local_question_pool.dart';
import 'offline_game_state.dart';

export 'offline_game_state.dart';

/// Cubit managing the offline pass-and-play game lifecycle.
class OfflineGameCubit extends Cubit<OfflineGameState> {
  OfflineGameCubit() : super(const OfflineGameState());

  final _sessionRepo = getIt<IOfflineSessionRepository>();
  final _questionPool = getIt<LocalQuestionPool>();
  final _uuid = const Uuid();

  /// Cached premium status (read from Hive appSettings box).
  // TODO: Restore after testing — currently bypassed with isPremium: true
  // bool _isPremium = false;

  // Temp state for the current round's question selection
  String? _pendingQuestionId;
  String? _pendingCategory;
  String? _pendingSubcategory;

  // ─── Emergency fallback questions ────────────────────

  static const _emergencyQuestions = {
    'en': [
      'Never have I ever done something I regret',
      'Never have I ever kept a secret from everyone',
      'Never have I ever pretended to be someone else',
    ],
    'de': [
      'Ich hab noch nie etwas getan das ich bereue',
      'Ich hab noch nie ein Geheimnis vor allen bewahrt',
      'Ich hab noch nie so getan als wäre ich jemand anderes',
    ],
    'es': [
      'Yo nunca nunca he hecho algo de lo que me arrepiento',
      'Yo nunca nunca he guardado un secreto de todos',
      'Yo nunca nunca he fingido ser otra persona',
    ],
  };

  // ─── Public API ──────────────────────────────────────

  /// Start a new offline game.
  Future<void> startGame({
    required List<OfflinePlayer> players,
    required int maxRounds,
    required String language,
    required bool nsfwEnabled,
    required bool isPremium,
    int? debugSeed,
  }) async {
    // TODO: Restore after testing
    // _isPremium = isPremium;

    final session = OfflineSession(
      id: _uuid.v4(),
      players: players,
      maxRounds: maxRounds,
      currentRound: 0,
      language: language,
      nsfwEnabled: nsfwEnabled,
      boldnessScore: 0.0,
      currentTone: 'safe',
      createdAt: DateTime.now(),
    );

    await _sessionRepo.saveSession(session);
    await _sessionRepo.setActiveSessionId(session.id);

    _questionPool.beginSession(debugSeed: debugSeed);

    emit(state.copyWith(phase: OfflineGamePhase.idle, session: session));

    // Immediately advance to round 1
    await advanceRound();
  }

  /// Resume an in-progress session from Hive.
  Future<bool> resumeSession(String sessionId) async {
    final session = await _sessionRepo.loadSession(sessionId);
    if (session == null || session.isComplete) return false;

    // Read cached premium
    // TODO: Restore after testing
    // _isPremium = _readCachedPremium();

    _questionPool.beginSession();

    emit(state.copyWith(phase: OfflineGamePhase.idle, session: session));

    await advanceRound();
    return true;
  }

  /// Advance to the next round (or finish the game).
  ///
  /// Strategy: Hybrid distribution using sigmoid curve to decide AI vs pool.
  /// Early rounds favor pool questions, later rounds favor AI generation.
  Future<void> advanceRound() async {
    final session = state.session;
    if (session == null) return;

    final nextRound = session.currentRound + 1;

    // Game over?
    if (nextRound > session.maxRounds) {
      await _finishGame();
      return;
    }

    // Escalation math
    final result = EscalationEngine.advanceRound(
      currentBoldness: session.boldnessScore,
      nextRound: nextRound,
      maxRounds: session.maxRounds,
      nsfwEnabled: session.nsfwEnabled,
      completedRounds: session.rounds,
    );

    // Build category tracking from session history
    final recentCategories = _recentCategories(session, count: 2);
    final recentSubcategories = _recentSubcategories(session, count: 3);
    final recentEnergies = _recentEnergies(session, count: 3);
    final earlyCategoriesSeen = _earlyWindowCategories(session);
    final earlyEnergiesSeen = _earlyWindowEnergies(session);
    final recentQuestionIds = _recentQuestionIds(session, count: 10);

    String questionText;
    bool recycled = false;
    int intensity;
    OfflineQuestionSource questionSource = OfflineQuestionSource.localPool;
    String? questionCategory;
    String? questionSubcategory;

    // Always select from the local JSON pool.
    final selection = _questionPool.select(
      language: session.language,
      intensityMin: result.intensityMin,
      intensityMax: result.intensityMax,
      nsfwEnabled: session.nsfwEnabled,
      // TODO: Restore premium gating after testing
      // isPremium: _isPremium,
      isPremium: true, // TEMP: bypassed for NSFW testing
      usedIds: session.usedQuestionIds,
      roundNumber: nextRound,
      recentCategories: recentCategories,
      recentSubcategories: recentSubcategories,
      recentEnergies: recentEnergies,
      categoriesSeenInEarlyWindow: earlyCategoriesSeen,
      energiesSeenInEarlyWindow: earlyEnergiesSeen,
      recentlyUsedIds: recentQuestionIds,
      escalationMultiplier: result.escalationMultiplier,
      vulnerabilityBias: result.vulnerabilityBias,
    );

    if (selection != null) {
      questionText = selection.text;
      recycled = selection.recycled;
      intensity = selection.question.intensity;
      questionSource = OfflineQuestionSource.localPool;
      _pendingQuestionId = selection.question.id;
      _pendingCategory = selection.question.category;
      _pendingSubcategory = selection.question.subcategory;
      questionCategory = selection.question.category;
      questionSubcategory = selection.question.subcategory;
    } else {
      // Emergency fallback
      final pool =
          _emergencyQuestions[session.language] ?? _emergencyQuestions['en']!;
      questionText = pool[nextRound % pool.length];
      intensity = result.intensityMin;
      questionSource = OfflineQuestionSource.emergencyFallback;
      _pendingQuestionId = null;
      _pendingCategory = null;
      _pendingSubcategory = null;
    }

    // Update session
    final updatedSession = session.copyWith(
      currentRound: nextRound,
      boldnessScore: result.boldness,
      currentTone: result.tone,
      usedQuestionIds: _pendingQuestionId != null && !recycled
          ? [...session.usedQuestionIds, _pendingQuestionId!]
          : session.usedQuestionIds,
    );

    await _sessionRepo.saveSession(updatedSession);

    emit(
      state.copyWith(
        phase: OfflineGamePhase.showingQuestion,
        session: updatedSession,
        currentQuestionText: questionText,
        currentQuestionRecycled: recycled,
        currentIntensity: intensity,
        currentQuestionSource: questionSource,
        currentCategory: questionCategory,
        currentSubcategory: questionSubcategory,
        errorMessage: null,
      ),
    );
  }

  /// Submit the "I have" count for the current round and immediately advance.
  ///
  /// Records the round data, then loads the next question with no
  /// intermediate results screen.
  Future<void> submitAndAdvance(int haveCount) async {
    final session = state.session;
    if (session == null) return;

    final round = OfflineRound(
      roundNumber: session.currentRound,
      questionText: state.currentQuestionText ?? '',
      questionId: _pendingQuestionId,
      tone: session.currentTone,
      intensity: state.currentIntensity,
      haveCount: haveCount,
      haveNotCount: session.playerCount - haveCount,
      totalPlayers: session.playerCount,
      recycled: state.currentQuestionRecycled,
      category: _pendingCategory,
      subcategory: _pendingSubcategory,
    );

    final updatedSession = session.copyWith(rounds: [...session.rounds, round]);

    await _sessionRepo.saveSession(updatedSession);

    // Update local state with the recorded session then immediately advance
    emit(state.copyWith(session: updatedSession));
    await advanceRound();
  }

  /// End the game early.
  Future<void> endGame() async {
    await _finishGame();
  }

  /// Check if there's an active session to resume.
  String? get activeSessionId => _sessionRepo.activeSessionId;

  // ─── Private ─────────────────────────────────────────

  /// Extract last N categories from played rounds.
  List<String> _recentCategories(OfflineSession session, {int count = 2}) {
    final rounds = session.rounds;
    if (rounds.isEmpty) return [];
    final recent = rounds.length >= count
        ? rounds.sublist(rounds.length - count)
        : rounds;
    return recent
        .where((r) => r.category != null)
        .map((r) => r.category!)
        .toList();
  }

  /// Extract last N subcategories from played rounds.
  List<String> _recentSubcategories(OfflineSession session, {int count = 3}) {
    final rounds = session.rounds;
    if (rounds.isEmpty) return [];
    final recent = rounds.length >= count
        ? rounds.sublist(rounds.length - count)
        : rounds;
    return recent
        .where((r) => r.subcategory != null && r.subcategory!.isNotEmpty)
        .map((r) => r.subcategory!)
        .toList();
  }

  /// Extract last N energies from played rounds.
  List<String> _recentEnergies(OfflineSession session, {int count = 3}) {
    final rounds = session.rounds;
    if (rounds.isEmpty) return [];
    final recent = rounds.length >= count
        ? rounds.sublist(rounds.length - count)
        : rounds;
    return recent.map((r) => _energyForIntensity(r.intensity)).toList();
  }

  /// Distinct categories seen in the first 20 played rounds.
  List<String> _earlyWindowCategories(OfflineSession session) {
    final seen = <String>{};
    for (final round in session.rounds.take(20)) {
      final category = round.category;
      if (category != null && category.isNotEmpty) {
        seen.add(category);
      }
    }
    return seen.toList();
  }

  /// Distinct energies seen in the first 20 played rounds.
  List<String> _earlyWindowEnergies(OfflineSession session) {
    final seen = <String>{};
    for (final round in session.rounds.take(20)) {
      seen.add(_energyForIntensity(round.intensity));
    }
    return seen.toList();
  }

  /// Last N asked question IDs, used to prevent immediate recycling loops.
  List<String> _recentQuestionIds(OfflineSession session, {int count = 10}) {
    final ids = session.rounds
        .where((r) => r.questionId != null && r.questionId!.isNotEmpty)
        .map((r) => r.questionId!)
        .toList();
    if (ids.isEmpty) return [];
    return ids.length > count ? ids.sublist(ids.length - count) : ids;
  }

  String _energyForIntensity(int intensity) {
    if (intensity >= 8) return 'heavy';
    if (intensity >= 4) return 'medium';
    return 'light';
  }

  Future<void> _finishGame() async {
    final session = state.session;
    if (session == null) return;

    final finishedSession = session.copyWith(isComplete: true);
    await _sessionRepo.saveSession(finishedSession);
    await _sessionRepo.setActiveSessionId(null);

    emit(
      state.copyWith(
        phase: OfflineGamePhase.complete,
        session: finishedSession,
      ),
    );
  }

  // TODO: Restore after testing
  // bool _readCachedPremium() {
  //   try {
  //     return false;
  //   } catch (_) {
  //     return false;
  //   }
  // }
}
