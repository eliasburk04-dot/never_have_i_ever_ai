// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Never Have I Ever';

  @override
  String get iHave => 'I Have';

  @override
  String get iHaveNot => 'I Have Not';

  @override
  String get createLobby => 'Create Lobby';

  @override
  String get joinLobby => 'Join Lobby';

  @override
  String get enterCode => 'Enter lobby code';

  @override
  String get waitingForPlayers => 'Waiting for players...';

  @override
  String roundOf(int current, int total) {
    return 'Round $current of $total';
  }

  @override
  String playersInLobby(int count) {
    return '$count players';
  }

  @override
  String get startGame => 'Start Game';

  @override
  String get nsfwMode => 'Spicy Mode 🌶️';

  @override
  String get premium => 'Go Premium';

  @override
  String get premiumUnlock => 'Unlock for \$4.99';

  @override
  String get premiumLifetime => 'One-time purchase';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get displayName => 'Display Name';

  @override
  String get avatar => 'Avatar';

  @override
  String get gameOver => 'Game Over!';

  @override
  String get groupProfile => 'Your Group Profile';

  @override
  String get conservative => 'Conservative 😇';

  @override
  String get adventurous => 'Adventurous 😏';

  @override
  String get wild => 'Wild 🔥';

  @override
  String get fearless => 'Fearless 💀';

  @override
  String get boldness => 'Boldness';

  @override
  String get roundsPlayed => 'Rounds Played';

  @override
  String get highestTone => 'Highest Tone';

  @override
  String get playAgain => 'Play Again';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get lobbyCode => 'Lobby Code';

  @override
  String get tapToCopy => 'Tap to copy';

  @override
  String get copied => 'Copied!';

  @override
  String playerJoined(String name) {
    return '$name joined';
  }

  @override
  String playerLeft(String name) {
    return '$name left';
  }

  @override
  String get reconnecting => 'Reconnecting...';

  @override
  String get connectionLost => 'Connection lost';

  @override
  String get retry => 'Retry';

  @override
  String get leave => 'Leave';

  @override
  String get notEnoughPlayers => 'Not enough players to continue';

  @override
  String get minPlayersRequired => 'At least 2 players required';

  @override
  String get rounds => 'Rounds';

  @override
  String get safe => 'Safe';

  @override
  String get deeper => 'Deeper';

  @override
  String get secretive => 'Secretive';

  @override
  String get freaky => 'Freaky';

  @override
  String get free => 'Free';

  @override
  String get premiumLabel => 'Premium';

  @override
  String get unlimitedAi => 'Unlimited AI';

  @override
  String get limitedAi => '10 AI questions/day';

  @override
  String get nsfwAccess => '🌶️ Spicy Mode';

  @override
  String get maxRounds100 => 'Up to 100 rounds';

  @override
  String get maxRounds50 => 'Up to 50 rounds';

  @override
  String get about => 'About';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get timesUp => 'Time\'s up!';

  @override
  String get waitingForAnswers => 'Waiting for answers...';

  @override
  String get everyoneAnswered => 'Everyone answered!';

  @override
  String get mostHonest => 'Most Honest';

  @override
  String get mostSecretive => 'Most Secretive';

  @override
  String get stats => 'Stats';

  @override
  String get avgHaveRatio => 'Avg \"I Have\"';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get error => 'Error';

  @override
  String get ok => 'OK';
}
