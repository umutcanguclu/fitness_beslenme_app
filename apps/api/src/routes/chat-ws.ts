import type { FastifyPluginAsync } from 'fastify';
import websocket from '@fastify/websocket';
import { z } from 'zod';
import { verifyAccessToken } from '../lib/tokens.js';
import { prisma } from '../lib/prisma.js';
import { chatHub } from '../services/chat-hub.js';
import { chatService } from '../services/chat.service.js';

const QuerySchema = z.object({
  threadId: z.string().uuid(),
  token: z.string().min(8),
});

export const chatWsRoutes: FastifyPluginAsync = async (app) => {
  await app.register(websocket);

  app.get('/ws/chat', { websocket: true }, async (socket, req) => {
    let parsed: z.infer<typeof QuerySchema>;
    try {
      parsed = QuerySchema.parse(req.query);
    } catch {
      socket.send(JSON.stringify({ type: 'error', message: 'invalid query' }));
      socket.close(1008, 'invalid query');
      return;
    }

    let userId: string;
    try {
      const payload = verifyAccessToken(parsed.token);
      userId = payload.sub;
    } catch {
      socket.send(JSON.stringify({ type: 'error', message: 'unauthorized' }));
      socket.close(1008, 'unauthorized');
      return;
    }

    // Validate that user has access to this thread.
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      socket.close(1008, 'user not found');
      return;
    }
    try {
      await chatService.ensureThreadAccess(parsed.threadId, user);
    } catch {
      socket.send(JSON.stringify({ type: 'error', message: 'forbidden' }));
      socket.close(1008, 'forbidden');
      return;
    }

    const unsubscribe = chatHub.subscribe(parsed.threadId, {
      userId,
      send: (data) => socket.send(data),
    });

    socket.send(JSON.stringify({ type: 'ready', threadId: parsed.threadId }));

    socket.on('close', () => unsubscribe());
    socket.on('error', () => unsubscribe());
  });
};
