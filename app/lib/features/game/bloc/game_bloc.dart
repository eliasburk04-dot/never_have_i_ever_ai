import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/service_locator.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/round.dart';
import '../../../domain/repositories/i_game_repository.dart';
import '../../../services/backend_api_service.dart';
import '../../../services/backend_session_service.dart';
import '../../../services/realtime_service.dart';
import 'game_event_state.dart';

export 'game_event_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc() : super(const GameState()) {
    on<GameStarted>(_onGameStarted);
    on<AnswerSubmitted>(_onAnswerSubmitted);
    on<AnswerReceived>(_onAnswerReceived);
    on<RoundUpdated>(_onRoundUpdated);
    on<HostAdvanceRequested>(_onHostAdvanceRequested);
    on<PlayersUpdated>(_onPlayersUpdated);
    on<LobbyUpdated>(_onLobbyUpdated);
  }

  final _gameRepo = getIt<IGameRepository>();
  final _realtime = getIt<RealtimeService>();
  final _session = getIt<BackendSessionService>();
  final _api = getIt<BackendApiService>();

  StreamSubscription? _lobbyStateSub;
  StreamSubscription? _roundStateSub;
  StreamSubscription? _answerStateSub;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;
  bool get isHost => state.hostId == currentUserId;

  Future<void> _onGameStarted(
    GameStarted event,
    Emitter<GameState> emit,
  ) async {
    final s = await _session.ensureSession();
    _currentUserId = s.userId;

    emit(state.copyWith(
      phase: GamePhase.loading,
      lobbyId: event.lobbyId,
      errorMessage: null,
    ));

    await _realtime.joinLobby(event.lobbyId);

    await _lobbyStateSub?.cancel();
    _lobbyStateSub = _realtime.lobbyState$.listen((payload) {
      try {
        final lobbyMap = payload['lobby'] as Map?;
        final playersList = payload['players'] as List?;
        final roundMap = payload['round'] as Map?;
        final answersMap = payload['answers'] as Map?;

        if (lobbyMap != null) {
          final hostId = (lobbyMap['host_id'] ??
              lobbyMap['hostId'] ??
              lobbyMap['host_user_id'] ??
              lobbyMap['hostUserId']) as String?;
          final status = lobbyMap['status'] as String?;
          add(LobbyUpdated(hostId: hostId, status: status));
        }

        if (playersList != null) {
          final players = playersList
              .whereType<Map>()
              .map((p) => Player.fromMap(Map<String, dynamic>.from(p)))
              .toList();
          add(PlayersUpdated(players));
        }

        if (roundMap != null) {
          add(RoundUpdated(
            GameRound.fromMap(Map<String, dynamic>.from(roundMap)),
          ));
        }

        if (answersMap != null) {
          final map = <String, bool>{};
          answersMap.forEach((k, v) {
            if (v == 'HAVE') map['$k'] = true;
            if (v == 'HAVE_NOT') map['$k'] = false;
            if (v is bool) map['$k'] = v;
          });

          for (final e in map.entries) {
            add(AnswerReceived(userId: e.key, answer: e.value));
          }
        }
      } catch (_) {}
    });

    await _roundStateSub?.cancel();
    _roundStateSub = _realtime.roundState$.listen((payload) {
      try {
        final roundMap = payload['round'] ?? payload;
        if (roundMap is Map) {
          add(RoundUpdated(
            GameRound.fromMap(Map<String, dynamic>.from(roundMap)),
          ));
        }
      } catch (_) {}
    });

    await _answerStateSub?.cancel();
    _answerStateSub = _realtime.answerState$.listen((payload) {
      try {
        final answers = payload['answers'] as Map?;
        if (answers == null) return;
        answers.forEach((k, v) {
          if (v == 'HAVE') add(AnswerReceived(userId: '$k', answer: true));
          if (v == 'HAVE_NOT') add(AnswerReceived(userId: '$k', answer: false));
          if (v is bool) add(AnswerReceived(userId: '$k', answer: v));
        });
      } catch (_) {}
    });
  }

  Future<void> _onAnswerSubmitted(
    AnswerSubmitted event,
    Emitter<GameState> emit,
  ) async {
    if (state.currentRound == null || state.lobbyId == null) return;

    final updatedAnswers = Map<String, bool>.from(state.answers);
    final uid = currentUserId;
    if (uid != null) {
      updatedAnswers[uid] = event.answer;
    }

    emit(state.copyWith(
      hasAnswered: true,
      myAnswer: event.answer,
      answers: updatedAnswers,
      errorMessage: null,
    ));

    try {
      await _gameRepo.submitAnswer(
        roundId: state.currentRound!.id,
        lobbyId: state.lobbyId!,
        answer: event.answer,
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to submit answer: $e'));
    }
  }

  void _onAnswerReceived(AnswerReceived event, Emitter<GameState> emit) {
    final updated = Map<String, bool>.from(state.answers);
    updated[event.userId] = event.answer;

    final uid = currentUserId;
    final my = uid != null ? updated[uid] : null;

    emit(state.copyWith(
      answers: updated,
      myAnswer: my,
      hasAnswered: my != null,
    ));
  }

  void _onRoundUpdated(RoundUpdated event, Emitter<GameState> emit) {
    final round = event.round;
    if (round.lobbyId != state.lobbyId) return;

    final updatedRounds = List<GameRound>.from(state.allRounds);
    final idx = updatedRounds.indexWhere((r) => r.id == round.id);
    if (idx >= 0) {
      updatedRounds[idx] = round;
    } else {
      updatedRounds.add(round);
    }

    if (round.status == RoundStatus.active) {
      emit(state.copyWith(
        phase: GamePhase.playing,
        currentRound: round,
        allRounds: updatedRounds,
        hasAnswered: false,
        myAnswer: null,
        answers: const {},
        isAdvancing: false,
        errorMessage: null,
      ));
    } else if (round.status == RoundStatus.completed) {
      emit(state.copyWith(currentRound: round, allRounds: updatedRounds));
    }
  }

  Future<void> _onHostAdvanceRequested(
    HostAdvanceRequested event,
    Emitter<GameState> emit,
  ) async {
    if (state.currentRound == null) return;
    if (!state.allAnswered) return;

    emit(state.copyWith(isAdvancing: true, errorMessage: null));
    try {
      await _api.postJson('/round/${state.currentRound!.id}/advance');
      emit(state.copyWith(isAdvancing: false));
    } catch (e) {
      emit(state.copyWith(
        isAdvancing: false,
        errorMessage: 'Failed to advance: $e',
      ));
    }
  }

  void _onPlayersUpdated(PlayersUpdated event, Emitter<GameState> emit) {
    emit(state.copyWith(players: event.players));
  }

  void _onLobbyUpdated(LobbyUpdated event, Emitter<GameState> emit) {
    if (event.hostId != null && event.hostId!.isNotEmpty) {
      emit(state.copyWith(hostId: event.hostId));
    }
    if (event.status == 'finished' || event.status == 'cancelled') {
      emit(state.copyWith(phase: GamePhase.complete));
    }
  }

  @override
  Future<void> close() async {
    await _lobbyStateSub?.cancel();
    await _roundStateSub?.cancel();
    await _answerStateSub?.cancel();
    return super.close();
  }
}

