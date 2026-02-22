import type { FastifyInstance } from 'fastify';
import type { Namespace, Socket } from 'socket.io';

import { pool, withTx } from '../../platform/db/index.js';
import { fetchLobbyStateByCode, getLobbyRoom } from './selectors.js';
import { NEVER_HAVE_I_EVER_GAME_KEY } from './routes.js';

const HOST_DISCONNECT_GRACE_MS = 15_000; // 15s grace before host migration
const hostMigrationTimers = new Map<string, NodeJS.Timeout>();

async function joinLobbyByCode(
  nsp: Namespace,
  socket: Socket,
  opts: { gameKey: string; lobbyCode: string },
): Promise<void> {
  const userId = (socket.data as any).userId as string;
  if (!userId) return;

  const client = await pool.connect();
  try {
    const member = await client.query(
      `SELECT l.id, l.code
       FROM lobby_players lp
       JOIN lobbies l ON l.id = lp.lobby_id
       WHERE l.game_key = $1
         AND l.code = UPPER($2)
         AND lp.user_id = $3
         AND lp.status != 'left'
       LIMIT 1`,
      [opts.gameKey, opts.lobbyCode, userId],
    );

    if (member.rowCount === 0) return;

    const lobby = member.rows[0];

    await client.query(
      `UPDATE lobby_players SET status = 'connected' WHERE lobby_id = $1 AND user_id = $2`,
      [lobby.id, userId],
    );

    // Cancel any pending host migration if this user is the host reconnecting
    const timerKey = `${lobby.id}:${userId}`;
    const existingTimer = hostMigrationTimers.get(timerKey);
    if (existingTimer) {
      clearTimeout(existingTimer);
      hostMigrationTimers.delete(timerKey);
    }

    const room = getLobbyRoom(opts.gameKey, lobby.code);

    // Leave all other lobby rooms first (prevents multi-lobby)
    for (const r of socket.rooms) {
      if (r !== socket.id && r.startsWith('game:')) {
        socket.leave(r);
      }
    }

    socket.join(room);

    // Store lobby info on socket for disconnect handler
    (socket.data as any).lobbyId = lobby.id;
    (socket.data as any).lobbyCode = lobby.code;
    (socket.data as any).gameKey = opts.gameKey;

    const state = await fetchLobbyStateByCode(client, { gameKey: opts.gameKey, code: lobby.code });
    if (state) {
      socket.emit('lobby:state', state);
      if (state.round) {
        socket.emit('round:state', { round: state.round });
      }
      socket.emit('answer:state', {
        gameKey: opts.gameKey,
        lobbyCode: state.lobby.code,
        lobbyId: state.lobby.id,
        roundId: state.round?.id ?? null,
        answers: state.answers,
        answered: state.answered,
      });
    }

    nsp.to(room).emit('player:joined', { gameKey: opts.gameKey, userId });
  } finally {
    client.release();
  }
}

async function handleDisconnect(nsp: Namespace, socket: Socket): Promise<void> {
  const userId = (socket.data as any).userId as string;
  if (!userId) return;

  const gameKey = NEVER_HAVE_I_EVER_GAME_KEY;

  const client = await pool.connect();
  try {
    // Mark all connected lobby_players for this user as disconnected
    const rows = await client.query(
      `UPDATE lobby_players lp
       SET status = 'disconnected'
       FROM lobbies l
       WHERE lp.lobby_id = l.id
         AND lp.user_id = $1
         AND lp.status = 'connected'
         AND l.game_key = $2
       RETURNING l.id AS lobby_id, l.code AS lobby_code, l.game_key, lp.is_host`,
      [userId, gameKey],
    );

    for (const row of rows.rows) {
      const room = getLobbyRoom(row.game_key as string, row.lobby_code as string);
      nsp.to(room).emit('player:left', { gameKey: row.game_key, userId });

      // If this was the host, schedule host migration after grace period
      if (row.is_host) {
        const timerKey = `${row.lobby_id}:${userId}`;
        // Clear any existing timer
        const existing = hostMigrationTimers.get(timerKey);
        if (existing) clearTimeout(existing);

        const timer = setTimeout(async () => {
          hostMigrationTimers.delete(timerKey);
          await migrateHost(nsp, row.lobby_id, row.lobby_code, row.game_key);
        }, HOST_DISCONNECT_GRACE_MS);

        hostMigrationTimers.set(timerKey, timer);
      }

      // Check if lobby should auto-end (fewer than 2 connected players)
      const connectedRes = await client.query(
        `SELECT COUNT(*)::int AS c FROM lobby_players WHERE lobby_id = $1 AND status = 'connected'`,
        [row.lobby_id],
      );
      const connectedCount = connectedRes.rows[0]?.c ?? 0;

      if (connectedCount < 1) {
        // All players disconnected — mark lobby as cancelled after a longer grace
        // (they might all reconnect)
        // For now, just broadcast the updated state
      }

      // Re-broadcast state to remaining players
      const state = await fetchLobbyStateByCode(client, {
        gameKey: row.game_key,
        code: row.lobby_code,
      });
      if (state) {
        nsp.to(room).emit('lobby:state', state);
      }
    }
  } finally {
    client.release();
  }
}

