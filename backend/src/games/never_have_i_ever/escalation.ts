export type ToneLevel = 'safe' | 'deeper' | 'secretive' | 'freaky';

export const TONE_THRESHOLDS: Record<
  ToneLevel,
  { min: number; max: number; intensityMin: number; intensityMax: number }
> = {
  safe: { min: 0, max: 0.3, intensityMin: 1, intensityMax: 3 },
  deeper: { min: 0.3, max: 0.55, intensityMin: 3, intensityMax: 5 },
  secretive: { min: 0.55, max: 0.8, intensityMin: 5, intensityMax: 7 },
  freaky: { min: 0.8, max: 1.2, intensityMin: 7, intensityMax: 10 },
};

const INTENSITY_WEIGHTS: Record<ToneLevel, number> = {
  safe: 0.5,
  deeper: 1.0,
  secretive: 1.5,
  freaky: 2.0,
};

export function calculateBoldnessDelta(
  haveCount: number,
  totalPlayers: number,
  tone: ToneLevel,
): number {
  if (!totalPlayers) return 0;
  const haveRatio = haveCount / totalPlayers;
  return haveRatio * (INTENSITY_WEIGHTS[tone] ?? 0.5);
}

export function updateBoldnessScore(currentBoldness: number, delta: number): number {
  const alpha = 0.3;
  return Math.max(0, Math.min(1, alpha * delta + (1 - alpha) * currentBoldness));
}

export function calculateProgressionModifier(currentRound: number, maxRounds: number): number {
  if (!maxRounds) return 0;
  return Math.max(0, Math.min(0.2, (currentRound / maxRounds) * 0.4));
}

export function determineTone(effectiveScore: number, nsfwEnabled: boolean): ToneLevel {
  if (effectiveScore >= 0.8 && nsfwEnabled) return 'freaky';
  if (effectiveScore >= 0.55) return 'secretive';
  if (effectiveScore >= 0.3) return 'deeper';
  return 'safe';
}

export function clampIntensityRange(
  range: { min: number; max: number },
  opts: {
    previousIntensity?: number;
    nextRound: number;
    yesTrend: number;
    nsfwEnabled: boolean;
  },
): { min: number; max: number } {
  let min = range.min;
  let max = opts.nsfwEnabled ? range.max : Math.min(range.max, 7);

  if (opts.nextRound <= 20) {
    min = Math.max(1, Math.min(4, min));
    max = Math.max(min, Math.min(4, max));
  }

  if (opts.yesTrend >= 0.68) {
    min = Math.max(1, Math.min(10, min + (opts.nextRound > 20 ? 1 : 0)));
    max = Math.max(min, Math.min(10, max + 1));
  } else if (opts.yesTrend <= 0.32) {
    min = Math.max(1, Math.min(10, min - 1));
    max = Math.max(min, Math.min(10, max - 1));
  }

  if (typeof opts.previousIntensity === 'number') {
    const prev = Math.max(1, Math.min(10, opts.previousIntensity));
    min = Math.max(Math.max(1, prev - 2), Math.min(min, prev + 2));
    max = Math.max(Math.max(1, prev - 1), Math.min(max, prev + 3));
    if (max < min) max = min;
  }

  return { min, max };
}

export function recentYesTrend(history: any[], window = 4): number {
  const entries = history.filter((h) => typeof h?.have_ratio === 'number').slice(-window);
  if (entries.length === 0) return 0.5;
  const sum = entries.reduce((acc, h) => acc + Number(h.have_ratio), 0);
  return Math.max(0, Math.min(1, sum / entries.length));
}

export function deriveSelectionBias(yesTrend: number, nextRound: number, maxRounds: number): {
  escalationMultiplier: number;
  vulnerabilityBias: number;
  trendBias: number;
} {
  const trendCentered = (yesTrend - 0.5) * 2;
  const roundProgress = maxRounds > 0 ? nextRound / maxRounds : 0;
  const escalationMultiplier = Math.max(0.7, Math.min(1.9, 1 + trendCentered * 0.45 + roundProgress * 0.2));
  const vulnerabilityBias = Math.max(0.75, Math.min(1.6, 1 + trendCentered * 0.35));
  const trendBias = (yesTrend - 0.5) * 0.22;

  return { escalationMultiplier, vulnerabilityBias, trendBias };
}
