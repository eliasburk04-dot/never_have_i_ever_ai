import { z } from 'zod';
import type pg from 'pg';

import { env } from '../../env.js';
import { passesSafetyFilter } from '../../game/safety.js';
import {
  calculateBoldnessDelta,
  calculateProgressionModifier,
  determineTone,
  TONE_THRESHOLDS,
  updateBoldnessScore,
  type ToneLevel,
} from './escalation.js';

const MAX_GROQ_TIMEOUT_MS = 5000;
const MAX_AI_CALLS_FREE = 10;

const SettingsSchema = z.object({
  language: z.enum(['en', 'de', 'es']).default('en'),
  maxRounds: z.number().int().min(10).max(100).default(20),
  nsfwEnabled: z.boolean().default(false),
  displayName: z.string().min(1).max(40).optional(),
  avatarEmoji: z.string().min(1).max(16).optional(),
});

interface GroqResponse {
  selected_question_id: string | null;
  question_text: string;
  was_modified: boolean;
  was_generated: boolean;
  reasoning: string;
}

const SYSTEM_PROMPT = `You are a game question engine for "Never Have I Ever", a party game.

RULES:
1. You MUST respond ONLY with valid JSON. No other text.
2. You select the best question from the provided candidate pool, or generate one if instructed.
3. You may slightly rephrase a pool question to match the group's tone — but preserve the core meaning.
4. You MUST respect the tone_level and intensity_range provided.
5. If NSFW is disabled, NEVER include sexual, explicit, or adult content.
6. Even with NSFW enabled: NO minors, NO illegal activities, NO explicit pornography, NO violence.
7. Questions must always start with the appropriate "Never have I ever" prefix for the language.
8. Keep questions under 100 characters.
9. Be culturally sensitive.

ABSOLUTE RESTRICTIONS:
- NEVER reference minors (anyone under 18) in any context
- NEVER describe explicit sexual acts
- NEVER encourage illegal activities
- NEVER promote violence or self-harm
- NEVER use hate speech or slurs

RESPONSE FORMAT:
{
  "selected_question_id": "uuid-or-null",
  "question_text": "Never have I ever ...",
  "was_modified": true/false,
  "was_generated": true/false,
  "reasoning": "brief explanation"
}`;

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

