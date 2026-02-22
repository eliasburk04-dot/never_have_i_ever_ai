import '../entities/lobby.dart';
import '../entities/player.dart';

/// Abstract repository for lobby operations.
abstract class ILobbyRepository {
  Future<Lobby> createLobby({
    required String language,
    required int maxRounds,
    required bool nsfwEnabled,
    required String displayName,
    required String avatarEmoji,
  });

  Future<Lobby?> joinLobby({
    required String code,
    required String displayName,
    required String avatarEmoji,
  });

  Future<Lobby?> getLobby(String lobbyId);
  String? codeForLobbyId(String lobbyId);
  Future<List<Player>> getPlayers(String lobbyId);
  Future<void> updatePlayerStatus(String lobbyId, String status);
  Future<void> leaveLobby(String lobbyId);
  Future<void> startGame(String lobbyId);
}
