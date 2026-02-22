import '../../domain/entities/offline_session.dart';

/// Pure-Dart escalation engine.
/// Mirrors the math in the backend `next-round` route handler.
/// If the server formulas change, update this file too.
class EscalationEngine {
  EscalationEngine._();

  // ─── Constants ─────────────────────────────────────────

  /// Boldness smoothing factor (EMA alpha).
  static const double alpha = 0.3;
  static const double responseSmoothing = 0.25;
  static const int yesTrendWindow = 4;

  /// Tone thresholds – maps effective score ranges to intensity bands.
  static const Map<String, ToneConfig> toneThresholds = {
    'safe': ToneConfig(min: 0.0, max: 0.3, intensityMin: 1, intensityMax: 3),
    'deeper': ToneConfig(min: 0.3, max: 0.55, intensityMin: 3, intensityMax: 5),
    'secretive': ToneConfig(
      min: 0.55,
      max: 0.8,
      intensityMin: 5,
      intensityMax: 7,
    ),
    'freaky': ToneConfig(min: 0.8, max: 1.2, intensityMin: 7, intensityMax: 10),
  };

  /// Intensity weight per tone for boldness delta.
  static const Map<String, double> intensityWeights = {
    'safe': 0.5,
    'deeper': 1.0,
    'secretive': 1.5,
    'freaky': 2.0,
  };

  // ─── Formulas ──────────────────────────────────────────

  /// How much boldness changes after one round.
  /// `delta = haveRatio × intensityWeight[tone]`
  static double calculateBoldnessDelta(
    int haveCount,
    int totalPlayers,
    String currentTone,
  ) {
    if (totalPlayers == 0) return 0.0;
    final haveRatio = haveCount / totalPlayers;
    final weight = intensityWeights[currentTone] ?? 0.5;
    return haveRatio * weight;
  }

  /// Exponential moving average update.
  /// `new = clamp(0, 1, α × delta + (1 − α) × current)`
  static double updateBoldnessScore(double currentBoldness, double delta) {
    return (alpha * delta + (1 - alpha) * currentBoldness).clamp(0.0, 1.0);
  }

  /// Natural escalation as the game progresses.
  /// `min(0.2, (currentRound / maxRounds) × 0.4)`
  static double calculateProgressionModifier(int currentRound, int maxRounds) {
    if (maxRounds == 0) return 0.0;
    return (currentRound / maxRounds * 0.4).clamp(0.0, 0.2);
  }

  /// Determine tone from effective score.
  static String determineTone(double effectiveScore, bool nsfwEnabled) {
    if (effectiveScore >= 0.8 && nsfwEnabled) return 'freaky';
    if (effectiveScore >= 0.55) return 'secretive';
    if (effectiveScore >= 0.3) return 'deeper';
    return 'safe';
  }

  /// Get the intensity range for a tone.
  static ({int min, int max}) getIntensityRange(String tone, bool nsfwEnabled) {
    final config = toneThresholds[tone] ?? toneThresholds['safe']!;
    final maxI = nsfwEnabled
        ? config.intensityMax
        : config.intensityMax.clamp(0, 7).toInt();
    return (min: config.intensityMin, max: maxI);
  }

  /// Check if de-escalation should trigger.
  /// Triggers when the last 2 rounds both had ≥75 % "I have not"
  /// and intensity > 5.
  static double applyDeEscalation(
    double boldness,
    List<OfflineRound> recentRounds,
  ) {
    if (recentRounds.length < 2) return boldness;
    final last = recentRounds[recentRounds.length - 1];
    final secondLast = recentRounds[recentRounds.length - 2];

    if ((1 - last.haveRatio) > 0.75 &&
        (1 - secondLast.haveRatio) > 0.75 &&
        last.intensity > 5 &&
        secondLast.intensity > 5) {
      return (boldness - 0.15).clamp(0.0, 1.0);
    }
    return boldness;
  }

