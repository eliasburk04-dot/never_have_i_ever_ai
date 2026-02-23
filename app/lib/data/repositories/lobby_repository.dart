import 'package:logger/logger.dart';

import '../../domain/entities/lobby.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/i_lobby_repository.dart';
import '../../services/backend_api_service.dart';
import '../../services/backend_session_service.dart';

class LobbyRepository implements ILobbyRepository {
  LobbyRepository(this._api, this._session);

  final BackendApiService _api;
  final BackendSessionService _session;
  final _log = Logger();

  // The public API uses lobby codes for state fetch; keep a small local cache.
  final Map<String, String> _lobbyIdToCode = {};

  String? _codeForLobbyId(String lobbyId) => _lobbyIdToCode[lobbyId];

  @override
  String? codeForLobbyId(String lobbyId) => _codeForLobbyId(lobbyId);

  void _rememberLobby(Lobby lobby) {
    _lobbyIdToCode[lobby.id] = lobby.code;
  }

  @override
  Future<Lobby> createLobby({
    required String language,
    required int maxRounds,
    required bool nsfwEnabled,
    required String displayName,
    required String avatarEmoji,
    required List<String> categories,
  }) async {
    await _session.ensureSession(); // ensure JWT exists
    final res = await _api.postJson(
      '/lobby/create',
      body: {
        'language': language,
        'maxRounds': maxRounds,
        'nsfwEnabled': nsfwEnabled,
        'displayName': displayName,
        'avatarEmoji': avatarEmoji,
        'categories': categories,
      },
    );

    final lobbyMap = (res['lobby'] ?? res) as Map<String, dynamic>;
    final lobby = Lobby.fromMap(lobbyMap);
    _rememberLobby(lobby);
    return lobby;
  }

  @override
  Future<Lobby?> joinLobby({
    required String code,
    required String displayName,
    required String avatarEmoji,
  }) async {
    await _session.ensureSession();
    try {
      final res = await _api.postJson(
        '/lobby/join',
        body: {
          'code': code,
          'displayName': displayName,
          'avatarEmoji': avatarEmoji,
        },
      );

      final lobbyMap = (res['lobby'] ?? res) as Map<String, dynamic>;
      final lobby = Lobby.fromMap(lobbyMap);
      _rememberLobby(lobby);
      return lobby;
    } catch (e) {
      _log.e('joinLobby failed', error: e);
      return null;
    }
  }

  @override
  Future<Lobby?> getLobby(String lobbyId) async {
    final code = _codeForLobbyId(lobbyId);
    if (code == null) return null;
    try {
      final res = await _api.getJson('/lobby/$code/state');
      final lobbyMap = res['lobby'] as Map<String, dynamic>?;
      if (lobbyMap == null) return null;
      final lobby = Lobby.fromMap(lobbyMap);
      _rememberLobby(lobby);
      return lobby;
    } catch (e) {
      _log.e('getLobby failed', error: e);
      return null;
    }
  }

  @override
  Future<List<Player>> getPlayers(String lobbyId) async {
    final code = _codeForLobbyId(lobbyId);
    if (code == null) return [];
    try {
      final res = await _api.getJson('/lobby/$code/state');
      final players = (res['players'] as List? ?? const [])
          .whereType<Map>()
          .map((p) => Player.fromMap(Map<String, dynamic>.from(p)))
          .toList();
      return players;
    } catch (e) {
      _log.e('getPlayers failed', error: e);
      return [];
    }
  }

  @override
  Future<void> updatePlayerStatus(String lobbyId, String status) async {
    // Server manages player status via WebSocket presence.
  }

  @override
  Future<void> leaveLobby(String lobbyId) async {
    final code = _codeForLobbyId(lobbyId);
    if (code == null) return;
    try {
      await _api.postJson('/lobby/$code/leave');
    } catch (e) {
      _log.e('leaveLobby failed', error: e);
    }
    _lobbyIdToCode.remove(lobbyId);
  }

  @override
  Future<void> startGame(String lobbyId) async {
    final code = _codeForLobbyId(lobbyId);
    if (code == null) throw Exception('No code for lobby $lobbyId');
    await _session.ensureSession();
    await _api.postJson('/lobby/$code/start');
  }
}
