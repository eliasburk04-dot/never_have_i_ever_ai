import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../game/game_page.dart';

class LobbyPage extends StatelessWidget {
  const LobbyPage({super.key});

  static const String routeName = 'lobby';
  static const String routePath = '/lobby';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lobby')),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Players are joining. Start when ready.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.goNamed(GamePage.routeName),
                  child: const Text('Start Game'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
