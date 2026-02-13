import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../lobby/lobby_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String routeName = 'home';
  static const String routePath = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Never Have I Ever AI')),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Create or join a lobby to start playing.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.goNamed(LobbyPage.routeName),
                  child: const Text('Go to Lobby'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
