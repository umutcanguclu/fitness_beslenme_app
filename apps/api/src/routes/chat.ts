import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { SendChatMessageInputSchema, StartChatInputSchema } from '@fittrack/shared';
import { AppError } from '../lib/errors.js';
import { prisma } from '../lib/prisma.js';
import { chatService } from '../services/chat.service.js';

const ThreadIdParamsSchema = z.object({ threadId: z.string().uuid() });
const ListMessagesQuerySchema = z.object({
  before: z.coerce.date().optional(),
  limit: z.coerce.number().int().min(1).max(200).optional(),
});

async function requireUser(authUser: { sub: string } | undefined) {
  if (!authUser) throw AppError.unauthorized();
  const user = await prisma.user.findUnique({ where: { id: authUser.sub } });
  if (!user) throw AppError.unauthorized();
  return user;
}

export const chatRoutes: FastifyPluginAsync = async (app) => {
  app.get('/chat/threads', { preHandler: app.requireAuth }, async (request) => {
    const user = await requireUser(request.authUser);
    return chatService.listThreadsForUser(user);
  });

  // Yalnızca koç açar; oyuncu mevcut thread'i kullanır.
  app.post('/chat/threads', { preHandler: app.requireAuth }, async (request, reply) => {
    const user = await requireUser(request.authUser);
    const { playerId } = StartChatInputSchema.parse(request.body);
    const thread = await chatService.upsertThreadForCoach(user, playerId);
    return reply.code(201).send(thread);
  });

  app.get('/chat/threads/:threadId/messages', { preHandler: app.requireAuth }, async (request) => {
    const user = await requireUser(request.authUser);
    const { threadId } = ThreadIdParamsSchema.parse(request.params);
    const opts = ListMessagesQuerySchema.parse(request.query);
    return chatService.listMessages(threadId, user, opts);
  });

  app.post('/chat/threads/:threadId/messages', { preHandler: app.requireAuth }, async (request, reply) => {
    const user = await requireUser(request.authUser);
    const { threadId } = ThreadIdParamsSchema.parse(request.params);
    const { body } = SendChatMessageInputSchema.parse(request.body);
    const message = await chatService.sendMessage(threadId, user, body);
    return reply.code(201).send(message);
  });

  app.post('/chat/threads/:threadId/read', { preHandler: app.requireAuth }, async (request, reply) => {
    const user = await requireUser(request.authUser);
    const { threadId } = ThreadIdParamsSchema.parse(request.params);
    await chatService.markRead(threadId, user);
    return reply.code(204).send();
  });
};
