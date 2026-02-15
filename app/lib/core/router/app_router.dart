import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_motion.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/language/view/language_select_screen.dart';
import '../../features/home/view/home_screen.dart';
import '../../features/lobby/view/create_lobby_screen.dart';
import '../../features/lobby/view/join_lobby_screen.dart';
import '../../features/lobby/view/lobby_waiting_screen.dart';
import '../../features/game/view/game_round_screen.dart';
import '../../features/game/view/results_screen.dart';
import '../../features/offline/view/offline_setup_screen.dart';
import '../../features/offline/view/offline_game_screen.dart';
import '../../features/offline/view/offline_results_screen.dart';
import '../../features/premium/view/premium_screen.dart';
import '../../features/settings/view/settings_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Shared fade+slide page transition — cinematic but fast.
CustomTransitionPage<void> _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.pageTransition,
    reverseTransitionDuration: AppMotion.pageTransitionReverse,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (_, state) => _buildPage(const SplashScreen(), state),
    ),
    GoRoute(
      path: '/language',
      pageBuilder: (_, state) =>
          _buildPage(const LanguageSelectScreen(), state),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (_, state) => _buildPage(const HomeScreen(), state),
    ),
    GoRoute(
      path: '/lobby/create',
      pageBuilder: (_, state) =>
          _buildPage(const CreateLobbyScreen(), state),
    ),
    GoRoute(
      path: '/lobby/join',
      pageBuilder: (_, state) =>
          _buildPage(const JoinLobbyScreen(), state),
    ),
    GoRoute(
      path: '/lobby/:id/waiting',
      pageBuilder: (_, state) => _buildPage(
        LobbyWaitingScreen(lobbyId: state.pathParameters['id']!),
        state,
      ),
    ),
    GoRoute(
      path: '/game/:lobbyId',
      pageBuilder: (_, state) => _buildPage(
        GameRoundScreen(lobbyId: state.pathParameters['lobbyId']!),
        state,
      ),
    ),
    GoRoute(
      path: '/game/:lobbyId/results',
      pageBuilder: (_, state) => _buildPage(
        ResultsScreen(lobbyId: state.pathParameters['lobbyId']!),
        state,
      ),
    ),
    GoRoute(
      path: '/premium',
      pageBuilder: (_, state) => _buildPage(const PremiumScreen(), state),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (_, state) => _buildPage(const SettingsScreen(), state),
    ),
    GoRoute(
      path: '/offline/setup',
      pageBuilder: (_, state) =>
          _buildPage(const OfflineSetupScreen(), state),
    ),
    GoRoute(
      path: '/offline/game',
      pageBuilder: (_, state) =>
          _buildPage(const OfflineGameScreen(), state),
    ),
    GoRoute(
      path: '/offline/results',
      pageBuilder: (_, state) =>
          _buildPage(const OfflineResultsScreen(), state),
    ),
  ],
);
