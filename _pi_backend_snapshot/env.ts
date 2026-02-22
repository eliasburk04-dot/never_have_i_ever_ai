import { z } from 'zod';

const EnvSchema = z.object({
  NODE_ENV: z.string().default('production'),
  API_PORT: z.coerce.number().int().positive().default(3000),
  JWT_SECRET: z.string().min(16),
  JWT_EXPIRES_IN: z.string().default('7d'),
  DATABASE_URL: z.string().min(1),
  GROQ_API_KEY: z.string().optional().default(''),
  BODY_LIMIT_BYTES: z.coerce.number().int().positive().default(1048576),
  CORS_ALLOWED_ORIGINS: z.string().default('http://localhost:3000,http://localhost:5173'),
  SOCKET_ALLOWED_ORIGINS: z.string().default('http://localhost:3000,http://localhost:5173'),
  GLOBAL_RATE_LIMIT_MAX: z.coerce.number().int().positive().default(200),
  GLOBAL_RATE_LIMIT_WINDOW: z.string().default('1 minute'),
  AUTH_RATE_LIMIT_MAX: z.coerce.number().int().positive().default(8),
  AUTH_RATE_LIMIT_WINDOW: z.string().default('10 minutes'),
});

export const env = EnvSchema.parse(process.env);
