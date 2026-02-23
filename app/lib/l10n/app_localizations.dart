import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'EXPOSED'**
  String get appTitle;

  /// No description provided for @iHave.
  ///
  /// In en, this message translates to:
  /// **'I Have'**
  String get iHave;

  /// No description provided for @iHaveNot.
  ///
  /// In en, this message translates to:
  /// **'I Have Not'**
  String get iHaveNot;

  /// No description provided for @createLobby.
  ///
  /// In en, this message translates to:
  /// **'Create Lobby'**
  String get createLobby;

  /// No description provided for @joinLobby.
  ///
  /// In en, this message translates to:
  /// **'Join Lobby'**
  String get joinLobby;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter lobby code'**
  String get enterCode;

  /// No description provided for @waitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for players...'**
  String get waitingForPlayers;

  /// No description provided for @roundOf.
  ///
  /// In en, this message translates to:
  /// **'Round {current} of {total}'**
  String roundOf(int current, int total);

  /// No description provided for @playersInLobby.
  ///
  /// In en, this message translates to:
  /// **'{count} players'**
  String playersInLobby(int count);

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get startGame;

  /// No description provided for @nsfwMode.
  ///
  /// In en, this message translates to:
  /// **'NSFW Mode 🌶️'**
  String get nsfwMode;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get premium;

  /// No description provided for @premiumUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock for \$4.99'**
  String get premiumUnlock;

  /// No description provided for @premiumLifetime.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase'**
  String get premiumLifetime;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @avatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatar;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over!'**
  String get gameOver;

  /// No description provided for @groupProfile.
  ///
  /// In en, this message translates to:
  /// **'Your Group Profile'**
  String get groupProfile;

  /// No description provided for @conservative.
  ///
  /// In en, this message translates to:
  /// **'Conservative 😇'**
  String get conservative;

  /// No description provided for @adventurous.
  ///
  /// In en, this message translates to:
  /// **'Adventurous 😏'**
  String get adventurous;

  /// No description provided for @wild.
  ///
  /// In en, this message translates to:
  /// **'Wild 🔥'**
  String get wild;

  /// No description provided for @fearless.
  ///
  /// In en, this message translates to:
  /// **'Fearless 💀'**
  String get fearless;

  /// No description provided for @boldness.
  ///
  /// In en, this message translates to:
  /// **'Boldness'**
  String get boldness;

  /// No description provided for @roundsPlayed.
  ///
  /// In en, this message translates to:
  /// **'Rounds Played'**
  String get roundsPlayed;

  /// No description provided for @highestTone.
  ///
  /// In en, this message translates to:
  /// **'Highest Tone'**
  String get highestTone;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @lobbyCode.
  ///
  /// In en, this message translates to:
  /// **'Lobby Code'**
  String get lobbyCode;

  /// No description provided for @tapToCopy.
  ///
  /// In en, this message translates to:
  /// **'Tap to copy'**
  String get tapToCopy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;

  /// No description provided for @playerJoined.
  ///
  /// In en, this message translates to:
  /// **'{name} joined'**
  String playerJoined(String name);

  /// No description provided for @playerLeft.
  ///
  /// In en, this message translates to:
  /// **'{name} left'**
  String playerLeft(String name);

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// No description provided for @connectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get connectionLost;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @notEnoughPlayers.
  ///
  /// In en, this message translates to:
  /// **'Not enough players to continue'**
  String get notEnoughPlayers;

  /// No description provided for @minPlayersRequired.
  ///
  /// In en, this message translates to:
  /// **'At least 2 players required'**
  String get minPlayersRequired;

  /// No description provided for @rounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get rounds;

  /// No description provided for @safe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get safe;

  /// No description provided for @deeper.
  ///
  /// In en, this message translates to:
  /// **'Deeper'**
  String get deeper;

  /// No description provided for @secretive.
  ///
  /// In en, this message translates to:
  /// **'Secretive'**
  String get secretive;

  /// No description provided for @freaky.
  ///
  /// In en, this message translates to:
  /// **'Freaky'**
  String get freaky;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @premiumLabel.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumLabel;

  /// No description provided for @unlimitedAi.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI'**
  String get unlimitedAi;

  /// No description provided for @limitedAi.
  ///
  /// In en, this message translates to:
  /// **'10 AI questions/day'**
  String get limitedAi;

  /// No description provided for @nsfwAccess.
  ///
  /// In en, this message translates to:
  /// **'🌶️ Spicy Mode'**
  String get nsfwAccess;

  /// No description provided for @maxRounds100.
  ///
  /// In en, this message translates to:
  /// **'Up to 100 rounds'**
  String get maxRounds100;

  /// No description provided for @maxRounds50.
  ///
  /// In en, this message translates to:
  /// **'Up to 50 rounds'**
  String get maxRounds50;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @timesUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up!'**
  String get timesUp;

  /// No description provided for @waitingForAnswers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for answers...'**
  String get waitingForAnswers;

  /// No description provided for @everyoneAnswered.
  ///
  /// In en, this message translates to:
  /// **'Everyone answered!'**
  String get everyoneAnswered;

  /// No description provided for @mostHonest.
  ///
  /// In en, this message translates to:
  /// **'Most Honest'**
  String get mostHonest;

  /// No description provided for @mostSecretive.
  ///
  /// In en, this message translates to:
  /// **'Most Secretive'**
  String get mostSecretive;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @avgHaveRatio.
  ///
  /// In en, this message translates to:
  /// **'Avg \"I Have\"'**
  String get avgHaveRatio;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'PLAYERS'**
  String get players;

  /// No description provided for @addPlayer.
  ///
  /// In en, this message translates to:
  /// **'Add Player'**
  String get addPlayer;

  /// No description provided for @playerHint.
  ///
  /// In en, this message translates to:
  /// **'Player {index}'**
  String playerHint(int index);

  /// No description provided for @allPlayersNeedName.
  ///
  /// In en, this message translates to:
  /// **'All players need a name!'**
  String get allPlayersNeedName;

  /// No description provided for @playerNamesMustBeUnique.
  ///
  /// In en, this message translates to:
  /// **'Player names must be unique!'**
  String get playerNamesMustBeUnique;

  /// No description provided for @nsfwLabel.
  ///
  /// In en, this message translates to:
  /// **'NSFW'**
  String get nsfwLabel;

  /// No description provided for @howManySaidIHave.
  ///
  /// In en, this message translates to:
  /// **'How many said \"I have\"?'**
  String get howManySaidIHave;

  /// No description provided for @outOfPlayers.
  ///
  /// In en, this message translates to:
  /// **'out of {count} players'**
  String outOfPlayers(int count);

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @endGame.
  ///
  /// In en, this message translates to:
  /// **'End Game'**
  String get endGame;

  /// No description provided for @endGameTitle.
  ///
  /// In en, this message translates to:
  /// **'End Game?'**
  String get endGameTitle;

  /// No description provided for @endGameBody.
  ///
  /// In en, this message translates to:
  /// **'Your progress will be saved. You can resume later.'**
  String get endGameBody;

  /// No description provided for @keepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep Playing'**
  String get keepPlaying;

  /// No description provided for @neverHaveIEver.
  ///
  /// In en, this message translates to:
  /// **'EXPOSED'**
  String get neverHaveIEver;

  /// No description provided for @recycled.
  ///
  /// In en, this message translates to:
  /// **'🔄 Recycled'**
  String get recycled;

  /// No description provided for @aiGenerated.
  ///
  /// In en, this message translates to:
  /// **'✨ AI'**
  String get aiGenerated;

  /// No description provided for @roundsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} rounds'**
  String roundsCount(int count);

  /// No description provided for @playersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} players'**
  String playersCount(int count);

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The party game'**
  String get appSubtitle;

  /// No description provided for @playOffline.
  ///
  /// In en, this message translates to:
  /// **'Play Offline'**
  String get playOffline;

  /// No description provided for @resumeOfflineGame.
  ///
  /// In en, this message translates to:
  /// **'Resume Offline Game'**
  String get resumeOfflineGame;

  /// No description provided for @noGameData.
  ///
  /// In en, this message translates to:
  /// **'No game data'**
  String get noGameData;

  /// No description provided for @chooseYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your\nlanguage'**
  String get chooseYourLanguage;

  /// No description provided for @changeLanguageLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in settings'**
  String get changeLanguageLater;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get account;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'LEGAL'**
  String get legal;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get version;

  /// No description provided for @drinkingGameMode.
  ///
  /// In en, this message translates to:
  /// **'Drinking Game Mode 🍺'**
  String get drinkingGameMode;

  /// No description provided for @premiumRules.
  ///
  /// In en, this message translates to:
  /// **'Premium Rules'**
  String get premiumRules;

  /// No description provided for @playerCount.
  ///
  /// In en, this message translates to:
  /// **'Player Count'**
  String get playerCount;

  /// No description provided for @upToPlayers.
  ///
  /// In en, this message translates to:
  /// **'Up to {count}'**
  String upToPlayers(int count);

  /// No description provided for @upToPlayersFree.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} (Free)'**
  String upToPlayersFree(int count);

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'YOUR NAME'**
  String get yourName;

  /// No description provided for @enterDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Enter your display name'**
  String get enterDisplayName;

  /// No description provided for @maxRoundsLabel.
  ///
  /// In en, this message translates to:
  /// **'MAX ROUNDS'**
  String get maxRoundsLabel;

  /// No description provided for @nsfwModeDesc.
  ///
  /// In en, this message translates to:
  /// **'18+ questions included'**
  String get nsfwModeDesc;

  /// No description provided for @waitingRoom.
  ///
  /// In en, this message translates to:
  /// **'Waiting Room'**
  String get waitingRoom;

  /// No description provided for @lobbyCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'LOBBY CODE'**
  String get lobbyCodeLabel;

  /// No description provided for @tapToCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Tap to copy'**
  String get tapToCopyCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get codeCopied;

  /// No description provided for @needMinPlayers.
  ///
  /// In en, this message translates to:
  /// **'Need at least {count} players to start'**
  String needMinPlayers(int count);

  /// No description provided for @waitingForHost.
  ///
  /// In en, this message translates to:
  /// **'Waiting for host to start the game…'**
  String get waitingForHost;

  /// No description provided for @gettingNextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Getting next question…'**
  String get gettingNextQuestion;

  /// No description provided for @nextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next Question'**
  String get nextQuestion;

  /// No description provided for @waitingForAnswers2.
  ///
  /// In en, this message translates to:
  /// **'Waiting for answers…'**
  String get waitingForAnswers2;

  /// No description provided for @waitingForHostToContinue.
  ///
  /// In en, this message translates to:
  /// **'Waiting for host to continue…'**
  String get waitingForHostToContinue;

  /// No description provided for @playersLabel.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get playersLabel;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get you;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'disconnected'**
  String get disconnected;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'waiting…'**
  String get waiting;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'HOST'**
  String get host;

  /// No description provided for @purchasePremium.
  ///
  /// In en, this message translates to:
  /// **'Purchase Premium'**
  String get purchasePremium;

  /// No description provided for @lifetimeOneTime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime · One-time purchase'**
  String get lifetimeOneTime;

  /// No description provided for @youArePremium.
  ///
  /// In en, this message translates to:
  /// **'You\'re Premium'**
  String get youArePremium;

  /// No description provided for @premiumEnjoy.
  ///
  /// In en, this message translates to:
  /// **'You have access to all Premium Categories\n& the Drinking Game Mode.'**
  String get premiumEnjoy;

  /// No description provided for @unlimitedOfflineRounds.
  ///
  /// In en, this message translates to:
  /// **'Unlimited offline rounds'**
  String get unlimitedOfflineRounds;

  /// No description provided for @upTo100Rounds.
  ///
  /// In en, this message translates to:
  /// **'Up to 100 rounds per game'**
  String get upTo100Rounds;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'Unlock all 10 topics (18+, Deep)'**
  String get allCategories;

  /// No description provided for @categoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'CATEGORIES'**
  String get categoriesLabel;

  /// No description provided for @goPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get goPremium;

  /// No description provided for @drinkSips.
  ///
  /// In en, this message translates to:
  /// **'Take {count} sip(s).'**
  String drinkSips(int count);

  /// No description provided for @catSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get catSocial;

  /// No description provided for @catParty.
  ///
  /// In en, this message translates to:
  /// **'Party'**
  String get catParty;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catEmbarrassing.
  ///
  /// In en, this message translates to:
  /// **'Embarrassing'**
  String get catEmbarrassing;

  /// No description provided for @catRelationships.
  ///
  /// In en, this message translates to:
  /// **'Relationships'**
  String get catRelationships;

  /// No description provided for @catConfessions.
  ///
  /// In en, this message translates to:
  /// **'Confessions'**
  String get catConfessions;

  /// No description provided for @catRisk.
  ///
  /// In en, this message translates to:
  /// **'Risk'**
  String get catRisk;

  /// No description provided for @catMoralGray.
  ///
  /// In en, this message translates to:
  /// **'Moral Gray'**
  String get catMoralGray;

  /// No description provided for @catDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get catDeep;

  /// No description provided for @catSexual.
  ///
  /// In en, this message translates to:
  /// **'Intimate'**
  String get catSexual;

  /// No description provided for @about2.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get about2;

  /// No description provided for @doubleTapHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press a category for details'**
  String get doubleTapHint;

  /// No description provided for @catDescSocial.
  ///
  /// In en, this message translates to:
  /// **'Friendships, social media & everyday interactions'**
  String get catDescSocial;

  /// No description provided for @catDescParty.
  ///
  /// In en, this message translates to:
  /// **'Nightlife, celebrations & wild moments'**
  String get catDescParty;

  /// No description provided for @catDescFood.
  ///
  /// In en, this message translates to:
  /// **'Eating habits, cooking fails & food adventures'**
  String get catDescFood;

  /// No description provided for @catDescEmbarrassing.
  ///
  /// In en, this message translates to:
  /// **'Awkward moments & cringe-worthy stories'**
  String get catDescEmbarrassing;

  /// No description provided for @catDescRelationships.
  ///
  /// In en, this message translates to:
  /// **'Love, dating, heartbreak & romance'**
  String get catDescRelationships;

  /// No description provided for @catDescConfessions.
  ///
  /// In en, this message translates to:
  /// **'Hidden secrets & things you never told anyone'**
  String get catDescConfessions;

  /// No description provided for @catDescRisk.
  ///
  /// In en, this message translates to:
  /// **'Dares, adrenaline & risky decisions'**
  String get catDescRisk;

  /// No description provided for @catDescMoralGray.
  ///
  /// In en, this message translates to:
  /// **'Ethical dilemmas & morally questionable choices'**
  String get catDescMoralGray;

  /// No description provided for @catDescDeep.
  ///
  /// In en, this message translates to:
  /// **'Life, identity, fears & philosophical questions'**
  String get catDescDeep;

  /// No description provided for @catDescSexual.
  ///
  /// In en, this message translates to:
  /// **'Intimate & sexual experiences (18+)'**
  String get catDescSexual;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
