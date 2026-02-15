import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../services/backend_session_service.dart';

class AuthRepository implements IAuthRepository {
  AuthRepository(this._session);

  final BackendSessionService _session;
  final _log = Logger();

  String? _currentUserId;

  static const _displayNameKey = 'profile_display_name';
  static const _avatarEmojiKey = 'profile_avatar_emoji';
  static const _preferredLanguageKey = 'profile_preferred_language';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  @override
  String? get currentUserId => _currentUserId;

  @override
  Future<AppUser?> signInAnonymously() async {
    try {
      final s = await _session.ensureSession(forceRefresh: true);
      _currentUserId = s.userId;
      return getCurrentUser();
    } catch (e) {
      _log.e('Anonymous auth failed', error: e);
      return null;
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      final s = await _session.ensureSession();
      _currentUserId = s.userId;

      final prefs = await _prefs();
      return AppUser(
        id: s.userId,
        displayName: prefs.getString(_displayNameKey) ?? 'Player',
        avatarEmoji: prefs.getString(_avatarEmojiKey) ?? '😎',
        preferredLanguage: prefs.getString(_preferredLanguageKey) ?? 'en',
      );
    } catch (e) {
      _log.e('Failed to get current user', error: e);
      return null;
    }
  }

  @override
  Future<void> updateProfile({
    String? displayName,
    String? avatarEmoji,
    String? preferredLanguage,
  }) async {
    final prefs = await _prefs();
    if (displayName != null) await prefs.setString(_displayNameKey, displayName);
    if (avatarEmoji != null) await prefs.setString(_avatarEmojiKey, avatarEmoji);
    if (preferredLanguage != null) {
      await prefs.setString(_preferredLanguageKey, preferredLanguage);
    }
  }
}
