import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(ref.watch(supabaseClientProvider));
});

class SupabaseService {
  SupabaseService(this._client);

  final SupabaseClient _client;
  final Uuid _uuid = const Uuid();

  SupabaseClient get client => _client;

  Future<User> signInAnonymouslyIfNeeded() async {
    final existing = _client.auth.currentUser;
    if (existing != null) {
      return existing;
    }

    final response = await _client.auth.signInAnonymously();
    final user = response.user;
    if (user == null) {
      throw const AuthException('Anonymous sign-in failed: user is null.');
    }
    return user;
  }

  Future<Map<String, dynamic>> createLobby(
    String language,
    int roundLimit, {
    int riskLevel = 1,
  }) async {
    final user = await signInAnonymouslyIfNeeded();
    final code = await _generateUniqueLobbyCode();

    final lobbyRows = await _client
        .from('lobbies')
        .insert({
          'code': code,
          'language': language,
          'round_limit': roundLimit,
          'risk_level': riskLevel,
          'status': 'waiting',
          'host_user_id': user.id,
        })
        .select()
        .limit(1);

    if (lobbyRows.isEmpty) {
      throw StateError('Failed to create lobby.');
    }

    final lobby = _mapRow(lobbyRows.first);

    // Create host player row so host appears in the player list and can score.
    await _client.from('players').insert({
      'lobby_id': lobby['id'],
      'auth_user_id': user.id,
      'nickname': 'Host',
      'score': 0,
    });

    return lobby;
  }

  Future<Map<String, dynamic>> joinLobby(String code, String nickname) async {
    final user = await signInAnonymouslyIfNeeded();

    final lobbyRows = await _client
        .from('lobbies')
        .select()
        .eq('code', code.toUpperCase())
        .limit(1);

    if (lobbyRows.isEmpty) {
      throw StateError('Lobby not found for code: $code');
    }

    final lobby = _mapRow(lobbyRows.first);
    final lobbyId = lobby['id'] as String;

    final existingPlayerRows = await _client
        .from('players')
        .select()
        .eq('lobby_id', lobbyId)
        .eq('auth_user_id', user.id)
        .limit(1);

    if (existingPlayerRows.isEmpty) {
      await _client.from('players').insert({
        'lobby_id': lobbyId,
        'auth_user_id': user.id,
        'nickname': nickname,
        'score': 0,
      });
    } else if ((existingPlayerRows.first['nickname'] as String?) != nickname) {
      await _client
          .from('players')
          .update({'nickname': nickname})
          .eq('id', existingPlayerRows.first['id'] as Object);
    }

    return lobby;
  }

  Stream<Map<String, dynamic>?> subscribeLobby(String lobbyId) {
    return _client
        .from('lobbies')
        .stream(primaryKey: ['id'])
        .eq('id', lobbyId)
        .map((rows) => rows.isEmpty ? null : _mapRow(rows.first));
  }

  Stream<List<Map<String, dynamic>>> subscribePlayers(String lobbyId) {
    return _client
        .from('players')
        .stream(primaryKey: ['id'])
        .eq('lobby_id', lobbyId)
        .order('created_at')
        .map((rows) => rows.map(_mapRow).toList(growable: false));
  }

  Stream<List<Map<String, dynamic>>> subscribeRounds(String lobbyId) {
    return _client
        .from('rounds')
        .stream(primaryKey: ['id'])
        .eq('lobby_id', lobbyId)
        .order('started_at')
        .map((rows) => rows.map(_mapRow).toList(growable: false));
  }

  Stream<List<Map<String, dynamic>>> subscribeAnswers(String roundId) {
    return _client
        .from('answers')
        .stream(primaryKey: ['id'])
        .eq('round_id', roundId)
        .order('created_at')
        .map((rows) => rows.map(_mapRow).toList(growable: false));
  }

  Future<Map<String, dynamic>> submitAnswer({
    required String roundId,
    required String playerId,
    required String answer,
    int? responseTimeMs,
  }) async {
    final normalized = answer.toLowerCase();
    if (normalized != 'yes' && normalized != 'no') {
      throw ArgumentError.value(answer, 'answer', "Must be 'yes' or 'no'.");
    }

    await signInAnonymouslyIfNeeded();

    final rows = await _client
        .from('answers')
        .upsert({
          'round_id': roundId,
          'player_id': playerId,
          'answer': normalized,
          'response_time_ms': responseTimeMs,
        }, onConflict: 'round_id,player_id')
        .select()
        .limit(1);

    if (rows.isEmpty) {
      throw StateError('Failed to submit answer.');
    }

    return _mapRow(rows.first);
  }

  Future<Map<String, dynamic>> startRound({
    required String lobbyId,
    required String statement,
    required int riskLevel,
    DateTime? startedAt,
  }) async {
    await signInAnonymouslyIfNeeded();

    final rows = await _client
        .from('rounds')
        .insert({
          'lobby_id': lobbyId,
          'statement': statement,
          'risk_level': riskLevel,
          'started_at': (startedAt ?? DateTime.now().toUtc()).toIso8601String(),
        })
        .select()
        .limit(1);

    if (rows.isEmpty) {
      throw StateError('Failed to start round.');
    }

    await _client.from('lobbies').update({'status': 'in_progress'}).eq('id', lobbyId);

    return _mapRow(rows.first);
  }

  Future<Map<String, dynamic>> endRound({
    required String roundId,
    DateTime? endedAt,
  }) async {
    await signInAnonymouslyIfNeeded();

    final rows = await _client
        .from('rounds')
        .update({
          'ended_at': (endedAt ?? DateTime.now().toUtc()).toIso8601String(),
        })
        .eq('id', roundId)
        .select()
        .limit(1);

    if (rows.isEmpty) {
      throw StateError('Failed to end round.');
    }

    return _mapRow(rows.first);
  }

  Future<Map<String, dynamic>> finishGame(String lobbyId) async {
    await signInAnonymouslyIfNeeded();

    final rows = await _client
        .from('lobbies')
        .update({'status': 'finished'})
        .eq('id', lobbyId)
        .select()
        .limit(1);

    if (rows.isEmpty) {
      throw StateError('Failed to finish game.');
    }

    return _mapRow(rows.first);
  }

  Future<void> cleanupLobby(String lobbyId) async {
    await signInAnonymouslyIfNeeded();

    final response = await _client.functions.invoke(
      'cleanup_lobby',
      body: {'lobby_id': lobbyId},
    );

    if (response.status >= 400) {
      final error = response.data;
      throw StateError('cleanup_lobby failed: $error');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAnswersForRounds(List<String> roundIds) async {
    if (roundIds.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final rows = await _client
        .from('answers')
        .select()
        .inFilter('round_id', roundIds)
        .order('created_at');

    return rows.map(_mapRow).toList(growable: false);
  }

  Future<String> _generateUniqueLobbyCode() async {
    for (var i = 0; i < 10; i++) {
      final candidate = _uuid.v4().replaceAll('-', '').substring(0, 6).toUpperCase();
      final existing = await _client
          .from('lobbies')
          .select('id')
          .eq('code', candidate)
          .limit(1);
      if (existing.isEmpty) {
        return candidate;
      }
    }

    throw StateError('Unable to generate unique lobby code.');
  }

  Map<String, dynamic> _mapRow(Map<String, dynamic> row) {
    return Map<String, dynamic>.from(row);
  }
}
