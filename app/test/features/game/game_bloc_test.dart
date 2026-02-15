import 'package:flutter_test/flutter_test.dart';

import 'package:nhie_app/domain/entities/lobby.dart';
import 'package:nhie_app/domain/entities/player.dart';
import 'package:nhie_app/features/game/bloc/game_bloc.dart';

import '../../fixtures.dart';

void main() {

  group('GameEvent', () {
    test('GameStarted props', () {
      const event = GameStarted('lobby-1');
      expect(event.lobbyId, 'lobby-1');
      expect(event.props, ['lobby-1']);
    });

    test('AnswerSubmitted props', () {
      const event = AnswerSubmitted(answer: true);
      expect(event.answer, true);
      expect(event.props, [true]);
    });

    test('RoundUpdated props', () {
      final event = RoundUpdated(TestFixtures.activeRound);
      expect(event.round.id, 'round-1');
    });

    test('AnswerReceived props', () {
      const event = AnswerReceived(userId: 'u1', answer: true);
      expect(event.userId, 'u1');
      expect(event.answer, true);
      expect(event.props, ['u1', true]);
    });

    test('HostAdvanceRequested props', () {
      const event = HostAdvanceRequested();
      expect(event.props, isEmpty);
    });

    test('PlayersUpdated props', () {
      final event = PlayersUpdated(TestFixtures.twoPlayers);
      expect(event.players.length, 2);
    });
  });

  group('GameState', () {
    test('initial state', () {
      const state = GameState();
      expect(state.phase, GamePhase.loading);
      expect(state.lobbyId, isNull);
      expect(state.currentRound, isNull);
      expect(state.allRounds, isEmpty);
      expect(state.hasAnswered, false);
      expect(state.myAnswer, isNull);
      expect(state.roundNumber, 0);
      expect(state.answers, isEmpty);
      expect(state.players, isEmpty);
      expect(state.hostId, isNull);
      expect(state.isAdvancing, false);
      expect(state.allAnswered, false);
    });

    test('copyWith preserves fields', () {
      final state = const GameState().copyWith(
        phase: GamePhase.playing,
        lobbyId: 'lobby-1',
        currentRound: TestFixtures.activeRound,
        hasAnswered: true,
        myAnswer: true,
        answers: {'user-1': true},
        players: TestFixtures.twoPlayers,
        hostId: 'user-1',
      );

      expect(state.phase, GamePhase.playing);
      expect(state.lobbyId, 'lobby-1');
      expect(state.currentRound, TestFixtures.activeRound);
      expect(state.hasAnswered, true);
      expect(state.myAnswer, true);
      expect(state.answers, {'user-1': true});
      expect(state.players.length, 2);
      expect(state.hostId, 'user-1');
    });

    test('roundNumber counts allRounds', () {
      final state = const GameState().copyWith(
        allRounds: [TestFixtures.activeRound, TestFixtures.completedRound],
      );
      expect(state.roundNumber, 2);
    });

    test('allAnswered returns false when no answers', () {
      final state = const GameState().copyWith(
        players: TestFixtures.twoPlayers,
        answers: const {},
      );
      expect(state.allAnswered, false);
    });

    test('allAnswered returns false when partial answers', () {
      final state = const GameState().copyWith(
        players: TestFixtures.twoPlayers,
        answers: {'user-1': true},
      );
      expect(state.allAnswered, false);
    });

    test('allAnswered returns true when all connected players answered', () {
      final state = const GameState().copyWith(
        players: TestFixtures.twoPlayers,
        answers: {'user-1': true, 'user-3': false},
      );
      expect(state.allAnswered, true);
    });

    test('allAnswered excludes disconnected players', () {
      final disconnectedGuest = Player(
        id: 'player-2',
        lobbyId: 'lobby-1',
        userId: 'user-3',
        displayName: 'GuestPlayer',
        avatarEmoji: '🙂',
        isHost: false,
        status: PlayerStatus.disconnected,
      );
      final state = const GameState().copyWith(
        players: [TestFixtures.hostPlayer, disconnectedGuest],
        answers: {'user-1': true},
      );
      expect(state.allAnswered, true);
    });

    test('allAnswered handles answer change (same count, different value)', () {
      final state = const GameState().copyWith(
        players: TestFixtures.twoPlayers,
        answers: {'user-1': false, 'user-3': true},
      );
      expect(state.allAnswered, true);

      // Player 1 changes answer
      final updated = state.copyWith(
        answers: {'user-1': true, 'user-3': true},
      );
      expect(updated.allAnswered, true);
    });
  });

  group('GameRound entity', () {
    test('haveRatio calculates correctly', () {
      expect(TestFixtures.completedRound.haveRatio, 0.5);
      expect(TestFixtures.activeRound.haveRatio, 0.0);
    });

    test('status getters', () {
      expect(TestFixtures.activeRound.isActive, true);
      expect(TestFixtures.activeRound.isCompleted, false);
      expect(TestFixtures.completedRound.isCompleted, true);
    });

    test('tone is ToneLevel enum', () {
      expect(TestFixtures.activeRound.tone, ToneLevel.safe);
      expect(TestFixtures.deeperRound.tone, ToneLevel.deeper);
    });
  });
}
