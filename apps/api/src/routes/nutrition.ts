import type { FastifyPluginAsync } from 'fastify';
import { NutritionGenerateInputSchema } from '@fittrack/shared';
import { z } from 'zod';
import { AppError } from '../lib/errors.js';
import { nutritionService, FOODS } from '../services/nutrition.service.js';

const IdParamsSchema = z.object({ id: z.string().uuid() });

export const nutritionRoutes: FastifyPluginAsync = async (app) => {
  app.addHook('preHandler', app.requireAuth);

  app.post('/nutrition/plan/generate', async (request, reply) => {
    const input = NutritionGenerateInputSchema.parse(request.body);
    const userId = requireUserId(request.authUser?.sub);
    const plan = await nutritionService.generate(userId, input);
    return reply.code(201).send(plan);
  });

  app.get('/nutrition/plan/active', async (request) => {
    const userId = requireUserId(request.authUser?.sub);
    const plan = await nutritionService.getActive(userId);
    if (!plan) throw AppError.notFound('No active nutrition plan');
    return plan;
  });

  app.delete('/nutrition/plan/:id', async (request, reply) => {
    const { id } = IdParamsSchema.parse(request.params);
    const userId = requireUserId(request.authUser?.sub);
    await nutritionService.delete(userId, id);
    return reply.code(204).send();
  });

  app.get('/nutrition/foods', async () => FOODS);
};

function requireUserId(sub: string | undefined): string {
  if (!sub) throw AppError.unauthorized();
  return sub;
}
