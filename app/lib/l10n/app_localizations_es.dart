// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Yo Nunca Nunca';

  @override
  String get iHave => 'Yo Sí';

  @override
  String get iHaveNot => 'Yo No';

  @override
  String get createLobby => 'Crear sala';

  @override
  String get joinLobby => 'Unirse a sala';

  @override
  String get enterCode => 'Ingresa el código';

  @override
  String get waitingForPlayers => 'Esperando jugadores...';

  @override
  String roundOf(int current, int total) {
    return 'Ronda $current de $total';
  }

  @override
  String playersInLobby(int count) {
    return '$count jugadores';
  }

  @override
  String get startGame => 'Iniciar juego';

  @override
  String get nsfwMode => 'Modo Picante 🌶️';

  @override
  String get premium => 'Obtener Premium';

  @override
  String get premiumUnlock => 'Desbloquear por \$4.99';

  @override
  String get premiumLifetime => 'Compra única';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get displayName => 'Nombre';

  @override
  String get avatar => 'Avatar';

  @override
  String get gameOver => '¡Fin del juego!';

  @override
  String get groupProfile => 'Perfil del grupo';

  @override
  String get conservative => 'Conservador 😇';

  @override
  String get adventurous => 'Aventurero 😏';

  @override
  String get wild => 'Salvaje 🔥';

  @override
  String get fearless => 'Sin miedo 💀';

  @override
  String get boldness => 'Audacia';

  @override
  String get roundsPlayed => 'Rondas jugadas';

  @override
  String get highestTone => 'Nivel más alto';

  @override
  String get playAgain => 'Jugar de nuevo';

  @override
  String get backToHome => 'Volver al inicio';

  @override
  String get lobbyCode => 'Código de sala';

  @override
  String get tapToCopy => 'Toca para copiar';

  @override
  String get copied => '¡Copiado!';

  @override
  String playerJoined(String name) {
    return '$name se unió';
  }

  @override
  String playerLeft(String name) {
    return '$name se fue';
  }

  @override
  String get reconnecting => 'Reconectando...';

  @override
  String get connectionLost => 'Conexión perdida';

  @override
  String get retry => 'Reintentar';

  @override
  String get leave => 'Salir';

  @override
  String get notEnoughPlayers => 'No hay suficientes jugadores';

  @override
  String get minPlayersRequired => 'Se necesitan al menos 2 jugadores';

  @override
  String get rounds => 'Rondas';

  @override
  String get safe => 'Seguro';

  @override
  String get deeper => 'Más profundo';

  @override
  String get secretive => 'Secreto';

  @override
  String get freaky => 'Atrevido';

  @override
  String get free => 'Gratis';

  @override
  String get premiumLabel => 'Premium';

  @override
  String get unlimitedAi => 'IA ilimitada';

  @override
  String get limitedAi => '10 preguntas IA/día';

  @override
  String get nsfwAccess => '🌶️ Modo Picante';

  @override
  String get maxRounds100 => 'Hasta 100 rondas';

  @override
  String get maxRounds50 => 'Hasta 50 rondas';

  @override
  String get about => 'Acerca de';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get termsOfService => 'Términos de servicio';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get timesUp => '¡Se acabó el tiempo!';

  @override
  String get waitingForAnswers => 'Esperando respuestas...';

  @override
  String get everyoneAnswered => '¡Todos respondieron!';

  @override
  String get mostHonest => 'Más honesto';

  @override
  String get mostSecretive => 'Más reservado';

  @override
  String get stats => 'Estadísticas';

  @override
  String get avgHaveRatio => 'Prom. \"Yo Sí\"';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get error => 'Error';

  @override
  String get ok => 'OK';
}
