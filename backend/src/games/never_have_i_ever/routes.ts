import type { FastifyInstance, FastifyRequest } from 'fastify';
import { z } from 'zod';

import { pool, withTx } from '../../platform/db/index.js';
import { generateLobbyCode } from '../../game/code.js';
import { routeRateLimits } from '../../platform/rate-limit/index.js';
import { engine, type LobbyRow } from './engine.js';
import { fetchLobbyStateByCode, getLobbyRoom } from './selectors.js';

export const NEVER_HAVE_I_EVER_GAME_KEY = 'never_have_i_ever';

const JoinBody = z.object({
  code: z.string().min(3).max(12),
  displayName: z.string().min(1).max(40),
  avatarEmoji: z.string().min(1).max(16),
});

const AnswerBody = z.object({
  value: z.enum(['HAVE', 'HAVE_NOT']),
});

const LeaveBody = z.object({
  lobbyCode: z.string().min(3).max(12).optional(),
}).optional();

function requireAuth(req: FastifyRequest) {
  if (!req.auth?.userId) throw new Error('unauthenticated');
}

function resolveGameKey(req: FastifyRequest, fixedGameKey?: string): string {
  if (fixedGameKey) return fixedGameKey;
  return ((req.params as any).gameKey as string) ?? '';
}

function ensureGameKey(gameKey: string, reply: any): boolean {
  if (gameKey !== NEVER_HAVE_I_EVER_GAME_KEY) {
    reply.code(404).send({ error: 'Game not found' });
    return false;
  }
  return true;
}

async function broadcastState(fastify: FastifyInstance, gameKey: string, code: string) {
  const client = await pool.connect();
  try {
    const state = await fetchLobbyStateByCode(client, { gameKey, code });
    if (!state) return;

    const room = getLobbyRoom(gameKey, state.lobby.code);
    fastify.io.to(room).emit('lobby:state', state);
    if (state.round) {
      fastify.io.to(room).emit('round:state', { round: state.round });
    }
    fastify.io.to(room).emit('answer:state', {
      gameKey,
      lobbyCode: state.lobby.code,
      lobbyId: state.lobby.id,
      roundId: state.round?.id ?? null,
      answers: state.answers,
      answered: state.answered,
    });
  } finally {
    client.release();
  }
}

function createLobbyHandler(fixedGameKey?: string) {
  return async (req: FastifyRequest, reply: any) => {
    requireAuth(req);

    const gameKey = resolveGameKey(req, fixedGameKey);
    if (!ensureGameKey(gameKey, reply)) return;

    const body = engine.validateSettings(req.body ?? {});
    const hostId = req.auth.userId;

    const lobby = await withTx(async (client) => {
      // Ensure user is not already in an active lobby
      const activeLobby = await client.query(
        `SELECT l.code FROM lobby_players lp
         JOIN lobbies l ON l.id = lp.lobby_id
         WHERE lp.user_id = $1 AND lp.status = 'connected'
           AND l.status IN ('waiting', 'playing') AND l.game_key = $2
         LIMIT 1`,
        [hostId, gameKey],
      );
      if (activeLobby.rowCount! > 0) {
        // Auto-leave previous lobby
        await client.query(
          `UPDATE lobby_players lp SET status = 'left'
           FROM lobbies l
           WHERE lp.lobby_id = l.id
             AND lp.user_id = $1
             AND lp.status IN ('connected', 'disconnected')
             AND l.status IN ('waiting', 'playing')
             AND l.game_key = $2`,
          [hostId, gameKey],
        );
      }

      await client.query(
        `UPDATE users SET
           display_name = COALESCE($2, display_name),
           avatar_emoji = COALESCE($3, avatar_emoji),
           preferred_language = COALESCE($4, preferred_language),
           last_seen_at = now()
         WHERE id = $1`,
        [hostId, body.displayName ?? null, body.avatarEmoji ?? null, body.language],
      );

      let code = '';
      for (let attempt = 0; attempt < 10; attempt++) {
        code = generateLobbyCode();
        const exists = await client.query(
          `SELECT id FROM lobbies WHERE game_key = $1 AND code = $2 AND status IN ('waiting','playing') LIMIT 1`,
          [gameKey, code],
        );
        if (exists.rowCount === 0) break;
        code = '';
      }
      if (!code) {
        reply.code(500);
        return reply.send({ error: 'Failed to generate unique code' });
      }

      const lobbyRes = await client.query(
        `INSERT INTO lobbies (game_key, code, host_id, language, max_rounds, nsfw_enabled, categories)
         VALUES ($1,$2,$3,$4,$5,$6,$7)
         RETURNING *`,
        [gameKey, code, hostId, body.language, body.maxRounds, body.nsfwEnabled, body.categories ?? []],
      );
      const lobby = lobbyRes.rows[0];

      await client.query(
        `INSERT INTO lobby_players (lobby_id, user_id, display_name, avatar_emoji, is_host, status)
         VALUES ($1,$2,COALESCE($3,'Host'),COALESCE($4,'👑'),true,'connected')
         ON CONFLICT (lobby_id, user_id) DO UPDATE SET
           status = 'connected',
           is_host = true,
           display_name = EXCLUDED.display_name,
           avatar_emoji = EXCLUDED.avatar_emoji`,
        [lobby.id, hostId, body.displayName ?? 'Host', body.avatarEmoji ?? '👑'],
      );

      return lobby;
    });

    return reply.code(201).send({ lobby });
  };
}

