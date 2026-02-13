import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';
import 'utils/i18n.dart';

class NeverHaveIApp extends ConsumerWidget {
  const NeverHaveIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Never Have I Ever AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: I18n.defaultLocale,
      supportedLocales: I18n.supportedLocales,
      routerConfig: router,
    );
  }
}
