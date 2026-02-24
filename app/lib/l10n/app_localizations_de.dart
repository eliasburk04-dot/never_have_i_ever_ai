// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'EXPOSED';

  @override
  String get iHave => 'Hab ich';

  @override
  String get iHaveNot => 'Hab ich nicht';

  @override
  String get createLobby => 'Lobby erstellen';

  @override
  String get joinLobby => 'Lobby beitreten';

  @override
  String get enterCode => 'Lobby-Code eingeben';

  @override
  String get waitingForPlayers => 'Warte auf Spieler...';

  @override
  String roundOf(int current, int total) {
    return 'Runde $current von $total';
  }

  @override
  String playersInLobby(int count) {
    return '$count Spieler';
  }

  @override
  String get startGame => 'Spiel starten';

  @override
  String get nsfwMode => 'NSFW Mode 🌶️';

  @override
  String get premium => 'Premium holen';

  @override
  String get premiumUnlock => 'Für 4,99 € freischalten';

  @override
  String get premiumLifetime => 'Einmaliger Kauf';

  @override
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get displayName => 'Anzeigename';

  @override
  String get avatar => 'Avatar';

  @override
  String get gameOver => 'Spiel vorbei!';

  @override
  String get groupProfile => 'Euer Gruppenprofil';

  @override
  String get conservative => 'Brav 😇';

  @override
  String get adventurous => 'Abenteuerlich 😏';

  @override
  String get wild => 'Wild 🔥';

  @override
  String get fearless => 'Furchtlos 💀';

  @override
  String get boldness => 'Mutigkeitswert';

  @override
  String get roundsPlayed => 'Gespielte Runden';

  @override
  String get highestTone => 'Höchstes Level';

  @override
  String get playAgain => 'Nochmal spielen';

  @override
  String get backToHome => 'Zurück zum Start';

  @override
  String get lobbyCode => 'Lobby-Code';

  @override
  String get tapToCopy => 'Tippen zum Kopieren';

  @override
  String get copied => 'Kopiert!';

  @override
  String playerJoined(String name) {
    return '$name ist beigetreten';
  }

  @override
  String playerLeft(String name) {
    return '$name hat verlassen';
  }

  @override
  String get reconnecting => 'Verbinde erneut...';

  @override
  String get connectionLost => 'Verbindung verloren';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get leave => 'Verlassen';

  @override
  String get notEnoughPlayers => 'Nicht genug Spieler';

  @override
  String get minPlayersRequired => 'Mindestens 2 Spieler erforderlich';

  @override
  String get rounds => 'Runden';

  @override
  String get safe => 'Safe';

  @override
  String get deeper => 'Deeper';

  @override
  String get secretive => 'Secretive';

  @override
  String get freaky => 'Freaky';

  @override
  String get free => 'Kostenlos';

  @override
  String get premiumLabel => 'Premium';

  @override
  String get unlimitedAi => 'Unbegrenzte KI';

  @override
  String get limitedAi => '10 KI-Fragen/Tag';

  @override
  String get nsfwAccess => '🌶️ NSFW Modus';

  @override
  String get maxRounds100 => 'Bis zu 100 Runden';

  @override
  String get maxRounds50 => 'Bis zu 50 Runden';

  @override
  String get about => 'Über';

  @override
  String get privacyPolicy => 'Datenschutz';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get selectLanguage => 'Sprache wählen';

  @override
  String get timesUp => 'Zeit abgelaufen!';

  @override
  String get waitingForAnswers => 'Warte auf Antworten...';

  @override
  String get everyoneAnswered => 'Alle haben geantwortet!';

  @override
  String get mostHonest => 'Am ehrlichsten';

  @override
  String get mostSecretive => 'Am verschwiegensten';

  @override
  String get stats => 'Statistiken';

  @override
  String get avgHaveRatio => 'Durchschn. \"Hab ich\"';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get error => 'Fehler';

  @override
  String get ok => 'OK';

  @override
  String get offlineMode => 'Offline Modus';

  @override
  String get players => 'SPIELER';

  @override
  String get addPlayer => 'Spieler hinzufügen';

  @override
  String playerHint(int index) {
    return 'Spieler $index';
  }

  @override
  String get allPlayersNeedName => 'Alle Spieler brauchen einen Namen!';

  @override
  String get playerNamesMustBeUnique => 'Spielernamen müssen einzigartig sein!';

  @override
  String get nsfwLabel => 'NSFW';

  @override
  String get howManySaidIHave => 'Wie viele haben \"Hab ich\" gesagt?';

  @override
  String outOfPlayers(int count) {
    return 'von $count Spielern';
  }

  @override
  String get next => 'Weiter';

  @override
  String get endGame => 'Spiel beenden';

  @override
  String get endGameTitle => 'Spiel beenden?';

  @override
  String get endGameBody =>
      'Dein Fortschritt wird gespeichert. Du kannst später weitermachen.';

  @override
  String get keepPlaying => 'Weiterspielen';

  @override
  String get neverHaveIEver => 'EXPOSED';

  @override
  String get recycled => '🔄 Wiederholt';

  @override
  String get aiGenerated => '✨ KI';

  @override
  String roundsCount(int count) {
    return '$count Runden';
  }

  @override
  String playersCount(int count) {
    return '$count Spieler';
  }

  @override
  String get appSubtitle => 'Das Partyspiel';

  @override
  String get playOffline => 'Offline spielen';

  @override
  String get resumeOfflineGame => 'Offline Spiel fortsetzen';

  @override
  String get noGameData => 'Keine Spieldaten';

  @override
  String get chooseYourLanguage => 'Wähle deine\nSprache';

  @override
  String get changeLanguageLater =>
      'Du kannst dies später in den Einstellungen ändern';

  @override
  String get account => 'KONTO';

  @override
  String get legal => 'RECHTLICHES';

  @override
  String get version => 'Version 1.0.0';

  @override
  String get drinkingGameMode => 'Trinkspiel Modus 🍺';

  @override
  String get premiumRules => 'Premium Regeln';

  @override
  String get playerCount => 'Spieleranzahl';

  @override
  String upToPlayers(int count) {
    return 'Bis zu $count';
  }

  @override
  String upToPlayersFree(int count) {
    return 'Bis zu $count (Kostenlos)';
  }

  @override
  String get yourName => 'DEIN NAME';

  @override
  String get enterDisplayName => 'Anzeigename eingeben';

  @override
  String get maxRoundsLabel => 'MAX RUNDEN';

  @override
  String get nsfwModeDesc => 'Ab 18 – explizite Fragen';

  @override
  String get waitingRoom => 'Warteraum';

  @override
  String get lobbyCodeLabel => 'LOBBY-CODE';

  @override
  String get tapToCopyCode => 'Tippen zum Kopieren';

  @override
  String get codeCopied => 'Code kopiert!';

  @override
  String needMinPlayers(int count) {
    return 'Mindestens $count Spieler zum Starten';
  }

  @override
  String get waitingForHost => 'Warte auf den Host…';

  @override
  String get gettingNextQuestion => 'Nächste Frage wird geladen…';

  @override
  String get nextQuestion => 'Nächste Frage';

  @override
  String get waitingForAnswers2 => 'Warte auf Antworten…';

  @override
  String get waitingForHostToContinue => 'Warte auf Host…';

  @override
  String get playersLabel => 'Spieler';

  @override
  String get you => 'du';

  @override
  String get disconnected => 'getrennt';

  @override
  String get waiting => 'wartet…';

  @override
  String get host => 'HOST';

  @override
  String get purchasePremium => 'Premium kaufen';

  @override
  String get lifetimeOneTime => 'Lebenslang · Einmalkauf';

  @override
  String get youArePremium => 'Du bist Premium';

  @override
  String get premiumEnjoy =>
      'Du hast Zugriff auf alle 1600+ Fragen,\nNSFW-Modus, Trinkspiel & mehr.';

  @override
  String get unlimitedOfflineRounds => 'Unbegrenzte Offline-Runden';

  @override
  String get upTo100Rounds => 'Bis zu 100 Runden pro Spiel';

  @override
  String get allCategories => '1600+ Fragen aus allen 10 Kategorien';

  @override
  String get premiumNsfwMode => 'NSFW-Modus 🌶️ – 160+ explizite Fragen';

  @override
  String get premiumDrinkingMode => 'Trinkspiel-Modus 🍺';

  @override
  String get premiumUpTo20Players => 'Bis zu 20 Spieler pro Lobby';

  @override
  String get categoriesLabel => 'KATEGORIEN';

  @override
  String get goPremium => 'Premium holen';

  @override
  String drinkSips(int count) {
    return 'Trink $count Schluck.';
  }

  @override
  String get catSocial => 'Soziales';

  @override
  String get catParty => 'Party';

  @override
  String get catFood => 'Essen';

  @override
  String get catEmbarrassing => 'Peinlich';

  @override
  String get catRelationships => 'Beziehungen';

  @override
  String get catConfessions => 'Geheimnisse';

  @override
  String get catRisk => 'Risiko';

  @override
  String get catMoralGray => 'Moralisch';

  @override
  String get catDeep => 'Deep';

  @override
  String get catSexual => 'Intim';

  @override
  String get about2 => 'ÜBER';

  @override
  String get doubleTapHint => 'Kategorie gedrückt halten für Details';

  @override
  String get catDescSocial =>
      'Freundschaften, Social Media & Alltagssituationen';

  @override
  String get catDescParty => 'Nachtleben, Feiern & wilde Momente';

  @override
  String get catDescFood => 'Essgewohnheiten, Koch-Fails & Food-Abenteuer';

  @override
  String get catDescEmbarrassing => 'Peinliche Momente & Cringe-Geschichten';

  @override
  String get catDescRelationships => 'Liebe, Dating, Herzschmerz & Romantik';

  @override
  String get catDescConfessions =>
      'Verborgene Geheimnisse & ungesagte Wahrheiten';

  @override
  String get catDescRisk => 'Mutproben, Adrenalin & riskante Entscheidungen';

  @override
  String get catDescMoralGray =>
      'Ethische Dilemmas & moralisch fragwürdige Entscheidungen';

  @override
  String get catDescDeep => 'Leben, Identität, Ängste & philosophische Fragen';

  @override
  String get catDescSexual => 'Intime & sexuelle Erfahrungen (18+)';
}
