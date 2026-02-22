import { createHash, randomBytes } from 'crypto';
import { z } from 'zod';
import type pg from 'pg';

import { env } from '../../env.js';
import { passesSafetyFilter } from '../../game/safety.js';
import {
  calculateBoldnessDelta,
  calculateProgressionModifier,
  clampIntensityRange,
  deriveSelectionBias,
  determineTone,
  recentYesTrend,
  TONE_THRESHOLDS,
  updateBoldnessScore,
  type ToneLevel,
} from './escalation.js';

const EARLY_ROUND_LIMIT = 20;
const EARLY_MIN_CATEGORIES = 5;
const EARLY_MIN_ENERGIES = 3;

const SettingsSchema = z.object({
  language: z.enum(['en', 'de', 'es']).default('en'),
  maxRounds: z.number().int().min(10).max(100).default(20),
  nsfwEnabled: z.boolean().default(false),
  displayName: z.string().min(1).max(40).optional(),
  avatarEmoji: z.string().min(1).max(16).optional(),
});

export interface LobbyRow {
  id: string;
  game_key: string;
  host_id: string;
  status: string;
  language: 'en' | 'de' | 'es';
  max_rounds: number;
  current_round: number;
  nsfw_enabled: boolean;
  boldness_score: number;
  current_tone: ToneLevel;
  escalation_history: any[];
  used_question_ids: string[];
}

export interface RoundRow {
  id: string;
  lobby_id: string;
  game_key: string;
  round_number: number;
  question_text: string;
  question_source_id: string | null;
  tone: ToneLevel;
  status: string;
  total_players: number;
  have_count: number;
  have_not_count: number;
}

interface CandidateQuestion {
  id: string;
  text: string;
  category: string;
  subcategory: string;
  intensity: number;
  is_nsfw: boolean;
  shock_factor: number;
  vulnerability_level: number;
  energy: 'light' | 'medium' | 'heavy';
}

function languageText(row: any, lang: 'en' | 'de' | 'es'): string {
  if (lang === 'de') return String(row.text_de ?? row.text_en ?? '');
  if (lang === 'es') return String(row.text_es ?? row.text_en ?? '');
  return String(row.text_en ?? '');
}

function validatePrefix(language: 'en' | 'de' | 'es', text: string): string {
  const trimmed = text.trim();
  if (language === 'de' && !/^ich hab noch nie\b/i.test(trimmed)) return `Ich hab noch nie ${trimmed}`;
  if (language === 'es' && !/^yo nunca nunca\b/i.test(trimmed)) return `Yo nunca nunca ${trimmed}`;
  if (language === 'en' && !/^never have i ever\b/i.test(trimmed)) return `Never have I ever ${trimmed}`;
  return trimmed;
}

function hashToSeed(input: string): number {
  const digest = createHash('sha256').update(input).digest();
  return digest.readUInt32BE(0);
}

function mulberry32(seed: number): () => number {
  let t = seed >>> 0;
  return () => {
    t += 0x6d2b79f5;
    let r = Math.imul(t ^ (t >>> 15), t | 1);
    r ^= r + Math.imul(r ^ (r >>> 7), r | 61);
    return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
  };
}

function chooseSeed(history: any[], lobbyId: string): { seed: number; historyMeta: any[] } {
  const debugSeedRaw = process.env.NHIE_DEBUG_SEED?.trim();
  const debugSeed = debugSeedRaw ? Number.parseInt(debugSeedRaw, 10) : NaN;
  if (!Number.isNaN(debugSeed)) {
    const clean = debugSeed >>> 0;
    return {
      seed: clean,
      historyMeta: [{ type: 'meta', session_seed: clean }],
    };
  }

  const existing = history.find((h) => h?.type === 'meta' && Number.isInteger(h?.session_seed));
  if (existing) {
    return {
      seed: Number(existing.session_seed) >>> 0,
      historyMeta: [existing],
    };
  }

  const cryptoSeed = randomBytes(4).readUInt32BE(0);
  const derived = hashToSeed(`${lobbyId}:${Date.now()}:${cryptoSeed}`);
  return {
    seed: derived,
    historyMeta: [{ type: 'meta', session_seed: derived }],
  };
}

