import '../entities/user.dart';

/// Abstract repository for authentication operations.
abstract class IAuthRepository {
  Future<AppUser?> signInAnonymously();
  Future<AppUser?> getCurrentUser();
  Future<void> updateProfile({String? displayName, String? avatarEmoji, String? preferredLanguage});
  String? get currentUserId;
}
