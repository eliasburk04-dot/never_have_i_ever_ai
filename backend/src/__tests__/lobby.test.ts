/**
 * Backend Lobby Unit Tests
 *
 * These tests verify lobby invariants without requiring a running server.
 * They can be run with: npx tsx --test src/__tests__/lobby.test.ts
 * Or adapted for any test runner (vitest, jest, node:test).
 *
 * NOTE: These tests require pg-mem or a test database.
 * For CI without DB, mock the pool/client.
 */

import { describe, it, beforeEach, afterEach, mock } from 'node:test';
import assert from 'node:assert/strict';

// ─── Types ─────────────────────────────────────────────

interface Player {
  id: string;
  lobby_id: string;
  user_id: string;
  display_name: string;
  avatar_emoji: string;
  is_host: boolean;
  status: 'connected' | 'disconnected' | 'left';
  joined_at: Date;
}

interface Lobby {
  id: string;
  game_key: string;
  code: string;
  host_id: string;
  status: 'waiting' | 'playing' | 'finished' | 'cancelled';
  max_rounds: number;
  current_round: number;
  min_players_to_start: number;
}

// ─── In-Memory Lobby Manager (mirrors server logic) ────

class LobbyManager {
  private lobbies = new Map<string, Lobby>();
  private players = new Map<string, Player[]>();
  private nextId = 1;

  createLobby(hostId: string, code: string, minPlayersToStart = 2): Lobby {
    // Invariant: auto-leave any existing lobby
    this.autoLeaveExistingLobbies(hostId);

    const lobby: Lobby = {
      id: `lobby-${this.nextId++}`,
      game_key: 'never_have_i_ever',
      code: code.toUpperCase(),
      host_id: hostId,
      status: 'waiting',
      max_rounds: 20,
      current_round: 0,
      min_players_to_start: minPlayersToStart,
    };
    this.lobbies.set(lobby.id, lobby);

    const player: Player = {
      id: `player-${this.nextId++}`,
      lobby_id: lobby.id,
      user_id: hostId,
      display_name: 'Host',
      avatar_emoji: '👑',
      is_host: true,
      status: 'connected',
      joined_at: new Date(),
    };
    this.players.set(lobby.id, [player]);

    return lobby;
  }

  joinLobby(
    lobbyCode: string,
    userId: string,
    displayName: string,
  ): { lobby: Lobby; error?: string } {
    const lobby = this.findByCode(lobbyCode);
    if (!lobby) return { lobby: null as any, error: 'Lobby not found' };
    if (!['waiting', 'playing'].includes(lobby.status))
      return { lobby, error: 'Lobby not joinable' };

    const players = this.players.get(lobby.id) ?? [];
    const existing = players.find((p) => p.user_id === userId);

    if (lobby.status === 'playing' && !existing) {
      return { lobby, error: 'Game already started' };
    }

    // Auto-leave other lobbies
    this.autoLeaveExistingLobbies(userId, lobby.id);

    if (existing) {
      // Re-connect
      existing.status = 'connected';
      existing.display_name = displayName;
    } else {
      players.push({
        id: `player-${this.nextId++}`,
        lobby_id: lobby.id,
        user_id: userId,
        display_name: displayName,
        avatar_emoji: '🙂',
        is_host: false,
        status: 'connected',
        joined_at: new Date(),
      });
      this.players.set(lobby.id, players);
    }

    // Auto-start
    const connectedCount = this.getConnectedCount(lobby.id);
    if (lobby.status === 'waiting' && connectedCount >= lobby.min_players_to_start) {
      lobby.status = 'playing';
      lobby.current_round = 1;
    }

    return { lobby };
  }

  leaveLobby(lobbyId: string, userId: string): void {
    const players = this.players.get(lobbyId);
    if (!players) return;

    const player = players.find((p) => p.user_id === userId);
    if (!player) return;

    const wasHost = player.is_host;
    player.status = 'left';

    if (wasHost) {
      this.migrateHost(lobbyId);
    }

    // Auto-end if < 2 connected
    const lobby = this.lobbies.get(lobbyId);
    if (lobby && lobby.status === 'playing' && this.getConnectedCount(lobbyId) < 2) {
      lobby.status = 'finished';
    }
  }

  disconnect(userId: string): string[] {
    const affectedLobbies: string[] = [];

    for (const [lobbyId, players] of this.players) {
      const player = players.find(
        (p) => p.user_id === userId && p.status === 'connected',
      );
      if (player) {
        player.status = 'disconnected';
        affectedLobbies.push(lobbyId);
      }
    }

    return affectedLobbies;
  }

