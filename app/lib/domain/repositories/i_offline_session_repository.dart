import '../entities/offline_session.dart';

/// Interface for persisting offline game sessions.
abstract class IOfflineSessionRepository {
  /// Save or update a session.
  Future<void> saveSession(OfflineSession session);

  /// Load a session by ID. Returns null if not found.
  Future<OfflineSession?> loadSession(String id);

  /// Get the ID of the currently active (in-progress) session, if any.
  String? get activeSessionId;

  /// Set or clear the active session ID.
  Future<void> setActiveSessionId(String? id);

  /// List all completed sessions, newest first.
  Future<List<OfflineSession>> listCompletedSessions();

  /// Delete a session by ID.
  Future<void> deleteSession(String id);
}
