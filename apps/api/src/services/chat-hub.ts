import type { ChatMessage } from '@prisma/client';

// In-memory pub/sub for chat thread subscribers.
// Each WS connection registers itself per threadId; sendMessage broadcasts.
// Single-instance only — multi-process deployment needs Redis pub/sub instead.

interface Subscriber {
  userId: string;
  send: (data: string) => void;
}

class ChatHub {
  private readonly threadSubs = new Map<string, Set<Subscriber>>();

  subscribe(threadId: string, sub: Subscriber): () => void {
    let set = this.threadSubs.get(threadId);
    if (!set) {
      set = new Set();
      this.threadSubs.set(threadId, set);
    }
    set.add(sub);
    return () => {
      set!.delete(sub);
      if (set!.size === 0) this.threadSubs.delete(threadId);
    };
  }

  broadcast(threadId: string, message: ChatMessage): void {
    const set = this.threadSubs.get(threadId);
    if (!set) return;
    const payload = JSON.stringify({
      type: 'message',
      message: {
        id: message.id,
        threadId: message.threadId,
        senderId: message.senderId,
        body: message.body,
        sentAt: message.sentAt.toISOString(),
      },
    });
    for (const sub of set) {
      try {
        sub.send(payload);
      } catch (_err) {
        // Best-effort broadcast; failed sockets get cleaned up on close.
      }
    }
  }

  subscriberCount(threadId: string): number {
    return this.threadSubs.get(threadId)?.size ?? 0;
  }
}

export const chatHub = new ChatHub();