function joinLobbyHandler(fastify: FastifyInstance, fixedGameKey?: string) {
  return async (req: FastifyRequest, reply: any) => {
    requireAuth(req);

    const gameKey = resolveGameKey(req, fixedGameKey);
    if (!ensureGameKey(gameKey, reply)) return;

    const body = JoinBody.parse(req.body ?? {});
    const userId = req.auth.userId;

    const out = await withTx(async (client) => {
      // Lock the lobby row to prevent race conditions on auto-start
      const lobbyRes = await client.query(
        'SELECT * FROM lobbies WHERE game_key = $1 AND code = UPPER($2) FOR UPDATE LIMIT 1',
        [gameKey, body.code],
      );
      const lobby = lobbyRes.rows[0];
      if (!lobby) {
        reply.code(404);
        return { error: 'Lobby not found' };
      }

      if (!['waiting', 'playing'].includes(lobby.status)) {
        reply.code(400);
        return { error: 'Lobby not joinable' };
      }

      const existing = await client.query(
        'SELECT status FROM lobby_players WHERE lobby_id = $1 AND user_id = $2 LIMIT 1',
        [lobby.id, userId],
      );

      if (lobby.status === 'playing' && existing.rowCount === 0) {
        reply.code(400);
        return { error: 'Game already started' };
      }

      // Auto-leave any other lobby
      await client.query(
        `UPDATE lobby_players lp SET status = 'left'
         FROM lobbies l
         WHERE lp.lobby_id = l.id
           AND lp.user_id = $1
           AND lp.status IN ('connected', 'disconnected')
           AND l.id != $2
           AND l.game_key = $3`,
        [userId, lobby.id, gameKey],
      );

      await client.query(
        `INSERT INTO lobby_players (lobby_id, user_id, display_name, avatar_emoji, is_host, status)
         VALUES ($1,$2,$3,$4,false,'connected')
         ON CONFLICT (lobby_id, user_id) DO UPDATE SET
           status = 'connected',
           display_name = EXCLUDED.display_name,
           avatar_emoji = EXCLUDED.avatar_emoji`,
        [lobby.id, userId, body.displayName, body.avatarEmoji],
      );

      const cntRes = await client.query(
        `SELECT COUNT(*)::int AS c FROM lobby_players WHERE lobby_id = $1 AND status = 'connected'`,
        [lobby.id],
      );
      const connectedCount = cntRes.rows[0]?.c ?? 0;

      // No auto-start — host must explicitly start the game via POST /lobby/:code/start

      const lobbyNow = await client.query('SELECT * FROM lobbies WHERE id = $1', [lobby.id]);
      return { lobby: lobbyNow.rows[0], round: null };
    });

    if ((out as any).error) return out;

    // Broadcast via the consistent room name
    await broadcastState(fastify, gameKey, body.code);
    const room = getLobbyRoom(gameKey, body.code);
    fastify.io.to(room).emit('player:joined', { gameKey, userId });

    return reply.send(out);
  };
}

