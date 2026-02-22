import type { FastifyInstance, FastifyRequest } from 'fastify';
import { z } from 'zod';
import { withTx, pool } from '../db.js';
import { generateLobbyCode } from '../game/code.js';
import { fetchLobbyStateByCode } from '../game/state.js';
import { buildNextRound, type LobbyRow } from '../game/nextRound.js';

const CreateBody = z.object({
  language: z.enum(['en', 'de', 'es']).default('en'),
  maxRounds: z.number().int().min(10).max(100).default(20),
  nsfwEnabled: z.boolean().default(false),
  displayName: z.string().min(1).max(40).optional(),
  avatarEmoji: z.string().min(1).max(16).optional(),
});

const JoinBody = z.object({
  code: z.string().min(3).max(12),
  displayName: z.string().min(1).max(40),
  avatarEmoji: z.string().min(1).max(16),
});

async function requireAuth(req: FastifyRequest) {
  if (!req.auth?.userId) throw new Error('unauthenticated');
}

export async function registerLobbyRoutes(fastify: FastifyInstance) {
  fastify.post('/lobby/create', { preHandler: [fastify.authenticate] }, async (req, reply) => {
    await requireAuth(req);
    const body = CreateBody.parse(req.body ?? {});

    const hostId = req.auth.userId;

    const lobby = await withTx(async (client) => {
      // Update user profile (best-effort)
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
      for (let attempt = 0; attempt < 5; attempt++) {
        code = generateLobbyCode();
        const exists = await client.query(
          `SELECT id FROM lobbies WHERE code = $1 AND status IN ('waiting','playing') LIMIT 1`,
          [code],
        );
        if (exists.rowCount === 0) break;
        code = '';
      }
      if (!code) {
        reply.code(500);
        return reply.send({ error: 'Failed to generate unique code' });
      }

      const lobbyRes = await client.query(
        `INSERT INTO lobbies (code, host_id, language, max_rounds, nsfw_enabled)
         VALUES ($1,$2,$3,$4,$5)
         RETURNING *`,
        [code, hostId, body.language, body.maxRounds, body.nsfwEnabled],
      );
      const l = lobbyRes.rows[0];

      await client.query(
        `INSERT INTO lobby_players (lobby_id, user_id, display_name, avatar_emoji, is_host, status)
         VALUES ($1,$2,COALESCE($3,'Host'),COALESCE($4,'👑'),true,'connected')
         ON CONFLICT (lobby_id, user_id) DO UPDATE SET
           status = 'connected',
           is_host = true,
           display_name = EXCLUDED.display_name,
           avatar_emoji = EXCLUDED.avatar_emoji`,
        [l.id, hostId, body.displayName ?? 'Host', body.avatarEmoji ?? '👑'],
      );

      return l;
    });

    return reply.code(201).send({ lobby });
  });

  fastify.post('/lobby/join', { preHandler: [fastify.authenticate] }, async (req, reply) => {
    await requireAuth(req);
    const body = JoinBody.parse(req.body ?? {});
    const userId = req.auth.userId;

    const out = await withTx(async (client) => {
      const lobbyRes = await client.query('SELECT * FROM lobbies WHERE code = UPPER($1) LIMIT 1', [body.code]);
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
        'SELECT * FROM lobby_players WHERE lobby_id = $1 AND user_id = $2 LIMIT 1',
        [lobby.id, userId],
      );

      if (lobby.status === 'playing' && existing.rowCount === 0) {
        reply.code(400);
        return { error: 'Game already started' };
      }

      await client.query(
        `INSERT INTO lobby_players (lobby_id, user_id, display_name, avatar_emoji, is_host, status)
         VALUES ($1,$2,$3,$4,false,'connected')
         ON CONFLICT (lobby_id, user_id) DO UPDATE SET
           status = 'connected',
           display_name = EXCLUDED.display_name,
           avatar_emoji = EXCLUDED.avatar_emoji`,
        [lobby.id, userId, body.displayName, body.avatarEmoji],
      );

      // Auto-start the game when the 2nd player joins.
      const cntRes = await client.query(
        `SELECT COUNT(*)::int AS c FROM lobby_players WHERE lobby_id = $1 AND status = 'connected'`,
        [lobby.id],
      );
      const connectedCount = cntRes.rows[0]?.c ?? 0;

      let round: any | null = null;

      if (lobby.status === 'waiting' && connectedCount >= 2) {
        // Transition lobby to playing if no rounds exist yet.
        const roundExists = await client.query(
          `SELECT 1 FROM rounds WHERE lobby_id = $1 LIMIT 1`,
          [lobby.id],
        );

        if (roundExists.rowCount === 0) {
          await client.query(`UPDATE lobbies SET status = 'playing' WHERE id = $1`, [lobby.id]);

          const lobbyRow: LobbyRow = {
            id: lobby.id,
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

          const next = await buildNextRound(client, lobbyRow, {
            nextRoundNumber: 1,
            playerCount: connectedCount,
            prevRound: null,
            prevHaveRatio: null,
          });

          const rRes = await client.query(
            `INSERT INTO rounds (lobby_id, round_number, question_text, question_source_id, tone, status, total_players, fallback_used, started_at)
             VALUES ($1,$2,$3,$4,$5,'active',$6,$7,now())
             RETURNING *`,
            [lobby.id, 1, next.questionText, next.questionSourceId, next.newTone, connectedCount, next.fallbackUsed],
          );
          round = rRes.rows[0];

          await client.query(
            `UPDATE lobbies SET
               current_round = $2,
               boldness_score = $3,
               current_tone = $4,
               escalation_history = $5::jsonb,
               used_question_ids = $6::uuid[]
             WHERE id = $1`,
            [lobby.id, 1, next.newBoldness, next.newTone, JSON.stringify(next.newHistory), next.usedIds],
          );

          if (next.questionSourceId) {
            await client.query(`UPDATE question_pool SET times_used = times_used + 1 WHERE id = $1`, [next.questionSourceId]);
          }
        }
      }

      const lobbyNow = await client.query('SELECT * FROM lobbies WHERE id = $1', [lobby.id]);
      return { lobby: lobbyNow.rows[0], round };
    });

    if ((out as any).error) return out;

    // Broadcast updated state
    const state = await pool.connect().then(async (c) => {
      try {
        const s = await fetchLobbyStateByCode(c, body.code);
        return s;
      } finally {
        c.release();
      }
    });

    if (state) {
      const room = `lobby:${state.lobby.id}`;
      fastify.io.to(room).emit('lobby:state', state);
      fastify.io.to(room).emit('player:joined', { userId });
      if ((out as any).round) fastify.io.to(room).emit('round:state', { round: (out as any).round });
    }

    return reply.send(out);
  });

  fastify.get('/lobby/:code/state', { preHandler: [fastify.authenticate] }, async (req, reply) => {
    await requireAuth(req);

    const code = (req.params as any).code as string;

    const client = await pool.connect();
    try {
      const state = await fetchLobbyStateByCode(client, code);
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
  });
}
