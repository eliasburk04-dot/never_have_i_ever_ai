import 'package:nhie_app/domain/entities/lobby.dart';
import 'package:nhie_app/domain/entities/player.dart';
import 'package:nhie_app/domain/entities/round.dart';
import 'package:nhie_app/domain/entities/user.dart';

/// Reusable test fixtures for unit and widget tests.
class TestFixtures {
  TestFixtures._();

  // ─── Users ──────────────────────────────────────────

  static const testUser = AppUser(
    id: 'user-1',
    displayName: 'TestPlayer',
    avatarEmoji: '😎',
    preferredLanguage: 'en',
  );

  static const premiumUser = AppUser(
    id: 'user-2',
    displayName: 'PremiumPlayer',
    avatarEmoji: '⭐',
    preferredLanguage: 'en',
  );

  // ─── Lobbies ────────────────────────────────────────

  static const testLobby = Lobby(
    id: 'lobby-1',
    code: 'ABC123',
    hostId: 'user-1',
    status: LobbyStatus.waiting,
    language: 'en',
    maxRounds: 20,
    currentRound: 0,
    nsfwEnabled: false,
    boldnessScore: 0.0,
    currentTone: ToneLevel.safe,
    roundTimeoutSeconds: 30,
  );

  static const playingLobby = Lobby(
    id: 'lobby-1',
    code: 'ABC123',
    hostId: 'user-1',
    status: LobbyStatus.playing,
    language: 'en',
    maxRounds: 20,
    currentRound: 3,
    nsfwEnabled: false,
    boldnessScore: 0.25,
    currentTone: ToneLevel.deeper,
    roundTimeoutSeconds: 30,
  );

  // ─── Players ────────────────────────────────────────

  static const hostPlayer = Player(
    id: 'player-1',
    lobbyId: 'lobby-1',
    userId: 'user-1',
    displayName: 'TestPlayer',
    avatarEmoji: '😎',
    isHost: true,
    status: PlayerStatus.connected,
  );

  static const guestPlayer = Player(
    id: 'player-2',
    lobbyId: 'lobby-1',
    userId: 'user-3',
    displayName: 'GuestPlayer',
    avatarEmoji: '🙂',
    isHost: false,
    status: PlayerStatus.connected,
  );

  static List<Player> get twoPlayers => [hostPlayer, guestPlayer];

  // ─── Rounds ─────────────────────────────────────────

  static const activeRound = GameRound(
    id: 'round-1',
    lobbyId: 'lobby-1',
    roundNumber: 1,
    questionText: 'Never have I ever traveled to another continent',
    tone: ToneLevel.safe,
    status: RoundStatus.active,
    totalPlayers: 2,
    haveCount: 0,
    haveNotCount: 0,
  );

  static const completedRound = GameRound(
    id: 'round-1',
    lobbyId: 'lobby-1',
    roundNumber: 1,
    questionText: 'Never have I ever traveled to another continent',
    tone: ToneLevel.safe,
    status: RoundStatus.completed,
    totalPlayers: 2,
    haveCount: 1,
    haveNotCount: 1,
  );

  static const deeperRound = GameRound(
    id: 'round-5',
    lobbyId: 'lobby-1',
    roundNumber: 5,
    questionText: 'Never have I ever lied to get out of trouble',
    tone: ToneLevel.deeper,
    status: RoundStatus.active,
    totalPlayers: 4,
    haveCount: 0,
    haveNotCount: 0,
  );
}
