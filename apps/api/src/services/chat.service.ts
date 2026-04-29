import type { ChatMessage, ChatThread, User } from '@prisma/client';
import { prisma } from '../lib/prisma.js';
import { AppError } from '../lib/errors.js';

export interface ThreadParticipantRole {
  user: User;
  isCoach: boolean;
}

export interface ChatThreadSummary extends ChatThread {
  otherPartyName: string;
  otherPartyRole: 'coach' | 'player';
  lastMessage: ChatMessage | null;
  unreadCount: number;
}

const MESSAGE_LIST_DEFAULT_LIMIT = 50;
const MESSAGE_LIST_MAX_LIMIT = 200;

export const chatService = {
  // Bir koç bir oyuncu için thread aç (yoksa upsert).
  // Yetki: koç oyuncunun kulübünde olmalı.
  async upsertThreadForCoach(coachUser: User, playerId: string): Promise<ChatThread> {
    if (coachUser.role !== 'coach') {
      throw AppError.forbidden('Sadece antrenör konuşma başlatabilir');
    }
    const player = await prisma.player.findUnique({
      where: { id: playerId },
      select: { id: true, clubId: true },
    });
    if (!player) throw AppError.notFound('Oyuncu bulunamadı');
    const coach = await prisma.coach.findUnique({ where: { userId: coachUser.id } });
    if (!coach || coach.clubId !== player.clubId) {
      throw AppError.forbidden('Bu oyuncu kulübünüzde değil');
    }
    return prisma.chatThread.upsert({
      where: { coachId_playerId: { coachId: coachUser.id, playerId } },
      create: { clubId: player.clubId, coachId: coachUser.id, playerId },
      update: {},
    });
  },

  async listThreadsForUser(user: User): Promise<ChatThreadSummary[]> {
    const where =
      user.role === 'coach'
        ? { coachId: user.id }
        : { player: { userId: user.id } };

    const threads = await prisma.chatThread.findMany({
      where,
      include: {
        coach: { select: { id: true, fullName: true } },
        player: { select: { id: true, fullName: true } },
        messages: { orderBy: { sentAt: 'desc' }, take: 1 },
      },
      orderBy: { updatedAt: 'desc' },
    });

    return Promise.all(
      threads.map(async (t) => {
        const isCoach = user.role === 'coach';
        const otherPartyName = isCoach ? t.player.fullName : t.coach.fullName;
        const otherPartyRole: 'coach' | 'player' = isCoach ? 'player' : 'coach';
        const lastReadAt = isCoach ? t.coachLastReadAt : t.playerLastReadAt;

        const unreadCount = await prisma.chatMessage.count({
          where: {
            threadId: t.id,
            senderId: { not: user.id },
            ...(lastReadAt ? { sentAt: { gt: lastReadAt } } : {}),
          },
        });

        const { messages, ...rest } = t;
        return {
          ...rest,
          otherPartyName,
          otherPartyRole,
          lastMessage: messages[0] ?? null,
          unreadCount,
        };
      }),
    );
  },

  // Thread erişimi: kullanıcı katılımcılardan biri mi?
  async ensureThreadAccess(threadId: string, user: User): Promise<{
    thread: ChatThread;
    role: 'coach' | 'player';
  }> {
    const thread = await prisma.chatThread.findUnique({
      where: { id: threadId },
      include: { player: { select: { userId: true } } },
    });
    if (!thread) throw AppError.notFound('Konuşma bulunamadı');

    if (user.role === 'coach' && thread.coachId === user.id) {
      const { player: _, ...rest } = thread;
      void _;
      return { thread: rest, role: 'coach' };
    }
    if (user.role === 'player' && thread.player.userId === user.id) {
      const { player: _, ...rest } = thread;
      void _;
      return { thread: rest, role: 'player' };
    }
    throw AppError.forbidden('Bu konuşmaya erişim yetkiniz yok');
  },

  async listMessages(
    threadId: string,
    user: User,
    opts: { before?: Date; limit?: number } = {},
  ): Promise<ChatMessage[]> {
    await this.ensureThreadAccess(threadId, user);
    const limit = Math.min(opts.limit ?? MESSAGE_LIST_DEFAULT_LIMIT, MESSAGE_LIST_MAX_LIMIT);
    return prisma.chatMessage.findMany({
      where: {
        threadId,
        ...(opts.before ? { sentAt: { lt: opts.before } } : {}),
      },
      orderBy: { sentAt: 'desc' },
      take: limit,
    });
  },

  async sendMessage(threadId: string, user: User, body: string): Promise<ChatMessage> {
    const trimmed = body.trim();
    if (!trimmed) throw AppError.validation('Mesaj boş olamaz');

    await this.ensureThreadAccess(threadId, user);

    const [message] = await prisma.$transaction([
      prisma.chatMessage.create({
        data: { threadId, senderId: user.id, body: trimmed },
      }),
      // Thread updatedAt'ı tetikle ki liste sıralaması güncellensin
      prisma.chatThread.update({
        where: { id: threadId },
        data: { updatedAt: new Date() },
      }),
    ]);
    return message;
  },

  async markRead(threadId: string, user: User): Promise<void> {
    const { role } = await this.ensureThreadAccess(threadId, user);
    await prisma.chatThread.update({
      where: { id: threadId },
      data:
        role === 'coach'
          ? { coachLastReadAt: new Date() }
          : { playerLastReadAt: new Date() },
    });
  },
};
