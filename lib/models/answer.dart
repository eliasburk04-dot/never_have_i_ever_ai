class Answer {
  const Answer({
    required this.id,
    required this.playerId,
    required this.text,
    required this.isTruth,
  });

  final String id;
  final String playerId;
  final String text;
  final bool isTruth;

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'] as String,
      playerId: json['playerId'] as String,
      text: json['text'] as String,
      isTruth: json['isTruth'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerId': playerId,
      'text': text,
      'isTruth': isTruth,
    };
  }
}
