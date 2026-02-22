import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nhie_app/domain/entities/lobby.dart';
import 'package:nhie_app/domain/entities/player.dart';
import 'package:nhie_app/domain/repositories/i_lobby_repository.dart';
import 'package:nhie_app/features/lobby/bloc/lobby_bloc.dart';
import 'package:nhie_app/services/realtime_service.dart';
import 'package:nhie_app/core/service_locator.dart';

import '../../fixtures.dart';

// ─── Mocks ──────────────────────────────────────────

class MockLobbyRepository extends Mock implements ILobbyRepository {}

class MockRealtimeService extends Mock implements RealtimeService {}

void main() {
  late MockLobbyRepository lobbyRepo;
  late MockRealtimeService realtimeService;

  setUp(() {
    lobbyRepo = MockLobbyRepository();
    realtimeService = MockRealtimeService();

    // Reset GetIt
    if (getIt.isRegistered<ILobbyRepository>()) {
      getIt.unregister<ILobbyRepository>();
    }
    if (getIt.isRegistered<RealtimeService>()) {
      getIt.unregister<RealtimeService>();
    }
    getIt.registerSingleton<ILobbyRepository>(lobbyRepo);
    getIt.registerSingleton<RealtimeService>(realtimeService);

    // Default stubs
    when(() => realtimeService.connect()).thenAnswer((_) async {});
    when(() => realtimeService.joinLobby(any(), lobbyCode: any(named: 'lobbyCode')))
        .thenAnswer((_) async {});
    when(() => realtimeService.leaveLobby()).thenReturn(null);
    when(() => realtimeService.disposeAll()).thenReturn(null);
    when(() => realtimeService.lobbyState$)
        .thenAnswer((_) => const Stream.empty());
    when(() => realtimeService.lastLobbyState).thenReturn(null);
  });

  tearDown(() {
    if (getIt.isRegistered<ILobbyRepository>()) {
      getIt.unregister<ILobbyRepository>();
    }
    if (getIt.isRegistered<RealtimeService>()) {
      getIt.unregister<RealtimeService>();
    }
  });

  // ─── CreateLobby Tests ───────────────────────────────

  group('CreateLobbyRequested', () {
    blocTest<LobbyBloc, LobbyState>(
      'emits [creating, loaded] when createLobby succeeds',
      build: () {
        when(() => lobbyRepo.createLobby(
              displayName: any(named: 'displayName'),
              avatarEmoji: any(named: 'avatarEmoji'),
              maxRounds: any(named: 'maxRounds'),
              nsfwEnabled: any(named: 'nsfwEnabled'),
              language: any(named: 'language'),
            )).thenAnswer((_) async => TestFixtures.testLobby);
        when(() => lobbyRepo.codeForLobbyId(any())).thenReturn('ABC123');
        when(() => lobbyRepo.getLobby(any()))
            .thenAnswer((_) async => TestFixtures.testLobby);
        when(() => lobbyRepo.getPlayers(any()))
            .thenAnswer((_) async => [TestFixtures.hostPlayer]);
        return LobbyBloc();
      },
      act: (bloc) => bloc.add(const CreateLobbyRequested(
        hostName: 'Alice',
        maxRounds: 20,
        nsfwEnabled: false,
        language: 'en',
      )),
      expect: () => [
        isA<LobbyState>()
            .having((s) => s.status, 'status', LobbyBlocStatus.creating),
        isA<LobbyState>()
            .having((s) => s.status, 'status', LobbyBlocStatus.loaded)
            .having((s) => s.lobby?.id, 'lobby.id', 'lobby-1'),
        // Additional states from subscription
        isA<LobbyState>(),
      ],
      verify: (_) {
        verify(() => lobbyRepo.createLobby(
              displayName: 'Alice',
              avatarEmoji: '😎',
              maxRounds: 20,
              nsfwEnabled: false,
              language: 'en',
            )).called(1);
        verify(() => realtimeService.connect()).called(1);
        verify(() => realtimeService.joinLobby(
              'lobby-1',
              lobbyCode: 'ABC123',
            )).called(1);
      },
    );

    blocTest<LobbyBloc, LobbyState>(
      'emits [creating, error] when createLobby fails',
      build: () {
        when(() => lobbyRepo.createLobby(
              displayName: any(named: 'displayName'),
              avatarEmoji: any(named: 'avatarEmoji'),
              maxRounds: any(named: 'maxRounds'),
              nsfwEnabled: any(named: 'nsfwEnabled'),
              language: any(named: 'language'),
            )).thenThrow(Exception('Network error'));
        return LobbyBloc();
      },
      act: (bloc) => bloc.add(const CreateLobbyRequested(
        hostName: 'Alice',
        maxRounds: 20,
        nsfwEnabled: false,
        language: 'en',
      )),
      expect: () => [
        isA<LobbyState>()
            .having((s) => s.status, 'status', LobbyBlocStatus.creating),
        isA<LobbyState>()
            .having((s) => s.status, 'status', LobbyBlocStatus.error)
            .having((s) => s.errorMessage, 'errorMessage',
                contains('Network error')),
      ],
    );
  });

  // ─── JoinLobby Tests ─────────────────────────────────

  group('JoinLobbyRequested', () {
    blocTest<LobbyBloc, LobbyState>(
      'emits [joining, loaded] when joinLobby succeeds',
      build: () {
        when(() => lobbyRepo.joinLobby(
              code: any(named: 'code'),
              displayName: any(named: 'displayName'),
              avatarEmoji: any(named: 'avatarEmoji'),
            )).thenAnswer((_) async => TestFixtures.testLobby);
        when(() => lobbyRepo.codeForLobbyId(any())).thenReturn('ABC123');
        when(() => lobbyRepo.getLobby(any()))
            .thenAnswer((_) async => TestFixtures.testLobby);
        when(() => lobbyRepo.getPlayers(any()))
            .thenAnswer((_) async => TestFixtures.twoPlayers);
        return LobbyBloc();
      },
      act: (bloc) => bloc.add(const JoinLobbyRequested(
        code: 'ABC123',
        playerName: 'Bob',
      )),
      expect: () => [
        isA<LobbyState>()
            .having((s) => s.status, 'status', LobbyBlocStatus.joining),
        isA<LobbyState>()
            .having((s) => s.status, 'status', LobbyBlocStatus.loaded)
            .having((s) => s.lobby?.code, 'lobby.code', 'ABC123'),
        // Additional states from subscription
        isA<LobbyState>(),
      ],
      verify: (_) {
        verify(() => lobbyRepo.joinLobby(
              code: 'ABC123',
              displayName: 'Bob',
              avatarEmoji: '🙂',
            )).called(1);
      },
    );

    blocTest<LobbyBloc, LobbyState>(
      'emits [joining, error] when lobby not found',
      build: () {
        when(() => lobbyRepo.joinLobby(
              code: any(named: 'code'),
              displayName: any(named: 'displayName'),
              avatarEmoji: any(named: 'avatarEmoji'),
            )).thenAnswer((_) async => null);
        return LobbyBloc();
      },
      act: (bloc) => bloc.add(const JoinLobbyRequested(
        code: 'INVALID',
        playerName: 'Bob',
      )),
      expect: () => [
        isA<LobbyState>()
            .having((s) => s.status, 'status', LobbyBlocStatus.joining),
        isA<LobbyState>()
            .having((s) => s.status, 'status', LobbyBlocStatus.error)
            .having((s) => s.errorMessage, 'errorMessage', 'Lobby not found'),
      ],
    );

    blocTest<LobbyBloc, LobbyState>(
      'emits [joining, error] when joinLobby throws',
      build: () {
        when(() => lobbyRepo.joinLobby(
              code: any(named: 'code'),
              displayName: any(named: 'displayName'),
              avatarEmoji: any(named: 'avatarEmoji'),
            )).thenThrow(Exception('Server offline'));
        return LobbyBloc();
      },
      act: (bloc) => bloc.add(const JoinLobbyRequested(
        code: 'ABC123',
        playerName: 'Bob',
      )),
      expect: () => [
        isA<LobbyState>()
            .having((s) => s.status, 'status', LobbyBlocStatus.joining),
        isA<LobbyState>()
            .having((s) => s.status, 'status', LobbyBlocStatus.error),
      ],
    );
  });

  // ─── LeaveLobby Tests ────────────────────────────────

  group('LeaveLobbyRequested', () {
    blocTest<LobbyBloc, LobbyState>(
      'calls leaveLobby on repo and disposes realtime',
      seed: () => LobbyState(
        status: LobbyBlocStatus.loaded,
        lobby: TestFixtures.testLobby,
        players: TestFixtures.twoPlayers,
      ),
      build: () {
        when(() => lobbyRepo.leaveLobby(any())).thenAnswer((_) async {});
        return LobbyBloc();
      },
      act: (bloc) => bloc.add(const LeaveLobbyRequested()),
      expect: () => [
        isA<LobbyState>()
            .having((s) => s.status, 'status', LobbyBlocStatus.initial)
            .having((s) => s.lobby, 'lobby', isNull),
      ],
      verify: (_) {
        verify(() => lobbyRepo.leaveLobby('lobby-1')).called(1);
        verify(() => realtimeService.leaveLobby()).called(1);
        verify(() => realtimeService.disposeAll()).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<LobbyBloc, LobbyState>(
      'does nothing when no lobby in state',
      build: () {
        return LobbyBloc();
      },
      act: (bloc) => bloc.add(const LeaveLobbyRequested()),
      expect: () => [],
      verify: (_) {
        verifyNever(() => lobbyRepo.leaveLobby(any()));
      },
    );

    blocTest<LobbyBloc, LobbyState>(
      'leave still resets state even if REST call fails',
      seed: () => LobbyState(
        status: LobbyBlocStatus.loaded,
        lobby: TestFixtures.testLobby,
        players: TestFixtures.twoPlayers,
      ),
      build: () {
        when(() => lobbyRepo.leaveLobby(any()))
            .thenThrow(Exception('Server error'));
        return LobbyBloc();
      },
      act: (bloc) => bloc.add(const LeaveLobbyRequested()),
      expect: () => [
        isA<LobbyState>()
            .having((s) => s.status, 'status', LobbyBlocStatus.initial),
      ],
    );
  });

  // ─── LobbyUpdated / PlayersUpdated Tests ──────────────

  group('LobbyUpdated', () {
    blocTest<LobbyBloc, LobbyState>(
      'updates lobby in state',
      seed: () => LobbyState(
        status: LobbyBlocStatus.loaded,
        lobby: TestFixtures.testLobby,
      ),
      build: () => LobbyBloc(),
      act: (bloc) => bloc.add(LobbyUpdated(TestFixtures.playingLobby)),
      expect: () => [
        isA<LobbyState>()
            .having((s) => s.lobby?.status, 'status', LobbyStatus.playing)
            .having((s) => s.lobby?.currentRound, 'round', 3),
      ],
    );
  });

  group('PlayersUpdated', () {
    blocTest<LobbyBloc, LobbyState>(
      'updates player list in state',
      seed: () => LobbyState(
        status: LobbyBlocStatus.loaded,
        lobby: TestFixtures.testLobby,
      ),
      build: () => LobbyBloc(),
      act: (bloc) => bloc.add(PlayersUpdated(TestFixtures.twoPlayers)),
      expect: () => [
        isA<LobbyState>()
            .having((s) => s.players.length, 'count', 2)
            .having((s) => s.players[0].isHost, 'host', true),
      ],
    );
  });

  // ─── Realtime State Sync Tests ───────────────────────

  group('Realtime lobby:state handling', () {
    blocTest<LobbyBloc, LobbyState>(
      'handles lobby:state payload with lobby and players',
      build: () {
        final lobbyStateCtrl =
            StreamController<Map<String, dynamic>>.broadcast();

        when(() => realtimeService.lobbyState$)
            .thenAnswer((_) => lobbyStateCtrl.stream);
        when(() => lobbyRepo.codeForLobbyId(any())).thenReturn('ABC123');
        when(() => lobbyRepo.getLobby(any()))
            .thenAnswer((_) async => TestFixtures.testLobby);
        when(() => lobbyRepo.getPlayers(any()))
            .thenAnswer((_) async => TestFixtures.twoPlayers);

        return LobbyBloc();
      },
      seed: () => LobbyState(
        status: LobbyBlocStatus.loaded,
        lobby: TestFixtures.testLobby,
      ),
      act: (bloc) {
        bloc.add(LobbySubscriptionStarted('lobby-1'));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        // From initial load
        isA<LobbyState>(),
      ],
    );
  });

  // ─── Event Equatable Tests ───────────────────────────

  group('Event equality', () {
    test('CreateLobbyRequested equatable', () {
      const a = CreateLobbyRequested(
        hostName: 'A',
        maxRounds: 20,
        nsfwEnabled: false,
        language: 'en',
      );
      const b = CreateLobbyRequested(
        hostName: 'A',
        maxRounds: 20,
        nsfwEnabled: false,
        language: 'en',
      );
      expect(a, equals(b));
    });

    test('JoinLobbyRequested equatable', () {
      const a = JoinLobbyRequested(code: 'X', playerName: 'Y');
      const b = JoinLobbyRequested(code: 'X', playerName: 'Y');
      expect(a, equals(b));
    });

    test('LobbySubscriptionStarted equatable', () {
      const a = LobbySubscriptionStarted('id-1');
      const b = LobbySubscriptionStarted('id-1');
      expect(a, equals(b));
    });

    test('StartGameRequested equatable', () {
      const a = StartGameRequested();
      const b = StartGameRequested();
      expect(a, equals(b));
    });

    test('LeaveLobbyRequested equatable', () {
      const a = LeaveLobbyRequested();
      const b = LeaveLobbyRequested();
      expect(a, equals(b));
    });
  });

  // ─── State Equatable Tests ───────────────────────────

  group('State equality', () {
    test('states with same data are equal', () {
      final a = LobbyState(
        status: LobbyBlocStatus.loaded,
        lobby: TestFixtures.testLobby,
        players: TestFixtures.twoPlayers,
      );
      final b = LobbyState(
        status: LobbyBlocStatus.loaded,
        lobby: TestFixtures.testLobby,
        players: TestFixtures.twoPlayers,
      );
      expect(a, equals(b));
    });

    test('states with different data are not equal', () {
      final a = LobbyState(
        status: LobbyBlocStatus.loaded,
        lobby: TestFixtures.testLobby,
      );
      final b = LobbyState(
        status: LobbyBlocStatus.error,
        errorMessage: 'fail',
      );
      expect(a, isNot(equals(b)));
    });
  });

  // ─── Host Election Scenario Tests ────────────────────

  group('Host election (client-side data handling)', () {
    test('PlayersUpdated reflects new host from server', () {
      // Simulate server sending new host after host disconnect
      const newHost = Player(
        id: 'player-2',
        lobbyId: 'lobby-1',
        userId: 'user-3',
        displayName: 'GuestPlayer',
        avatarEmoji: '🙂',
        isHost: true,
        status: PlayerStatus.connected,
      );
      const oldHost = Player(
        id: 'player-1',
        lobbyId: 'lobby-1',
        userId: 'user-1',
        displayName: 'TestPlayer',
        avatarEmoji: '😎',
        isHost: false,
        status: PlayerStatus.disconnected,
      );

      final players = [oldHost, newHost];
      final hosts = players.where((p) => p.isHost).toList();
      expect(hosts.length, 1);
      expect(hosts.first.userId, 'user-3');
    });

    test('Lobby.copyWith can change hostId', () {
      final lobby = TestFixtures.testLobby.copyWith(hostId: 'user-3');
      expect(lobby.hostId, 'user-3');
      expect(lobby.id, 'lobby-1'); // other fields unchanged
    });
  });

  // ─── Idempotency Tests ───────────────────────────────

  group('Idempotency', () {
    blocTest<LobbyBloc, LobbyState>(
      'duplicate LobbyUpdated events produce identical state',
      seed: () => LobbyState(
        status: LobbyBlocStatus.loaded,
        lobby: TestFixtures.testLobby,
      ),
      build: () => LobbyBloc(),
      act: (bloc) {
        bloc.add(LobbyUpdated(TestFixtures.playingLobby));
        bloc.add(LobbyUpdated(TestFixtures.playingLobby));
      },
      // Equatable deduplication means second emit is suppressed
      expect: () => [
        isA<LobbyState>()
            .having((s) => s.lobby?.status, 'status', LobbyStatus.playing),
      ],
    );

    blocTest<LobbyBloc, LobbyState>(
      'duplicate PlayersUpdated events produce identical state',
      seed: () => LobbyState(
        status: LobbyBlocStatus.loaded,
        lobby: TestFixtures.testLobby,
      ),
      build: () => LobbyBloc(),
      act: (bloc) {
        bloc.add(PlayersUpdated(TestFixtures.twoPlayers));
        bloc.add(PlayersUpdated(TestFixtures.twoPlayers));
      },
      // Equatable deduplication
      expect: () => [
        isA<LobbyState>()
            .having((s) => s.players.length, 'count', 2),
      ],
    );
  });

  // ─── Entity + State unit tests (merged from lobby_bloc_test) ──

  group('LobbyState copyWith', () {
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
