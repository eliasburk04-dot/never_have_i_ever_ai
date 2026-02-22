import type { FastifyInstance } from 'fastify';
import type { Namespace } from 'socket.io';

import { neverHaveIeverGame } from './never_have_i_ever/index.js';

export interface GameModule {
  key: string;
  engine: {
    validateSettings: (input: unknown) => unknown;
    selectNextItem: (...args: any[]) => Promise<any>;
    applyAnswer: (...args: any[]) => Promise<any>;
    canAdvance: (...args: any[]) => Promise<any>;
    advance: (...args: any[]) => Promise<any>;
  };
  registerRoutes: (fastify: FastifyInstance) => Promise<void>;
  registerWs: (fastify: FastifyInstance, namespace: Namespace) => void;
}

const games: GameModule[] = [neverHaveIeverGame];

export const gameRegistry = new Map(games.map((game) => [game.key, game]));

export function getGame(gameKey: string): GameModule | undefined {
  return gameRegistry.get(gameKey);
}

export function listGameKeys(): string[] {
  return [...gameRegistry.keys()];
}

export async function registerGameRoutes(fastify: FastifyInstance): Promise<void> {
  for (const game of games) {
    await game.registerRoutes(fastify);
  }

  fastify.get('/v1/games', async () => ({
    games: games.map((game) => ({ key: game.key })),
  }));
}

export function registerGameWsHandlers(fastify: FastifyInstance, namespace: Namespace): void {
  for (const game of games) {
    game.registerWs(fastify, namespace);
  }
}
