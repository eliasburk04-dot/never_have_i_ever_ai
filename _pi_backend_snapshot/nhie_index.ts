import type { FastifyInstance } from 'fastify';
import type { Namespace } from 'socket.io';

import { engine } from './engine.js';
import { registerNeverHaveIeverRoutes, NEVER_HAVE_I_EVER_GAME_KEY } from './routes.js';
import { registerNeverHaveIeverWsHandlers } from './ws.js';

export const neverHaveIeverGame = {
  key: NEVER_HAVE_I_EVER_GAME_KEY,
  engine,
  async registerRoutes(fastify: FastifyInstance) {
    await registerNeverHaveIeverRoutes(fastify);
  },
  registerWs(fastify: FastifyInstance, namespace: Namespace) {
    registerNeverHaveIeverWsHandlers(namespace, fastify);
  },
};

export type NeverHaveIeverGame = typeof neverHaveIeverGame;
