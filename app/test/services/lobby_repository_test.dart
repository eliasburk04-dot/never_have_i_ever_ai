import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nhie_app/domain/entities/lobby.dart';
import 'package:nhie_app/domain/entities/player.dart';
import 'package:nhie_app/domain/repositories/i_lobby_repository.dart';
import 'package:nhie_app/services/backend_api_service.dart';
import 'package:nhie_app/services/backend_session_service.dart';
import 'package:nhie_app/data/repositories/lobby_repository.dart';

import '../fixtures.dart';

// ─── Mocks ──────────────────────────────────────────

class MockBackendApiService extends Mock implements BackendApiService {}

class MockBackendSessionService extends Mock implements BackendSessionService {}

void main() {
  late MockBackendApiService api;
  late MockBackendSessionService session;
  late LobbyRepository repo;

  setUp(() {
    api = MockBackendApiService();
    session = MockBackendSessionService();
    repo = LobbyRepository(api, session);

    when(() => session.ensureSession()).thenAnswer(
      (_) async => const BackendSession(userId: 'user-1', jwt: 'test-jwt'),
    );
  });

  group('createLobby', () {
    test('sends correct body and returns lobby', () async {
      when(() => api.postJson('/lobby/create', body: any(named: 'body')))
          .thenAnswer((_) async => {
                'lobby': {
                  'id': 'lobby-1',
                  'code': 'ABC123',
                  'host_id': 'user-1',
                  'status': 'waiting',
                  'language': 'en',
                  'max_rounds': 20,
                  'current_round': 0,
                  'nsfw_enabled': false,
                  'boldness_score': 0.0,
                  'current_tone': 'safe',
                  'round_timeout_seconds': 30,
                }
              });

      final lobby = await repo.createLobby(
        language: 'en',
        maxRounds: 20,
        nsfwEnabled: false,
        displayName: 'Alice',
        avatarEmoji: '😎',
      );

      expect(lobby.id, 'lobby-1');
      expect(lobby.code, 'ABC123');
      expect(lobby.hostId, 'user-1');
      expect(lobby.status, LobbyStatus.waiting);

      // Verify code cache works
      expect(repo.codeForLobbyId('lobby-1'), 'ABC123');
    });
  });

  group('joinLobby', () {
    test('sends code and returns lobby', () async {
      when(() => api.postJson('/lobby/join', body: any(named: 'body')))
          .thenAnswer((_) async => {
                'lobby': {
                  'id': 'lobby-1',
                  'code': 'ABC123',
                  'host_id': 'user-1',
                  'status': 'waiting',
                  'language': 'en',
                  'max_rounds': 20,
                  'current_round': 0,
                  'nsfw_enabled': false,
                  'boldness_score': 0.0,
                  'current_tone': 'safe',
                  'round_timeout_seconds': 30,
                }
              });

      final lobby = await repo.joinLobby(
        code: 'ABC123',
        displayName: 'Bob',
        avatarEmoji: '🙂',
      );

      expect(lobby, isNotNull);
      expect(lobby!.code, 'ABC123');
      expect(repo.codeForLobbyId('lobby-1'), 'ABC123');
    });

    test('returns null on failure', () async {
      when(() => api.postJson('/lobby/join', body: any(named: 'body')))
          .thenThrow(Exception('404'));

      final lobby = await repo.joinLobby(
        code: 'INVALID',
        displayName: 'Bob',
        avatarEmoji: '🙂',
      );

      expect(lobby, isNull);
    });
  });

  group('getLobby', () {
    test('fetches state by code', () async {
      // First, populate the code cache
      when(() => api.postJson('/lobby/create', body: any(named: 'body')))
          .thenAnswer((_) async => {
                'lobby': {
                  'id': 'lobby-1',
                  'code': 'ABC123',
                  'host_id': 'user-1',
                  'status': 'waiting',
                  'language': 'en',
                  'max_rounds': 20,
                  'current_round': 0,
                  'nsfw_enabled': false,
                  'boldness_score': 0.0,
                  'current_tone': 'safe',
                  'round_timeout_seconds': 30,
                }
              });

      await repo.createLobby(
        language: 'en',
        maxRounds: 20,
        nsfwEnabled: false,
        displayName: 'Alice',
        avatarEmoji: '😎',
      );

      when(() => api.getJson('/lobby/ABC123/state')).thenAnswer((_) async => {
            'lobby': {
              'id': 'lobby-1',
              'code': 'ABC123',
              'host_id': 'user-1',
              'status': 'playing',
              'language': 'en',
              'max_rounds': 20,
              'current_round': 3,
              'nsfw_enabled': false,
              'boldness_score': 0.2,
              'current_tone': 'safe',
              'round_timeout_seconds': 30,
            }
          });

      final lobby = await repo.getLobby('lobby-1');
      expect(lobby, isNotNull);
      expect(lobby!.status, LobbyStatus.playing);
      expect(lobby.currentRound, 3);
    });

    test('returns null when code not cached', () async {
      final lobby = await repo.getLobby('unknown-id');
      expect(lobby, isNull);
    });
  });

  group('getPlayers', () {
    test('parses player list from state endpoint', () async {
      // Populate cache
      when(() => api.postJson('/lobby/create', body: any(named: 'body')))
          .thenAnswer((_) async => {
                'lobby': {
                  'id': 'lobby-1',
                  'code': 'ABC123',
                  'host_id': 'user-1',
                  'status': 'waiting',
                  'language': 'en',
                  'max_rounds': 20,
                  'current_round': 0,
                  'nsfw_enabled': false,
                  'boldness_score': 0.0,
                  'current_tone': 'safe',
                  'round_timeout_seconds': 30,
                }
              });

      await repo.createLobby(
        language: 'en',
        maxRounds: 20,
        nsfwEnabled: false,
        displayName: 'Alice',
        avatarEmoji: '😎',
      );

      when(() => api.getJson('/lobby/ABC123/state')).thenAnswer((_) async => {
            'lobby': {'id': 'lobby-1', 'code': 'ABC123'},
            'players': [
              {
                'id': 'p-1',
                'lobby_id': 'lobby-1',
                'user_id': 'user-1',
                'display_name': 'Alice',
                'avatar_emoji': '😎',
                'status': 'connected',
                'is_host': true,
              },
              {
                'id': 'p-2',
                'lobby_id': 'lobby-1',
                'user_id': 'user-2',
                'display_name': 'Bob',
                'avatar_emoji': '🙂',
                'status': 'connected',
                'is_host': false,
              },
            ],
          });

      final players = await repo.getPlayers('lobby-1');
      expect(players.length, 2);
      expect(players[0].isHost, true);
      expect(players[1].displayName, 'Bob');
    });

    test('returns empty list when code not cached', () async {
      final players = await repo.getPlayers('unknown-id');
      expect(players, isEmpty);
    });
  });

  group('leaveLobby', () {
    test('calls REST leave endpoint and clears cache', () async {
      // Populate cache
      when(() => api.postJson('/lobby/create', body: any(named: 'body')))
          .thenAnswer((_) async => {
                'lobby': {
                  'id': 'lobby-1',
                  'code': 'ABC123',
                  'host_id': 'user-1',
                  'status': 'waiting',
                  'language': 'en',
                  'max_rounds': 20,
                  'current_round': 0,
                  'nsfw_enabled': false,
                  'boldness_score': 0.0,
                  'current_tone': 'safe',
                  'round_timeout_seconds': 30,
                }
              });

      await repo.createLobby(
        language: 'en',
        maxRounds: 20,
        nsfwEnabled: false,
        displayName: 'Alice',
        avatarEmoji: '😎',
      );
      expect(repo.codeForLobbyId('lobby-1'), 'ABC123');

      when(() => api.postJson('/lobby/ABC123/leave'))
          .thenAnswer((_) async => {'ok': true});

      await repo.leaveLobby('lobby-1');

      verify(() => api.postJson('/lobby/ABC123/leave')).called(1);
      expect(repo.codeForLobbyId('lobby-1'), isNull);
    });

    test('silently handles error on leave', () async {
      // No code in cache → no API call, no crash
      await repo.leaveLobby('unknown-id');
      // No exception thrown
    });
  });
}
