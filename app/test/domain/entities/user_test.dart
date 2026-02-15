import 'package:flutter_test/flutter_test.dart';

import 'package:nhie_app/domain/entities/user.dart';

void main() {
  group('AppUser', () {
    test('fromMap creates user', () {
      final user = AppUser.fromMap({
        'id': 'abc-123',
        'display_name': 'Alice',
        'avatar_emoji': '🎉',
        'preferred_language': 'de',
      });

      expect(user.id, 'abc-123');
      expect(user.displayName, 'Alice');
      expect(user.avatarEmoji, '🎉');
      expect(user.preferredLanguage, 'de');
    });

    test('fromMap uses defaults for missing fields', () {
      final user = AppUser.fromMap({'id': 'xyz'});
      expect(user.displayName, 'Player');
      expect(user.avatarEmoji, '😎');
      expect(user.preferredLanguage, 'en');
    });

    test('toMap serializes correctly', () {
      const user = AppUser(
        id: 'u1',
        displayName: 'Bob',
        avatarEmoji: '🎸',
        preferredLanguage: 'es',
      );

      final map = user.toMap();
      expect(map['id'], 'u1');
      expect(map['display_name'], 'Bob');
      expect(map['preferred_language'], 'es');
    });

    test('copyWith overrides specific fields', () {
      const user = AppUser(
        id: 'u1',
        displayName: 'Alice',
        avatarEmoji: '😎',
        preferredLanguage: 'en',
      );

      final updated = user.copyWith(displayName: 'Bob', preferredLanguage: 'de');
      expect(updated.displayName, 'Bob');
      expect(updated.preferredLanguage, 'de');
      expect(updated.id, 'u1'); // unchanged
      expect(updated.avatarEmoji, '😎'); // unchanged
    });

    test('equatable equality', () {
      const a = AppUser(
          id: 'u1',
          displayName: 'A',
          avatarEmoji: '😎',
          preferredLanguage: 'en');
      const b = AppUser(
          id: 'u1',
          displayName: 'A',
          avatarEmoji: '😎',
          preferredLanguage: 'en');
      expect(a, equals(b));
    });
  });
}
