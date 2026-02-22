import type pg from 'pg';
import { env } from '../env.js';
import { passesSafetyFilter } from './safety.js';

const ALPHA = 0.3;
const MAX_GROQ_TIMEOUT_MS = 5000;
const MAX_AI_CALLS_FREE = 10;

const TONE_THRESHOLDS = {
  safe: { min: 0.0, max: 0.3, intensityMin: 1, intensityMax: 3 },
  deeper: { min: 0.3, max: 0.55, intensityMin: 3, intensityMax: 5 },
  secretive: { min: 0.55, max: 0.8, intensityMin: 5, intensityMax: 7 },
  freaky: { min: 0.8, max: 1.2, intensityMin: 7, intensityMax: 10 },
} as const;

type ToneLevel = keyof typeof TONE_THRESHOLDS;

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

function calculateBoldnessDelta(haveCount: number, totalPlayers: number, currentTone: ToneLevel): number {
  if (totalPlayers === 0) return 0;
  const haveRatio = haveCount / totalPlayers;
  const intensityWeights: Record<ToneLevel, number> = {
    safe: 0.5,
    deeper: 1.0,
    secretive: 1.5,
    freaky: 2.0,
  };
  return haveRatio * intensityWeights[currentTone];
}

function updateBoldnessScore(currentBoldness: number, delta: number): number {
  return Math.min(1.0, Math.max(0.0, ALPHA * delta + (1 - ALPHA) * currentBoldness));
}

function calculateProgressionModifier(currentRound: number, maxRounds: number): number {
  return Math.min(0.2, (currentRound / maxRounds) * 0.4);
}

function determineTone(effectiveScore: number, nsfwEnabled: boolean): ToneLevel {
  if (effectiveScore >= 0.8 && nsfwEnabled) return 'freaky';
  if (effectiveScore >= 0.55) return 'secretive';
  if (effectiveScore >= 0.3) return 'deeper';
  return 'safe';
}

interface GroqResponse {
  selected_question_id: string | null;
  question_text: string;
  was_modified: boolean;
  was_generated: boolean;
  reasoning: string;
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

export interface LobbyRow {
  id: string;
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
  round_number: number;
  question_text: string;
  question_source_id: string | null;
  tone: ToneLevel;
  status: string;
  total_players: number;
  have_count: number;
  have_not_count: number;
}

export async function buildNextRound(
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

  // Update boldness from previous round (if provided)
  let newBoldness = lobby.boldness_score;
  if (opts.prevRound) {
    const delta = calculateBoldnessDelta(opts.prevRound.have_count, opts.prevRound.total_players, opts.prevRound.tone);
    newBoldness = updateBoldnessScore(lobby.boldness_score, delta);
  }

  // Ensure last history item has have_ratio before we compute de-escalation
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

  const langField = lobby.language === 'de' ? 'text_de' : lobby.language === 'es' ? 'text_es' : 'text_en';

  const cand = await client.query(
    `SELECT id, ${langField} AS text, intensity, category
     FROM question_pool
     WHERE active = true
       AND intensity >= $1 AND intensity <= $2
       AND ($3::boolean OR is_nsfw = false)
       AND NOT (id = ANY($4::uuid[]))
     ORDER BY times_used ASC
     LIMIT 5`,
    [intensityMin, intensityMax, lobby.nsfw_enabled, usedIds],
  );

  const candidateList = cand.rows.map((q: any) => ({
    id: q.id,
    text: q.text,
    intensity: q.intensity,
    category: q.category,
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
      questionText = aiResult.question_text;
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
}
