import type { FastifyInstance } from 'fastify';
import { Server } from 'socket.io';

import { env } from './env.js';
import { extractSocketToken, verifySocketUserId } from './platform/auth/index.js';
import { registerGameWsHandlers } from './games/index.js';

const socketOrigins = env.SOCKET_ALLOWED_ORIGINS.split(',').map((v) => v.trim()).filter(Boolean);

export function setupSocket(fastify: FastifyInstance) {
  const io = new Server(fastify.server, {
    path: '/ws',
    cors: {
      origin: (origin, callback) => {
        if (!origin) return callback(null, true);
        if (socketOrigins.includes(origin)) return callback(null, true);
        return callback(new Error('Origin not allowed'));
      },
      methods: ['GET', 'POST'],
    },
    transports: ['websocket', 'polling'],
  });

  const namespace = io.of('/ws');

  namespace.use(async (socket, next) => {
    const token = extractSocketToken(socket.handshake);
    const userId = verifySocketUserId(fastify, token);
    if (!userId) return next(new Error('unauthorized'));
    (socket.data as any).userId = userId;
    return next();
  });

  registerGameWsHandlers(fastify, namespace);

  fastify.decorate('io', namespace);
}