  /// Orchestrate all calculations for the next round.
  /// Returns the new boldness, tone, and intensity range.
  static EscalationResult advanceRound({
    required double currentBoldness,
    required int nextRound,
    required int maxRounds,
    required bool nsfwEnabled,
    required List<OfflineRound> completedRounds,
  }) {
    double boldness = currentBoldness;

    // 1. Process previous round
    if (completedRounds.isNotEmpty) {
      final prev = completedRounds.last;
      final delta = calculateBoldnessDelta(
        prev.haveCount,
        prev.totalPlayers,
        prev.tone,
      );
      boldness = updateBoldnessScore(boldness, delta);
    }

    // 2. De-escalation check
    boldness = applyDeEscalation(boldness, completedRounds);

    // 3. Calculate effective score + tone
    final progMod = calculateProgressionModifier(nextRound, maxRounds);
    final yesTrend = calculateRecentHaveRatio(
      completedRounds,
      window: yesTrendWindow,
    );
    final trendBias = (yesTrend - 0.5) * 0.22;
    final previousEffective = currentBoldness + progMod;
    final rawEffective = boldness + progMod + trendBias;
    final effectiveScore =
        (previousEffective * (1 - responseSmoothing) +
                rawEffective * responseSmoothing)
            .clamp(0.0, 1.2);
    final tone = determineTone(effectiveScore, nsfwEnabled);
    var range = getIntensityRange(tone, nsfwEnabled);

    // Early game clamp for diversity and onboarding feel.
    if (nextRound <= 20) {
      final min = range.min.clamp(1, 4).toInt();
      final max = range.max.clamp(min, 4).toInt();
      range = (min: min, max: max);
    }

    // Response-aware steering:
    // YES-heavy trends allow a mild upward shift, NO-heavy trends soften.
    if (yesTrend >= 0.68) {
      final min = (range.min + (nextRound > 20 ? 1 : 0)).clamp(1, 10).toInt();
      final max = (range.max + 1).clamp(min, 10).toInt();
      range = (min: min, max: max);
    } else if (yesTrend <= 0.32) {
      final min = (range.min - 1).clamp(1, 10).toInt();
      final max = (range.max - 1).clamp(min, 10).toInt();
      range = (min: min, max: max);
    }

    // Prevent abrupt jumps relative to the previously played intensity.
    if (completedRounds.isNotEmpty) {
      final previousIntensity = completedRounds.last.intensity
          .clamp(1, 10)
          .toInt();
      var min = range.min
          .clamp(
            (previousIntensity - 2).clamp(1, 10),
            (previousIntensity + 2).clamp(1, 10),
          )
          .toInt();
      var max = range.max
          .clamp(
            (previousIntensity - 1).clamp(1, 10),
            (previousIntensity + 3).clamp(1, 10),
          )
          .toInt();
      if (max < min) max = min;
      range = (min: min, max: max);
    }

    final trendCentered = (yesTrend - 0.5) * 2; // -1 .. 1
    final roundProgress = maxRounds == 0 ? 0.0 : (nextRound / maxRounds);
    final escalationMultiplier =
        (1.0 + trendCentered * 0.45 + roundProgress * 0.2).clamp(0.7, 1.9);
    final vulnerabilityBias = (1.0 + trendCentered * 0.35).clamp(0.75, 1.6);

    return EscalationResult(
      boldness: boldness,
      tone: tone,
      intensityMin: range.min,
      intensityMax: range.max,
      yesTrend: yesTrend,
      effectiveScore: effectiveScore,
      escalationMultiplier: escalationMultiplier,
      vulnerabilityBias: vulnerabilityBias,
    );
  }

  /// Average HAVE ratio over recent rounds (0.0 .. 1.0).
  static double calculateRecentHaveRatio(
    List<OfflineRound> rounds, {
    int window = 4,
  }) {
    if (rounds.isEmpty) return 0.5;
    final start = rounds.length > window ? rounds.length - window : 0;
    final slice = rounds.sublist(start);
    final sum = slice.fold<double>(0, (acc, r) => acc + r.haveRatio);
    return (sum / slice.length).clamp(0.0, 1.0);
  }
}

// ─── Helper Types ────────────────────────────────────────

class ToneConfig {
  const ToneConfig({
    required this.min,
    required this.max,
    required this.intensityMin,
    required this.intensityMax,
  });
  final double min, max;
  final int intensityMin, intensityMax;
}

class EscalationResult {
  const EscalationResult({
    required this.boldness,
    required this.tone,
    required this.intensityMin,
    required this.intensityMax,
    required this.yesTrend,
    required this.effectiveScore,
    required this.escalationMultiplier,
    required this.vulnerabilityBias,
  });
  final double boldness;
  final String tone;
  final int intensityMin;
  final int intensityMax;
  final double yesTrend;
  final double effectiveScore;
  final double escalationMultiplier;
  final double vulnerabilityBias;
}
