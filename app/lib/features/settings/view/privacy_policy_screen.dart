import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(l10n.privacyPolicy,
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildContent(locale),
        ),
      ),
    );
  }

  List<Widget> _buildContent(String locale) {
    switch (locale) {
      case 'de':
        return _buildDe();
      case 'es':
        return _buildEs();
      default:
        return _buildEn();
    }
  }

  // ─── ENGLISH ──────────────────────────────────────────

  List<Widget> _buildEn() {
    return [
      _heading('Privacy Policy'),
      _body('Last updated: February 24, 2026'),
      _body(
        'EXPOSED – Party Game ("EXPOSED", "we", "us", or "our") is developed and operated by Elias Burk. '
        'We take your privacy seriously. This Privacy Policy explains what information we collect, '
        'how we use it, and your rights regarding your data.',
      ),
      _section('1. Information We Collect'),
      _subsection('1.1 Information You Provide'),
      _body(
        '• Display Name: When playing online, you enter a display name for the lobby. '
        'This name is only used during the game session and is not stored permanently.\n'
        '• No Account Required: EXPOSED does not require you to create an account, '
        'provide an email address, phone number, or any other personal information.',
      ),
      _subsection('1.2 Information Collected Automatically'),
      _body(
        '• Device Information: We do not collect device identifiers, IP addresses, or hardware information.\n'
        '• Analytics: EXPOSED does not use any third-party analytics or tracking services '
        '(no Google Analytics, Firebase Analytics, Facebook SDK, or similar).\n'
        '• Crash Reports: We do not collect crash reports or diagnostic data.\n'
        '• Cookies: EXPOSED does not use cookies or similar tracking technologies.',
      ),
      _subsection('1.3 In-App Purchases'),
      _body(
        'Premium purchases are processed entirely by Apple (App Store) or Google (Google Play). '
        'We do not receive or store any payment information such as credit card numbers, '
        'billing addresses, or Apple/Google account details. '
        'Purchase status is stored locally on your device only.',
      ),
      _section('2. How We Use Information'),
      _body(
        '• Online Multiplayer: When you join an online lobby, your display name and game responses '
        'are transmitted to our game server to enable real-time multiplayer gameplay. '
        'This data exists only for the duration of the game session and is deleted when the lobby closes.\n'
        '• Offline Mode: All offline game data is stored exclusively on your device and never leaves it.\n'
        '• Premium Status: Your premium purchase status is stored locally on your device using SharedPreferences.',
      ),
      _section('3. Data Storage & Servers'),
      _body(
        '• Online game sessions are processed on our self-hosted game server.\n'
        '• No personal data is stored permanently on our servers.\n'
        '• Game lobby data (display names, responses) is held in memory only during active sessions '
        'and is automatically deleted when the lobby ends.\n'
        '• We do not maintain user databases, profiles, or persistent records of gameplay.',
      ),
      _section('4. Data Sharing'),
      _body(
        'We do not sell, trade, rent, or share your personal information with any third parties. '
        'Specifically:\n\n'
        '• No advertising networks\n'
        '• No analytics providers\n'
        '• No social media platforms\n'
        '• No data brokers\n'
        '• No other third-party services\n\n'
        'The only data transmitted externally is game session data to our own game server during online play.',
      ),
      _section('5. Children\'s Privacy'),
      _body(
        'EXPOSED is rated 18+ and contains optional NSFW content for adults. '
        'We do not knowingly collect personal information from children under 18. '
        'The NSFW mode is disabled by default and must be explicitly enabled. '
        'If you believe a child has provided personal information through our app, '
        'please contact us so we can take appropriate action.',
      ),
      _section('6. Your Rights'),
      _body(
        'Since we do not collect or store personal data, there is generally no personal data to access, '
        'correct, or delete. However, you have the right to:\n\n'
        '• Delete local app data: Uninstall the app or clear app data in your device settings.\n'
        '• Restore purchases: Use the "Restore Purchases" feature in the app\'s Premium section.\n'
        '• Contact us: Reach out with any privacy-related questions or concerns.',
      ),
      _section('7. Data Security'),
      _body(
        'We implement appropriate technical measures to protect any data transmitted during online gameplay:\n\n'
        '• All network communication uses HTTPS/TLS encryption.\n'
        '• Online game sessions use secure WebSocket connections.\n'
        '• No sensitive personal data is transmitted or stored.',
      ),
      _section('8. Changes to This Policy'),
      _body(
        'We may update this Privacy Policy from time to time. Any changes will be reflected in the app '
        'with an updated "Last updated" date. We encourage you to review this policy periodically.',
      ),
      _section('9. Contact Us'),
      _body(
        'If you have any questions, concerns, or requests regarding this Privacy Policy or your data, '
        'please contact us at:\n\n'
        'Elias Burk\n'
        'Email: eliasburk04@gmail.com\n',
      ),
      const SizedBox(height: AppSpacing.xl),
    ];
  }

  // ─── DEUTSCH ──────────────────────────────────────────

  List<Widget> _buildDe() {
    return [
      _heading('Datenschutzerklärung'),
      _body('Stand: 24. Februar 2026'),
      _body(
        'EXPOSED – Party Game („EXPOSED", „wir", „uns") wird von Elias Burk entwickelt und betrieben. '
        'Wir nehmen den Schutz deiner Daten sehr ernst. Diese Datenschutzerklärung erläutert, welche Daten '
        'wir erheben, wie wir sie verwenden und welche Rechte du hast.',
      ),
      _section('1. Welche Daten wir erheben'),
      _subsection('1.1 Von dir bereitgestellte Daten'),
      _body(
        '• Anzeigename: Beim Online-Spielen gibst du einen Anzeigenamen für die Lobby ein. '
        'Dieser wird nur während der Spielsitzung verwendet und nicht dauerhaft gespeichert.\n'
        '• Kein Konto erforderlich: EXPOSED erfordert keine Registrierung, keine E-Mail-Adresse, '
        'Telefonnummer oder sonstige persönliche Daten.',
      ),
      _subsection('1.2 Automatisch erhobene Daten'),
      _body(
        '• Geräteinformationen: Wir erheben keine Gerätekennungen, IP-Adressen oder Hardware-Informationen.\n'
        '• Analyse-Tools: EXPOSED verwendet keinerlei Drittanbieter-Analyse- oder Tracking-Dienste '
        '(kein Google Analytics, Firebase Analytics, Facebook SDK o. Ä.).\n'
        '• Absturzberichte: Wir erheben keine Absturzberichte oder Diagnosedaten.\n'
        '• Cookies: EXPOSED verwendet keine Cookies oder ähnliche Tracking-Technologien.',
      ),
      _subsection('1.3 In-App-Käufe'),
      _body(
        'Premium-Käufe werden vollständig über Apple (App Store) bzw. Google (Google Play) abgewickelt. '
        'Wir erhalten und speichern keinerlei Zahlungsinformationen wie Kreditkartendaten, '
        'Rechnungsadressen oder Apple-/Google-Kontodaten. '
        'Der Kaufstatus wird ausschließlich lokal auf deinem Gerät gespeichert.',
      ),
      _section('2. Wie wir Daten verwenden'),
      _body(
        '• Online-Multiplayer: Wenn du einer Online-Lobby beitrittst, werden dein Anzeigename und '
        'deine Spielantworten an unseren Spielserver übertragen, um Echtzeit-Multiplayer zu ermöglichen. '
        'Diese Daten existieren nur für die Dauer der Spielsitzung und werden beim Schließen der Lobby gelöscht.\n'
        '• Offline-Modus: Alle Offline-Spieldaten werden ausschließlich auf deinem Gerät gespeichert '
        'und verlassen es niemals.\n'
        '• Premium-Status: Dein Premium-Kaufstatus wird lokal auf deinem Gerät mittels SharedPreferences gespeichert.',
      ),
      _section('3. Datenspeicherung & Server'),
      _body(
        '• Online-Spielsitzungen werden auf unserem selbst gehosteten Spielserver verarbeitet.\n'
        '• Es werden keine personenbezogenen Daten dauerhaft auf unseren Servern gespeichert.\n'
        '• Lobby-Daten (Anzeigenamen, Antworten) werden nur während aktiver Sitzungen im Arbeitsspeicher gehalten '
        'und beim Ende der Lobby automatisch gelöscht.\n'
        '• Wir führen keine Nutzerdatenbanken, Profile oder dauerhafte Spielverlaufs-Aufzeichnungen.',
      ),
      _section('4. Datenweitergabe'),
      _body(
        'Wir verkaufen, handeln, vermieten oder teilen deine Daten nicht mit Dritten. '
        'Im Einzelnen:\n\n'
        '• Keine Werbenetzwerke\n'
        '• Keine Analyse-Anbieter\n'
        '• Keine Social-Media-Plattformen\n'
        '• Keine Datenhändler\n'
        '• Keine sonstigen Drittanbieter-Dienste\n\n'
        'Die einzigen extern übertragenen Daten sind Spielsitzungsdaten an unseren eigenen Server '
        'während des Online-Spiels.',
      ),
      _section('5. Jugendschutz'),
      _body(
        'EXPOSED ist mit 18+ eingestuft und enthält optionale NSFW-Inhalte für Erwachsene. '
        'Wir erheben wissentlich keine personenbezogenen Daten von Kindern unter 18 Jahren. '
        'Der NSFW-Modus ist standardmäßig deaktiviert und muss explizit aktiviert werden. '
        'Falls du glaubst, dass ein Kind über unsere App personenbezogene Daten bereitgestellt hat, '
        'kontaktiere uns bitte, damit wir entsprechende Maßnahmen ergreifen können.',
      ),
      _section('6. Deine Rechte'),
      _body(
        'Da wir keine personenbezogenen Daten erheben oder speichern, gibt es in der Regel keine Daten, '
        'auf die zugegriffen, die korrigiert oder gelöscht werden müssten. Du hast dennoch das Recht:\n\n'
        '• Lokale App-Daten zu löschen: Deinstalliere die App oder lösche die App-Daten in den Geräteeinstellungen.\n'
        '• Käufe wiederherzustellen: Nutze die Funktion „Käufe wiederherstellen" im Premium-Bereich.\n'
        '• Uns zu kontaktieren: Bei datenschutzbezogenen Fragen oder Anliegen.',
      ),
      _section('7. Datensicherheit'),
      _body(
        'Wir setzen angemessene technische Maßnahmen ein, um während des Online-Spiels übertragene Daten zu schützen:\n\n'
        '• Sämtliche Netzwerkkommunikation erfolgt über HTTPS/TLS-Verschlüsselung.\n'
        '• Online-Spielsitzungen verwenden sichere WebSocket-Verbindungen.\n'
        '• Es werden keine sensiblen personenbezogenen Daten übertragen oder gespeichert.',
      ),
      _section('8. Änderungen dieser Erklärung'),
      _body(
        'Wir können diese Datenschutzerklärung von Zeit zu Zeit aktualisieren. Änderungen werden in der App '
        'mit aktualisiertem Datum angezeigt. Wir empfehlen, diese Erklärung regelmäßig zu überprüfen.',
      ),
      _section('9. Kontakt'),
      _body(
        'Bei Fragen, Anliegen oder Anfragen zu dieser Datenschutzerklärung oder deinen Daten '
        'wende dich bitte an:\n\n'
        'Elias Burk\n'
        'E-Mail: eliasburk04@gmail.com\n',
      ),
      const SizedBox(height: AppSpacing.xl),
    ];
  }

  // ─── ESPAÑOL ──────────────────────────────────────────

  List<Widget> _buildEs() {
    return [
      _heading('Política de Privacidad'),
      _body('Última actualización: 24 de febrero de 2026'),
      _body(
        'EXPOSED – Party Game ("EXPOSED", "nosotros") es desarrollado y operado por Elias Burk. '
        'Nos tomamos tu privacidad muy en serio. Esta Política de Privacidad explica qué datos '
        'recopilamos, cómo los usamos y cuáles son tus derechos.',
      ),
      _section('1. Datos que recopilamos'),
      _subsection('1.1 Datos que proporcionas'),
      _body(
        '• Nombre de usuario: Al jugar en línea, ingresas un nombre para la sala. '
        'Este nombre solo se usa durante la sesión y no se almacena de forma permanente.\n'
        '• Sin cuenta requerida: EXPOSED no requiere registro, correo electrónico, '
        'número de teléfono ni ningún otro dato personal.',
      ),
      _subsection('1.2 Datos recopilados automáticamente'),
      _body(
        '• Información del dispositivo: No recopilamos identificadores de dispositivo, direcciones IP ni información de hardware.\n'
        '• Análisis: EXPOSED no utiliza servicios de análisis o rastreo de terceros '
        '(ni Google Analytics, Firebase Analytics, Facebook SDK, ni similares).\n'
        '• Informes de fallos: No recopilamos informes de fallos ni datos de diagnóstico.\n'
        '• Cookies: EXPOSED no utiliza cookies ni tecnologías de rastreo similares.',
      ),
      _subsection('1.3 Compras dentro de la app'),
      _body(
        'Las compras Premium se procesan íntegramente a través de Apple (App Store) o Google (Google Play). '
        'No recibimos ni almacenamos información de pago como números de tarjetas, '
        'direcciones de facturación o datos de cuenta de Apple/Google. '
        'El estado de compra se almacena solo localmente en tu dispositivo.',
      ),
      _section('2. Cómo usamos los datos'),
      _body(
        '• Multijugador en línea: Al unirte a una sala, tu nombre y respuestas se transmiten '
        'a nuestro servidor para habilitar el juego en tiempo real. '
        'Estos datos solo existen durante la sesión y se eliminan al cerrar la sala.\n'
        '• Modo offline: Todos los datos del juego offline se almacenan exclusivamente en tu dispositivo.\n'
        '• Estado Premium: Tu estado de compra se almacena localmente en tu dispositivo.',
      ),
      _section('3. Almacenamiento y servidores'),
      _body(
        '• Las sesiones en línea se procesan en nuestro servidor autogestionado.\n'
        '• No se almacenan datos personales de forma permanente en nuestros servidores.\n'
        '• Los datos de la sala (nombres, respuestas) se mantienen en memoria solo durante las sesiones activas '
        'y se eliminan automáticamente al finalizar.\n'
        '• No mantenemos bases de datos de usuarios, perfiles ni registros permanentes.',
      ),
      _section('4. Compartición de datos'),
      _body(
        'No vendemos, intercambiamos, alquilamos ni compartimos tus datos con terceros. '
        'En concreto:\n\n'
        '• Sin redes publicitarias\n'
        '• Sin proveedores de análisis\n'
        '• Sin plataformas de redes sociales\n'
        '• Sin intermediarios de datos\n'
        '• Sin otros servicios de terceros\n\n'
        'Los únicos datos transmitidos externamente son los datos de sesión a nuestro propio servidor.',
      ),
      _section('5. Privacidad de menores'),
      _body(
        'EXPOSED está clasificado para mayores de 18 años y contiene contenido NSFW opcional para adultos. '
        'No recopilamos deliberadamente datos de menores de 18 años. '
        'El modo NSFW está desactivado por defecto y debe activarse explícitamente. '
        'Si crees que un menor ha proporcionado datos personales a través de nuestra app, '
        'por favor contáctanos para que podamos tomar las medidas adecuadas.',
      ),
      _section('6. Tus derechos'),
      _body(
        'Como no recopilamos ni almacenamos datos personales, generalmente no hay datos que consultar, '
        'corregir o eliminar. Sin embargo, tienes derecho a:\n\n'
        '• Eliminar datos locales: Desinstala la app o borra los datos en la configuración del dispositivo.\n'
        '• Restaurar compras: Usa la función "Restaurar compras" en la sección Premium.\n'
        '• Contactarnos: Para cualquier consulta relacionada con la privacidad.',
      ),
      _section('7. Seguridad de los datos'),
      _body(
        'Implementamos medidas técnicas adecuadas para proteger los datos transmitidos durante el juego en línea:\n\n'
        '• Toda la comunicación de red utiliza cifrado HTTPS/TLS.\n'
        '• Las sesiones en línea usan conexiones WebSocket seguras.\n'
        '• No se transmiten ni almacenan datos personales sensibles.',
      ),
      _section('8. Cambios en esta política'),
      _body(
        'Podemos actualizar esta Política de Privacidad periódicamente. Los cambios se reflejarán en la app '
        'con una fecha actualizada. Te recomendamos revisarla regularmente.',
      ),
      _section('9. Contacto'),
      _body(
        'Si tienes preguntas, inquietudes o solicitudes sobre esta Política de Privacidad o tus datos, '
        'contáctanos en:\n\n'
        'Elias Burk\n'
        'Email: eliasburk04@gmail.com\n',
      ),
      const SizedBox(height: AppSpacing.xl),
    ];
  }

  // ─── Helpers ──────────────────────────────────────────

  static Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(text,
          style: AppTypography.display.copyWith(
            fontSize: 22,
            color: AppColors.textPrimary,
          )),
    );
  }

  static Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Text(text,
          style: AppTypography.h3.copyWith(
            fontSize: 17,
            color: AppColors.textPrimary,
          )),
    );
  }

  static Widget _subsection(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      child: Text(text,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          )),
    );
  }

  static Widget _body(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text,
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          )),
    );
  }
}
