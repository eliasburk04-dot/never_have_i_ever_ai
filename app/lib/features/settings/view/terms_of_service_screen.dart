import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
        title: Text(l10n.termsOfService,
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
      _heading('Terms of Service'),
      _body('Last updated: February 24, 2026'),
      _body(
        'By downloading, installing, or using EXPOSED – Party Game ("EXPOSED", "the App"), '
        'you agree to these Terms of Service. If you do not agree, do not use the App.',
      ),
      _section('1. Eligibility'),
      _body(
        'EXPOSED is rated 18+. By using the App, you confirm that you are at least 18 years old. '
        'The NSFW mode contains explicit content intended exclusively for adults.',
      ),
      _section('2. License'),
      _body(
        'We grant you a limited, non-exclusive, non-transferable, revocable license to use the App '
        'for personal, non-commercial purposes, subject to these Terms.',
      ),
      _section('3. In-App Purchases'),
      _body(
        '• EXPOSED offers a one-time, non-consumable Premium purchase ("EXPOSED Premium – Lifetime").\n'
        '• This purchase unlocks all premium features permanently.\n'
        '• All payments are processed by Apple or Google. We do not handle payment information.\n'
        '• Refund requests must be directed to Apple or Google per their respective refund policies.\n'
        '• You can restore your purchase on any device using the "Restore Purchases" feature.',
      ),
      _section('4. User Conduct'),
      _body(
        'When using online multiplayer features, you agree to:\n\n'
        '• Not use offensive, discriminatory, or harassing display names.\n'
        '• Not attempt to exploit, hack, or disrupt the game server.\n'
        '• Not use the App for any illegal purpose.\n'
        '• Respect other players during gameplay.',
      ),
      _section('5. Content'),
      _body(
        '• EXPOSED contains pre-written questions across various intensity levels.\n'
        '• NSFW content (18+) is optional and must be explicitly enabled.\n'
        '• Drinking Game Mode is optional and intended for legal drinking age users only.\n'
        '• We are not responsible for how players choose to answer or act upon questions.',
      ),
      _section('6. Disclaimer'),
      _body(
        'The App is provided "as is" without warranties of any kind. We do not guarantee '
        'uninterrupted or error-free operation. Online features depend on server availability '
        'and internet connectivity.',
      ),
      _section('7. Limitation of Liability'),
      _body(
        'To the maximum extent permitted by applicable law, we shall not be liable for any indirect, '
        'incidental, special, or consequential damages arising from the use of the App, '
        'including but not limited to damages from gameplay decisions, social interactions, '
        'or consumption of alcohol during Drinking Game Mode.',
      ),
      _section('8. Intellectual Property'),
      _body(
        'All content, design, code, and branding of EXPOSED are the property of Elias Burk. '
        'You may not copy, modify, distribute, or create derivative works without prior written permission.',
      ),
      _section('9. Termination'),
      _body(
        'We reserve the right to terminate or restrict access to the App or its online features '
        'at any time, for any reason, without notice.',
      ),
      _section('10. Changes to These Terms'),
      _body(
        'We may update these Terms from time to time. Continued use of the App after changes '
        'constitutes acceptance of the updated Terms.',
      ),
      _section('11. Contact'),
      _body(
        'For questions about these Terms, contact us at:\n\n'
        'Elias Burk\n'
        'Email: eliasburk04@gmail.com\n',
      ),
      const SizedBox(height: AppSpacing.xl),
    ];
  }

  // ─── DEUTSCH ──────────────────────────────────────────

  List<Widget> _buildDe() {
    return [
      _heading('Nutzungsbedingungen'),
      _body('Stand: 24. Februar 2026'),
      _body(
        'Durch das Herunterladen, Installieren oder Nutzen von EXPOSED – Party Game '
        '(„EXPOSED", „die App") stimmst du diesen Nutzungsbedingungen zu. '
        'Wenn du nicht einverstanden bist, nutze die App nicht.',
      ),
      _section('1. Nutzungsvoraussetzungen'),
      _body(
        'EXPOSED ist mit 18+ eingestuft. Durch die Nutzung bestätigst du, dass du mindestens 18 Jahre alt bist. '
        'Der NSFW-Modus enthält explizite Inhalte, die ausschließlich für Erwachsene bestimmt sind.',
      ),
      _section('2. Lizenz'),
      _body(
        'Wir gewähren dir eine eingeschränkte, nicht-exklusive, nicht übertragbare, widerrufliche Lizenz '
        'zur Nutzung der App für persönliche, nicht-kommerzielle Zwecke gemäß diesen Bedingungen.',
      ),
      _section('3. In-App-Käufe'),
      _body(
        '• EXPOSED bietet einen einmaligen, nicht-verbrauchbaren Premium-Kauf („EXPOSED Premium – Lifetime").\n'
        '• Dieser Kauf schaltet alle Premium-Funktionen dauerhaft frei.\n'
        '• Alle Zahlungen werden über Apple oder Google abgewickelt. Wir verarbeiten keine Zahlungsinformationen.\n'
        '• Erstattungsanfragen sind gemäß den jeweiligen Richtlinien an Apple oder Google zu richten.\n'
        '• Du kannst deinen Kauf auf jedem Gerät über „Käufe wiederherstellen" wiederherstellen.',
      ),
      _section('4. Nutzerverhalten'),
      _body(
        'Bei der Nutzung der Online-Multiplayer-Funktionen verpflichtest du dich:\n\n'
        '• Keine beleidigenden, diskriminierenden oder belästigenden Anzeigenamen zu verwenden.\n'
        '• Nicht zu versuchen, den Spielserver auszunutzen, zu hacken oder zu stören.\n'
        '• Die App nicht für illegale Zwecke zu nutzen.\n'
        '• Andere Spieler während des Spiels zu respektieren.',
      ),
      _section('5. Inhalte'),
      _body(
        '• EXPOSED enthält vorgeschriebene Fragen in verschiedenen Intensitätsstufen.\n'
        '• NSFW-Inhalte (18+) sind optional und müssen explizit aktiviert werden.\n'
        '• Der Trinkspiel-Modus ist optional und nur für Nutzer im gesetzlichen Trinkalter bestimmt.\n'
        '• Wir sind nicht verantwortlich dafür, wie Spieler auf Fragen antworten oder handeln.',
      ),
      _section('6. Haftungsausschluss'),
      _body(
        'Die App wird „wie besehen" ohne jegliche Garantien bereitgestellt. Wir garantieren keinen '
        'unterbrechungs- oder fehlerfreien Betrieb. Online-Funktionen sind abhängig von der '
        'Serververfügbarkeit und Internetverbindung.',
      ),
      _section('7. Haftungsbeschränkung'),
      _body(
        'Im gesetzlich zulässigen Rahmen haften wir nicht für indirekte, zufällige, besondere oder '
        'Folgeschäden, die aus der Nutzung der App entstehen, einschließlich, aber nicht beschränkt auf '
        'Schäden durch Spielentscheidungen, soziale Interaktionen oder Alkoholkonsum im Trinkspiel-Modus.',
      ),
      _section('8. Geistiges Eigentum'),
      _body(
        'Alle Inhalte, das Design, der Code und das Branding von EXPOSED sind Eigentum von Elias Burk. '
        'Ohne vorherige schriftliche Genehmigung darfst du nichts kopieren, ändern, verbreiten oder '
        'abgeleitete Werke erstellen.',
      ),
      _section('9. Kündigung'),
      _body(
        'Wir behalten uns das Recht vor, den Zugang zur App oder ihren Online-Funktionen jederzeit, '
        'aus jedem Grund und ohne Vorankündigung einzuschränken oder zu beenden.',
      ),
      _section('10. Änderungen dieser Bedingungen'),
      _body(
        'Wir können diese Bedingungen von Zeit zu Zeit aktualisieren. Die fortgesetzte Nutzung der App '
        'nach Änderungen gilt als Zustimmung zu den aktualisierten Bedingungen.',
      ),
      _section('11. Kontakt'),
      _body(
        'Bei Fragen zu diesen Nutzungsbedingungen kontaktiere uns unter:\n\n'
        'Elias Burk\n'
        'E-Mail: eliasburk04@gmail.com\n',
      ),
      const SizedBox(height: AppSpacing.xl),
    ];
  }

  // ─── ESPAÑOL ──────────────────────────────────────────

  List<Widget> _buildEs() {
    return [
      _heading('Términos de Servicio'),
      _body('Última actualización: 24 de febrero de 2026'),
      _body(
        'Al descargar, instalar o usar EXPOSED – Party Game ("EXPOSED", "la App"), '
        'aceptas estos Términos de Servicio. Si no estás de acuerdo, no uses la App.',
      ),
      _section('1. Elegibilidad'),
      _body(
        'EXPOSED está clasificado para mayores de 18 años. Al usar la App, confirmas que tienes al menos 18 años. '
        'El modo NSFW contiene contenido explícito destinado exclusivamente a adultos.',
      ),
      _section('2. Licencia'),
      _body(
        'Te concedemos una licencia limitada, no exclusiva, intransferible y revocable para usar la App '
        'con fines personales y no comerciales, sujeta a estos Términos.',
      ),
      _section('3. Compras dentro de la app'),
      _body(
        '• EXPOSED ofrece una compra Premium única y permanente ("EXPOSED Premium – Lifetime").\n'
        '• Esta compra desbloquea todas las funciones premium de forma permanente.\n'
        '• Todos los pagos son procesados por Apple o Google. No manejamos información de pago.\n'
        '• Las solicitudes de reembolso deben dirigirse a Apple o Google según sus políticas.\n'
        '• Puedes restaurar tu compra en cualquier dispositivo usando "Restaurar compras".',
      ),
      _section('4. Conducta del usuario'),
      _body(
        'Al usar las funciones multijugador en línea, aceptas:\n\n'
        '• No usar nombres ofensivos, discriminatorios o acosadores.\n'
        '• No intentar explotar, hackear o interrumpir el servidor del juego.\n'
        '• No usar la App con fines ilegales.\n'
        '• Respetar a los demás jugadores durante el juego.',
      ),
      _section('5. Contenido'),
      _body(
        '• EXPOSED contiene preguntas predefinidas en varios niveles de intensidad.\n'
        '• El contenido NSFW (18+) es opcional y debe activarse explícitamente.\n'
        '• El Modo Trago es opcional y está destinado solo a usuarios en edad legal para beber.\n'
        '• No somos responsables de cómo los jugadores responden o actúan ante las preguntas.',
      ),
      _section('6. Descargo de responsabilidad'),
      _body(
        'La App se proporciona "tal cual" sin garantías de ningún tipo. No garantizamos un '
        'funcionamiento ininterrumpido o libre de errores. Las funciones en línea dependen de la '
        'disponibilidad del servidor y la conectividad a internet.',
      ),
      _section('7. Limitación de responsabilidad'),
      _body(
        'En la máxima medida permitida por la ley, no seremos responsables de daños indirectos, '
        'incidentales, especiales o consecuentes derivados del uso de la App, incluyendo, '
        'entre otros, daños por decisiones de juego, interacciones sociales o consumo de alcohol '
        'durante el Modo Trago.',
      ),
      _section('8. Propiedad intelectual'),
      _body(
        'Todo el contenido, diseño, código y marca de EXPOSED son propiedad de Elias Burk. '
        'No puedes copiar, modificar, distribuir ni crear obras derivadas sin permiso previo por escrito.',
      ),
      _section('9. Terminación'),
      _body(
        'Nos reservamos el derecho de terminar o restringir el acceso a la App o sus funciones en línea '
        'en cualquier momento, por cualquier motivo, sin previo aviso.',
      ),
      _section('10. Cambios en estos términos'),
      _body(
        'Podemos actualizar estos Términos periódicamente. El uso continuado de la App después de los cambios '
        'constituye la aceptación de los Términos actualizados.',
      ),
      _section('11. Contacto'),
      _body(
        'Para preguntas sobre estos Términos, contáctanos en:\n\n'
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
