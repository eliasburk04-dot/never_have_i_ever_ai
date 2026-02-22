// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Ich hab noch nie';

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
  String get nsfwMode => 'Pikanter Modus 🌶️';

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
  String get safe => 'Harmlos';

  @override
  String get deeper => 'Tiefer';

  @override
  String get secretive => 'Geheimnisvoll';

  @override
  String get freaky => 'Gewagt';

  @override
  String get free => 'Kostenlos';

  @override
  String get premiumLabel => 'Premium';

  @override
  String get unlimitedAi => 'Unbegrenzte KI';

  @override
  String get limitedAi => '10 KI-Fragen/Tag';

  @override
  String get nsfwAccess => '🌶️ Pikanter Modus';

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
  String get neverHaveIEver => 'ICH HAB NOCH NIE';

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
}