  migrateHost(lobbyId: string): void {
    const players = this.players.get(lobbyId);
    if (!players) return;

    const currentHost = players.find((p) => p.is_host);
    if (currentHost?.status === 'connected') return; // No migration needed

    // Clear all host flags
    players.forEach((p) => (p.is_host = false));

    // Find next connected player (earliest joined)
    const connected = players
      .filter((p) => p.status === 'connected')
      .sort((a, b) => a.joined_at.getTime() - b.joined_at.getTime());

    if (connected.length > 0) {
      connected[0].is_host = true;
      const lobby = this.lobbies.get(lobbyId);
      if (lobby) lobby.host_id = connected[0].user_id;
    }
  }

  // ─── Helpers ─────────────────────────────────────

  findByCode(code: string): Lobby | undefined {
    return [...this.lobbies.values()].find(
      (l) => l.code === code.toUpperCase(),
    );
  }

  getConnectedCount(lobbyId: string): number {
    return (this.players.get(lobbyId) ?? []).filter(
      (p) => p.status === 'connected',
    ).length;
  }

  getPlayers(lobbyId: string): Player[] {
    return this.players.get(lobbyId) ?? [];
  }

  getLobby(lobbyId: string): Lobby | undefined {
    return this.lobbies.get(lobbyId);
  }

  getHosts(lobbyId: string): Player[] {
    return (this.players.get(lobbyId) ?? []).filter((p) => p.is_host);
  }

  private autoLeaveExistingLobbies(userId: string, exceptLobbyId?: string): void {
    for (const [lobbyId, players] of this.players) {
      if (lobbyId === exceptLobbyId) continue;
      const player = players.find(
        (p) => p.user_id === userId && ['connected', 'disconnected'].includes(p.status),
      );
      if (player) {
        player.status = 'left';
      }
    }
  }
}

// ─── Tests ─────────────────────────────────────────────