function toEnergyForIntensity(intensity: number): 'light' | 'medium' | 'heavy' {
  if (intensity >= 8) return 'heavy';
  if (intensity >= 4) return 'medium';
  return 'light';
}

function isValidEnergy(value: unknown): value is 'light' | 'medium' | 'heavy' {
  return value === 'light' || value === 'medium' || value === 'heavy';
}

function weightCandidate(
  q: CandidateQuestion,
  ctx: {
    recentCategories: string[];
    recentSubcategories: string[];
    recentEnergies: string[];
    earlyCategorySeen: Set<string>;
    earlyEnergySeen: Set<string>;
    nextRoundNumber: number;
    escalationMultiplier: number;
    vulnerabilityBias: number;
  },
): number {
  const esc = Math.max(0.4, Math.min(2.2, ctx.escalationMultiplier));
  const vuln = Math.max(0.4, Math.min(2.0, ctx.vulnerabilityBias));

  let diversityBonus = 0;
  let repetitionPenalty = 0;

  if (!ctx.recentCategories.includes(q.category)) diversityBonus += 0.35;
  if (!ctx.recentSubcategories.includes(q.subcategory)) diversityBonus += 0.25;
  if (!ctx.recentEnergies.includes(q.energy)) diversityBonus += 0.25;

  if (ctx.nextRoundNumber <= EARLY_ROUND_LIMIT) {
    if (ctx.earlyCategorySeen.size < EARLY_MIN_CATEGORIES && !ctx.earlyCategorySeen.has(q.category)) {
      diversityBonus += 1.2;
    }
    if (ctx.earlyEnergySeen.size < EARLY_MIN_ENERGIES && !ctx.earlyEnergySeen.has(q.energy)) {
      diversityBonus += 0.9;
    }
  }

  if (ctx.recentCategories.at(-1) === q.category) repetitionPenalty += 0.45;
  if (ctx.recentEnergies.at(-1) === q.energy) repetitionPenalty += 0.2;
  if (ctx.recentSubcategories.at(-1) === q.subcategory) repetitionPenalty += 2.0;

  const weight = 1 + q.shock_factor * esc + q.vulnerability_level * vuln + diversityBonus - repetitionPenalty;
  return Math.max(0.05, weight);
}

function weightedPick(candidates: CandidateQuestion[], seed: number, round: number, weights: number[]): CandidateQuestion {
  if (candidates.length === 1) return candidates[0];
  const rng = mulberry32((seed ^ (round * 2654435761)) >>> 0);
  const total = weights.reduce((a, b) => a + b, 0);
  let dart = rng() * total;

  for (let i = 0; i < candidates.length; i++) {
    dart -= weights[i];
    if (dart <= 0) return candidates[i];
  }
  return candidates[candidates.length - 1];
}

function mapRowsToCandidates(rows: any[], lang: 'en' | 'de' | 'es'): CandidateQuestion[] {
  return rows.map((row) => ({
    id: String(row.id),
    text: languageText(row, lang),
    category: String(row.category ?? 'social'),
    subcategory: String(row.subcategory ?? ''),
    intensity: Number(row.intensity ?? 1),
    is_nsfw: Boolean(row.is_nsfw),
    shock_factor: Number(row.shock_factor ?? 0),
    vulnerability_level: Number(row.vulnerability_level ?? 0),
    energy: isValidEnergy(row.energy) ? row.energy : toEnergyForIntensity(Number(row.intensity ?? 1)),
  }));
}

