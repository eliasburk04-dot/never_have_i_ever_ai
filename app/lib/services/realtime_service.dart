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
/// - client emits: `lobby:join { lobbyCode, gameKey }` (or legacy `{ lobbyId }`)
/// - client emits: `lobby:leave { lobbyCode }` for explicit leave
/// - server emits: `lobby:state`, `round:state`, `answer:state`, `player:joined`, `player:left`
class RealtimeService {
  RealtimeService(this._session);

  final BackendSessionService _session;
  final _log = Logger();

  io.Socket? _socket;
  String? _joinedLobbyId;
  String? _joinedLobbyCode;
  Map<String, dynamic>? _lastLobbyState;
  Map<String, dynamic>? _lastRoundState;
  Map<String, dynamic>? _lastAnswerState;

  final _lobbyStateCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _roundStateCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _answerStateCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _playerJoinedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _playerLeftCtrl = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get lobbyState$ => _lobbyStateCtrl.stream;
  Stream<Map<String, dynamic>> get roundState$ => _roundStateCtrl.stream;
  Stream<Map<String, dynamic>> get answerState$ => _answerStateCtrl.stream;
  Stream<Map<String, dynamic>> get playerJoined$ => _playerJoinedCtrl.stream;
  Stream<Map<String, dynamic>> get playerLeft$ => _playerLeftCtrl.stream;
  Map<String, dynamic>? get lastLobbyState => _lastLobbyState;
  Map<String, dynamic>? get lastRoundState => _lastRoundState;
  Map<String, dynamic>? get lastAnswerState => _lastAnswerState;

  Future<void> connect() async {
    if (_socket != null) return;

    final s = await _session.ensureSession();
    // Server creates namespace at io.of('/ws') with Engine.IO path '/ws'.
    // socket_io_client: URL suffix = namespace, setPath = Engine.IO path.
    final socket = io.io(
      '${Env.apiUrl}/ws',
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
      final code = _joinedLobbyCode;
      final lobbyId = _joinedLobbyId;
      if (code != null) {
        socket.emit('lobby:join', {
          'lobbyCode': code,
          'gameKey': 'never_have_i_ever',
        });
      } else if (lobbyId != null) {
        // Fallback for legacy — server resolves lobbyId to code
        socket.emit('lobby:join', {'lobbyId': lobbyId});
      }
    });
    socket.onDisconnect((_) => _log.w('Socket disconnected'));
    socket.onConnectError((e) => _log.e('Socket connect error', error: e));
    socket.onError((e) => _log.e('Socket error', error: e));

    socket.on('lobby:state', (data) {
      if (data is Map) {
        _lastLobbyState = Map<String, dynamic>.from(data);
        _lobbyStateCtrl.add(_lastLobbyState!);
      }
    });
    socket.on('round:state', (data) {
      if (data is Map) {
        _lastRoundState = Map<String, dynamic>.from(data);
        _roundStateCtrl.add(_lastRoundState!);
      }
    });
    socket.on('answer:state', (data) {
      if (data is Map) {
        _lastAnswerState = Map<String, dynamic>.from(data);
        _answerStateCtrl.add(_lastAnswerState!);
      }
    });
    socket.on('player:joined', (data) {
      if (data is Map) _playerJoinedCtrl.add(Map<String, dynamic>.from(data));
    });
    socket.on('player:left', (data) {
      if (data is Map) _playerLeftCtrl.add(Map<String, dynamic>.from(data));
    });

    _socket = socket;
  }

  /// Join a lobby by its lobby code (preferred) and optionally lobbyId (legacy).
  Future<void> joinLobby(String lobbyId, {String? lobbyCode}) async {
    await connect();
    if (_joinedLobbyId != null && _joinedLobbyId != lobbyId) {
      _lastLobbyState = null;
      _lastRoundState = null;
      _lastAnswerState = null;
    }
    _joinedLobbyId = lobbyId;
    _joinedLobbyCode = lobbyCode;

    if (lobbyCode != null && lobbyCode.isNotEmpty) {
      _socket?.emit('lobby:join', {
        'lobbyCode': lobbyCode,
        'gameKey': 'never_have_i_ever',
      });
    } else {
      // Legacy fallback — server will resolve lobbyId to code
      _socket?.emit('lobby:join', {'lobbyId': lobbyId});
    }
  }

  /// Explicitly leave the current lobby.
  void leaveLobby() {
    final code = _joinedLobbyCode;
    final lobbyId = _joinedLobbyId;
    if (code != null) {
      _socket?.emit('lobby:leave', {'lobbyCode': code});
    } else if (lobbyId != null) {
      _socket?.emit('lobby:leave', {'lobbyId': lobbyId});
    }
    _joinedLobbyId = null;
    _joinedLobbyCode = null;
    _lastLobbyState = null;
    _lastRoundState = null;
    _lastAnswerState = null;
  }

  /// Back-compat no-op (legacy channel removal).
  void removeByPrefix(String prefix) {}

  void disposeAll() {
    // Send leave before disposing if still joined
    leaveLobby();
    final s = _socket;
    _socket = null;
    s?.dispose();

    // Do not close controllers; they are app-singletons.
  }
}
