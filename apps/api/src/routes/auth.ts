import type { FastifyPluginAsync } from 'fastify';
import {
  LoginByCodeInputSchema,
  LoginInputSchema,
  RegisterCoachInputSchema,
  RegisterPlayerInputSchema,
} from '@fittrack/shared';
import { z } from 'zod';
import { AppError } from '../lib/errors.js';
import { env } from '../lib/env.js';
import { prisma } from '../lib/prisma.js';
import { authService } from '../services/auth.service.js';
import { passwordResetService } from '../services/password-reset.service.js';

const RefreshInputSchema = z.object({
  refreshToken: z.string().min(1),
});

const ForgotPasswordInputSchema = z.object({
  email: z.string().email(),
});

const ResetPasswordInputSchema = z.object({
  token: z.string().min(8),
  newPassword: z.string().min(8).max(128),
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

  // Şifremi unuttum: bağlantı yerine token üret. Production'da email service ile gönderilir.
  // Dev'de güvenliği bozmamak için email yoksa da 200 döner (UI bilgi sızdırmaz),
  // ancak token sadece email gerçekse kullanıcı log'da görür.
  app.post('/auth/forgot-password', async (request) => {
    const { email } = ForgotPasswordInputSchema.parse(request.body);
    const result = await passwordResetService.createResetToken(email);
    if (result.userExists) {
      // Dev modu: token'i log'a yaz, response'da da döndür ki UI test edebilsin.
      // Production'da bunu kaldır + transactional email gönder.
      app.log.info({ email, token: result.token }, 'Password reset token issued');
      return env.NODE_ENV === 'production'
        ? { message: 'Eğer bu adres kayıtlıysa sıfırlama bağlantısı gönderildi.' }
        : { message: 'Sıfırlama tokeni oluşturuldu.', devToken: result.token };
    }
    return { message: 'Eğer bu adres kayıtlıysa sıfırlama bağlantısı gönderildi.' };
  });

  app.post('/auth/reset-password', async (request, reply) => {
    const { token, newPassword } = ResetPasswordInputSchema.parse(request.body);
    await passwordResetService.resetPassword(token, newPassword);
    return reply.code(204).send();
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