function recentWindow(history: any[]): {
  recentCategories: string[];
  recentSubcategories: string[];
  recentEnergies: string[];
  recentIds: string[];
  earlyCategorySeen: Set<string>;
  earlyEnergySeen: Set<string>;
} {
  const playable = history.filter((h) => typeof h?.round === 'number');
  const recent = playable.slice(-3);

  const recentCategories = recent.map((h) => String(h.category ?? '')).filter(Boolean);
  const recentSubcategories = recent.map((h) => String(h.subcategory ?? '')).filter(Boolean);
  const recentEnergies = recent.map((h) => String(h.energy ?? '')).filter(Boolean);
  const recentIds = playable
    .slice(-10)
    .map((h) => String(h.question_id ?? ''))
    .filter(Boolean);

  const earlyRounds = playable.filter((h) => Number(h.round) <= EARLY_ROUND_LIMIT);
  const earlyCategorySeen = new Set(
    earlyRounds.map((h) => String(h.category ?? '')).filter(Boolean),
  );
  const earlyEnergySeen = new Set(
    earlyRounds.map((h) => String(h.energy ?? '')).filter(Boolean),
  );

  return {
    recentCategories,
    recentSubcategories,
    recentEnergies,
    recentIds,
    earlyCategorySeen,
    earlyEnergySeen,
  };
}

async function countEligiblePool(
  client: pg.PoolClient,
  opts: { gameKey: string; nsfwEnabled: boolean },
): Promise<number> {
  const res = await client.query(
    `SELECT COUNT(*)::int AS c
     FROM questions
     WHERE game_key = $1
       AND status = 'active'
       AND ($2::boolean OR is_nsfw = false)`,
    [opts.gameKey, opts.nsfwEnabled],
  );
  return res.rows[0]?.c ?? 0;
}

async function fetchCandidateRows(
  client: pg.PoolClient,
  opts: {
    gameKey: string;
    intensityMin: number;
    intensityMax: number;
    nsfwEnabled: boolean;
    usedIds: string[];
    allowUsed: boolean;
    limit: number;
  },
): Promise<any[]> {
  const usedClause = opts.allowUsed ? '' : 'AND NOT (id = ANY($6::text[]))';
  const params = opts.allowUsed
    ? [opts.gameKey, opts.intensityMin, opts.intensityMax, opts.nsfwEnabled, opts.limit]
    : [opts.gameKey, opts.intensityMin, opts.intensityMax, opts.nsfwEnabled, opts.limit, opts.usedIds];

  const rows = await client.query(
    `SELECT id, text_en, text_de, text_es, category, subcategory, intensity, is_nsfw,
            shock_factor, vulnerability_level, energy
     FROM questions
     WHERE game_key = $1
       AND status = 'active'
       AND intensity >= $2 AND intensity <= $3
       AND ($4::boolean OR is_nsfw = false)
       ${usedClause}
     ORDER BY intensity, category
     LIMIT $5`,
    params,
  );

  return rows.rows;
}

