import { api } from './api';

export interface ChatMessage {
  id: string;
  threadId: string;
  senderId: string;
  body: string;
  sentAt: string;
}

export interface ChatThread {
  id: string;
  clubId: string;
  coachId: string;
  playerId: string;
  coachLastReadAt: string | null;
  playerLastReadAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ChatThreadSummary extends ChatThread {
  otherPartyName: string;
  otherPartyRole: 'coach' | 'player';
  lastMessage: ChatMessage | null;
  unreadCount: number;
}

export const chatApi = {
  listThreads: () => api<ChatThreadSummary[]>('/chat/threads'),
  startThreadWithPlayer: (playerId: string) =>
    api<ChatThread>('/chat/threads', { method: 'POST', body: { playerId } }),
  listMessages: (threadId: string, opts: { before?: string; limit?: number } = {}) => {
    const params = new URLSearchParams();
    if (opts.before) params.set('before', opts.before);
    if (opts.limit) params.set('limit', String(opts.limit));
    const qs = params.toString();
    return api<ChatMessage[]>(`/chat/threads/${threadId}/messages${qs ? `?${qs}` : ''}`);
  },
  sendMessage: (threadId: string, body: string) =>
    api<ChatMessage>(`/chat/threads/${threadId}/messages`, {
      method: 'POST',
      body: { body },
    }),
  markRead: (threadId: string) =>
    api<void>(`/chat/threads/${threadId}/read`, { method: 'POST' }),
};
