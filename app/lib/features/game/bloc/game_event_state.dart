import 'package:equatable/equatable.dart';

import '../../../domain/entities/player.dart';
import '../../../domain/entities/round.dart';

// ─── Events ────────────────────────────────────────────

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class GameStarted extends GameEvent {
  const GameStarted(this.lobbyId);

  final String lobbyId;

  @override
  List<Object?> get props => [lobbyId];
}

class AnswerSubmitted extends GameEvent {
  const AnswerSubmitted({required this.answer});

  final bool answer; // true = "I have", false = "I have not"

  @override
  List<Object?> get props => [answer];
}

/// A remote player's answer arrived (or was updated) via Realtime.
class AnswerReceived extends GameEvent {
  const AnswerReceived({required this.userId, required this.answer});

  final String userId;
  final bool answer;

  @override
  List<Object?> get props => [userId, answer];
}

class RoundUpdated extends GameEvent {
  const RoundUpdated(this.round);

  final GameRound round;

  @override
  List<Object?> get props => [round];
}

/// Host taps "Next Question".
class HostAdvanceRequested extends GameEvent {
  const HostAdvanceRequested();
}

/// Lobby players list changed (join/leave/disconnect).
class PlayersUpdated extends GameEvent {
  const PlayersUpdated(this.players);

  final List<Player> players;

  @override
  List<Object?> get props => [players];
}

/// Lobby metadata updated (host change, status change, etc.).
class LobbyUpdated extends GameEvent {
  const LobbyUpdated({this.hostId, this.status});

  final String? hostId;
  final String? status;

  @override
  List<Object?> get props => [hostId, status];
}

// ─── State ─────────────────────────────────────────────

enum GamePhase { loading, playing, complete }

class GameState extends Equatable {
  const GameState({
    this.phase = GamePhase.loading,
    this.lobbyId,
    this.currentRound,
    this.allRounds = const [],
    this.hasAnswered = false,
    this.myAnswer,
    this.answers = const {},
    this.players = const [],
    this.hostId,
    this.isAdvancing = false,
    this.errorMessage,
  });

  final GamePhase phase;
  final String? lobbyId;
  final GameRound? currentRound;
  final List<GameRound> allRounds;
  final bool hasAnswered;
  final bool? myAnswer;

  /// userId → answer for the current round.
  final Map<String, bool> answers;

  /// All players in the lobby.
  final List<Player> players;

  /// Current host user id.
  final String? hostId;

  /// True while the host-advance network call is in-flight.
  final bool isAdvancing;

  final String? errorMessage;

  int get roundNumber => allRounds.length;

  /// All connected players have submitted an answer.
  bool get allAnswered {
    final connected = players.where((p) => p.isConnected).toList();
    if (connected.isEmpty) return false;
    return connected.every((p) => answers.containsKey(p.userId));
  }

  GameState copyWith({
    GamePhase? phase,
    String? lobbyId,
    GameRound? currentRound,
    List<GameRound>? allRounds,
    bool? hasAnswered,
    bool? myAnswer,
    Map<String, bool>? answers,
    List<Player>? players,
    String? hostId,
    bool? isAdvancing,
    String? errorMessage,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      lobbyId: lobbyId ?? this.lobbyId,
      currentRound: currentRound ?? this.currentRound,
      allRounds: allRounds ?? this.allRounds,
      hasAnswered: hasAnswered ?? this.hasAnswered,
      myAnswer: myAnswer,
      answers: answers ?? this.answers,
      players: players ?? this.players,
      hostId: hostId ?? this.hostId,
      isAdvancing: isAdvancing ?? this.isAdvancing,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        lobbyId,
        currentRound,
        allRounds,
        hasAnswered,
        myAnswer,
        answers,
        players,
        hostId,
        isAdvancing,
        errorMessage,
      ];
}