export const engine = {
  validateSettings(input: unknown) {
    return SettingsSchema.parse(input ?? {});
  },

  async selectNextItem(
    client: pg.PoolClient,
    lobby: LobbyRow,
    opts: {
      nextRoundNumber: number;
      playerCount: number;
      prevRound?: RoundRow | null;
      prevHaveRatio?: number | null;
    },
  ): Promise<{
    questionText: string;
    questionSourceId: string | null;
    fallbackUsed: boolean;
    newTone: ToneLevel;
    newBoldness: number;
    deEscalated: boolean;
    intensityMin: number;
    intensityMax: number;
    intensityChosen: number;
    usedIds: string[];
    newHistory: any[];
  }> {
    const rawHistory = Array.isArray(lobby.escalation_history) ? lobby.escalation_history : [];
    const { seed: sessionSeed, historyMeta } = chooseSeed(rawHistory, lobby.id);
    const historyWithoutMeta = rawHistory.filter((h) => h?.type !== 'meta');

    let newBoldness = lobby.boldness_score;
    if (opts.prevRound) {
      const delta = calculateBoldnessDelta(
        opts.prevRound.have_count,
        opts.prevRound.total_players,
        opts.prevRound.tone,
      );
      newBoldness = updateBoldnessScore(lobby.boldness_score, delta);
    }

    const historyWithRatio = historyWithoutMeta.map((h) => ({ ...h }));
    if (typeof opts.prevHaveRatio === 'number' && historyWithRatio.length > 0) {
      historyWithRatio[historyWithRatio.length - 1].have_ratio = opts.prevHaveRatio;
    }

    let deEscalated = false;
    if (historyWithRatio.length >= 2) {
      const last = historyWithRatio[historyWithRatio.length - 1];
      const secondLast = historyWithRatio[historyWithRatio.length - 2];
      if (
        typeof last.have_ratio === 'number' &&
        typeof secondLast.have_ratio === 'number' &&
        1 - last.have_ratio > 0.75 &&
        1 - secondLast.have_ratio > 0.75 &&
        Number(last.intensity ?? 0) > 5 &&
        Number(secondLast.intensity ?? 0) > 5
      ) {
        newBoldness = Math.max(0, newBoldness - 0.15);
        deEscalated = true;
      }
    }

    const yesTrend = recentYesTrend(historyWithRatio, 4);
    const progressionMod = calculateProgressionModifier(opts.nextRoundNumber, lobby.max_rounds);
    const { escalationMultiplier, vulnerabilityBias, trendBias } = deriveSelectionBias(
      yesTrend,
      opts.nextRoundNumber,
      lobby.max_rounds,
    );

    const prevEffective = lobby.boldness_score + progressionMod;
    const rawEffective = newBoldness + progressionMod + trendBias;
    const effectiveScore = Math.max(0, Math.min(1.2, prevEffective * 0.75 + rawEffective * 0.25));

    const newTone = determineTone(effectiveScore, lobby.nsfw_enabled);
    const toneConfig = TONE_THRESHOLDS[newTone];
    const previousIntensity = historyWithRatio.length > 0 ? Number(historyWithRatio.at(-1)?.intensity ?? NaN) : undefined;

    const range = clampIntensityRange(
      { min: toneConfig.intensityMin, max: toneConfig.intensityMax },
      {
        previousIntensity: Number.isFinite(previousIntensity) ? previousIntensity : undefined,
        nextRound: opts.nextRoundNumber,
        yesTrend,
        nsfwEnabled: lobby.nsfw_enabled,
      },
    );

    const intensityMin = range.min;
    const intensityMax = range.max;
    const intensityChosen = Math.round((intensityMin + intensityMax) / 2);

    const usedIds = Array.isArray(lobby.used_question_ids)
      ? [...new Set(lobby.used_question_ids.map((id) => String(id)))]
      : [];

    const recentSignals = recentWindow(historyWithRatio);

    let candidateRows = await fetchCandidateRows(client, {
      gameKey: lobby.game_key,
      intensityMin,
      intensityMax,
      nsfwEnabled: lobby.nsfw_enabled,
      usedIds,
      allowUsed: false,
      limit: 300,
    });

    if (candidateRows.length === 0) {
      candidateRows = await fetchCandidateRows(client, {
        gameKey: lobby.game_key,
        intensityMin: Math.max(1, intensityMin - 1),
        intensityMax: Math.min(10, intensityMax + 1),
        nsfwEnabled: lobby.nsfw_enabled,
        usedIds,
        allowUsed: false,
        limit: 300,
      });
    }

    let candidates = mapRowsToCandidates(candidateRows, lobby.language);

    const lastSubcategory = recentSignals.recentSubcategories.at(-1);
    if (lastSubcategory) {
      const filtered = candidates.filter((q) => !q.subcategory || q.subcategory !== lastSubcategory);
      if (filtered.length > 0) candidates = filtered;
    }

    if (opts.nextRoundNumber <= EARLY_ROUND_LIMIT) {
      if (recentSignals.earlyCategorySeen.size < EARLY_MIN_CATEGORIES) {
        const unseenCategoryCandidates = candidates.filter((q) => !recentSignals.earlyCategorySeen.has(q.category));
        if (unseenCategoryCandidates.length > 0) candidates = unseenCategoryCandidates;
      }
      if (recentSignals.earlyEnergySeen.size < EARLY_MIN_ENERGIES) {
        const unseenEnergyCandidates = candidates.filter((q) => !recentSignals.earlyEnergySeen.has(q.energy));
        if (unseenEnergyCandidates.length > 0) candidates = unseenEnergyCandidates;
      }
    }

    let fallbackUsed = false;
    let questionText = '';
    let questionSourceId: string | null = null;
    let selectedCategory = 'social';
    let selectedSubcategory = 'general';
    let selectedEnergy: 'light' | 'medium' | 'heavy' = 'medium';
    let selectedIntensity = intensityChosen;



    if (!questionText) {
      fallbackUsed = true;
      let fallbackCandidate: CandidateQuestion | null = null;

      if (candidates.length > 0) {
        const weights = candidates.map((q) =>
          weightCandidate(q, {
            recentCategories: recentSignals.recentCategories,
            recentSubcategories: recentSignals.recentSubcategories,
            recentEnergies: recentSignals.recentEnergies,
            earlyCategorySeen: recentSignals.earlyCategorySeen,
            earlyEnergySeen: recentSignals.earlyEnergySeen,
            nextRoundNumber: opts.nextRoundNumber,
            escalationMultiplier,
            vulnerabilityBias,
          }),
        );
        fallbackCandidate = weightedPick(candidates, sessionSeed, opts.nextRoundNumber, weights);
      } else {
        const totalEligible = await countEligiblePool(client, {
          gameKey: lobby.game_key,
          nsfwEnabled: lobby.nsfw_enabled,
        });
        const exhaustedRatio = totalEligible > 0 ? usedIds.length / totalEligible : 0;
        const canRecycle = opts.nextRoundNumber >= 10 && exhaustedRatio >= 0.7;

        if (canRecycle) {
          const recycleRows = await fetchCandidateRows(client, {
            gameKey: lobby.game_key,
            intensityMin,
            intensityMax,
            nsfwEnabled: lobby.nsfw_enabled,
            usedIds,
            allowUsed: true,
            limit: 250,
          });

          const recycleCandidates = mapRowsToCandidates(recycleRows, lobby.language)
            .filter((q) => !recentSignals.recentIds.includes(q.id))
            .sort((a, b) => a.shock_factor - b.shock_factor);

          if (recycleCandidates.length > 0) {
            const slice = Math.max(1, Math.ceil(recycleCandidates.length * 0.35));
            const lowShock = recycleCandidates.slice(0, slice);
            const weights = lowShock.map((q) => Math.max(0.05, 1.25 - q.shock_factor));
            fallbackCandidate = weightedPick(lowShock, sessionSeed ^ 0xa5a5a5a5, opts.nextRoundNumber, weights);
          }
        }
      }

      if (fallbackCandidate) {
        questionText = fallbackCandidate.text;
        questionSourceId = fallbackCandidate.id;
        selectedCategory = fallbackCandidate.category;
        selectedSubcategory = fallbackCandidate.subcategory;
        selectedEnergy = fallbackCandidate.energy;
        selectedIntensity = fallbackCandidate.intensity;
      } else {
        const emergencyQuestions: Record<string, string[]> = {
          en: [
            'Never have I ever done something I regret',
            'Never have I ever kept a secret from everyone',
            'Never have I ever pretended to be someone else',
          ],
          de: [
            'Ich hab noch nie etwas getan das ich bereue',
            'Ich hab noch nie ein Geheimnis vor allen bewahrt',
            'Ich hab noch nie so getan als wäre ich jemand anderes',
          ],
          es: [
            'Yo nunca nunca he hecho algo de lo que me arrepiento',
            'Yo nunca nunca he guardado un secreto de todos',
            'Yo nunca nunca he fingido ser otra persona',
          ],
        };
        const fallbackPool = emergencyQuestions[lobby.language] || emergencyQuestions.en;
        const rng = mulberry32(sessionSeed ^ 0xabcdef);
        questionText = fallbackPool[Math.floor(rng() * fallbackPool.length)];
        questionSourceId = null;
      }
    }

    questionText = validatePrefix(lobby.language, questionText);

    const usedIdsNew = [...usedIds];
    if (questionSourceId && !usedIdsNew.includes(questionSourceId)) {
      usedIdsNew.push(questionSourceId);
    }

    const historyRound = {
      round: opts.nextRoundNumber,
      tone: newTone,
      intensity: selectedIntensity,
      boldness: newBoldness,
      de_escalated: deEscalated,
      yes_trend: yesTrend,
      effective_score: effectiveScore,
      escalation_multiplier: escalationMultiplier,
      vulnerability_bias: vulnerabilityBias,
      category: selectedCategory,
      subcategory: selectedSubcategory,
      energy: selectedEnergy,
      question_id: questionSourceId,
    };

    const newHistory = [...historyMeta, ...historyWithRatio, historyRound];

    return {
      questionText,
      questionSourceId,
      fallbackUsed,
      newTone,
      newBoldness,
      deEscalated,
      intensityMin,
      intensityMax,
      intensityChosen: selectedIntensity,
      usedIds: usedIdsNew,
      newHistory,
    };
  },

  async applyAnswer(
    client: pg.PoolClient,
    opts: {
      gameKey: string;
      roundId: string;
      userId: string;
      answer: boolean;
    },
  ): Promise<{ ok: boolean; lobbyCode?: string; lobbyId?: string }> {
    const r = await client.query(
      `SELECT r.id, r.lobby_id, r.status, l.code AS lobby_code
       FROM rounds r
       JOIN lobbies l ON l.id = r.lobby_id
       WHERE r.id = $1 AND r.game_key = $2 AND l.game_key = $2
       LIMIT 1`,
      [opts.roundId, opts.gameKey],
    );
    const round = r.rows[0];
    if (!round || round.status !== 'active') return { ok: false };

    const member = await client.query(
      `SELECT 1 FROM lobby_players WHERE lobby_id = $1 AND user_id = $2 AND status != 'left'`,
      [round.lobby_id, opts.userId],
    );
    if (member.rowCount === 0) return { ok: false };

    await client.query(
      `INSERT INTO answers (round_id, user_id, lobby_id, answer, answered_at, updated_at)
       VALUES ($1,$2,$3,$4,now(),now())
       ON CONFLICT (round_id, user_id) DO UPDATE SET
         answer = EXCLUDED.answer,
         answered_at = now(),
         updated_at = now()`,
      [opts.roundId, opts.userId, round.lobby_id, opts.answer],
    );

    return { ok: true, lobbyCode: round.lobby_code, lobbyId: round.lobby_id };
  },

  async canAdvance(
    client: pg.PoolClient,
    opts: {
      gameKey: string;
      roundId: string;
      userId: string;
    },
  ): Promise<{ ok: boolean; reason?: string; row?: any; activeCount?: number }> {
    const rRes = await client.query(
      `SELECT r.*, l.code AS lobby_code, l.host_id, l.status AS lobby_status, l.language, l.max_rounds, l.current_round,
              l.nsfw_enabled, l.boldness_score, l.current_tone, l.escalation_history, l.used_question_ids, l.game_key
       FROM rounds r
       JOIN lobbies l ON l.id = r.lobby_id
       WHERE r.id = $1 AND r.game_key = $2 AND l.game_key = $2
       FOR UPDATE`,
      [opts.roundId, opts.gameKey],
    );

    const row = rRes.rows[0];
    if (!row) return { ok: false, reason: 'round_not_found' };
    if (row.host_id !== opts.userId) return { ok: false, reason: 'forbidden' };
    if (row.status !== 'active') return { ok: false, reason: 'round_inactive' };
    if (row.lobby_status !== 'playing') return { ok: false, reason: 'lobby_inactive' };

    const cnt = await client.query('SELECT COUNT(*)::int AS c FROM lobby_players WHERE lobby_id = $1 AND status = $2', [
      row.lobby_id,
      'connected',
    ]);
    const activeCount = cnt.rows[0]?.c ?? 0;
    if (activeCount < 1) return { ok: false, reason: 'no_active_players' };

    const answeredCnt = await client.query(
      `SELECT COUNT(*)::int AS c
       FROM lobby_players lp
       JOIN answers a ON a.round_id = $2 AND a.user_id = lp.user_id
       WHERE lp.lobby_id = $1 AND lp.status = 'connected'`,
      [row.lobby_id, opts.roundId],
    );
    const answeredCount = answeredCnt.rows[0]?.c ?? 0;
    if (answeredCount < activeCount) return { ok: false, reason: 'not_all_answered' };

    return { ok: true, row, activeCount };
  },

  async advance(
    client: pg.PoolClient,
    opts: {
      gameKey: string;
      roundId: string;
      userId: string;
    },
  ): Promise<{ ok: boolean; status?: 'round_started' | 'game_over'; round?: any; lobbyCode?: string; reason?: string }> {
    const can = await this.canAdvance(client, opts);
    if (!can.ok || !can.row) return { ok: false, reason: can.reason };

    const row = can.row;
    const activeCount = can.activeCount ?? 0;

    const ans = await client.query('SELECT answer FROM answers WHERE round_id = $1', [opts.roundId]);
    const haveCount = ans.rows.filter((a: any) => a.answer === true).length;
    const haveNotCount = ans.rows.filter((a: any) => a.answer === false).length;
    const totalPlayers = activeCount;
    const haveRatio = totalPlayers === 0 ? 0 : haveCount / totalPlayers;

    await client.query(
      `UPDATE rounds SET
         have_count = $2,
         have_not_count = $3,
         total_players = $4,
         status = 'completed',
         completed_at = now()
       WHERE id = $1`,
      [opts.roundId, haveCount, haveNotCount, totalPlayers],
    );

    const history = Array.isArray(row.escalation_history) ? row.escalation_history : [];
    const meta = history.filter((h: any) => h?.type === 'meta');
    const rounds = history.filter((h: any) => h?.type !== 'meta');

    if (rounds.length > 0) {
      rounds[rounds.length - 1] = { ...rounds[rounds.length - 1], have_ratio: haveRatio };
      await client.query('UPDATE lobbies SET escalation_history = $2::jsonb WHERE id = $1', [
        row.lobby_id,
        JSON.stringify([...meta, ...rounds]),
      ]);
    }

    const nextRoundNumber = row.round_number + 1;
    if (nextRoundNumber > row.max_rounds) {
      await client.query("UPDATE lobbies SET status = 'finished', ended_at = now() WHERE id = $1", [row.lobby_id]);
      return { ok: true, status: 'game_over', lobbyCode: row.lobby_code };
    }

    const lobbyRow: LobbyRow = {
      id: row.lobby_id,
      game_key: row.game_key,
      host_id: row.host_id,
      status: row.lobby_status,
      language: row.language,
      max_rounds: row.max_rounds,
      current_round: row.current_round,
      nsfw_enabled: row.nsfw_enabled,
      boldness_score: row.boldness_score,
      current_tone: row.current_tone,
      escalation_history: [...meta, ...rounds],
      used_question_ids: (row.used_question_ids ?? []).map((id: unknown) => String(id)),
    };

    const prevRound: RoundRow = {
      id: row.id,
      lobby_id: row.lobby_id,
      game_key: row.game_key,
      round_number: row.round_number,
      question_text: row.question_text,
      question_source_id: row.question_source_id,
      tone: row.tone,
      status: row.status,
      total_players: totalPlayers,
      have_count: haveCount,
      have_not_count: haveNotCount,
    };

    const next = await this.selectNextItem(client, lobbyRow, {
      nextRoundNumber,
      playerCount: activeCount,
      prevRound,
      prevHaveRatio: haveRatio,
    });

    const newRoundRes = await client.query(
      `INSERT INTO rounds (lobby_id, game_key, round_number, question_text, question_source_id, tone, status, total_players, fallback_used, started_at)
       VALUES ($1,$2,$3,$4,$5,$6,'active',$7,$8,now())
       RETURNING *`,
      [
        row.lobby_id,
        row.game_key,
        nextRoundNumber,
        next.questionText,
        next.questionSourceId,
        next.newTone,
        activeCount,
        next.fallbackUsed,
      ],
    );
    const newRound = newRoundRes.rows[0];

    await client.query(
      `UPDATE lobbies SET
         current_round = $2,
         boldness_score = $3,
         current_tone = $4,
         escalation_history = $5::jsonb,
         used_question_ids = $6::text[]
       WHERE id = $1`,
      [row.lobby_id, nextRoundNumber, next.newBoldness, next.newTone, JSON.stringify(next.newHistory), next.usedIds],
    );

    return { ok: true, status: 'round_started', round: newRound, lobbyCode: row.lobby_code };
  },
};

export type NeverHaveIeverEngine = typeof engine;
