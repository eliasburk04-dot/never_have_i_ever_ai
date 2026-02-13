enum StatementLanguage {
  en('en'),
  de('de'),
  es('es');

  const StatementLanguage(this.code);

  final String code;

  static StatementLanguage fromCode(String value) {
    for (final language in StatementLanguage.values) {
      if (language.code == value.toLowerCase()) {
        return language;
      }
    }
    throw ArgumentError.value(value, 'value', 'Unsupported language code.');
  }
}

enum StatementSource {
  local('local'),
  groqRewrite('groq_rewrite');

  const StatementSource(this.code);

  final String code;

  static StatementSource fromCode(String value) {
    for (final source in StatementSource.values) {
      if (source.code == value.toLowerCase()) {
        return source;
      }
    }
    throw ArgumentError.value(value, 'value', 'Unsupported statement source.');
  }
}

class Statement {
  const Statement({
    required this.id,
    required this.language,
    required this.riskLevel,
    required this.text,
    this.source = StatementSource.local,
    this.baseStatementId,
  });

  final String id;
  final StatementLanguage language;
  final int riskLevel;
  final String text;
  final StatementSource source;
  final String? baseStatementId;

  Statement copyWith({
    String? id,
    StatementLanguage? language,
    int? riskLevel,
    String? text,
    StatementSource? source,
    String? baseStatementId,
  }) {
    return Statement(
      id: id ?? this.id,
      language: language ?? this.language,
      riskLevel: riskLevel ?? this.riskLevel,
      text: text ?? this.text,
      source: source ?? this.source,
      baseStatementId: baseStatementId ?? this.baseStatementId,
    );
  }

  factory Statement.fromJson(Map<String, dynamic> json) {
    final rawLanguage = json['language'] as String? ?? 'en';
    final rawRisk = json['risk_level'] ?? json['riskLevel'] ?? json['difficulty'] ?? 1;
    final rawSource = json['source'] as String? ?? StatementSource.local.code;

    return Statement(
      id: json['id'] as String,
      language: StatementLanguage.fromCode(rawLanguage),
      riskLevel: rawRisk as int,
      text: json['text'] as String,
      source: StatementSource.fromCode(rawSource),
      baseStatementId: json['base_statement_id'] as String? ?? json['baseStatementId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language': language.code,
      'risk_level': riskLevel,
      'text': text,
      'source': source.code,
      'base_statement_id': baseStatementId,
    };
  }
}
