import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/offline_session.dart';
import '../../domain/repositories/i_offline_session_repository.dart';

/// Hive-backed implementation of [IOfflineSessionRepository].
class OfflineSessionRepository implements IOfflineSessionRepository {
  OfflineSessionRepository();

  static const _sessionsBoxName = 'offlineSessions';
  static const _settingsBoxName = 'appSettings';
  static const _activeIdKey = 'activeOfflineSessionId';
  static const _maxStoredSessions = 20;

  Box<String> get _sessionsBox => Hive.box<String>(_sessionsBoxName);
  Box<dynamic> get _settingsBox => Hive.box(_settingsBoxName);

  @override
  Future<void> saveSession(OfflineSession session) async {
    await _sessionsBox.put(session.id, session.toJson());
    await _enforceRetentionLimit();
  }

  @override
  Future<OfflineSession?> loadSession(String id) async {
    final json = _sessionsBox.get(id);
    if (json == null) return null;
    return OfflineSession.fromJson(json);
  }

  @override
  String? get activeSessionId =>
      _settingsBox.get(_activeIdKey) as String?;

  @override
  Future<void> setActiveSessionId(String? id) async {
    if (id == null) {
      await _settingsBox.delete(_activeIdKey);
    } else {
      await _settingsBox.put(_activeIdKey, id);
    }
  }

  @override
  Future<List<OfflineSession>> listCompletedSessions() async {
    final sessions = <OfflineSession>[];
    for (final key in _sessionsBox.keys) {
      final json = _sessionsBox.get(key);
      if (json == null) continue;
      try {
        final session = OfflineSession.fromJson(json);
        if (session.isComplete) sessions.add(session);
      } catch (_) {
        // Skip corrupted entries
      }
    }
    sessions.sort((a, b) =>
        (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return sessions;
  }

  @override
  Future<void> deleteSession(String id) async {
    await _sessionsBox.delete(id);
    if (activeSessionId == id) {
      await setActiveSessionId(null);
    }
  }

  /// Keep at most [_maxStoredSessions] completed sessions.
  Future<void> _enforceRetentionLimit() async {
    final completed = await listCompletedSessions();
    if (completed.length > _maxStoredSessions) {
      final toDelete = completed.sublist(_maxStoredSessions);
      for (final s in toDelete) {
        await _sessionsBox.delete(s.id);
      }
    }
  }
}
