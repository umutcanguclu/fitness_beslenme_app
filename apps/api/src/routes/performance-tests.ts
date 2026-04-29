import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { PerformanceTestTypeSchema } from '@fittrack/shared';
import { authorizePlayerAccess } from '../lib/auth-context.js';
import { AppError } from '../lib/errors.js';
import { performanceTestService } from '../services/performance-test.service.js';

const PlayerIdParamsSchema = z.object({ playerId: z.string().uuid() });

const CreateTestBodySchema = z.object({
  type: PerformanceTestTypeSchema,
  value: z.number(),
  unit: z.string().min(1).max(16),
  testedAt: z.coerce.date().optional(),
  notes: z.string().max(500).nullable().optional(),
});

const ListTestsQuerySchema = z.object({
  type: PerformanceTestTypeSchema.optional(),
});

export const performanceTestRoutes: FastifyPluginAsync = async (app) => {
  // POST yalnızca koç tarafından — testi koç ölçer.
  app.post(
    '/players/:playerId/performance-tests',
    { preHandler: app.requireAuth },
    async (request, reply) => {
      const { playerId } = PlayerIdParamsSchema.parse(request.params);
      const auth = await authorizePlayerAccess(request.authUser, playerId);
      if (auth.actor !== 'coach') {
        throw AppError.forbidden('Performans testi giriş yetkisi koça aittir');
      }
      const input = CreateTestBodySchema.parse(request.body);
      const result = await performanceTestService.create(playerId, input);
      return reply.code(201).send(result);
    },
  );

  app.get('/players/:playerId/performance-tests', { preHandler: app.requireAuth }, async (request) => {
    const { playerId } = PlayerIdParamsSchema.parse(request.params);
    await authorizePlayerAccess(request.authUser, playerId);
    const filter = ListTestsQuerySchema.parse(request.query);
    return performanceTestService.list(playerId, filter);
  });
};
