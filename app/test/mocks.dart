import 'package:mocktail/mocktail.dart';

import 'package:nhie_app/domain/repositories/i_auth_repository.dart';
import 'package:nhie_app/domain/repositories/i_game_repository.dart';
import 'package:nhie_app/domain/repositories/i_lobby_repository.dart';
import 'package:nhie_app/domain/repositories/i_premium_repository.dart';
import 'package:nhie_app/services/store_kit_service.dart';
import 'package:nhie_app/services/realtime_service.dart';

// ─── Service Mocks ──────────────────────────────────────

class MockRealtimeService extends Mock implements RealtimeService {}

class MockStoreKitService extends Mock implements StoreKitService {}

// ─── Repository Mocks ───────────────────────────────────

class MockAuthRepository extends Mock implements IAuthRepository {}

class MockLobbyRepository extends Mock implements ILobbyRepository {}

class MockGameRepository extends Mock implements IGameRepository {}

class MockPremiumRepository extends Mock implements IPremiumRepository {}
