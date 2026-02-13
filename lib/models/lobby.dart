import 'player.dart';
import 'round.dart';

class Lobby {
  const Lobby({
    required this.id,
    required this.code,
    required this.createdAt,
    required this.players,
    required this.rounds,
  });

  final String id;
  final String code;
  final DateTime createdAt;
  final List<Player> players;
  final List<Round> rounds;

  factory Lobby.fromJson(Map<String, dynamic> json) {
    final playersJson = json['players'] as List<dynamic>? ?? const [];
    final roundsJson = json['rounds'] as List<dynamic>? ?? const [];

    return Lobby(
      id: json['id'] as String,
      code: json['code'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      players: playersJson
          .map((item) => Player.fromJson(item as Map<String, dynamic>))
          .toList(),
      rounds: roundsJson
          .map((item) => Round.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'createdAt': createdAt.toIso8601String(),
      'players': players.map((player) => player.toJson()).toList(),
      'rounds': rounds.map((round) => round.toJson()).toList(),
    };
  }
}
