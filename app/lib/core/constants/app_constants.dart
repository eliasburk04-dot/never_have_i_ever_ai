/// App-wide constants.
class AppConstants {
  AppConstants._();

  // Game
  static const int minPlayers = 2;
  static const int maxPlayers = 20;
  static const int defaultRounds = 20;
  static const int minRounds = 10;
  static const int maxRoundsFree = 50;
  static const int maxRoundsPremium = 100;
  static const int lobbyCodeLength = 6;

  // AI
  static const int maxFreeAiCallsPerDay = 10;

  // Reconnect
  static const int maxReconnectRetries = 10;
  static const int reconnectBaseDelayMs = 1000;
  static const int reconnectMaxDelayMs = 30000;

  // Premium (App Store product ID)
  static const String lifetimeProductId = 'nhie_premium_lifetime';
}