async function callGroq(gameState: any, candidates: any[], instruction: string): Promise<GroqResponse | null> {
  if (!env.GROQ_API_KEY) return null;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), MAX_GROQ_TIMEOUT_MS);

  try {
    const resp = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.GROQ_API_KEY}`,
        'Content-Type': 'application/json',
      },
      signal: controller.signal,
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          {
            role: 'user',
            content: `GAME STATE:\n- Language: ${gameState.language}\n- Round: ${gameState.currentRound} / ${gameState.maxRounds}\n- Players: ${gameState.playerCount}\n- NSFW Mode: ${gameState.nsfwEnabled}\n- Current Tone: ${gameState.currentTone}\n- Boldness Score: ${gameState.boldnessScore.toFixed(2)}\n- Target Intensity Range: ${gameState.intensityMin} - ${gameState.intensityMax}\n\nRECENT HISTORY (last 3 rounds):\n${JSON.stringify(gameState.recentHistory, null, 2)}\n\nCANDIDATE QUESTIONS FROM POOL:\n${JSON.stringify(candidates, null, 2)}\n\nINSTRUCTIONS:\n${instruction}\n\nRespond ONLY with the JSON object.`,
          },
        ],
        temperature: 0.7,
        max_tokens: 300,
        top_p: 0.9,
        frequency_penalty: 0.3,
        response_format: { type: 'json_object' },
      }),
    });

    clearTimeout(timeout);

    if (!resp.ok) return null;
    const result: any = await resp.json();
    const content = result?.choices?.[0]?.message?.content;
    if (typeof content !== 'string') return null;

    const parsed: GroqResponse = JSON.parse(content);
    if (!parsed.question_text || typeof parsed.question_text !== 'string') return null;
    if (!passesSafetyFilter(parsed.question_text, gameState.nsfwEnabled)) return null;

    return parsed;
  } catch {
    clearTimeout(timeout);
    return null;
  }
}

async function canUseAi(client: pg.PoolClient, hostId: string): Promise<boolean> {
  const prem = await client.query('SELECT is_premium FROM premium_status WHERE user_id = $1', [hostId]);
  if (prem.rows[0]?.is_premium) return true;

  const rate = await client.query('SELECT daily_ai_calls, last_reset_date FROM ai_rate_limits WHERE user_id = $1', [hostId]);
  const row = rate.rows[0];
  if (!row) return true;

  const today = new Date().toISOString().slice(0, 10);
  const last = typeof row.last_reset_date === 'string' ? row.last_reset_date : row.last_reset_date?.toISOString?.().slice(0, 10);
  if (last && last !== today) return true;
  return (row.daily_ai_calls ?? 0) < MAX_AI_CALLS_FREE;
}

async function incrementAiCalls(client: pg.PoolClient, userId: string): Promise<void> {
  await client.query(
    `INSERT INTO ai_rate_limits (user_id, daily_ai_calls, last_reset_date, lifetime_ai_calls)
     VALUES ($1, 1, CURRENT_DATE, 1)
     ON CONFLICT (user_id) DO UPDATE SET
       daily_ai_calls = CASE WHEN ai_rate_limits.last_reset_date < CURRENT_DATE THEN 1 ELSE ai_rate_limits.daily_ai_calls + 1 END,
       last_reset_date = CURRENT_DATE,
       lifetime_ai_calls = ai_rate_limits.lifetime_ai_calls + 1`,
    [userId],
  );
}

function validatePrefix(language: 'en' | 'de' | 'es', text: string): string {
  if (language === 'de' && !/^ich hab noch nie\b/i.test(text)) return `Ich hab noch nie ${text}`;
  if (language === 'es' && !/^yo nunca nunca\b/i.test(text)) return `Yo nunca nunca ${text}`;
  if (language === 'en' && !/^never have i ever\b/i.test(text)) return `Never have I ever ${text}`;
  return text;
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
    const history = Array.isArray(lobby.escalation_history) ? lobby.escalation_history : [];

    let newBoldness = lobby.boldness_score;
    if (opts.prevRound) {
      const delta = calculateBoldnessDelta(opts.prevRound.have_count, opts.prevRound.total_players, opts.prevRound.tone);
      newBoldness = updateBoldnessScore(lobby.boldness_score, delta);
    }

    const historyWithRatio = history.map((h) => ({ ...h }));
    if (typeof opts.prevHaveRatio === 'number' && historyWithRatio.length > 0) {
      historyWithRatio[historyWithRatio.length - 1].have_ratio = opts.prevHaveRatio;
    }

    const progressionMod = calculateProgressionModifier(opts.nextRoundNumber, lobby.max_rounds);
    const effectiveScore = newBoldness + progressionMod;

    let deEscalated = false;
    if (historyWithRatio.length >= 2) {
      const last = historyWithRatio[historyWithRatio.length - 1];
      const secondLast = historyWithRatio[historyWithRatio.length - 2];
      if (
        last.have_ratio !== undefined &&
        secondLast.have_ratio !== undefined &&
        1 - last.have_ratio > 0.75 &&
        1 - secondLast.have_ratio > 0.75 &&
        last.intensity > 5 &&
        secondLast.intensity > 5
      ) {
        newBoldness = Math.max(0, newBoldness - 0.15);
        deEscalated = true;
      }
    }

    const finalEffective = deEscalated ? newBoldness + progressionMod : effectiveScore;
    const newTone = determineTone(finalEffective, lobby.nsfw_enabled);
    const toneConfig = TONE_THRESHOLDS[newTone];
    const intensityMin = toneConfig.intensityMin;
    const intensityMax = lobby.nsfw_enabled ? toneConfig.intensityMax : Math.min(toneConfig.intensityMax, 7);
    const intensityChosen = Math.round((intensityMin + intensityMax) / 2);

    const usedIds = Array.isArray(lobby.used_question_ids) ? [...lobby.used_question_ids] : [];

    const candidateRows = await client.query(
      `SELECT id, text, intensity, category, weight
       FROM questions
       WHERE game_key = $1
         AND lang = $2
         AND status = 'active'
         AND intensity >= $3 AND intensity <= $4
         AND ($5::boolean OR is_nsfw = false)
         AND NOT (id = ANY($6::uuid[]))
       ORDER BY weight DESC, random()
       LIMIT 8`,
      [lobby.game_key, lobby.language, intensityMin, intensityMax, lobby.nsfw_enabled, usedIds],
    );

    const candidateList = candidateRows.rows.map((q: any) => ({
      id: q.id,
      text: q.text,
      intensity: q.intensity,
      category: q.category,
      weight: Number(q.weight ?? 1),
    }));

    const recentHistory = historyWithRatio.slice(-3);
    const gameState = {
      language: lobby.language,
      currentRound: opts.nextRoundNumber,
      maxRounds: lobby.max_rounds,
      playerCount: opts.playerCount,
      nsfwEnabled: lobby.nsfw_enabled,
      currentTone: newTone,
      boldnessScore: newBoldness,
      intensityMin,
      intensityMax,
      recentHistory,
    };

    const instruction =
      candidateList.length >= 3
        ? deEscalated
          ? `The group showed discomfort in recent rounds. Select a LIGHTER question. Aim for intensity ${Math.max(intensityMin, intensityMin + 1)} to give the group breathing room.`
          : `Choose the best candidate from the pool that matches the current tone and group energy. You may slightly rephrase it.`
        : `The question pool has insufficient candidates. Generate a NEW "Never have I ever" question that fits intensity ${intensityChosen}, tone: ${newTone}, in ${lobby.language}. Set was_generated=true.`;

    let questionText = '';
    let questionSourceId: string | null = null;
    let fallbackUsed = false;

    const aiAllowed = await canUseAi(client, lobby.host_id);

    if (aiAllowed && candidateList.length > 0) {
      const aiResult = await callGroq(gameState, candidateList, instruction);
      if (aiResult) {
        questionText = validatePrefix(lobby.language, aiResult.question_text);
        questionSourceId = aiResult.selected_question_id || null;
        await incrementAiCalls(client, lobby.host_id);
      } else {
        fallbackUsed = true;
        const fb = candidateList[Math.floor(Math.random() * candidateList.length)];
        questionText = fb.text;
        questionSourceId = fb.id;
      }
    } else if (candidateList.length > 0) {
      fallbackUsed = true;
      const fb = candidateList[Math.floor(Math.random() * candidateList.length)];
      questionText = fb.text;
      questionSourceId = fb.id;
    } else {
      fallbackUsed = true;
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
      const pool = emergencyQuestions[lobby.language] || emergencyQuestions.en;
      questionText = pool[Math.floor(Math.random() * pool.length)];
    }

    const newHistory = [
      ...historyWithRatio,
      {
        round: opts.nextRoundNumber,
        tone: newTone,
        intensity: intensityChosen,
        boldness: newBoldness,
        de_escalated: deEscalated,
      },
    ];

    const usedIdsNew = [...usedIds];
    if (questionSourceId) usedIdsNew.push(questionSourceId);

    return {
      questionText,
      questionSourceId,
      fallbackUsed,
      newTone,
      newBoldness,
      deEscalated,
      intensityMin,
      intensityMax,
      intensityChosen,
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
    if (history.length > 0) {
      history[history.length - 1] = { ...history[history.length - 1], have_ratio: haveRatio };
      await client.query('UPDATE lobbies SET escalation_history = $2::jsonb WHERE id = $1', [
        row.lobby_id,
        JSON.stringify(history),
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
      escalation_history: history,
      used_question_ids: row.used_question_ids ?? [],
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
        null,
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
         used_question_ids = $6::uuid[]
       WHERE id = $1`,
      [row.lobby_id, nextRoundNumber, next.newBoldness, next.newTone, JSON.stringify(next.newHistory), next.usedIds],
    );

    return { ok: true, status: 'round_started', round: newRound, lobbyCode: row.lobby_code };
  },
};

export type NeverHaveIeverEngine = typeof engine;
