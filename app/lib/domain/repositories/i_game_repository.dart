import '../entities/round.dart';

/// Abstract repository for game operations.
abstract class IGameRepository {
  Future<GameRound?> triggerNextRound(String lobbyId);
  Future<void> submitAnswer({
    required String roundId,
    required String lobbyId,
    required bool answer,
  });
  Future<void> completeRound({
    required String roundId,
    required String lobbyId,
  });
  Future<GameRound?> getCurrentRound(String lobbyId);
  Future<List<GameRound>> getAllRounds(String lobbyId);

  /// Server-side check: all active players answered? Caller is host?
  Future<bool> checkCanAdvance({
    required String lobbyId,
    required String roundId,
  });

  /// Fetch all answers for a given round (for catching up after subscribe).
  Future<Map<String, bool>> fetchAnswersForRound(String roundId);
}
