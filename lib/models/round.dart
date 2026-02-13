import 'answer.dart';
import 'statement.dart';

class Round {
  const Round({
    required this.id,
    required this.index,
    required this.statement,
    required this.answers,
  });

  final String id;
  final int index;
  final Statement statement;
  final List<Answer> answers;

  factory Round.fromJson(Map<String, dynamic> json) {
    final answersJson = json['answers'] as List<dynamic>? ?? const [];

    return Round(
      id: json['id'] as String,
      index: json['index'] as int? ?? 0,
      statement: Statement.fromJson(json['statement'] as Map<String, dynamic>),
      answers: answersJson
          .map((item) => Answer.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'index': index,
      'statement': statement.toJson(),
      'answers': answers.map((answer) => answer.toJson()).toList(),
    };
  }
}
