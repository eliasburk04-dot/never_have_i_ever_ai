import 'package:equatable/equatable.dart';

import 'lobby.dart';

/// Status of a game round.
enum RoundStatus { pending, active, completed }

/// Domain entity for a game round.
class GameRound extends Equatable {
  const GameRound({
    required this.id,
    required this.lobbyId,
    required this.roundNumber,
    required this.questionText,
    this.questionSourceId,
    required this.tone,
    required this.status,
    required this.totalPlayers,
    required this.haveCount,
    required this.haveNotCount,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String lobbyId;
  final int roundNumber;
  final String questionText;
  final String? questionSourceId;
  final ToneLevel tone;
  final RoundStatus status;
  final int totalPlayers;
  final int haveCount;
  final int haveNotCount;
  final DateTime? startedAt;
  final DateTime? completedAt;

  double get haveRatio =>
      totalPlayers > 0 ? haveCount / totalPlayers : 0.0;

  bool get isActive => status == RoundStatus.active;
  bool get isCompleted => status == RoundStatus.completed;

  GameRound copyWith({
    RoundStatus? status,
    int? haveCount,
    int? haveNotCount,
    int? totalPlayers,
  }) {
    return GameRound(
      id: id,
      lobbyId: lobbyId,
      roundNumber: roundNumber,
      questionText: questionText,
      questionSourceId: questionSourceId,
      tone: tone,
      status: status ?? this.status,
      totalPlayers: totalPlayers ?? this.totalPlayers,
      haveCount: haveCount ?? this.haveCount,
      haveNotCount: haveNotCount ?? this.haveNotCount,
      startedAt: startedAt,
      completedAt: completedAt,
    );
  }

  factory GameRound.fromMap(Map<String, dynamic> map) {
    return GameRound(
      id: map['id'] as String,
      lobbyId: (map['lobby_id'] ?? map['lobbyId']) as String,
      roundNumber: (map['round_number'] ?? map['roundNumber']) as int,
      questionText: (map['question_text'] ?? map['questionText']) as String,
      questionSourceId:
          (map['question_source_id'] ?? map['questionSourceId']) as String?,
      tone: ToneLevel.values.byName(map['tone'] as String? ?? 'safe'),
      status: RoundStatus.values.byName(map['status'] as String? ?? 'pending'),
      totalPlayers:
          (map['total_players'] ?? map['totalPlayers']) as int? ?? 0,
      haveCount: (map['have_count'] ?? map['haveCount']) as int? ?? 0,
      haveNotCount:
          (map['have_not_count'] ?? map['haveNotCount']) as int? ?? 0,
      startedAt: (map['started_at'] ?? map['startedAt']) != null
          ? DateTime.parse((map['started_at'] ?? map['startedAt']) as String)
          : null,
      completedAt: (map['completed_at'] ?? map['completedAt']) != null
          ? DateTime.parse(
              (map['completed_at'] ?? map['completedAt']) as String,
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        roundNumber,
        questionText,
        tone,
        status,
        haveCount,
        haveNotCount,
      ];
}
