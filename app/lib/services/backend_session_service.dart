import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/env.dart';

class BackendSession {
  const BackendSession({
    required this.userId,
    required this.jwt,
  });

  final String userId;
  final String jwt;
}

/// Manages anonymous auth against our self-hosted backend:
/// `POST /auth/anon -> { jwt, userId }`
class BackendSessionService {
  BackendSessionService({
    FlutterSecureStorage? secureStorage,
    http.Client? httpClient,
    Uuid? uuid,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _http = httpClient ?? http.Client(),
        _uuid = uuid ?? const Uuid();

  static const _userIdKey = 'backend_user_id';
  static const _jwtKey = 'backend_jwt';

  final FlutterSecureStorage _secureStorage;
  final http.Client _http;
  final Uuid _uuid;

  SharedPreferences? _prefs;
  BackendSession? _cached;

  /// The currently cached userId (available after [ensureSession]).
  String? get cachedUserId => _cached?.userId;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String> _getOrCreateUserId() async {
    final prefs = await _getPrefs();
    final existing = prefs.getString(_userIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = _uuid.v4();
    await prefs.setString(_userIdKey, created);
    return created;
  }

  /// Ensures we have a valid JWT for our stable `userId`.
  ///
  /// We don't parse token expiry client-side; instead we refresh on demand
  /// (and on 401 from API calls).
  Future<BackendSession> ensureSession({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) return _cached!;

    final userId = await _getOrCreateUserId();
    if (!forceRefresh) {
      final jwt = await _secureStorage.read(key: _jwtKey);
      if (jwt != null && jwt.isNotEmpty) {
        _cached = BackendSession(userId: userId, jwt: jwt);
        return _cached!;
      }
    }

    final uri = Env.apiBaseUri.resolve('/auth/anon');
    final res = await _http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Auth failed (${res.statusCode})');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final jwt = data['jwt'] as String?;
    final returnedUserId = data['userId'] as String?;
    if (jwt == null || jwt.isEmpty) {
      throw Exception('Auth response missing jwt');
    }

    final finalUserId = (returnedUserId != null && returnedUserId.isNotEmpty)
        ? returnedUserId
        : userId;

    final prefs = await _getPrefs();
    await prefs.setString(_userIdKey, finalUserId);
    await _secureStorage.write(key: _jwtKey, value: jwt);

    _cached = BackendSession(userId: finalUserId, jwt: jwt);
    return _cached!;
  }

  Future<String?> get userId async => (await _getPrefs()).getString(_userIdKey);

  Future<void> clear() async {
    final prefs = await _getPrefs();
    await prefs.remove(_userIdKey);
    await _secureStorage.delete(key: _jwtKey);
    _cached = null;
  }
}

