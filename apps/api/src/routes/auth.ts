import type { FastifyPluginAsync } from 'fastify';
import {
  LoginByCodeInputSchema,
  LoginInputSchema,
  RegisterCoachInputSchema,
  RegisterPlayerInputSchema,
} from '@fittrack/shared';
import { z } from 'zod';
import { AppError } from '../lib/errors.js';
import { prisma } from '../lib/prisma.js';
import { authService } from '../services/auth.service.js';

const RefreshInputSchema = z.object({
  refreshToken: z.string().min(1),
});

export const authRoutes: FastifyPluginAsync = async (app) => {
  app.post('/auth/register/coach', async (request, reply) => {
    const input = RegisterCoachInputSchema.parse(request.body);
    const result = await authService.registerCoach(input);
    return reply.code(201).send(result);
  });

  app.post('/auth/register/player', async (request, reply) => {
    const input = RegisterPlayerInputSchema.parse(request.body);
    const result = await authService.registerPlayer(input);
    return reply.code(201).send(result);
  });

  app.post('/auth/login', async (request) => {
    const input = LoginInputSchema.parse(request.body);
    return authService.login(input);
  });

  app.post('/auth/login/code', async (request) => {
    const { code } = LoginByCodeInputSchema.parse(request.body);
    return authService.loginWithCode(code);
  });

  app.post('/auth/refresh', async (request) => {
    const { refreshToken } = RefreshInputSchema.parse(request.body);
    return authService.refresh(refreshToken);
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

  // Oyuncu rolündeki kullanıcı kendi Player.id'sini buradan alır.
  // /my-program gibi UI sayfaları için.
  app.get('/auth/me/player', { preHandler: app.requireAuth }, async (request) => {
    const userId = request.authUser?.sub;
    if (!userId) throw AppError.unauthorized();
    const player = await prisma.player.findUnique({
      where: { userId },
      select: { id: true, clubId: true, fullName: true, position: true, jerseyNumber: true },
    });
    return { playerId: player?.id ?? null, player };
  });
};