describe('LobbyManager', () => {
  let mgr: LobbyManager;

  beforeEach(() => {
    mgr = new LobbyManager();
  });

  // ─── createLobby ─────────────────────────────────

  describe('createLobby', () => {
    it('creates lobby with host as only player', () => {
      const lobby = mgr.createLobby('user-1', 'ABC123');
      assert.equal(lobby.status, 'waiting');
      assert.equal(lobby.host_id, 'user-1');
      assert.equal(lobby.code, 'ABC123');

      const players = mgr.getPlayers(lobby.id);
      assert.equal(players.length, 1);
      assert.equal(players[0].is_host, true);
      assert.equal(players[0].status, 'connected');
    });

    it('auto-leaves previous lobby when creating new one', () => {
      const lobby1 = mgr.createLobby('user-1', 'AAA111');
      const lobby2 = mgr.createLobby('user-1', 'BBB222');

      const p1 = mgr.getPlayers(lobby1.id);
      assert.equal(p1[0].status, 'left');

      const p2 = mgr.getPlayers(lobby2.id);
      assert.equal(p2[0].status, 'connected');
    });
  });

  // ─── joinLobby ──────────────────────────────────

  describe('joinLobby', () => {
    it('second player triggers auto-start', () => {
      const lobby = mgr.createLobby('user-1', 'ABC123');
      const result = mgr.joinLobby('ABC123', 'user-2', 'Player2');

      assert.equal(result.error, undefined);
      assert.equal(result.lobby.status, 'playing');
      assert.equal(mgr.getConnectedCount(lobby.id), 2);
    });

    it('returns error for non-existent lobby', () => {
      const result = mgr.joinLobby('NONEXIST', 'user-2', 'Player2');
      assert.equal(result.error, 'Lobby not found');
    });

    it('prevents new player from joining a playing lobby', () => {
      mgr.createLobby('user-1', 'ABC123');
      mgr.joinLobby('ABC123', 'user-2', 'Player2'); // starts game

      const result = mgr.joinLobby('ABC123', 'user-3', 'Player3');
      assert.equal(result.error, 'Game already started');
    });

    it('allows re-join of existing player in playing lobby', () => {
      const lobby = mgr.createLobby('user-1', 'ABC123');
      mgr.joinLobby('ABC123', 'user-2', 'Player2');
      mgr.disconnect('user-2');

      const result = mgr.joinLobby('ABC123', 'user-2', 'Player2-reconnect');
      assert.equal(result.error, undefined);
      assert.equal(mgr.getConnectedCount(lobby.id), 2);
    });

    it('duplicate join is idempotent', () => {
      const lobby = mgr.createLobby('user-1', 'ABC123');
      mgr.joinLobby('ABC123', 'user-2', 'Player2');
      mgr.joinLobby('ABC123', 'user-2', 'Player2'); // duplicate

      const players = mgr.getPlayers(lobby.id);
      const user2 = players.filter((p) => p.user_id === 'user-2');
      assert.equal(user2.length, 1); // still just one player entry
      assert.equal(user2[0].status, 'connected');
    });

    it('auto-leaves other lobby when joining new one', () => {
      const lobby1 = mgr.createLobby('user-1', 'AAA111');
      mgr.joinLobby('AAA111', 'user-2', 'P2');

      const lobby2 = mgr.createLobby('user-3', 'BBB222');
      mgr.joinLobby('BBB222', 'user-2', 'P2'); // user-2 joins different lobby

      const p1 = mgr.getPlayers(lobby1.id);
      const user2InLobby1 = p1.find((p) => p.user_id === 'user-2');
      assert.equal(user2InLobby1?.status, 'left');

      const p2 = mgr.getPlayers(lobby2.id);
      const user2InLobby2 = p2.find((p) => p.user_id === 'user-2');
      assert.equal(user2InLobby2?.status, 'connected');
    });
  });

  // ─── leaveLobby ─────────────────────────────────

  describe('leaveLobby', () => {
    it('marks player as left', () => {
      // Use minPlayersToStart=4 so lobby stays 'waiting' while we add 3 players
      const lobby = mgr.createLobby('user-1', 'ABC123', 4);
      mgr.joinLobby('ABC123', 'user-2', 'P2');
      mgr.joinLobby('ABC123', 'user-3', 'P3');

      mgr.leaveLobby(lobby.id, 'user-3');

      const players = mgr.getPlayers(lobby.id);
      const p3 = players.find((p) => p.user_id === 'user-3');
      assert.ok(p3, 'user-3 should exist in players');
      assert.equal(p3!.status, 'left');
    });

    it('host leave triggers host migration', () => {
      // Use minPlayersToStart=4 so lobby stays 'waiting' while we add 3 players
      const lobby = mgr.createLobby('user-1', 'ABC123', 4);
      mgr.joinLobby('ABC123', 'user-2', 'P2');
      mgr.joinLobby('ABC123', 'user-3', 'P3');

      mgr.leaveLobby(lobby.id, 'user-1'); // host leaves

      const hosts = mgr.getHosts(lobby.id);
      assert.equal(hosts.length, 1);
      assert.notEqual(hosts[0].user_id, 'user-1');
      assert.equal(hosts[0].status, 'connected');

      // Lobby host_id should be updated
      const updatedLobby = mgr.getLobby(lobby.id);
      assert.notEqual(updatedLobby?.host_id, 'user-1');
    });

    it('game ends when less than 2 connected players during playing', () => {
      const lobby = mgr.createLobby('user-1', 'ABC123');
      mgr.joinLobby('ABC123', 'user-2', 'P2');
      // lobby is now 'playing'

      mgr.leaveLobby(lobby.id, 'user-2');

      const updatedLobby = mgr.getLobby(lobby.id);
      assert.equal(updatedLobby?.status, 'finished');
    });
  });

  // ─── disconnect ─────────────────────────────────

  describe('disconnect', () => {
    it('marks player as disconnected', () => {
      const lobby = mgr.createLobby('user-1', 'ABC123');
      mgr.joinLobby('ABC123', 'user-2', 'P2');

      mgr.disconnect('user-2');

      const p2 = mgr.getPlayers(lobby.id).find((p) => p.user_id === 'user-2');
      assert.equal(p2?.status, 'disconnected');
    });

    it('returns affected lobby IDs', () => {
      const lobby = mgr.createLobby('user-1', 'ABC123');
      mgr.joinLobby('ABC123', 'user-2', 'P2');

      const affected = mgr.disconnect('user-2');
      assert.equal(affected.length, 1);
      assert.equal(affected[0], lobby.id);
    });

    it('disconnect + reconnect preserves player', () => {
      const lobby = mgr.createLobby('user-1', 'ABC123');
      mgr.joinLobby('ABC123', 'user-2', 'P2');

      mgr.disconnect('user-2');
      mgr.joinLobby('ABC123', 'user-2', 'P2');

      const p2 = mgr.getPlayers(lobby.id).find((p) => p.user_id === 'user-2');
      assert.equal(p2?.status, 'connected');
      assert.equal(mgr.getConnectedCount(lobby.id), 2);
    });
  });

  // ─── Host election ──────────────────────────────

  describe('host migration', () => {
    it('exactly one host at all times', () => {
      // Use minPlayersToStart=4 so lobby stays 'waiting' while we add 3 players
      const lobby = mgr.createLobby('user-1', 'ABC123', 4);
      mgr.joinLobby('ABC123', 'user-2', 'P2');
      mgr.joinLobby('ABC123', 'user-3', 'P3');

      // Initially: one host
      let hosts = mgr.getHosts(lobby.id);
      assert.equal(hosts.length, 1);

      // After host disconnect + migration
      mgr.disconnect('user-1');
      mgr.migrateHost(lobby.id);

      hosts = mgr.getHosts(lobby.id);
      assert.equal(hosts.length, 1);
      assert.equal(hosts[0].status, 'connected');
    });

    it('migrates to earliest joined connected player', () => {
      // Use minPlayersToStart=4 so lobby stays 'waiting' while we add 3 players
      const lobby = mgr.createLobby('user-1', 'ABC123', 4);

      // user-2 joins first, then user-3
      mgr.joinLobby('ABC123', 'user-2', 'P2');
      mgr.joinLobby('ABC123', 'user-3', 'P3');

      mgr.disconnect('user-1');
      mgr.migrateHost(lobby.id);

      const hosts = mgr.getHosts(lobby.id);
      assert.equal(hosts[0].user_id, 'user-2');
    });

    it('no migration if host is still connected', () => {
      const lobby = mgr.createLobby('user-1', 'ABC123');
      mgr.joinLobby('ABC123', 'user-2', 'P2');

      mgr.migrateHost(lobby.id); // host is connected, no-op

      const hosts = mgr.getHosts(lobby.id);
      assert.equal(hosts.length, 1);
      assert.equal(hosts[0].user_id, 'user-1');
    });
  });

  // ─── Invariant: User in max 1 lobby ─────────────

  describe('invariant: max 1 lobby per user', () => {
    it('creating second lobby leaves first', () => {
      mgr.createLobby('user-1', 'AAA111');
      mgr.createLobby('user-1', 'BBB222');

      const all = [...new Set([
        ...mgr.getPlayers(mgr.findByCode('AAA111')!.id),
        ...mgr.getPlayers(mgr.findByCode('BBB222')!.id),
      ])];

      const activeEntries = all.filter(
        (p) => p.user_id === 'user-1' && p.status === 'connected',
      );
      assert.equal(activeEntries.length, 1);
    });

    it('joining second lobby leaves first', () => {
      const l1 = mgr.createLobby('user-a', 'AAA111');
      mgr.joinLobby('AAA111', 'user-x', 'X');

      const l2 = mgr.createLobby('user-b', 'BBB222');
      mgr.joinLobby('BBB222', 'user-x', 'X');

      const inL1 = mgr.getPlayers(l1.id).find((p) => p.user_id === 'user-x');
      const inL2 = mgr.getPlayers(l2.id).find((p) => p.user_id === 'user-x');

      assert.equal(inL1?.status, 'left');
      assert.equal(inL2?.status, 'connected');
    });
  });

  // ─── Concurrency scenarios ──────────────────────

  describe('concurrency scenarios (sequential simulation)', () => {
    it('two joins simultaneously: both succeed, game starts once', () => {
      // Use minPlayersToStart=3 so game starts only after both join
      const lobby = mgr.createLobby('user-host', 'CONC01', 3);

      // Simulate two near-simultaneous joins (sequential in-memory)
      mgr.joinLobby('CONC01', 'user-a', 'A');
      mgr.joinLobby('CONC01', 'user-b', 'B');

      const l = mgr.getLobby(lobby.id);
      assert.equal(l?.status, 'playing');
      assert.equal(l?.current_round, 1);
      assert.equal(mgr.getConnectedCount(lobby.id), 3);
    });

    it('join + leave: player count remains consistent', () => {
      const lobby = mgr.createLobby('user-host', 'CONC02');
      mgr.joinLobby('CONC02', 'user-a', 'A');

      // user-a joins then immediately leaves
      mgr.leaveLobby(lobby.id, 'user-a');

      assert.equal(mgr.getConnectedCount(lobby.id), 1);
    });
  });

  // ─── Finished/Cancelled lobby not joinable ──────

  describe('finished lobby', () => {
    it('cannot join finished lobby', () => {
      const lobby = mgr.createLobby('user-1', 'FIN001');
      mgr.joinLobby('FIN001', 'user-2', 'P2');
      mgr.leaveLobby(lobby.id, 'user-2'); // triggers finish

      const result = mgr.joinLobby('FIN001', 'user-3', 'P3');
      assert.equal(result.error, 'Lobby not joinable');
    });
  });
});
