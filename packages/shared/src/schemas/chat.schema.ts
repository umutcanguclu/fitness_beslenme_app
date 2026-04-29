import { z } from 'zod';

export const ChatMessageSchema = z.object({
  id: z.string().uuid(),
  threadId: z.string().uuid(),
  senderId: z.string().uuid(),
  body: z.string().min(1).max(2000),
  sentAt: z.coerce.date(),
});
export type ChatMessage = z.infer<typeof ChatMessageSchema>;

export const SendChatMessageInputSchema = z.object({
  body: z.string().min(1).max(2000),
});
export type SendChatMessageInput = z.infer<typeof SendChatMessageInputSchema>;

export const StartChatInputSchema = z.object({
  playerId: z.string().uuid(),
});
export type StartChatInput = z.infer<typeof StartChatInputSchema>;

export const ChatThreadSchema = z.object({
  id: z.string().uuid(),
  clubId: z.string().uuid(),
  coachId: z.string().uuid(),
  playerId: z.string().uuid(),
  coachLastReadAt: z.coerce.date().nullable(),
  playerLastReadAt: z.coerce.date().nullable(),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});
export type ChatThread = z.infer<typeof ChatThreadSchema>;

export const ChatThreadSummarySchema = ChatThreadSchema.extend({
  // Karşı tarafın görünen adı (UI bunu listede gösterir).
  otherPartyName: z.string(),
  otherPartyRole: z.enum(['coach', 'player']),
  lastMessage: ChatMessageSchema.nullable(),
  unreadCount: z.number().int().nonnegative(),
});
export type ChatThreadSummary = z.infer<typeof ChatThreadSummarySchema>;
