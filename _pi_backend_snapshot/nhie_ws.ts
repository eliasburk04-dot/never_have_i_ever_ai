import type { FastifyInstance } from 'fastify';
import type { Namespace, Socket } from 'socket.io';

import { pool } from '../../platform/db/index.js';
import { fetchLobbyStateByCode, getLobbyRoom } from './selectors.js';
import { NEVER_HAVE_I_EVER_GAME_KEY } from './routes.js';

async function joinLobbyByCode(
  nsp: Namespace,
  socket: Socket,
  opts: { gameKey: string; lobbyCode: string },
): Promise<void> {
  const userId = (socket.data as any).userId as string;

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

    await client.query(`UPDATE lobby_players SET status = 'connected' WHERE lobby_id = $1 AND user_id = $2`, [
      lobby.id,
      userId,
    ]);

    const room = getLobbyRoom(opts.gameKey, lobby.code);
    socket.join(room);

    const state = await fetchLobbyStateByCode(client, { gameKey: opts.gameKey, code: lobby.code });
    if (state) {
      socket.emit('lobby:state', state);
      socket.emit('round:state', { round: state.round });
      socket.emit('answer:state', {
        gameKey: opts.gameKey,
        lobbyCode: state.lobby.code,
        lobbyId: state.lobby.id,
        roundId: state.round?.id,
        answers: state.answers,
        answered: state.answered,
      });
    }

    nsp.to(room).emit('player:joined', { gameKey: opts.gameKey, userId });
  } finally {
    client.release();
  }
}

export function registerNeverHaveIeverWsHandlers(nsp: Namespace, _fastify: FastifyInstance): void {
  nsp.on('connection', (socket: Socket) => {
    socket.on('lobby:join', async (payload: any) => {
      const gameKey = (payload?.gameKey as string | undefined) ?? NEVER_HAVE_I_EVER_GAME_KEY;
      if (gameKey !== NEVER_HAVE_I_EVER_GAME_KEY) return;

      let lobbyCode = (payload?.lobbyCode as string | undefined) ?? (payload?.code as string | undefined);

      // Compatibility: allow legacy payload { lobbyId } on same event.
      if (!lobbyCode && payload?.lobbyId) {
        const client = await pool.connect();
        try {
          const lookup = await client.query('SELECT code FROM lobbies WHERE id = $1 AND game_key = $2 LIMIT 1', [
            payload.lobbyId,
            gameKey,
          ]);
          lobbyCode = lookup.rows[0]?.code as string | undefined;
        } finally {
          client.release();
        }
      }

      if (!lobbyCode) return;

      await joinLobbyByCode(nsp, socket, { gameKey, lobbyCode });
    });

    socket.on('disconnect', async () => {
      const userId = (socket.data as any).userId as string;
      if (!userId) return;

      const client = await pool.connect();
      try {
        const rows = await client.query(
          `UPDATE lobby_players lp
           SET status = 'disconnected'
           FROM lobbies l
           WHERE lp.lobby_id = l.id
             AND lp.user_id = $1
             AND lp.status = 'connected'
             AND l.game_key = $2
           RETURNING l.code AS lobby_code, l.game_key`,
          [userId, NEVER_HAVE_I_EVER_GAME_KEY],
        );

        for (const row of rows.rows) {
          const room = getLobbyRoom(row.game_key as string, row.lobby_code as string);
          nsp.to(room).emit('player:left', { gameKey: row.game_key, userId });
        }
      } finally {
        client.release();
      }
    });
  });
}
