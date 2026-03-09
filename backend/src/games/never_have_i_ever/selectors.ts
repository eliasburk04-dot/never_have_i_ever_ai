import type pg from 'pg';

export type AnswerValue = 'HAVE' | 'HAVE_NOT' | null;

export interface LobbyState {
  lobby: any;
  players: any[];
  round: any | null;
  answers: Record<string, AnswerValue>;
  answered: Record<string, boolean>;
}

export function getLobbyRoom(gameKey: string, lobbyCode: string): string {
  return `game:${gameKey}:lobby:${lobbyCode.toUpperCase()}`;
}

export async function fetchLobbyStateByCode(
  client: pg.PoolClient,
  opts: { gameKey: string; code: string },
): Promise<LobbyState | null> {
  const lobbyRes = await client.query('SELECT * FROM lobbies WHERE game_key = $1 AND code = UPPER($2) LIMIT 1', [
    opts.gameKey,
    opts.code,
  ]);
  const lobby = lobbyRes.rows[0];
  if (!lobby) return null;
  const packIds = Array.isArray(lobby.pack_ids) ? lobby.pack_ids.map((value: unknown) => String(value)) : [];
  const customQuestions = Array.isArray(lobby.custom_questions)
    ? lobby.custom_questions.map((value: unknown) => String(value ?? '').trim()).filter(Boolean)
    : [];
  const { custom_questions: _customQuestions, ...lobbyRest } = lobby;
  const lobbyPayload = {
    ...lobbyRest,
    pack_ids: packIds,
    custom_questions_count: customQuestions.length,
  };

  const playersRes = await client.query(
    `SELECT lp.*, u.display_name AS user_display_name, u.avatar_emoji AS user_avatar_emoji
     FROM lobby_players lp
     JOIN users u ON u.id = lp.user_id
     WHERE lp.lobby_id = $1
     ORDER BY lp.joined_at ASC`,
    [lobby.id],
  );

  const players = playersRes.rows.map((p: any) => ({
    id: p.id,
    lobby_id: p.lobby_id,
    user_id: p.user_id,
    display_name: p.display_name ?? p.user_display_name,
    avatar_emoji: p.avatar_emoji ?? p.user_avatar_emoji,
    status: p.status,
    is_host: p.is_host,
    joined_at: p.joined_at,
  }));

  const roundRes = await client.query(
    `SELECT * FROM rounds
     WHERE lobby_id = $1 AND game_key = $2
     ORDER BY round_number DESC
     LIMIT 1`,
    [lobby.id, opts.gameKey],
  );
  const round = roundRes.rows[0] ?? null;

  const answers: Record<string, AnswerValue> = {};
  const answered: Record<string, boolean> = {};
  for (const p of players) {
    answers[p.user_id] = null;
    answered[p.user_id] = false;
  }

  if (round) {
    const ansRes = await client.query('SELECT user_id, answer FROM answers WHERE round_id = $1', [round.id]);
    for (const r of ansRes.rows) {
      answers[r.user_id] = r.answer ? 'HAVE' : 'HAVE_NOT';
      answered[r.user_id] = true;
    }
  }

  return { lobby: lobbyPayload, players, round, answers, answered };
}
