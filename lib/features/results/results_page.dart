import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../home/home_page.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  static const String routeName = 'results';
  static const String routePath = '/results';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Round results appear here.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.goNamed(HomePage.routeName),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
