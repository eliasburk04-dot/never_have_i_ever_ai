// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'EXPOSED';

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
  String get nsfwMode => 'NSFW Mode 🌶️';

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

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get players => 'PLAYERS';

  @override
  String get addPlayer => 'Add Player';

  @override
  String playerHint(int index) {
    return 'Player $index';
  }

  @override
  String get allPlayersNeedName => 'All players need a name!';

  @override
  String get playerNamesMustBeUnique => 'Player names must be unique!';

  @override
  String get nsfwLabel => 'NSFW';

  @override
  String get howManySaidIHave => 'How many said \"I have\"?';

  @override
  String outOfPlayers(int count) {
    return 'out of $count players';
  }

  @override
  String get next => 'Next';

  @override
  String get endGame => 'End Game';

  @override
  String get endGameTitle => 'End Game?';

  @override
  String get endGameBody =>
      'Your progress will be saved. You can resume later.';

  @override
  String get keepPlaying => 'Keep Playing';

  @override
  String get neverHaveIEver => 'EXPOSED';

  @override
  String get recycled => '🔄 Recycled';

  @override
  String get aiGenerated => '✨ AI';

  @override
  String roundsCount(int count) {
    return '$count rounds';
  }

  @override
  String playersCount(int count) {
    return '$count players';
  }

  @override
  String get appSubtitle => 'The party game';

  @override
  String get playOffline => 'Play Offline';

  @override
  String get resumeOfflineGame => 'Resume Offline Game';

  @override
  String get noGameData => 'No game data';

  @override
  String get chooseYourLanguage => 'Choose your\nlanguage';

  @override
  String get changeLanguageLater => 'You can change this later in settings';

  @override
  String get account => 'ACCOUNT';

  @override
  String get legal => 'LEGAL';

  @override
  String get version => 'Version 1.0.0';

  @override
  String get drinkingGameMode => 'Drinking Game Mode 🍺';

  @override
  String get premiumRules => 'Premium Rules';

  @override
  String get playerCount => 'Player Count';

  @override
  String upToPlayers(int count) {
    return 'Up to $count';
  }

  @override
  String upToPlayersFree(int count) {
    return 'Up to $count (Free)';
  }

  @override
  String get yourName => 'YOUR NAME';

  @override
  String get enterDisplayName => 'Enter your display name';

  @override
  String get maxRoundsLabel => 'MAX ROUNDS';

  @override
  String get nsfwModeDesc => '18+ questions included';

  @override
  String get waitingRoom => 'Waiting Room';

  @override
  String get lobbyCodeLabel => 'LOBBY CODE';

  @override
  String get tapToCopyCode => 'Tap to copy';

  @override
  String get codeCopied => 'Code copied!';

  @override
  String needMinPlayers(int count) {
    return 'Need at least $count players to start';
  }

  @override
  String get waitingForHost => 'Waiting for host to start the game…';

  @override
  String get gettingNextQuestion => 'Getting next question…';

  @override
  String get nextQuestion => 'Next Question';

  @override
  String get waitingForAnswers2 => 'Waiting for answers…';

  @override
  String get waitingForHostToContinue => 'Waiting for host to continue…';

  @override
  String get playersLabel => 'Players';

  @override
  String get you => 'you';

  @override
  String get disconnected => 'disconnected';

  @override
  String get waiting => 'waiting…';

  @override
  String get host => 'HOST';

  @override
  String get purchasePremium => 'Purchase Premium';

  @override
  String get lifetimeOneTime => 'Lifetime · One-time purchase';

  @override
  String get youArePremium => 'You\'re Premium';

  @override
  String get premiumEnjoy =>
      'You have access to all 1600+ questions,\nNSFW Mode, Drinking Game & more.';

  @override
  String get unlimitedOfflineRounds => 'Unlimited offline rounds';

  @override
  String get upTo100Rounds => 'Up to 100 rounds per game';

  @override
  String get allCategories => '1600+ questions across all 10 categories';

  @override
  String get premiumNsfwMode => 'NSFW Mode 🌶️ – 160+ explicit questions';

  @override
  String get premiumDrinkingMode => 'Drinking Game Mode 🍺';

  @override
  String get premiumUpTo20Players => 'Up to 20 players per lobby';

  @override
  String get categoriesLabel => 'CATEGORIES';

  @override
  String get goPremium => 'Go Premium';

  @override
  String drinkSips(int count) {
    return 'Take $count sip(s).';
  }

  @override
  String get catSocial => 'Social';

  @override
  String get catParty => 'Party';

  @override
  String get catFood => 'Food';

  @override
  String get catEmbarrassing => 'Embarrassing';

  @override
  String get catRelationships => 'Relationships';

  @override
  String get catConfessions => 'Confessions';

  @override
  String get catRisk => 'Risk';

  @override
  String get catMoralGray => 'Moral Gray';

  @override
  String get catDeep => 'Deep';

  @override
  String get catSexual => 'Intimate';

  @override
  String get about2 => 'ABOUT';

  @override
  String get doubleTapHint => 'Long-press a category for details';

  @override
  String get catDescSocial =>
      'Friendships, social media & everyday interactions';

  @override
  String get catDescParty => 'Nightlife, celebrations & wild moments';

  @override
  String get catDescFood => 'Eating habits, cooking fails & food adventures';

  @override
  String get catDescEmbarrassing => 'Awkward moments & cringe-worthy stories';

  @override
  String get catDescRelationships => 'Love, dating, heartbreak & romance';

  @override
  String get catDescConfessions =>
      'Hidden secrets & things you never told anyone';

  @override
  String get catDescRisk => 'Dares, adrenaline & risky decisions';

  @override
  String get catDescMoralGray =>
      'Ethical dilemmas & morally questionable choices';

  @override
  String get catDescDeep => 'Life, identity, fears & philosophical questions';

  @override
  String get catDescSexual => 'Intimate & sexual experiences (18+)';
}
