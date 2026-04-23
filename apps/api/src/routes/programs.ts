import type { FastifyPluginAsync } from 'fastify';
import { ProgramGenerateInputSchema } from '@fittrack/shared';
import { z } from 'zod';
import { AppError } from '../lib/errors.js';
import { programService } from '../services/program.service.js';

const IdParamsSchema = z.object({ id: z.string().uuid() });

export const programRoutes: FastifyPluginAsync = async (app) => {
  app.addHook('preHandler', app.requireAuth);

  app.post('/programs/generate', async (request, reply) => {
    const input = ProgramGenerateInputSchema.parse(request.body);
    const userId = requireUserId(request.authUser?.sub);
    const program = await programService.generate(userId, input);
    return reply.code(201).send(program);
  });

  app.get('/programs', async (request) => {
    const userId = requireUserId(request.authUser?.sub);
    return programService.list(userId);
  });

  app.get('/programs/active', async (request) => {
    const userId = requireUserId(request.authUser?.sub);
    const program = await programService.getActive(userId);
    if (!program) throw AppError.notFound('No active program');
    return program;
  });

  app.post('/programs/:id/activate', async (request) => {
    const { id } = IdParamsSchema.parse(request.params);
    const userId = requireUserId(request.authUser?.sub);
    return programService.activate(userId, id);
  });

  app.delete('/programs/:id', async (request, reply) => {
    const { id } = IdParamsSchema.parse(request.params);
    const userId = requireUserId(request.authUser?.sub);
    await programService.delete(userId, id);
    return reply.code(204).send();
  });
};

function requireUserId(sub: string | undefined): string {
  if (!sub) throw AppError.unauthorized();
  return sub;
}
