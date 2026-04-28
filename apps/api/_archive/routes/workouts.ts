import type { FastifyPluginAsync } from 'fastify';
import {
  FinishWorkoutInputSchema,
  SetInputSchema,
  StartWorkoutInputSchema,
} from '@fittrack/shared';
import { z } from 'zod';
import { AppError } from '../lib/errors.js';
import { workoutService } from '../services/workout.service.js';

const IdParamsSchema = z.object({ id: z.string().uuid() });
const ListQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(20),
  cursor: z.string().uuid().optional(),
});
const UpdateNotesSchema = z.object({ notes: z.string().max(2000) });

export const workoutRoutes: FastifyPluginAsync = async (app) => {
  app.addHook('preHandler', app.requireAuth);

  app.get('/workouts', async (request) => {
    const { limit, cursor } = ListQuerySchema.parse(request.query);
    const userId = requireUserId(request.authUser?.sub);
    return workoutService.list(userId, limit, cursor);
  });

  app.post('/workouts', async (request, reply) => {
    const input = StartWorkoutInputSchema.parse(request.body);
    const userId = requireUserId(request.authUser?.sub);
    const workout = await workoutService.start(userId, input);
    return reply.code(201).send(workout);
  });

  app.get('/workouts/:id', async (request) => {
    const { id } = IdParamsSchema.parse(request.params);
    const userId = requireUserId(request.authUser?.sub);
    return workoutService.get(id, userId);
  });

  app.patch('/workouts/:id', async (request) => {
    const { id } = IdParamsSchema.parse(request.params);
    const userId = requireUserId(request.authUser?.sub);
    const body = request.body as Record<string, unknown>;
    if (body && 'finishedAt' in body) {
      const parsed = FinishWorkoutInputSchema.parse(body);
      return workoutService.finish(id, userId, parsed);
    }
    const { notes } = UpdateNotesSchema.parse(body);
    return workoutService.updateNotes(id, userId, notes);
  });

  app.post('/workouts/:id/finish', async (request) => {
    const { id } = IdParamsSchema.parse(request.params);
    const userId = requireUserId(request.authUser?.sub);
    const input = FinishWorkoutInputSchema.parse(request.body ?? {});
    return workoutService.finish(id, userId, input);
  });

  app.post('/workouts/:id/sets', async (request, reply) => {
    const { id } = IdParamsSchema.parse(request.params);
    const userId = requireUserId(request.authUser?.sub);
    const input = SetInputSchema.parse(request.body);
    const set = await workoutService.addSet(id, userId, input);
    return reply.code(201).send(set);
  });

  app.delete('/workouts/:id', async (request, reply) => {
    const { id } = IdParamsSchema.parse(request.params);
    const userId = requireUserId(request.authUser?.sub);
    await workoutService.delete(id, userId);
    return reply.code(204).send();
  });
};

function requireUserId(sub: string | undefined): string {
  if (!sub) throw AppError.unauthorized();
  return sub;
}
