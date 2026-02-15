import 'package:equatable/equatable.dart';

/// Domain entity for a user profile.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.avatarEmoji,
    required this.preferredLanguage,
  });

  final String id;
  final String displayName;
  final String avatarEmoji;
  final String preferredLanguage;

  AppUser copyWith({
    String? displayName,
    String? avatarEmoji,
    String? preferredLanguage,
  }) {
    return AppUser(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      displayName: map['display_name'] as String? ?? 'Player',
      avatarEmoji: map['avatar_emoji'] as String? ?? '😎',
      preferredLanguage: map['preferred_language'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'display_name': displayName,
        'avatar_emoji': avatarEmoji,
        'preferred_language': preferredLanguage,
      };

  @override
  List<Object?> get props => [id, displayName, avatarEmoji, preferredLanguage];
}
