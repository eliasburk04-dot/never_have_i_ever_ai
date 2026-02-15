import 'package:flutter_test/flutter_test.dart';

import 'package:nhie_app/domain/entities/lobby.dart';
import 'package:nhie_app/features/lobby/bloc/lobby_bloc.dart';

import '../../fixtures.dart';

void main() {
  group('LobbyEvent', () {
    test('CreateLobbyRequested props', () {
      const event = CreateLobbyRequested(
        hostName: 'Alice',
        maxRounds: 20,
        nsfwEnabled: false,
        language: 'en',
      );
      expect(event.hostName, 'Alice');
      expect(event.props, ['Alice', 20, false, 'en']);
    });

    test('JoinLobbyRequested props', () {
      const event = JoinLobbyRequested(code: 'ABC123', playerName: 'Bob');
      expect(event.code, 'ABC123');
      expect(event.playerName, 'Bob');
    });
  });

  group('LobbyState', () {
    test('initial state', () {
      const state = LobbyState();
      expect(state.status, LobbyBlocStatus.initial);
      expect(state.lobby, isNull);
      expect(state.players, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('copyWith preserves fields', () {
      final state = const LobbyState().copyWith(
        status: LobbyBlocStatus.loaded,
        lobby: TestFixtures.testLobby,
        players: TestFixtures.twoPlayers,
      );

      expect(state.status, LobbyBlocStatus.loaded);
      expect(state.lobby?.code, 'ABC123');
      expect(state.players.length, 2);
    });

    test('error state includes message', () {
      final state = const LobbyState().copyWith(
        status: LobbyBlocStatus.error,
        errorMessage: 'Network error',
      );
      expect(state.status, LobbyBlocStatus.error);
      expect(state.errorMessage, 'Network error');
    });
  });

  group('Lobby entity', () {
    test('fromMap parses correctly', () {
      final map = {
        'id': 'lobby-1',
        'code': 'XYZ789',
        'host_id': 'user-1',
        'status': 'waiting',
        'language': 'de',
        'max_rounds': 30,
        'current_round': 5,
        'nsfw_enabled': true,
        'boldness_score': 0.45,
        'current_tone': 'deeper',
        'round_timeout_seconds': 30,
      };

      final lobby = Lobby.fromMap(map);
      expect(lobby.code, 'XYZ789');
      expect(lobby.language, 'de');
      expect(lobby.nsfwEnabled, true);
      expect(lobby.currentTone, ToneLevel.deeper);
      expect(lobby.boldnessScore, 0.45);
    });

    test('status enum values', () {
      expect(LobbyStatus.waiting.name, 'waiting');
      expect(LobbyStatus.playing.name, 'playing');
      expect(LobbyStatus.finished.name, 'finished');
      expect(LobbyStatus.cancelled.name, 'cancelled');
    });
  });

  group('Player entity', () {
    test('two players fixture', () {
      final players = TestFixtures.twoPlayers;
      expect(players.length, 2);
      expect(players[0].isHost, true);
      expect(players[1].isHost, false);
    });
  });
}
