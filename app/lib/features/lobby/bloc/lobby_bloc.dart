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
  Timer? _pollTimer;

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
      emit(
        state.copyWith(
          status: LobbyBlocStatus.error,
          errorMessage: 'Failed to create lobby: $e',
        ),
      );
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
        emit(
          state.copyWith(
            status: LobbyBlocStatus.error,
            errorMessage: 'Lobby not found',
          ),
        );
        return;
      }
      emit(state.copyWith(status: LobbyBlocStatus.loaded, lobby: lobby));
      add(LobbySubscriptionStarted(lobby.id));
    } catch (e) {
      emit(
        state.copyWith(
          status: LobbyBlocStatus.error,
          errorMessage: 'Failed to join lobby: $e',
        ),
      );
    }
  }

  Future<void> _onSubscriptionStarted(
    LobbySubscriptionStarted event,
    Emitter<LobbyState> emit,
  ) async {
    await _realtimeService.connect();

    await _lobbyStateSub?.cancel();
    _lobbyStateSub = _realtimeService.lobbyState$.listen((payload) {
      _handleLobbyStatePayload(payload, event.lobbyId);
    });

    // Use lobbyCode for WS join (server uses room: game:<key>:lobby:<CODE>)
    final code = _lobbyRepo.codeForLobbyId(event.lobbyId);
    await _realtimeService.joinLobby(event.lobbyId, lobbyCode: code);

    final cached = _realtimeService.lastLobbyState;
    if (cached != null) {
      _handleLobbyStatePayload(cached, event.lobbyId);
    }

    // Initial load
    try {
      final lobby = await _lobbyRepo.getLobby(event.lobbyId);
      if (lobby != null) add(LobbyUpdated(lobby));

      final players = await _lobbyRepo.getPlayers(event.lobbyId);
      emit(state.copyWith(players: players));
    } catch (_) {}

    // Safety polling: if WS misses the status change, REST catches it.
    // Polls every 3s while lobby is still 'waiting', stops once 'playing'.
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final lobby = await _lobbyRepo.getLobby(event.lobbyId);
        if (lobby == null) return;
        add(LobbyUpdated(lobby));

        final players = await _lobbyRepo.getPlayers(event.lobbyId);
        add(PlayersUpdated(players));

        // Stop polling once we transition out of waiting
        if (lobby.status != LobbyStatus.waiting) {
          _pollTimer?.cancel();
          _pollTimer = null;
        }
      } catch (_) {}
    });
  }

  void _handleLobbyStatePayload(Map<String, dynamic> payload, String lobbyId) {
    try {
      final lobbyMap = payload['lobby'] as Map?;
      final playersList = payload['players'] as List?;

      if (lobbyMap != null) {
        final lobby = Lobby.fromMap(Map<String, dynamic>.from(lobbyMap));
        if (lobby.id == lobbyId) add(LobbyUpdated(lobby));
      }

      if (playersList != null) {
        final players = playersList
            .whereType<Map>()
            .map((p) => Player.fromMap(Map<String, dynamic>.from(p)))
            .where((p) => p.lobbyId == lobbyId)
            .toList();
        add(PlayersUpdated(players));
      }
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
    if (state.lobby == null) return;
    emit(state.copyWith(status: LobbyBlocStatus.starting));
    try {
      await _lobbyRepo.startGame(state.lobby!.id);
      // Server broadcasts lobby:state with status 'playing' via WS.
      // The BlocListener in LobbyWaitingScreen will navigate to /game.
    } catch (e) {
      emit(
        state.copyWith(
          status: LobbyBlocStatus.error,
          errorMessage: 'Failed to start game: $e',
        ),
      );
    }
  }

  Future<void> _onLeaveLobby(
    LeaveLobbyRequested event,
    Emitter<LobbyState> emit,
  ) async {
    if (state.lobby == null) return;
    _pollTimer?.cancel();
    _pollTimer = null;
    // Notify server via both REST and WS
    try {
      await _lobbyRepo.leaveLobby(state.lobby!.id);
    } catch (_) {}
    _realtimeService.leaveLobby();
    _realtimeService.disposeAll();
    emit(const LobbyState());
  }

  @override
  Future<void> close() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    await _lobbyStateSub?.cancel();
    _realtimeService.disposeAll();
    return super.close();
  }
}
