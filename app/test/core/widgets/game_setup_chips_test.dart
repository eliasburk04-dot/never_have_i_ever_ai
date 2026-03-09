import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nhie_app/core/constants/game_setup_config.dart';
import 'package:nhie_app/core/widgets/game_setup_chips.dart';
import 'package:nhie_app/l10n/app_localizations.dart';

void main() {
  Future<void> pumpGrid(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CategoryGrid(
            selectedCategories: const ['social'],
            isPremium: true,
            onCategoryToggled: (_) {},
            onPremiumLockedTapped: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('long press shows English category description', (tester) async {
    const locale = Locale('en');
    final l10n = await AppLocalizations.delegate.load(locale);
    final categoryLabel = GameSetupConfig.categoryLabel(l10n, 'social');
    final message = GameSetupConfig.categoryDescriptionMessage(l10n, 'social');

    await pumpGrid(tester, locale);

    await tester.longPress(find.text(categoryLabel).first);
    await tester.pumpAndSettle();

    expect(find.text(message!), findsOneWidget);
  });

  testWidgets('long press shows German category description', (tester) async {
    const locale = Locale('de');
    final l10n = await AppLocalizations.delegate.load(locale);
    final categoryLabel = GameSetupConfig.categoryLabel(l10n, 'social');
    final message = GameSetupConfig.categoryDescriptionMessage(l10n, 'social');

    await pumpGrid(tester, locale);

    await tester.longPress(find.text(categoryLabel).first);
    await tester.pumpAndSettle();

    expect(find.text(message!), findsOneWidget);
  });

  testWidgets('long press shows Spanish category description', (tester) async {
    const locale = Locale('es');
    final l10n = await AppLocalizations.delegate.load(locale);
    final categoryLabel = GameSetupConfig.categoryLabel(l10n, 'social');
    final message = GameSetupConfig.categoryDescriptionMessage(l10n, 'social');

    await pumpGrid(tester, locale);

    await tester.longPress(find.text(categoryLabel).first);
    await tester.pumpAndSettle();

    expect(find.text(message!), findsOneWidget);
  });
}
