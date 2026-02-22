import 'package:flutter/foundation.dart';

/// Environment configuration loaded from dart-define at build time.
///
/// Run with:
/// ```
/// flutter run --dart-define-from-file=.env.json
/// ```
///
class Env {
  Env._();

  /// Base URL of your backend API.
  ///
  /// Example (LAN): `http://192.168.178.143`
  static String get apiUrl {
    if (kIsWeb) return 'http://localhost:8080';
    return const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://192.168.178.143',
    );
  }

  static Uri get apiBaseUri => Uri.parse(apiUrl);
}