async function migrateHost(
  nsp: Namespace,
  lobbyId: string,
  lobbyCode: string,
  gameKey: string,
): Promise<void> {
  const client = await pool.connect();
  try {
    // Check if old host has reconnected
    const currentHost = await client.query(
      `SELECT lp.user_id, lp.status FROM lobby_players lp
       WHERE lp.lobby_id = $1 AND lp.is_host = true LIMIT 1`,
      [lobbyId],
    );
    if (currentHost.rows[0]?.status === 'connected') {
      // Host reconnected, no migration needed
      return;
    }

    // Find the next eligible host (earliest joined, still connected)
    const nextHost = await client.query(
      `SELECT user_id FROM lobby_players
       WHERE lobby_id = $1 AND status = 'connected'
       ORDER BY joined_at ASC
       LIMIT 1`,
      [lobbyId],
    );

    if (nextHost.rowCount === 0) {
      // No connected players, no migration possible
      return;
    }

    const newHostUserId = nextHost.rows[0].user_id;

    // Atomic host transfer
    await client.query(`UPDATE lobby_players SET is_host = false WHERE lobby_id = $1`, [lobbyId]);
    await client.query(`UPDATE lobby_players SET is_host = true WHERE lobby_id = $1 AND user_id = $2`, [
      lobbyId,
      newHostUserId,
    ]);
    await client.query(`UPDATE lobbies SET host_id = $1 WHERE id = $2`, [newHostUserId, lobbyId]);

    // Broadcast updated state
    const room = getLobbyRoom(gameKey, lobbyCode);
    const state = await fetchLobbyStateByCode(client, { gameKey, code: lobbyCode });
    if (state) {
      nsp.to(room).emit('lobby:state', state);
    }
  } finally {
    client.release();
  }
}

