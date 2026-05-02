import Fastify, { type FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import { ZodError } from 'zod';
import { env } from './lib/env.js';
import { AppError } from './lib/errors.js';
import authPlugin from './plugins/auth.js';
import { healthRoutes } from './routes/health.js';
import { authRoutes } from './routes/auth.js';
import { clubRoutes } from './routes/clubs.js';
import { teamRoutes } from './routes/teams.js';
import { playerRoutes } from './routes/players.js';
import { programRoutes } from './routes/programs.js';
import { matchRoutes } from './routes/matches.js';
import { performanceTestRoutes } from './routes/performance-tests.js';
import { chatRoutes } from './routes/chat.js';
import { chatWsRoutes } from './routes/chat-ws.js';

export async function buildApp(): Promise<FastifyInstance> {
  const app = Fastify({
    logger: {
      level: env.LOG_LEVEL,
      transport:
        env.NODE_ENV === 'development'
          ? { target: 'pino-pretty', options: { translateTime: 'SYS:HH:MM:ss.l' } }
          : undefined,
    },
  });

  await app.register(helmet, { global: true });
  await app.register(cors, {
    origin: env.CORS_ORIGINS === '*' ? true : env.CORS_ORIGINS.split(',').map((s) => s.trim()),
    credentials: true,
  });

  app.addContentTypeParser('application/json', { parseAs: 'string' }, (_req, body, done) => {
    const raw = (body as string).trim();
    if (raw.length === 0) return done(null, undefined);
    try {
      done(null, JSON.parse(raw));
    } catch (err) {
      const parseError = err as Error & { statusCode?: number };
      parseError.statusCode = 400;
      done(parseError, undefined);
    }
  });

  await app.register(authPlugin);

  app.setErrorHandler((error, request, reply) => {
    if (error instanceof AppError) {
      return reply.code(error.statusCode).send({
        error: { code: error.code, message: error.message, details: error.details },
      });
    }
    if (error instanceof ZodError) {
      return reply.code(400).send({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid request body',
          details: error.flatten(),
        },
      });
    }
    const httpError = error as Error & { statusCode?: number; code?: string };
    if (
      typeof httpError.statusCode === 'number' &&
      httpError.statusCode >= 400 &&
      httpError.statusCode < 500
    ) {
      return reply.code(httpError.statusCode).send({
        error: {
          code: httpError.code ?? 'BAD_REQUEST',
          message: httpError.message,
        },
      });
    }
    request.log.error({ err: error }, 'unhandled error');
    return reply.code(500).send({
      error: { code: 'INTERNAL_ERROR', message: 'Internal server error' },
    });
  });

  app.setNotFoundHandler((_request, reply) => {
    return reply.code(404).send({
      error: { code: 'NOT_FOUND', message: 'Route not found' },
    });
  });

  await app.register(healthRoutes);
  await app.register(authRoutes);
  await app.register(clubRoutes);
  await app.register(teamRoutes);
  await app.register(playerRoutes);
  await app.register(programRoutes);
  await app.register(matchRoutes);
  await app.register(performanceTestRoutes);
  await app.register(chatRoutes);
  await app.register(chatWsRoutes);

  return app;
}
