import 'dart:async';

import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../core/constants/env.dart';
import 'backend_session_service.dart';

/// Socket.IO realtime bridge for lobby/game state.
///
/// Server contract:
/// - Socket.IO path: `/ws`
/// - auth: `{ jwt }` in connect options
/// - client emits: `lobby:join { lobbyId }`
/// - server emits: `lobby:state`, `round:state`, `answer:state`, `player:joined`, `player:left`
class RealtimeService {
  RealtimeService(this._session);

  final BackendSessionService _session;
  final _log = Logger();

  io.Socket? _socket;
  String? _joinedLobbyId;

  final _lobbyStateCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _roundStateCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _answerStateCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _playerJoinedCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  final _playerLeftCtrl =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get lobbyState$ => _lobbyStateCtrl.stream;
  Stream<Map<String, dynamic>> get roundState$ => _roundStateCtrl.stream;
  Stream<Map<String, dynamic>> get answerState$ => _answerStateCtrl.stream;
  Stream<Map<String, dynamic>> get playerJoined$ => _playerJoinedCtrl.stream;
  Stream<Map<String, dynamic>> get playerLeft$ => _playerLeftCtrl.stream;

  Future<void> connect() async {
    if (_socket != null) return;

    final s = await _session.ensureSession();
    final socket = io.io(
      Env.apiUrl,
      io.OptionBuilder()
          .setPath('/ws')
          .setAuth({'jwt': s.jwt})
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .enableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      _log.i('Socket connected');
      // Re-join lobby after reconnect.
      final lobbyId = _joinedLobbyId;
      if (lobbyId != null) {
        socket.emit('lobby:join', {'lobbyId': lobbyId});
      }
    });
    socket.onDisconnect((_) => _log.w('Socket disconnected'));
    socket.onConnectError((e) => _log.e('Socket connect error', error: e));
    socket.onError((e) => _log.e('Socket error', error: e));

    socket.on('lobby:state', (data) {
      if (data is Map) _lobbyStateCtrl.add(Map<String, dynamic>.from(data));
    });
    socket.on('round:state', (data) {
      if (data is Map) _roundStateCtrl.add(Map<String, dynamic>.from(data));
    });
    socket.on('answer:state', (data) {
      if (data is Map) _answerStateCtrl.add(Map<String, dynamic>.from(data));
    });
    socket.on('player:joined', (data) {
      if (data is Map) _playerJoinedCtrl.add(Map<String, dynamic>.from(data));
    });
    socket.on('player:left', (data) {
      if (data is Map) _playerLeftCtrl.add(Map<String, dynamic>.from(data));
    });

    _socket = socket;
  }

  Future<void> joinLobby(String lobbyId) async {
    await connect();
    _joinedLobbyId = lobbyId;
    _socket?.emit('lobby:join', {'lobbyId': lobbyId});
  }

  /// Back-compat no-op (legacy channel removal).
  void removeByPrefix(String prefix) {}

  void disposeAll() {
    _joinedLobbyId = null;
    final s = _socket;
    _socket = null;
    s?.dispose();

    // Do not close controllers; they are app-singletons.
  }
}

