import 'package:equatable/equatable.dart';

import '../../../domain/entities/lobby.dart';
import '../../../domain/entities/player.dart';

// ─── Events ────────────────────────────────────────────

abstract class LobbyEvent extends Equatable {
  const LobbyEvent();

  @override
  List<Object?> get props => [];
}

class CreateLobbyRequested extends LobbyEvent {
  const CreateLobbyRequested({
    required this.hostName,
    required this.maxRounds,
    required this.nsfwEnabled,
    required this.language,
  });

  final String hostName;
  final int maxRounds;
  final bool nsfwEnabled;
  final String language;

  @override
  List<Object?> get props => [hostName, maxRounds, nsfwEnabled, language];
}

class JoinLobbyRequested extends LobbyEvent {
  const JoinLobbyRequested({required this.code, required this.playerName});

  final String code;
  final String playerName;

  @override
  List<Object?> get props => [code, playerName];
}

class LobbySubscriptionStarted extends LobbyEvent {
  const LobbySubscriptionStarted(this.lobbyId);

  final String lobbyId;

  @override
  List<Object?> get props => [lobbyId];
}

class LobbyUpdated extends LobbyEvent {
  const LobbyUpdated(this.lobby);

  final Lobby lobby;

  @override
  List<Object?> get props => [lobby];
}

class PlayersUpdated extends LobbyEvent {
  const PlayersUpdated(this.players);

  final List<Player> players;

  @override
  List<Object?> get props => [players];
}

class StartGameRequested extends LobbyEvent {
  const StartGameRequested();
}

class LeaveLobbyRequested extends LobbyEvent {
  const LeaveLobbyRequested();
}

// ─── State ─────────────────────────────────────────────

enum LobbyBlocStatus { initial, creating, joining, loaded, starting, error }

class LobbyState extends Equatable {
  const LobbyState({
    this.status = LobbyBlocStatus.initial,
    this.lobby,
    this.players = const [],
    this.errorMessage,
  });

  final LobbyBlocStatus status;
  final Lobby? lobby;
  final List<Player> players;
  final String? errorMessage;

  LobbyState copyWith({
    LobbyBlocStatus? status,
    Lobby? lobby,
    List<Player>? players,
    String? errorMessage,
  }) {
    return LobbyState(
      status: status ?? this.status,
      lobby: lobby ?? this.lobby,
      players: players ?? this.players,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, lobby, players, errorMessage];
}
