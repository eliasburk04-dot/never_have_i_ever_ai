import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/statement.dart';

final localDeckStatementProvider = Provider<LocalDeckStatementProvider>((ref) {
  return LocalDeckStatementProvider();
});

final groqRewriteStatementProvider = Provider<GroqRewriteStatementProvider>((ref) {
  return GroqRewriteStatementProvider(client: Supabase.instance.client);
});

class LocalDeckStatementProvider {
  LocalDeckStatementProvider({
    Map<StatementLanguage, Map<int, List<Statement>>>? deck,
    Random? random,
  })  : _deck = deck ?? StatementDeckRepository.defaultDeck(),
        _random = random ?? Random();

  final Map<StatementLanguage, Map<int, List<Statement>>> _deck;
  final Random _random;
  final Set<String> _usedStatementIds = <String>{};

  Statement nextStatement({
    required StatementLanguage language,
    required int riskLevel,
  }) {
    _validateRiskLevel(riskLevel);

    final levelDeck = _deck[language]?[riskLevel];
    if (levelDeck == null || levelDeck.isEmpty) {
      throw StateError('No local statements configured for ${language.code}/risk $riskLevel.');
    }

    final available = levelDeck.where((s) => !_usedStatementIds.contains(s.id)).toList(growable: false);
    if (available.isEmpty) {
      throw StateError(
        'No unused local statements left for ${language.code}/risk $riskLevel. Reset to reuse.',
      );
    }

    final selected = available[_random.nextInt(available.length)];
    _usedStatementIds.add(selected.id);

    return selected.copyWith(source: StatementSource.local, baseStatementId: selected.id);
  }

  int remainingFor({
    required StatementLanguage language,
    required int riskLevel,
  }) {
    _validateRiskLevel(riskLevel);

    final levelDeck = _deck[language]?[riskLevel] ?? const <Statement>[];
    return levelDeck.where((s) => !_usedStatementIds.contains(s.id)).length;
  }

  bool hasAvailable({
    required StatementLanguage language,
    required int riskLevel,
  }) {
    return remainingFor(language: language, riskLevel: riskLevel) > 0;
  }

  void markUsed(Statement statement) {
    _usedStatementIds.add(statement.id);
  }

  void reset({StatementLanguage? language, int? riskLevel}) {
    if (language == null && riskLevel == null) {
      _usedStatementIds.clear();
      return;
    }

    final idsToRemove = <String>{};
    for (final entry in _deck.entries) {
      final lang = entry.key;
      if (language != null && language != lang) {
        continue;
      }

      for (final riskEntry in entry.value.entries) {
        final level = riskEntry.key;
        if (riskLevel != null && level != riskLevel) {
          continue;
        }
        idsToRemove.addAll(riskEntry.value.map((s) => s.id));
      }
    }

    _usedStatementIds.removeAll(idsToRemove);
  }

  void _validateRiskLevel(int riskLevel) {
    if (riskLevel < 1 || riskLevel > 5) {
      throw ArgumentError.value(riskLevel, 'riskLevel', 'riskLevel must be between 1 and 5.');
    }
  }
}

class GroqRewriteStatementProvider {
  GroqRewriteStatementProvider({
    required SupabaseClient client,
    this.edgeFunctionName = 'rewrite-statement',
  }) : _client = client;

  final SupabaseClient _client;
  final String edgeFunctionName;
  final Set<String> _usedNormalizedTexts = <String>{};

  Future<Statement> nextStatement({
    required LocalDeckStatementProvider localProvider,
    required StatementLanguage language,
    required int riskLevel,
  }) async {
    final local = localProvider.nextStatement(language: language, riskLevel: riskLevel);
    return rewriteStatement(local);
  }

  Future<Statement> rewriteStatement(
    Statement localStatement, {
    int maxAttempts = 3,
  }) async {
    if (maxAttempts <= 0) {
      throw ArgumentError.value(maxAttempts, 'maxAttempts', 'maxAttempts must be > 0.');
    }

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final rewrittenText = await _invokeRewrite(localStatement);
      if (rewrittenText == null || rewrittenText.trim().isEmpty) {
        continue;
      }

      if (!_isFresh(rewrittenText)) {
        continue;
      }

      _remember(rewrittenText);
      return localStatement.copyWith(
        text: rewrittenText,
        source: StatementSource.groqRewrite,
        baseStatementId: localStatement.id,
      );
    }

