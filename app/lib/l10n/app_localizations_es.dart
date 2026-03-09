// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'EXPOSED';

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
  String get nsfwMode => 'NSFW Mode 🌶️';

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
  String get safe => 'Safe';

  @override
  String get deeper => 'Deeper';

  @override
  String get secretive => 'Secretive';

  @override
  String get freaky => 'Freaky';

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

  @override
  String get offlineMode => 'Modo sin conexión';

  @override
  String get players => 'JUGADORES';

  @override
  String get addPlayer => 'Agregar jugador';

  @override
  String playerHint(int index) {
    return 'Jugador $index';
  }

  @override
  String get allPlayersNeedName => '¡Todos los jugadores necesitan un nombre!';

  @override
  String get playerNamesMustBeUnique => '¡Los nombres deben ser únicos!';

  @override
  String get nsfwLabel => 'NSFW';

  @override
  String get howManySaidIHave => '¿Cuántos dijeron \"Yo sí\"?';

  @override
  String outOfPlayers(int count) {
    return 'de $count jugadores';
  }

  @override
  String get next => 'Siguiente';

  @override
  String get endGame => 'Terminar juego';

  @override
  String get endGameTitle => '¿Terminar juego?';

  @override
  String get endGameBody =>
      'Tu progreso se guardará. Puedes continuar después.';

  @override
  String get keepPlaying => 'Seguir jugando';

  @override
  String get neverHaveIEver => 'EXPOSED';

  @override
  String get recycled => '🔄 Repetida';

  @override
  String get aiGenerated => '✨ IA';

  @override
  String roundsCount(int count) {
    return '$count rondas';
  }

  @override
  String playersCount(int count) {
    return '$count jugadores';
  }

  @override
  String get appSubtitle => 'El juego social de conversación';

  @override
  String get playOffline => 'Jugar sin conexión';

  @override
  String get resumeOfflineGame => 'Continuar juego sin conexión';

  @override
  String get noGameData => 'Sin datos del juego';

  @override
  String get chooseYourLanguage => 'Elige tu\nidioma';

  @override
  String get changeLanguageLater => 'Puedes cambiarlo más tarde en ajustes';

  @override
  String get account => 'CUENTA';

  @override
  String get legal => 'LEGAL';

  @override
  String get version => 'Version 1.0.0';

  @override
  String get creatorPacksMode => 'Modo Creator Packs ✨';

  @override
  String get premiumRules => 'Reglas Premium';

  @override
  String get playerCount => 'Cantidad de jugadores';

  @override
  String upToPlayers(int count) {
    return 'Hasta $count';
  }

  @override
  String upToPlayersFree(int count) {
    return 'Hasta $count (Gratis)';
  }

  @override
  String get yourName => 'TU NOMBRE';

  @override
  String get enterDisplayName => 'Ingresa tu nombre';

  @override
  String get maxRoundsLabel => 'RONDAS MÁXIMAS';

  @override
  String get nsfwModeDesc => '+18 preguntas incluidas';

  @override
  String get waitingRoom => 'Sala de espera';

  @override
  String get lobbyCodeLabel => 'CÓDIGO DE SALA';

  @override
  String get tapToCopyCode => 'Toca para copiar';

  @override
  String get codeCopied => '¡Código copiado!';

  @override
  String needMinPlayers(int count) {
    return 'Se necesitan al menos $count jugadores para empezar';
  }

  @override
  String get waitingForHost => 'Esperando al anfitrión…';

  @override
  String get gettingNextQuestion => 'Cargando siguiente pregunta…';

  @override
  String get nextQuestion => 'Siguiente pregunta';

  @override
  String get waitingForAnswers2 => 'Esperando respuestas…';

  @override
  String get waitingForHostToContinue => 'Esperando al anfitrión…';

  @override
  String get playersLabel => 'Jugadores';

  @override
  String get you => 'tú';

  @override
  String get disconnected => 'desconectado';

  @override
  String get waiting => 'esperando…';

  @override
  String get host => 'ANFITRIÓN';

  @override
  String get purchasePremium => 'Comprar Premium';

  @override
  String get lifetimeOneTime => 'De por vida · Compra única';

  @override
  String get youArePremium => 'Eres Premium';

  @override
  String get premiumEnjoy =>
      'Tienes acceso a las 1600+ preguntas,\nModo NSFW, Creator Packs y más.';

  @override
  String get unlimitedOfflineRounds => 'Rondas sin conexión ilimitadas';

  @override
  String get upTo100Rounds => 'Hasta 100 rondas por juego';

  @override
  String get allCategories => '1600+ preguntas en las 10 categorías';

  @override
  String get premiumNsfwMode => 'Modo NSFW 🌶️ – 160+ preguntas explícitas';

  @override
  String get premiumCreatorPacks => 'Creator Packs ✨';

  @override
  String get premiumUpTo20Players => 'Hasta 20 jugadores por sala';

  @override
  String get categoriesLabel => 'CATEGORÍAS';

  @override
  String get goPremium => 'Obtener Premium';

  @override
  String packBonusPrompts(int count) {
    return 'Bonus de pack: agrega $count pregunta(s) personalizada(s).';
  }

  @override
  String get catSocial => 'Social';

  @override
  String get catParty => 'Fiesta';

  @override
  String get catFood => 'Comida';

  @override
  String get catEmbarrassing => 'Vergüenza';

  @override
  String get catRelationships => 'Relaciones';

  @override
  String get catConfessions => 'Confesiones';

  @override
  String get catRisk => 'Riesgo';

  @override
  String get catMoralGray => 'Dilema';

  @override
  String get catDeep => 'Profundo';

  @override
  String get catSexual => 'Íntimo';

  @override
  String get about2 => 'ACERCA DE';

  @override
  String get doubleTapHint =>
      'Mantén presionada una categoría para ver detalles';

  @override
  String get catDescSocial =>
      'Amistades, redes sociales e interacciones diarias';

  @override
  String get catDescParty => 'Vida nocturna, celebraciones y momentos salvajes';

  @override
  String get catDescFood =>
      'Hábitos alimenticios, fails cocinando y aventuras gastronómicas';

  @override
  String get catDescEmbarrassing => 'Momentos vergonzosos e historias cringe';

  @override
  String get catDescRelationships => 'Amor, citas, desamor y romance';

  @override
  String get catDescConfessions =>
      'Secretos ocultos y cosas que nunca contaste';

  @override
  String get catDescRisk => 'Retos, adrenalina y decisiones arriesgadas';

  @override
  String get catDescMoralGray =>
      'Dilemas éticos y decisiones moralmente cuestionables';

  @override
  String get catDescDeep => 'Vida, identidad, miedos y preguntas filosóficas';

  @override
  String get catDescSexual => 'Experiencias íntimas y sexuales (18+)';
}