function lobbyStateHandler(fixedGameKey?: string) {
  return async (req: FastifyRequest, reply: any) => {
    requireAuth(req);

    const gameKey = resolveGameKey(req, fixedGameKey);
    if (!ensureGameKey(gameKey, reply)) return;

    const code = (req.params as any).code as string;

    const client = await pool.connect();
    try {
      const state = await fetchLobbyStateByCode(client, { gameKey, code });
      if (!state) return reply.code(404).send({ error: 'Lobby not found' });

      const member = await client.query(
        `SELECT 1 FROM lobby_players WHERE lobby_id = $1 AND user_id = $2 AND status != 'left'`,
        [state.lobby.id, req.auth.userId],
      );
      if (member.rowCount === 0) return reply.code(403).send({ error: 'Forbidden' });

      return reply.send(state);
    } finally {
      client.release();
    }
  };
}

function leaveLobbyHandler(fastify: FastifyInstance, fixedGameKey?: string) {
  return async (req: FastifyRequest, reply: any) => {
    requireAuth(req);

    const gameKey = resolveGameKey(req, fixedGameKey);
    if (!ensureGameKey(gameKey, reply)) return;

    const code = (req.params as any).code as string;
    const userId = req.auth.userId;

    await withTx(async (client) => {
      const lobbyRes = await client.query(
        'SELECT * FROM lobbies WHERE game_key = $1 AND code = UPPER($2) FOR UPDATE LIMIT 1',
        [gameKey, code],
      );
      const lobby = lobbyRes.rows[0];
      if (!lobby) return reply.code(404).send({ error: 'Lobby not found' });

      await client.query(
        `UPDATE lobby_players SET status = 'left' WHERE lobby_id = $1 AND user_id = $2`,
        [lobby.id, userId],
      );

      // Check if leaving user was host
      const wasHost = await client.query(
        `SELECT is_host FROM lobby_players WHERE lobby_id = $1 AND user_id = $2`,
        [lobby.id, userId],
      );

      if (wasHost.rows[0]?.is_host) {
        // Find next connected player to be host
        const nextHost = await client.query(
          `SELECT user_id FROM lobby_players
           WHERE lobby_id = $1 AND status = 'connected' AND user_id != $2
           ORDER BY joined_at ASC LIMIT 1`,
          [lobby.id, userId],
        );

        if (nextHost.rowCount! > 0) {
          const newHostId = nextHost.rows[0].user_id;
          await client.query(`UPDATE lobby_players SET is_host = false WHERE lobby_id = $1`, [lobby.id]);
          await client.query(
            `UPDATE lobby_players SET is_host = true WHERE lobby_id = $1 AND user_id = $2`,
            [lobby.id, newHostId],
          );
          await client.query(`UPDATE lobbies SET host_id = $1 WHERE id = $2`, [newHostId, lobby.id]);
        }
      }

      // Check remaining connected
      const connRes = await client.query(
        `SELECT COUNT(*)::int AS c FROM lobby_players WHERE lobby_id = $1 AND status = 'connected'`,
        [lobby.id],
      );
      const connectedCount = connRes.rows[0]?.c ?? 0;

      if (connectedCount < 2 && lobby.status === 'playing') {
        await client.query(
          `UPDATE lobbies SET status = 'finished', ended_at = now() WHERE id = $1`,
          [lobby.id],
        );
      }
    });

    const room = getLobbyRoom(gameKey, code);
    fastify.io.to(room).emit('player:left', { gameKey, userId });

    await broadcastState(fastify, gameKey, code);

    return reply.send({ ok: true });
  };
}

