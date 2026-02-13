import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/game/game_screen.dart';
import 'features/home/home_screen.dart';
import 'features/lobby/create_lobby_screen.dart';
import 'features/lobby/join_lobby_screen.dart';
import 'features/lobby/lobby_waiting_screen.dart';
import 'features/results/results_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: HomeScreen.routePath,
    routes: <RouteBase>[
      GoRoute(
        path: HomeScreen.routePath,
        name: HomeScreen.routeName,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: CreateLobbyScreen.routePath,
        name: CreateLobbyScreen.routeName,
        builder: (context, state) => const CreateLobbyScreen(),
      ),
      GoRoute(
        path: JoinLobbyScreen.routePath,
        name: JoinLobbyScreen.routeName,
        builder: (context, state) => const JoinLobbyScreen(),
      ),
      GoRoute(
        path: LobbyWaitingScreen.routePath,
        name: LobbyWaitingScreen.routeName,
        builder: (context, state) => LobbyWaitingScreen(
          lobbyId: state.pathParameters['lobbyId']!,
        ),
      ),
      GoRoute(
        path: GameScreen.routePath,
        name: GameScreen.routeName,
        builder: (context, state) => GameScreen(
          lobbyId: state.pathParameters['lobbyId']!,
        ),
      ),
      GoRoute(
        path: ResultsScreen.routePath,
        name: ResultsScreen.routeName,
        builder: (context, state) => ResultsScreen(
          lobbyId: state.pathParameters['lobbyId']!,
        ),
      ),
    ],
  );
});
