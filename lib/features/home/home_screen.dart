import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../utils/i18n.dart';
import '../lobby/create_lobby_screen.dart';
import '../lobby/join_lobby_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = 'home';
  static const routePath = '/';

  @override
  Widget build(BuildContext context) {
    final languageCode = I18n.resolveLanguageCode(Localizations.localeOf(context).languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(I18n.tr('app_title', languageCode: languageCode))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      I18n.tr('home_tagline', languageCode: languageCode),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.goNamed(CreateLobbyScreen.routeName),
                        child: Text(I18n.tr('create_lobby', languageCode: languageCode)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.goNamed(JoinLobbyScreen.routeName),
                        child: Text(I18n.tr('join_lobby', languageCode: languageCode)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