function startGameHandler(fastify: FastifyInstance, fixedGameKey?: string) {
  return async (req: FastifyRequest, reply: any) => {
    requireAuth(req);

    const gameKey = resolveGameKey(req, fixedGameKey);
    if (!ensureGameKey(gameKey, reply)) return;

    const code = (req.params as any).code as string;
    const userId = req.auth.userId;

    const out = await withTx(async (client) => {
      const lobbyRes = await client.query(
        'SELECT * FROM lobbies WHERE game_key = $1 AND code = UPPER($2) FOR UPDATE LIMIT 1',
        [gameKey, code],
      );
      const lobby = lobbyRes.rows[0];
      if (!lobby) {
        reply.code(404);
        return { error: 'Lobby not found' };
      }

      if (lobby.status !== 'waiting') {
        reply.code(400);
        return { error: 'Lobby already started or finished' };
      }

      // Only host can start the game
      if (lobby.host_id !== userId) {
        reply.code(403);
        return { error: 'Only the host can start the game' };
      }

      const cntRes = await client.query(
        `SELECT COUNT(*)::int AS c FROM lobby_players WHERE lobby_id = $1 AND status = 'connected'`,
        [lobby.id],
      );
      const connectedCount = cntRes.rows[0]?.c ?? 0;

      if (connectedCount < 2) {
        reply.code(400);
        return { error: 'Need at least 2 players to start' };
      }

      // Transition to playing + create first round
      await client.query("UPDATE lobbies SET status = 'playing' WHERE id = $1", [lobby.id]);

      const lobbyRow: LobbyRow = {
        id: lobby.id,
        game_key: gameKey,
        host_id: lobby.host_id,
        status: 'playing',
        language: lobby.language,
        max_rounds: lobby.max_rounds,
        current_round: lobby.current_round,
        nsfw_enabled: lobby.nsfw_enabled,
        boldness_score: lobby.boldness_score,
        current_tone: lobby.current_tone,
        escalation_history: lobby.escalation_history ?? [],
        used_question_ids: lobby.used_question_ids ?? [],
      };

      const next = await engine.selectNextItem(client, lobbyRow, {
        nextRoundNumber: 1,
        playerCount: connectedCount,
        prevRound: null,
        prevHaveRatio: null,
      });

      const rRes = await client.query(
        `INSERT INTO rounds (lobby_id, game_key, round_number, question_text, question_source_id, tone, status, total_players, fallback_used, started_at)
         VALUES ($1,$2,$3,$4,$5,$6,'active',$7,$8,now())
         RETURNING *`,
        [
          lobby.id,
          gameKey,
          1,
          next.questionText,
          next.questionSourceId,
          next.newTone,
          connectedCount,
          next.fallbackUsed,
        ],
      );
      const round = rRes.rows[0];

      await client.query(
        `UPDATE lobbies SET
           current_round = $2,
           boldness_score = $3,
           current_tone = $4,
           escalation_history = $5::jsonb,
           used_question_ids = $6::text[]
         WHERE id = $1`,
        [lobby.id, 1, next.newBoldness, next.newTone, JSON.stringify(next.newHistory), next.usedIds],
      );

      if (next.questionSourceId) {
        await client.query(`UPDATE questions SET updated_at = now() WHERE id = $1`, [
          next.questionSourceId,
        ]);
      }

      const lobbyNow = await client.query('SELECT * FROM lobbies WHERE id = $1', [lobby.id]);
      return { lobby: lobbyNow.rows[0], round };
    });

    if ((out as any).error) return out;

    // Broadcast the playing state to all players in the room
    await broadcastState(fastify, gameKey, code);

    return reply.send(out);
  };
}

