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
}