async function handleLeaveLobby(
  nsp: Namespace,
  socket: Socket,
  payload: any,
): Promise<void> {
  const userId = (socket.data as any).userId as string;
  if (!userId) return;

  const gameKey = NEVER_HAVE_I_EVER_GAME_KEY;

  await withTx(async (client) => {
    let lobbyCode = payload?.lobbyCode as string | undefined;
    let lobbyId = payload?.lobbyId as string | undefined;

    // Resolve lobbyCode from lobbyId if needed
    if (!lobbyCode && lobbyId) {
      const lookup = await client.query(
        'SELECT code FROM lobbies WHERE id = $1 AND game_key = $2 LIMIT 1',
        [lobbyId, gameKey],
      );
      lobbyCode = lookup.rows[0]?.code as string | undefined;
    }

    // If still no lobby code, find any lobby this user is in
    if (!lobbyCode) {
      const lookup = await client.query(
        `SELECT l.code, l.id FROM lobby_players lp
         JOIN lobbies l ON l.id = lp.lobby_id
         WHERE lp.user_id = $1 AND lp.status != 'left' AND l.game_key = $2
         LIMIT 1`,
        [userId, gameKey],
      );
      lobbyCode = lookup.rows[0]?.code as string | undefined;
      lobbyId = lookup.rows[0]?.id as string | undefined;
    }

    if (!lobbyCode) return;

    // Get lobby id if we don't have it
    if (!lobbyId) {
      const lookup = await client.query(
        'SELECT id FROM lobbies WHERE game_key = $1 AND code = UPPER($2) LIMIT 1',
        [gameKey, lobbyCode],
      );
      lobbyId = lookup.rows[0]?.id as string | undefined;
    }
    if (!lobbyId) return;

    // Mark player as left
    await client.query(
      `UPDATE lobby_players SET status = 'left' WHERE lobby_id = $1 AND user_id = $2`,
      [lobbyId, userId],
    );

    // Check if this was the host
    const wasHost = await client.query(
      `SELECT is_host FROM lobby_players WHERE lobby_id = $1 AND user_id = $2`,
      [lobbyId, userId],
    );

    const room = getLobbyRoom(gameKey, lobbyCode);
    socket.leave(room);

    nsp.to(room).emit('player:left', { gameKey, userId });

    if (wasHost.rows[0]?.is_host) {
      await migrateHost(nsp, lobbyId, lobbyCode, gameKey);
    }

    // Check remaining connected players
    const connRes = await client.query(
      `SELECT COUNT(*)::int AS c FROM lobby_players WHERE lobby_id = $1 AND status = 'connected'`,
      [lobbyId],
    );
    const connectedCount = connRes.rows[0]?.c ?? 0;

    if (connectedCount < 2) {
      // Check lobby status — if playing, end the game
      const lobbyRes = await client.query('SELECT status FROM lobbies WHERE id = $1', [lobbyId]);
      if (lobbyRes.rows[0]?.status === 'playing') {
        await client.query(
          `UPDATE lobbies SET status = 'finished', ended_at = now() WHERE id = $1`,
          [lobbyId],
        );
      }
    }

    // Broadcast updated state
    const state = await fetchLobbyStateByCode(client, { gameKey, code: lobbyCode });
    if (state) {
      nsp.to(room).emit('lobby:state', state);
    }
  });
}

export function registerNeverHaveIeverWsHandlers(nsp: Namespace, _fastify: FastifyInstance): void {
  nsp.on('connection', (socket: Socket) => {
    socket.on('lobby:join', async (payload: any) => {
      try {
        const gameKey = (payload?.gameKey as string | undefined) ?? NEVER_HAVE_I_EVER_GAME_KEY;
        if (gameKey !== NEVER_HAVE_I_EVER_GAME_KEY) return;

        let lobbyCode = (payload?.lobbyCode as string | undefined) ?? (payload?.code as string | undefined);

        // Compatibility: allow legacy payload { lobbyId } on same event.
        if (!lobbyCode && payload?.lobbyId) {
          const client = await pool.connect();
          try {
            const lookup = await client.query(
              `SELECT code FROM lobbies WHERE id = $1 AND game_key = $2 LIMIT 1`,
              [payload.lobbyId, gameKey],
            );
            lobbyCode = lookup.rows[0]?.code as string | undefined;

            // Fallback: try without game_key filter for legacy lobbies
            if (!lobbyCode) {
              const fallback = await client.query(
                'SELECT code FROM lobbies WHERE id = $1 LIMIT 1',
                [payload.lobbyId],
              );
              lobbyCode = fallback.rows[0]?.code as string | undefined;

              // Fix: set game_key on legacy lobby if missing
              if (lobbyCode) {
                await client.query(
                  `UPDATE lobbies SET game_key = $1 WHERE id = $2 AND game_key IS NULL`,
                  [gameKey, payload.lobbyId],
                );
              }
            }
          } finally {
            client.release();
          }
        }

        if (!lobbyCode) return;

        await joinLobbyByCode(nsp, socket, { gameKey, lobbyCode });
      } catch (err) {
        console.error('[ws] lobby:join error', err);
      }
    });

    socket.on('lobby:leave', async (payload: any) => {
      try {
        await handleLeaveLobby(nsp, socket, payload);
      } catch (err) {
        console.error('[ws] lobby:leave error', err);
      }
    });

    socket.on('disconnect', async () => {
      try {
        await handleDisconnect(nsp, socket);
      } catch (err) {
        console.error('[ws] disconnect error', err);
      }
    });
  });
}
