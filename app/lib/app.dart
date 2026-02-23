import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/game/bloc/game_bloc.dart';
import 'features/lobby/bloc/lobby_bloc.dart';
import 'features/offline/cubit/game_config_cubit.dart';
import 'features/offline/cubit/offline_game_cubit.dart';
import 'features/premium/cubit/premium_cubit.dart';
import 'l10n/app_localizations.dart';

class NhieApp extends StatelessWidget {
  const NhieApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Force dark status bar icons for our dark theme
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LobbyBloc()),
        BlocProvider(create: (_) => GameBloc()),
        BlocProvider(create: (_) => PremiumCubit()..checkPremium()),
        BlocProvider(create: (_) => OfflineGameCubit()),
        BlocProvider(create: (_) => GameConfigCubit()..loadPersistedSettings()),
      ],
      child: BlocBuilder<GameConfigCubit, GameConfigState>(
        buildWhen: (prev, curr) => prev.language != curr.language,
        builder: (context, configState) {
          return MaterialApp.router(
            title: 'EXPOSED',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            routerConfig: appRouter,
            locale: Locale(configState.language),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