    final fallback = localStatement.text;
    if (_isFresh(fallback)) {
      _remember(fallback);
      return localStatement.copyWith(
        source: StatementSource.local,
        baseStatementId: localStatement.id,
      );
    }

    throw StateError('Could not produce a fresh statement rewrite.');
  }

  void resetHistory() {
    _usedNormalizedTexts.clear();
  }

  Future<String?> _invokeRewrite(Statement statement) async {
    try {
      final response = await _client.functions.invoke(
        edgeFunctionName,
        body: {
          'statement': statement.text,
          'language': statement.language.code,
          'risk_level': statement.riskLevel,
          'instructions':
              'Rewrite the statement with a fresh tone. Keep risk unchanged and do not make it more extreme.',
          'avoid': _usedNormalizedTexts.toList(growable: false),
        },
      );

      final data = response.data;
      if (data is String) {
        return data.trim();
      }
      if (data is Map<String, dynamic>) {
        final value = data['text'] ?? data['statement'] ?? data['rewrite'];
        if (value is String) {
          return value.trim();
        }
      }
    } catch (_) {
      // Fallback handled by caller.
    }

    return null;
  }

  bool _isFresh(String text) {
    final normalized = _normalizeText(text);
    return normalized.isNotEmpty && !_usedNormalizedTexts.contains(normalized);
  }

  void _remember(String text) {
    _usedNormalizedTexts.add(_normalizeText(text));
  }

  String _normalizeText(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

abstract final class StatementDeckRepository {
  static Map<StatementLanguage, Map<int, List<Statement>>> defaultDeck() {
    final deck = <StatementLanguage, Map<int, List<Statement>>>{
      StatementLanguage.en: _buildDeckForLanguage(
        language: StatementLanguage.en,
        actions: _enActions,
        templatesByRisk: _enTemplatesByRisk,
      ),
      StatementLanguage.de: _buildDeckForLanguage(
        language: StatementLanguage.de,
        actions: _deActions,
        templatesByRisk: _deTemplatesByRisk,
      ),
      StatementLanguage.es: _buildDeckForLanguage(
        language: StatementLanguage.es,
        actions: _esActions,
        templatesByRisk: _esTemplatesByRisk,
      ),
    };

    _validateDeckShape(deck);
    return deck;
  }

  static Map<int, List<Statement>> _buildDeckForLanguage({
    required StatementLanguage language,
    required List<String> actions,
    required Map<int, String> templatesByRisk,
  }) {
    final levels = <int, List<Statement>>{};

    for (var risk = 1; risk <= 5; risk++) {
      final template = templatesByRisk[risk];
      if (template == null) {
        throw StateError('Missing template for risk $risk (${language.code}).');
      }

      final statements = <Statement>[];
      for (var index = 0; index < actions.length; index++) {
        final id = '${language.code}-r$risk-${index + 1}';
        final text = template.replaceFirst('{action}', actions[index]);

        statements.add(
          Statement(
            id: id,
            language: language,
            riskLevel: risk,
            text: text,
            source: StatementSource.local,
            baseStatementId: id,
          ),
        );
      }

      levels[risk] = List<Statement>.unmodifiable(statements);
    }

    return Map<int, List<Statement>>.unmodifiable(levels);
  }

  static void _validateDeckShape(Map<StatementLanguage, Map<int, List<Statement>>> deck) {
    for (final language in StatementLanguage.values) {
      final byRisk = deck[language];
      if (byRisk == null || byRisk.length != 5) {
        throw StateError('Deck must contain 5 risk levels for ${language.code}.');
      }

      for (var risk = 1; risk <= 5; risk++) {
        final rows = byRisk[risk];
        if (rows == null || rows.length != 20) {
          throw StateError('Deck must contain 20 statements for ${language.code}/risk $risk.');
        }
      }
    }
  }

  static const Map<int, String> _enTemplatesByRisk = <int, String>{
    1: 'Never have I ever {action}.',
    2: 'Never have I ever {action} and hoped nobody noticed.',
    3: 'Never have I ever {action} and then lied to avoid embarrassment.',
    4: 'Never have I ever {action} and let someone else take the blame.',
    5: 'Never have I ever {action} even though I knew it could seriously damage trust.',
  };

  static const Map<int, String> _deTemplatesByRisk = <int, String>{
    1: 'Ich habe noch nie {action}.',
    2: 'Ich habe noch nie {action} und gehofft, dass es niemand merkt.',
    3: 'Ich habe noch nie {action} und danach gelogen, um Peinlichkeit zu vermeiden.',
    4: 'Ich habe noch nie {action} und jemand anderen die Schuld tragen lassen.',
    5: 'Ich habe noch nie {action}, obwohl ich wusste, dass es Vertrauen ernsthaft verletzen kann.',
  };

  static const Map<int, String> _esTemplatesByRisk = <int, String>{
    1: 'Nunca he {action}.',
    2: 'Nunca he {action} y esperado que nadie lo notara.',
    3: 'Nunca he {action} y luego mentido para evitar verguenza.',
    4: 'Nunca he {action} y dejado que otra persona cargara con la culpa.',
    5: 'Nunca he {action} aunque sabia que podia danar seriamente la confianza.',
  };

  static const List<String> _enActions = <String>[
    'forgotten to answer a message for days',
    'pretended I had seen a movie I never watched',
    'arrived late and blamed traffic when it was my fault',
    'taken food from a roommate without asking',
    'laughed at a joke I did not understand',
    'copied homework from a friend',
    'left a group chat because of drama and quietly rejoined later',
    'looked at my phone during an important conversation',
    'said I was almost there while still at home',
    'canceled plans at the last minute for no real reason',
    'searched my own name online',
    'used someone else\'s streaming account without permission',
    're-gifted a present',
    'stayed silent when I should have apologized',
    'checked an ex profile more than once in one day',
    'snoozed an alarm so long that I missed something important',
    'taken credit for a team idea',
    'ignored a family call and said my battery died',
    'read a spoiler and still acted surprised',
    'hidden snacks so I would not have to share',
  ];

  static const List<String> _deActions = <String>[
    'tagelang nicht auf eine Nachricht geantwortet',
    'so getan, als haette ich einen Film gesehen, den ich nie geschaut habe',
    'mich verspaetet und den Verkehr beschuldigt, obwohl ich selbst schuld war',
    'Essen von Mitbewohnern genommen, ohne zu fragen',
    'ueber einen Witz gelacht, den ich nicht verstanden habe',
    'Hausaufgaben von einer Freundin oder einem Freund abgeschrieben',
    'einen Gruppenchat wegen Drama verlassen und spaeter heimlich wieder betreten',
    'waehrend eines wichtigen Gespraechs auf mein Handy geschaut',
    'gesagt, ich sei gleich da, waehrend ich noch zu Hause war',
    'Plaene in letzter Minute ohne guten Grund abgesagt',
    'meinen eigenen Namen online gesucht',
    'den Streaming Account von jemand anderem ohne Erlaubnis benutzt',
    'ein Geschenk weiter verschenkt',
    'geschwiegen, obwohl ich mich haette entschuldigen sollen',
    'das Profil einer Ex Person mehrmals an einem Tag gecheckt',
    'einen Wecker so oft verschoben, dass ich etwas Wichtiges verpasst habe',
    'die Anerkennung fuer eine Teamidee genommen',
    'einen Anruf aus der Familie ignoriert und gesagt, mein Akku sei leer',
    'einen Spoiler gelesen und trotzdem ueberrascht getan',
    'Snacks versteckt, damit ich nicht teilen muss',
  ];

  static const List<String> _esActions = <String>[
    'dejado un mensaje sin responder durante dias',
    'fingido que vi una pelicula que nunca vi',
    'llegado tarde y culpado al trafico cuando fue mi culpa',
    'tomado comida de un companero de piso sin pedir permiso',
    'reido de un chiste que no entendi',
    'copiado la tarea de una amistad',
    'salido de un chat grupal por drama y vuelto en silencio despues',
    'mirado el telefono durante una conversacion importante',
    'dicho que ya casi llegaba cuando aun estaba en casa',
    'cancelado planes a ultimo minuto sin una razon real',
    'buscado mi propio nombre en internet',
    'usado la cuenta de streaming de otra persona sin permiso',
    'regalado de nuevo un regalo que me dieron',
    'quedado en silencio cuando debi pedir perdon',
    'revisado el perfil de mi ex mas de una vez en un dia',
    'puesto la alarma en repeticion tanto que perdi algo importante',
    'quedado con el credito de una idea del equipo',
    'ignorado una llamada familiar y dicho que no tenia bateria',
    'leido un spoiler y aun asi actuado con sorpresa',
    'escondido snacks para no compartir',
  ];
}
