import 'package:flutter_test/flutter_test.dart';
import 'package:nhie_app/core/engine/escalation_engine.dart';
import 'package:nhie_app/domain/entities/offline_session.dart';

void main() {
  group('EscalationEngine', () {
    // ─── calculateBoldnessDelta ───────────────────────

    test('returns 0.0 when totalPlayers is 0', () {
      final result = EscalationEngine.calculateBoldnessDelta(3, 0, 'safe');
      expect(result, 0.0);
    });

    test('calculates delta for all "I have" in safe tone', () {
      // haveRatio = 4/4 = 1.0, weight = 0.5
      final result = EscalationEngine.calculateBoldnessDelta(4, 4, 'safe');
      expect(result, 0.5);
    });

    test('calculates delta for all "I have not" in deeper tone', () {
      // haveRatio = 0/5 = 0.0, weight = 1.0
      final result = EscalationEngine.calculateBoldnessDelta(0, 5, 'deeper');
      expect(result, 0.0);
    });

    test('calculates delta for mixed answers in secretive tone', () {
      // haveRatio = 3/5 = 0.6, weight = 1.5
      final result = EscalationEngine.calculateBoldnessDelta(3, 5, 'secretive');
      expect(result, closeTo(0.9, 0.001));
    });

    test('calculates delta for freaky tone', () {
      // haveRatio = 2/4 = 0.5, weight = 2.0
      final result = EscalationEngine.calculateBoldnessDelta(2, 4, 'freaky');
      expect(result, 1.0);
    });

    // ─── updateBoldnessScore ──────────────────────────

    test('updates boldness with EMA formula', () {
      // α=0.3, new = 0.3*0.8 + 0.7*0.4 = 0.24 + 0.28 = 0.52
      final result = EscalationEngine.updateBoldnessScore(0.4, 0.8);
      expect(result, closeTo(0.52, 0.001));
    });

    test('clamps boldness to 0.0', () {
      final result = EscalationEngine.updateBoldnessScore(0.0, 0.0);
      expect(result, 0.0);
    });

    test('clamps boldness to 1.0', () {
      final result = EscalationEngine.updateBoldnessScore(1.0, 2.0);
      expect(result, 1.0);
    });

    // ─── calculateProgressionModifier ─────────────────

    test('returns 0.0 for round 0', () {
      expect(EscalationEngine.calculateProgressionModifier(0, 20), 0.0);
    });

    test('calculates mid-game progression', () {
      // 10/20 * 0.4 = 0.2, min(0.2, 0.2) = 0.2
      expect(
        EscalationEngine.calculateProgressionModifier(10, 20),
        closeTo(0.2, 0.001),
      );
    });

    test('caps at 0.2 for late game', () {
      expect(
        EscalationEngine.calculateProgressionModifier(18, 20),
        closeTo(0.2, 0.001),
      );
    });

    test('returns 0.0 when maxRounds is 0', () {
      expect(EscalationEngine.calculateProgressionModifier(5, 0), 0.0);
    });

    // ─── determineTone ────────────────────────────────

    test('returns safe for low score', () {
      expect(EscalationEngine.determineTone(0.1, false), 'safe');
    });

    test('returns deeper for score >= 0.3', () {
      expect(EscalationEngine.determineTone(0.35, false), 'deeper');
    });

    test('returns secretive for score >= 0.55', () {
      expect(EscalationEngine.determineTone(0.6, false), 'secretive');
    });

    test('returns secretive when score >= 0.8 but nsfw disabled', () {
      expect(EscalationEngine.determineTone(0.85, false), 'secretive');
    });

    test('returns freaky when score >= 0.8 and nsfw enabled', () {
      expect(EscalationEngine.determineTone(0.85, true), 'freaky');
    });

    // ─── getIntensityRange ────────────────────────────

    test('safe range is 1-3', () {
      final r = EscalationEngine.getIntensityRange('safe', false);
      expect(r.min, 1);
      expect(r.max, 3);
    });

    test('freaky range capped at 7 when nsfw disabled', () {
      final r = EscalationEngine.getIntensityRange('freaky', false);
      expect(r.min, 7);
      expect(r.max, 7);
    });

    test('freaky range goes to 10 when nsfw enabled', () {
      final r = EscalationEngine.getIntensityRange('freaky', true);
      expect(r.min, 7);
      expect(r.max, 10);
    });

    // ─── applyDeEscalation ────────────────────────────

    test('does not trigger with fewer than 2 rounds', () {
      final rounds = [
        const OfflineRound(
          roundNumber: 1,
          questionText: 'q',
          tone: 'secretive',
          intensity: 6,
          haveCount: 1,
          haveNotCount: 4,
          totalPlayers: 5,
        ),
      ];
      expect(EscalationEngine.applyDeEscalation(0.6, rounds), 0.6);
    });

    test(
      'triggers when last 2 rounds have > 75% "I have not" and intensity > 5',
      () {
        final rounds = [
          const OfflineRound(
            roundNumber: 1,
            questionText: 'q1',
            tone: 'secretive',
            intensity: 6,
            haveCount: 1,
            haveNotCount: 4,
            totalPlayers: 5,
          ),
          const OfflineRound(
            roundNumber: 2,
            questionText: 'q2',
            tone: 'secretive',
            intensity: 7,
            haveCount: 0,
            haveNotCount: 5,
            totalPlayers: 5,
          ),
        ];
        expect(
          EscalationEngine.applyDeEscalation(0.6, rounds),
          closeTo(0.45, 0.001),
        );
      },
    );

    test('does not trigger when intensity <= 5', () {
      final rounds = [
        const OfflineRound(
          roundNumber: 1,
          questionText: 'q1',
          tone: 'deeper',
          intensity: 4,
          haveCount: 0,
          haveNotCount: 5,
          totalPlayers: 5,
        ),
        const OfflineRound(
          roundNumber: 2,
          questionText: 'q2',
          tone: 'deeper',
          intensity: 5,
          haveCount: 1,
          haveNotCount: 4,
          totalPlayers: 5,
        ),
      ];
      expect(EscalationEngine.applyDeEscalation(0.6, rounds), 0.6);
    });

    // ─── advanceRound (integration) ───────────────────

    test('first round starts at safe tone', () {
      final result = EscalationEngine.advanceRound(
        currentBoldness: 0.0,
        nextRound: 1,
        maxRounds: 20,
        nsfwEnabled: false,
        completedRounds: [],
      );
      expect(result.tone, 'safe');
      expect(result.boldness, 0.0);
      expect(result.intensityMin, 1);
      expect(result.intensityMax, 3);
    });

    test('boldness increases after a high-participation round', () {
      final result = EscalationEngine.advanceRound(
        currentBoldness: 0.0,
        nextRound: 2,
        maxRounds: 20,
        nsfwEnabled: false,
        completedRounds: [
          const OfflineRound(
            roundNumber: 1,
            questionText: 'q',
            tone: 'safe',
            intensity: 2,
            haveCount: 5,
            haveNotCount: 0,
            totalPlayers: 5,
          ),
        ],
      );
      // delta = 1.0 * 0.5 = 0.5, new = 0.3*0.5 + 0.7*0.0 = 0.15
      expect(result.boldness, closeTo(0.15, 0.001));
    });

    test('YES-heavy trend increases average intensity vs NO-heavy trend', () {
      ({double meanIntensity, List<OfflineRound> rounds}) run({
        required int haveCountPerRound,
      }) {
        var boldness = 0.0;
        final rounds = <OfflineRound>[];
        final intensities = <int>[];

        for (var round = 1; round <= 30; round++) {
          final next = EscalationEngine.advanceRound(
            currentBoldness: boldness,
            nextRound: round,
            maxRounds: 30,
            nsfwEnabled: true,
            completedRounds: rounds,
          );
          final intensity = ((next.intensityMin + next.intensityMax) / 2)
              .round();
          intensities.add(intensity);

          rounds.add(
            OfflineRound(
              roundNumber: round,
              questionText: 'q$round',
              tone: next.tone,
              intensity: intensity,
              haveCount: haveCountPerRound,
              haveNotCount: 5 - haveCountPerRound,
              totalPlayers: 5,
            ),
          );
          boldness = next.boldness;
        }

        final mean = intensities.reduce((a, b) => a + b) / intensities.length;
        return (meanIntensity: mean, rounds: rounds);
      }

      final yesHeavy = run(haveCountPerRound: 4);
      final noHeavy = run(haveCountPerRound: 1);

      expect(yesHeavy.meanIntensity, greaterThan(noHeavy.meanIntensity));
    });

    test('NO-heavy trend does not ramp intensity in late game', () {
      var boldness = 0.0;
      final rounds = <OfflineRound>[];
      final intensities = <int>[];

      for (var round = 1; round <= 30; round++) {
        final next = EscalationEngine.advanceRound(
          currentBoldness: boldness,
          nextRound: round,
          maxRounds: 30,
          nsfwEnabled: true,
          completedRounds: rounds,
        );

        final intensity = ((next.intensityMin + next.intensityMax) / 2).round();
        intensities.add(intensity);
        rounds.add(
          OfflineRound(
            roundNumber: round,
            questionText: 'q$round',
            tone: next.tone,
            intensity: intensity,
            haveCount: 1,
            haveNotCount: 4,
            totalPlayers: 5,
          ),
        );
        boldness = next.boldness;
      }

      final firstHalf = intensities.sublist(0, 15);
      final secondHalf = intensities.sublist(15);
      final meanFirst = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final meanSecond = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

      expect(meanSecond, lessThanOrEqualTo(meanFirst + 0.6));
    });
  });
}
