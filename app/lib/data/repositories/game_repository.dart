import 'package:logger/logger.dart';

import '../../domain/entities/round.dart';
import '../../domain/repositories/i_game_repository.dart';
import '../../services/backend_api_service.dart';
import '../../services/backend_session_service.dart';

class GameRepository implements IGameRepository {
  GameRepository(this._api, this._session);

  final BackendApiService _api;
  final BackendSessionService _session;
  final _log = Logger();

  @override
  Future<GameRound?> triggerNextRound(String lobbyId) async {
    try {
      _log.w('triggerNextRound(lobbyId) is not supported by the new backend');
      return null;
    } catch (e) {
      _log.e('triggerNextRound failed', error: e);
      return null;
    }
  }

  @override
  Future<void> submitAnswer({
    required String roundId,
    required String lobbyId,
    required bool answer,
  }) async {
    await _session.ensureSession();
    await _api.postJson(
      '/round/$roundId/answer',
      body: {'value': answer ? 'HAVE' : 'HAVE_NOT'},
    );
  }

  @override
  Future<void> completeRound({
    required String roundId,
    required String lobbyId,
  }) async {
    // Not needed; advance endpoint completes and creates next round atomically.
  }

  @override
  Future<GameRound?> getCurrentRound(String lobbyId) async {
    return null;
  }

  @override
  Future<List<GameRound>> getAllRounds(String lobbyId) async {
    // Not exposed by backend right now.
    return const [];
  }

  @override
  Future<bool> checkCanAdvance({
    required String lobbyId,
    required String roundId,
  }) async {
    // We rely on the server-side invariant in `/round/:roundId/advance`.
    return true;
  }

  @override
  Future<Map<String, bool>> fetchAnswersForRound(String roundId) async {
    return {};
  }
}
