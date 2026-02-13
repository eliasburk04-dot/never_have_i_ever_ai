class Player {
  const Player({
    required this.id,
    required this.name,
    this.isHost = false,
    this.isReady = false,
  });

  final String id;
  final String name;
  final bool isHost;
  final bool isReady;

  Player copyWith({
    String? id,
    String? name,
    bool? isHost,
    bool? isReady,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
    );
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      isHost: json['isHost'] as bool? ?? false,
      isReady: json['isReady'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isHost': isHost,
      'isReady': isReady,
    };
  }
}
