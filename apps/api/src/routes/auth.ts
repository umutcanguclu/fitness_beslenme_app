import type { FastifyPluginAsync } from 'fastify';
import { LoginInputSchema, RegisterInputSchema } from '@fittrack/shared';
import { z } from 'zod';
import { AppError } from '../lib/errors.js';
import { authService } from '../services/auth.service.js';

const RefreshInputSchema = z.object({
  refreshToken: z.string().min(1),
});

export const authRoutes: FastifyPluginAsync = async (app) => {
  app.post('/auth/register', async (request, reply) => {
    const input = RegisterInputSchema.parse(request.body);
    const result = await authService.register(input);
    return reply.code(201).send(result);
  });

  app.post('/auth/login', async (request) => {
    const input = LoginInputSchema.parse(request.body);
    return authService.login(input);
  });

  app.post('/auth/refresh', async (request) => {
    const { refreshToken } = RefreshInputSchema.parse(request.body);
    const tokens = await authService.refresh(refreshToken);
    return tokens;
  });

  app.post('/auth/logout', async (request, reply) => {
    const { refreshToken } = RefreshInputSchema.parse(request.body);
    await authService.logout(refreshToken);
    return reply.code(204).send();
  });

  app.get('/auth/me', { preHandler: app.requireAuth }, async (request) => {
    const userId = request.authUser?.sub;
    if (!userId) throw AppError.unauthorized();
    return authService.getById(userId);
  });
};
