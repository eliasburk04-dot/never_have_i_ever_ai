import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/service_locator.dart';
import '../../../domain/entities/lobby.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/repositories/i_lobby_repository.dart';
import '../../../services/realtime_service.dart';
import 'lobby_event_state.dart';

export 'lobby_event_state.dart';

class LobbyBloc extends Bloc<LobbyEvent, LobbyState> {
  LobbyBloc() : super(const LobbyState()) {
    on<CreateLobbyRequested>(_onCreateLobby);
    on<JoinLobbyRequested>(_onJoinLobby);
    on<LobbySubscriptionStarted>(_onSubscriptionStarted);
    on<LobbyUpdated>(_onLobbyUpdated);
    on<PlayersUpdated>(_onPlayersUpdated);
    on<StartGameRequested>(_onStartGame);
    on<LeaveLobbyRequested>(_onLeaveLobby);
  }

  final _lobbyRepo = getIt<ILobbyRepository>();
  final _realtimeService = getIt<RealtimeService>();
  StreamSubscription? _lobbyStateSub;

  // ─── Handlers ─────────────────────────────────────────

  Future<void> _onCreateLobby(
    CreateLobbyRequested event,
    Emitter<LobbyState> emit,
  ) async {
    emit(state.copyWith(status: LobbyBlocStatus.creating));
    try {
      final lobby = await _lobbyRepo.createLobby(
        displayName: event.hostName,
        avatarEmoji: '😎',
        maxRounds: event.maxRounds,
        nsfwEnabled: event.nsfwEnabled,
        language: event.language,
      );
      emit(state.copyWith(status: LobbyBlocStatus.loaded, lobby: lobby));
      add(LobbySubscriptionStarted(lobby.id));
    } catch (e) {
      emit(state.copyWith(
        status: LobbyBlocStatus.error,
        errorMessage: 'Failed to create lobby: $e',
      ));
    }
  }

  Future<void> _onJoinLobby(
    JoinLobbyRequested event,
    Emitter<LobbyState> emit,
  ) async {
    emit(state.copyWith(status: LobbyBlocStatus.joining));
    try {
      final lobby = await _lobbyRepo.joinLobby(
        code: event.code,
        displayName: event.playerName,
        avatarEmoji: '🙂',
      );
      if (lobby == null) {
        emit(state.copyWith(
          status: LobbyBlocStatus.error,
          errorMessage: 'Lobby not found',
        ));
        return;
      }
      emit(state.copyWith(status: LobbyBlocStatus.loaded, lobby: lobby));
      add(LobbySubscriptionStarted(lobby.id));
    } catch (e) {
      emit(state.copyWith(
        status: LobbyBlocStatus.error,
        errorMessage: 'Failed to join lobby: $e',
      ));
    }
  }

  Future<void> _onSubscriptionStarted(
    LobbySubscriptionStarted event,
    Emitter<LobbyState> emit,
  ) async {
    await _realtimeService.joinLobby(event.lobbyId);

    await _lobbyStateSub?.cancel();
    _lobbyStateSub = _realtimeService.lobbyState$.listen((payload) {
      try {
        final lobbyMap = payload['lobby'] as Map?;
        final playersList = payload['players'] as List?;
        if (lobbyMap != null) {
          add(LobbyUpdated(Lobby.fromMap(Map<String, dynamic>.from(lobbyMap))));
        }
        if (playersList != null) {
          final players = playersList
              .whereType<Map>()
              .map((p) => Player.fromMap(Map<String, dynamic>.from(p)))
              .toList();
          add(PlayersUpdated(players));
        }
      } catch (_) {}
    });

    // Initial load
    try {
      final players = await _lobbyRepo.getPlayers(event.lobbyId);
      emit(state.copyWith(players: players));
    } catch (_) {}
  }

  void _onLobbyUpdated(LobbyUpdated event, Emitter<LobbyState> emit) {
    emit(state.copyWith(lobby: event.lobby));
  }

  void _onPlayersUpdated(PlayersUpdated event, Emitter<LobbyState> emit) {
    emit(state.copyWith(players: event.players));
  }

  Future<void> _onStartGame(
    StartGameRequested event,
    Emitter<LobbyState> emit,
  ) async {
    // Backend auto-starts when the second player joins.
  }

  Future<void> _onLeaveLobby(
    LeaveLobbyRequested event,
    Emitter<LobbyState> emit,
  ) async {
    if (state.lobby == null) return;
    try {
      await _lobbyRepo.leaveLobby(state.lobby!.id);
    } catch (_) {}
    _realtimeService.disposeAll();
    emit(const LobbyState());
  }

  @override
  Future<void> close() async {
    await _lobbyStateSub?.cancel();
    _realtimeService.disposeAll();
    return super.close();
  }
}
