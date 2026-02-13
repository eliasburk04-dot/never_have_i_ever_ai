import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../results/results_page.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  static const String routeName = 'game';
  static const String routePath = '/game';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game')),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Round in progress...'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.goNamed(ResultsPage.routeName),
                  child: const Text('Finish Round'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
