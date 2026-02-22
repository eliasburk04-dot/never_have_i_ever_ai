import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import jwt from '@fastify/jwt';
import rateLimit from '@fastify/rate-limit';

import { env } from './env.js';
import { buildLoggerOptions } from './platform/logger/index.js';
import { globalRateLimitConfig } from './platform/rate-limit/index.js';
import { registerErrorHandler } from './platform/middleware/error-handler.js';
import { registerAuthDecorator } from './platform/auth/index.js';
import { registerHealthRoutes } from './routes/health.js';
import { registerAuthRoutes } from './routes/auth.js';
import { registerGameRoutes } from './games/index.js';
import { setupSocket } from './socket.js';

const parseOrigins = (csv: string): string[] => {
  const origins = csv
    .split(',')
    .map((x) => x.trim())
    .filter(Boolean);

  if (origins.includes('*')) {
    throw new Error('Wildcard CORS origins are not allowed in production');
  }

  return origins;
};

const allowedCorsOrigins = parseOrigins(env.CORS_ALLOWED_ORIGINS);

const fastify = Fastify({
  logger: buildLoggerOptions(),
  bodyLimit: env.BODY_LIMIT_BYTES,
  trustProxy: true,
});

await fastify.register(helmet, {
  contentSecurityPolicy: false,
  global: true,
});

await fastify.register(cors, {
  origin: (origin, cb) => {
    if (!origin) return cb(null, true);
    if (allowedCorsOrigins.includes(origin)) return cb(null, true);
    return cb(null, false);
  },
});

await fastify.register(rateLimit, globalRateLimitConfig);

await fastify.register(jwt, {
  secret: env.JWT_SECRET,
  sign: { expiresIn: env.JWT_EXPIRES_IN },
});

await registerAuthDecorator(fastify);
registerErrorHandler(fastify);

setupSocket(fastify);

await registerHealthRoutes(fastify);
await registerAuthRoutes(fastify);
await registerGameRoutes(fastify);

await fastify.listen({ host: '0.0.0.0', port: env.API_PORT });
