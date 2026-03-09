import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/creator_packs.dart';
import '../../../core/engine/escalation_engine.dart';
import '../../../core/service_locator.dart';
import '../../../domain/entities/offline_player.dart';
import '../../../domain/entities/offline_session.dart';
import '../../../domain/repositories/i_offline_session_repository.dart';
import '../../../services/local_question_pool.dart';
import 'offline_game_state.dart';

export 'offline_game_state.dart';

class OfflineGameCubit extends Cubit<OfflineGameState> {
  OfflineGameCubit() : super(const OfflineGameState());

  final _sessionRepo = getIt<IOfflineSessionRepository>();
  final _questionPool = getIt<LocalQuestionPool>();
  final _uuid = const Uuid();

  bool _isPremium = false;

  String? _pendingQuestionId;
  String? _pendingCategory;
  String? _pendingSubcategory;

  Future<void> startGame({
    required List<OfflinePlayer> players,
    required int maxRounds,
    required String language,
    required bool nsfwEnabled,
    required bool isPremium,
    required List<String> categories,
    required String? selectedPackId,
    int? debugSeed,
  }) async {
    _isPremium = isPremium;
    final selectedPack = selectedPackId != null
        ? CreatorPacks.byId(selectedPackId)
        : null;
    final effectiveCategories = <String>{
      ...categories,
      ...?selectedPack?.categories,
    }.toList();

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

    emit(
      state.copyWith(
        phase: OfflineGamePhase.idle,
        session: session,
        selectedPackId: selectedPackId,
        categories: effectiveCategories,
      ),
    );

    await advanceRound();
  }

  Future<bool> resumeSession(String sessionId) async {
    final session = await _sessionRepo.loadSession(sessionId);
    if (session == null || session.isComplete) return false;

    _isPremium = await _readCachedPremium();

    _questionPool.beginSession();

    emit(state.copyWith(phase: OfflineGamePhase.idle, session: session));

    await advanceRound();
    return true;
  }

  Future<void> advanceRound() async {
    final session = state.session;
    if (session == null) return;

    final nextRound = session.currentRound + 1;

    if (nextRound > session.maxRounds) {
      await _finishGame();
      return;
    }

    final result = EscalationEngine.advanceRound(
      currentBoldness: session.boldnessScore,
      nextRound: nextRound,
      maxRounds: session.maxRounds,
      nsfwEnabled: session.nsfwEnabled,
      completedRounds: session.rounds,
    );

    final recentCategories = _recentCategories(session, count: 2);
    final recentSubcategories = _recentSubcategories(session, count: 3);
    final recentEnergies = _recentEnergies(session, count: 3);
    final earlyCategoriesSeen = _earlyWindowCategories(session);
    final earlyEnergiesSeen = _earlyWindowEnergies(session);
    final recentQuestionIds = _recentQuestionIds(session, count: 10);

    String questionText = '';
    var recycled = false;
    var intensity = 1;
    var questionSource = OfflineQuestionSource.localPool;
    String? questionCategory;
    String? questionSubcategory;
    final selection = _questionPool.select(
      language: session.language,
      intensityMin: result.intensityMin,
      intensityMax: result.intensityMax,
      nsfwEnabled: session.nsfwEnabled,
      categories: state.categories,
      isPremium: _isPremium,
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
      return;
    }

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

    emit(state.copyWith(session: updatedSession));
    await advanceRound();
  }

  Future<void> endGame() async {
    await _finishGame();
  }

  String? get activeSessionId => _sessionRepo.activeSessionId;

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

  List<String> _recentEnergies(OfflineSession session, {int count = 3}) {
    final rounds = session.rounds;
    if (rounds.isEmpty) return [];
    final recent = rounds.length >= count
        ? rounds.sublist(rounds.length - count)
        : rounds;
    return recent.map((r) => _energyForIntensity(r.intensity)).toList();
  }

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

  List<String> _earlyWindowEnergies(OfflineSession session) {
    final seen = <String>{};
    for (final round in session.rounds.take(20)) {
      seen.add(_energyForIntensity(round.intensity));
    }
    return seen.toList();
  }

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

  Future<bool> _readCachedPremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_premium') ?? false;
    } catch (_) {
      return false;
    }
  }
}