function answerHandler(fastify: FastifyInstance, fixedGameKey?: string) {
  return async (req: FastifyRequest, reply: any) => {
    requireAuth(req);

    const gameKey = resolveGameKey(req, fixedGameKey);
    if (!ensureGameKey(gameKey, reply)) return;

    const roundId = (req.params as any).roundId as string;
    const body = AnswerBody.parse(req.body ?? {});
    const userId = req.auth.userId;

    const answerBool = body.value === 'HAVE';

    const result = await withTx((client) =>
      engine.applyAnswer(client, {
        gameKey,
        roundId,
        userId,
        answer: answerBool,
      }),
    );

    if (!result.ok || !result.lobbyCode) {
      return reply.code(409).send({ ok: false });
    }

    await broadcastState(fastify, gameKey, result.lobbyCode);

    return reply.send({ ok: true });
  };
}

function advanceHandler(fastify: FastifyInstance, fixedGameKey?: string) {
  return async (req: FastifyRequest, reply: any) => {
    requireAuth(req);

    const gameKey = resolveGameKey(req, fixedGameKey);
    if (!ensureGameKey(gameKey, reply)) return;

    const roundId = (req.params as any).roundId as string;
    const userId = req.auth.userId;

    const result = await withTx((client) =>
      engine.advance(client, {
        gameKey,
        roundId,
        userId,
      }),
    );

    if (!result.ok) {
      if (result.reason === 'round_not_found') return reply.code(404).send(result);
      if (result.reason === 'forbidden') return reply.code(403).send(result);
      return reply.code(409).send(result);
    }

    if (result.lobbyCode) {
      await broadcastState(fastify, gameKey, result.lobbyCode);
    }

    return reply.send(result);
  };
}

export async function registerNeverHaveIeverRoutes(fastify: FastifyInstance) {
  const auth = { preHandler: [fastify.authenticate] };

  // Platform routes
  fastify.post('/v1/games/:gameKey/lobbies', {
    ...auth,
    config: { rateLimit: routeRateLimits.lobbyCreate },
  }, createLobbyHandler());

  fastify.post('/v1/games/:gameKey/lobbies/join', {
    ...auth,
    config: { rateLimit: routeRateLimits.lobbyJoin },
  }, joinLobbyHandler(fastify));

  fastify.get('/v1/games/:gameKey/lobbies/:code/state', auth, lobbyStateHandler());

  fastify.post('/v1/games/:gameKey/lobbies/:code/leave', auth, leaveLobbyHandler(fastify));

  fastify.post('/v1/games/:gameKey/lobbies/:code/start', auth, startGameHandler(fastify));

  fastify.post('/v1/games/:gameKey/rounds/:roundId/answer', {
    ...auth,
    config: { rateLimit: routeRateLimits.answer },
  }, answerHandler(fastify));

  fastify.post('/v1/games/:gameKey/rounds/:roundId/advance', {
    ...auth,
    config: { rateLimit: routeRateLimits.advance },
  }, advanceHandler(fastify));

  // Legacy compatibility endpoints (used by current Flutter client)
  fastify.post('/lobby/create', {
    ...auth,
    config: { rateLimit: routeRateLimits.lobbyCreate },
  }, createLobbyHandler(NEVER_HAVE_I_EVER_GAME_KEY));

  fastify.post('/lobby/join', {
    ...auth,
    config: { rateLimit: routeRateLimits.lobbyJoin },
  }, joinLobbyHandler(fastify, NEVER_HAVE_I_EVER_GAME_KEY));

  fastify.get('/lobby/:code/state', auth, lobbyStateHandler(NEVER_HAVE_I_EVER_GAME_KEY));

  fastify.post('/lobby/:code/leave', auth, leaveLobbyHandler(fastify, NEVER_HAVE_I_EVER_GAME_KEY));

  fastify.post('/lobby/:code/start', auth, startGameHandler(fastify, NEVER_HAVE_I_EVER_GAME_KEY));

  fastify.post('/round/:roundId/answer', {
    ...auth,
    config: { rateLimit: routeRateLimits.answer },
  }, answerHandler(fastify, NEVER_HAVE_I_EVER_GAME_KEY));

  fastify.post('/round/:roundId/advance', {
    ...auth,
    config: { rateLimit: routeRateLimits.advance },
  }, advanceHandler(fastify, NEVER_HAVE_I_EVER_GAME_KEY));
}
