import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:nhie_app/core/constants/game_setup_config.dart';
import 'package:nhie_app/l10n/app_localizations.dart';

void main() {
  group('GameSetupConfig.canStartGame', () {
    test('allows categories only', () {
      final canStart = GameSetupConfig.canStartGame(
        categories: const ['social'],
        selectedPackId: null,
      );

      expect(canStart, isTrue);
    });

    test('allows creator pack only', () {
      final canStart = GameSetupConfig.canStartGame(
        categories: const [],
        selectedPackId: 'icebreakers',
      );

      expect(canStart, isTrue);
    });

    test('allows categories and creator pack', () {
      final canStart = GameSetupConfig.canStartGame(
        categories: const ['social'],
        selectedPackId: 'icebreakers',
      );

      expect(canStart, isTrue);
    });

    test('blocks when neither categories nor creator pack is selected', () {
      final canStart = GameSetupConfig.canStartGame(
        categories: const [],
        selectedPackId: null,
      );

      expect(canStart, isFalse);
    });
  });

  group('category descriptions', () {
    test('are present for all categories in EN/DE/ES', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final localizations = [
        await AppLocalizations.delegate.load(const Locale('en')),
        await AppLocalizations.delegate.load(const Locale('de')),
        await AppLocalizations.delegate.load(const Locale('es')),
      ];

      for (final l10n in localizations) {
        for (final category in GameSetupConfig.allCategories) {
          final description = GameSetupConfig.categoryDescription(
            l10n,
            category,
          );
          final message = GameSetupConfig.categoryDescriptionMessage(
            l10n,
            category,
          );

          expect(description.trim(), isNotEmpty);
          expect(message, isNotNull);
          expect(message!.contains(': '), isTrue);
        }
      }
    });
  });
}
