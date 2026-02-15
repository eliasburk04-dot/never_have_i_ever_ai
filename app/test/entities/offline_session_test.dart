import 'package:flutter_test/flutter_test.dart';
import 'package:nhie_app/domain/entities/offline_player.dart';
import 'package:nhie_app/domain/entities/offline_session.dart';

void main() {
  group('OfflinePlayer', () {
    test('toMap / fromMap roundtrip', () {
      const player = OfflinePlayer(
        name: 'Alice',
        emoji: '😎',
        haveCount: 3,
        totalRoundsPlayed: 5,
      );
      final map = player.toMap();
      final restored = OfflinePlayer.fromMap(map);
      expect(restored, player);
    });

    test('haveRatio is correct', () {
      const player = OfflinePlayer(
        name: 'Bob',
        emoji: '🤩',
        haveCount: 3,
        totalRoundsPlayed: 6,
      );
      expect(player.haveRatio, 0.5);
    });

    test('haveRatio is 0.0 when no rounds', () {
      const player = OfflinePlayer(name: 'X', emoji: '🥳');
      expect(player.haveRatio, 0.0);
    });
  });

  group('OfflineRound', () {
    test('toMap / fromMap roundtrip', () {
      const round = OfflineRound(
        roundNumber: 3,
        questionText: 'Never have I ever...',
        questionId: 'q001',
        tone: 'deeper',
        intensity: 4,
        haveCount: 3,
        haveNotCount: 2,
        totalPlayers: 5,
        recycled: true,
      );
      final map = round.toMap();
      final restored = OfflineRound.fromMap(map);
      expect(restored.roundNumber, round.roundNumber);
      expect(restored.questionText, round.questionText);
      expect(restored.tone, round.tone);
      expect(restored.recycled, true);
      expect(restored.haveRatio, closeTo(0.6, 0.001));
    });
  });

  group('OfflineSession', () {
    final session = OfflineSession(
      id: 'test-uuid',
      players: const [
        OfflinePlayer(name: 'Alice', emoji: '😎'),
        OfflinePlayer(name: 'Bob', emoji: '🤩'),
      ],
      maxRounds: 10,
      currentRound: 2,
      language: 'en',
      nsfwEnabled: false,
      boldnessScore: 0.35,
      currentTone: 'deeper',
      rounds: const [
        OfflineRound(
          roundNumber: 1,
          questionText: 'Q1',
          questionId: 'q001',
          tone: 'safe',
          intensity: 2,
          haveCount: 2,
          haveNotCount: 0,
          totalPlayers: 2,
        ),
        OfflineRound(
          roundNumber: 2,
          questionText: 'Q2',
          tone: 'safe',
          intensity: 3,
          haveCount: 1,
          haveNotCount: 1,
          totalPlayers: 2,
        ),
      ],
      usedQuestionIds: const ['q001'],
      isComplete: false,
      createdAt: DateTime(2025, 2, 14),
    );

    test('toJson / fromJson roundtrip', () {
      final json = session.toJson();
      final restored = OfflineSession.fromJson(json);
      expect(restored.id, session.id);
      expect(restored.players.length, 2);
      expect(restored.rounds.length, 2);
      expect(restored.boldnessScore, closeTo(0.35, 0.001));
      expect(restored.currentTone, 'deeper');
      expect(restored.usedQuestionIds, ['q001']);
      expect(restored.isComplete, false);
    });

    test('toMap / fromMap roundtrip', () {
      final map = session.toMap();
      final restored = OfflineSession.fromMap(map);
      expect(restored.id, session.id);
      expect(restored.players, session.players);
      expect(restored.rounds.length, session.rounds.length);
      expect(restored.rounds[0].questionText, session.rounds[0].questionText);
      expect(restored.rounds[1].tone, session.rounds[1].tone);
      expect(restored.boldnessScore, closeTo(0.35, 0.001));
      expect(restored.currentTone, 'deeper');
      expect(restored.usedQuestionIds, ['q001']);
      expect(restored.language, 'en');
      expect(restored.isComplete, false);
    });

    test('copyWith preserves unchanged fields', () {
      final updated = session.copyWith(currentRound: 3);
      expect(updated.currentRound, 3);
      expect(updated.players.length, 2);
      expect(updated.language, 'en');
      expect(updated.boldnessScore, closeTo(0.35, 0.001));
    });

    test('playerCount getter', () {
      expect(session.playerCount, 2);
    });
  });
}
