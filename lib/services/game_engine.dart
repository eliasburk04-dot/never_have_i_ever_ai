typedef PlayerId = String;
typedef ScoreDelta = int;

enum PlayerAnswerValue {
  yes,
  no;

  static PlayerAnswerValue parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'yes':
        return PlayerAnswerValue.yes;
      case 'no':
        return PlayerAnswerValue.no;
      default:
        throw ArgumentError.value(raw, 'raw', "Expected 'yes' or 'no'.");
    }
  }
}

class PlayerRoundAnswer {
  const PlayerRoundAnswer({
    required this.playerId,
    required this.answer,
    required this.responseTimeMs,
  });

  final PlayerId playerId;
  final PlayerAnswerValue answer;
  final int responseTimeMs;

  factory PlayerRoundAnswer.fromRaw({
    required PlayerId playerId,
    required String answer,
    required int responseTimeMs,
  }) {
    return PlayerRoundAnswer(
      playerId: playerId,
      answer: PlayerAnswerValue.parse(answer),
      responseTimeMs: responseTimeMs,
    );
  }
}

abstract final class GameEngine {
  static const int soloConfessionBonus = 8;

  static Map<PlayerId, ScoreDelta> scoreRound({
    required List<PlayerRoundAnswer> answers,
    int? totalPlayersInRound,
  }) {
    if (answers.isEmpty) {
      return const <PlayerId, ScoreDelta>{};
    }

    final playerIds = answers.map((a) => a.playerId).toList(growable: false);
    final uniqueIds = playerIds.toSet();
    if (uniqueIds.length != playerIds.length) {
      throw ArgumentError('Duplicate answers for the same player are not allowed.');
    }

    for (final answer in answers) {
      if (answer.responseTimeMs < 0) {
        throw ArgumentError.value(
          answer.responseTimeMs,
          'responseTimeMs',
          'responseTimeMs must be >= 0.',
        );
      }
    }

    final int participantCount = totalPlayersInRound ?? answers.length;
    if (participantCount <= 0) {
      throw ArgumentError.value(
        participantCount,
        'totalPlayersInRound',
        'totalPlayersInRound must be > 0.',
      );
    }
    if (participantCount < answers.length) {
      throw ArgumentError.value(
        participantCount,
        'totalPlayersInRound',
        'totalPlayersInRound cannot be less than number of answers.',
      );
    }

    final yesAnswers = answers.where((a) => a.answer == PlayerAnswerValue.yes).toList(growable: false);
    final pYes = yesProbability(
      yesCount: yesAnswers.length,
      totalPlayers: participantCount,
    );

    final deltas = <PlayerId, ScoreDelta>{};
    for (final answer in answers) {
      deltas[answer.playerId] = scoreForAnswer(
        answer: answer.answer,
        pYes: pYes,
        responseTimeMs: answer.responseTimeMs,
      );
    }

    if (yesAnswers.length == 1) {
      final soloPlayerId = yesAnswers.first.playerId;
      deltas[soloPlayerId] = (deltas[soloPlayerId] ?? 0) + soloConfessionBonus;
    }

    return Map<PlayerId, ScoreDelta>.unmodifiable(deltas);
  }

  static ScoreDelta scoreForAnswer({
    required PlayerAnswerValue answer,
    required double pYes,
    required int responseTimeMs,
  }) {
    switch (answer) {
      case PlayerAnswerValue.yes:
        return scoreForYes(
          pYes: pYes,
          responseTimeMs: responseTimeMs,
        );
      case PlayerAnswerValue.no:
        return scoreForNo(responseTimeMs: responseTimeMs);
    }
  }

  static ScoreDelta scoreForYes({
    required double pYes,
    required int responseTimeMs,
  }) {
    final mut = mutScore(pYes: pYes);
    final speed = speedScore(responseTimeMs: responseTimeMs);
    return 2 + mut + speed;
  }

  static ScoreDelta scoreForNo({required int responseTimeMs}) {
    final speed = speedScore(responseTimeMs: responseTimeMs);
    return 1 + speed;
  }

  static ScoreDelta mutScore({required double pYes}) {
    if (pYes < 0 || pYes > 1) {
      throw ArgumentError.value(pYes, 'pYes', 'pYes must be in [0, 1].');
    }
    return (10 * (1 - pYes)).round();
  }

  static ScoreDelta speedScore({required int responseTimeMs}) {
    if (responseTimeMs < 0) {
      throw ArgumentError.value(
        responseTimeMs,
        'responseTimeMs',
        'responseTimeMs must be >= 0.',
      );
    }
    return (6 - (responseTimeMs / 1000)).round();
  }

  static double yesProbability({
    required int yesCount,
    required int totalPlayers,
  }) {
    if (totalPlayers <= 0) {
      throw ArgumentError.value(totalPlayers, 'totalPlayers', 'totalPlayers must be > 0.');
    }
    if (yesCount < 0 || yesCount > totalPlayers) {
      throw ArgumentError.value(
        yesCount,
        'yesCount',
        'yesCount must be in range [0, totalPlayers].',
      );
    }
    return yesCount / totalPlayers;
  }
}
