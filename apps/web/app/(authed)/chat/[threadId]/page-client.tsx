'use client';

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useSession } from '@/lib/session';
import { chatApi, type ChatMessage, type ChatThreadSummary } from '@/lib/chat-api';
import { Spinner } from '@/components/Spinner';
import { ErrorMessage } from '@/components/ErrorMessage';
import type { ApiError } from '@/lib/api';

const POLL_INTERVAL_MS = 5000;

export default function ChatThreadPage() {
  const params = useParams<{ threadId: string }>();
  const threadId = params.threadId;
  const { user } = useSession();

  const [thread, setThread] = useState<ChatThreadSummary | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const [draft, setDraft] = useState('');
  const scrollRef = useRef<HTMLDivElement>(null);
  const lastIdRef = useRef<string | null>(null);

  useEffect(() => {
    if (!threadId) return;
    void initialLoad();

    // Polling — sayfa görünür değilken durdur
    const poll = setInterval(() => {
      if (document.visibilityState === 'visible') void refresh();
    }, POLL_INTERVAL_MS);

    return () => clearInterval(poll);
  }, [threadId]);

  async function initialLoad() {
    setLoading(true);
    try {
      const [list, msgs] = await Promise.all([
        chatApi.listThreads(),
        chatApi.listMessages(threadId, { limit: 100 }),
      ]);
      const found = list.find((t) => t.id === threadId);
      setThread(found ?? null);
      const ordered = [...msgs].reverse();
      setMessages(ordered);
      lastIdRef.current = ordered[ordered.length - 1]?.id ?? null;
      await chatApi.markRead(threadId).catch(() => {});
      scrollToBottom();
    } catch (err) {
      setError(err as ApiError);
    } finally {
      setLoading(false);
    }
  }

  async function refresh() {
    try {
      const msgs = await chatApi.listMessages(threadId, { limit: 100 });
      const ordered = [...msgs].reverse();
      setMessages(ordered);
      const newLastId = ordered[ordered.length - 1]?.id ?? null;
      if (newLastId !== lastIdRef.current) {
        lastIdRef.current = newLastId;
        await chatApi.markRead(threadId).catch(() => {});
        scrollToBottom();
      }
    } catch { /* sessizce geç — polling'in kontrol için tek hata göstermek doğru değil */ }
  }

  function scrollToBottom() {
    requestAnimationFrame(() => {
      const el = scrollRef.current;
      if (el) el.scrollTop = el.scrollHeight;
    });
  }

  async function onSend(e: React.FormEvent) {
    e.preventDefault();
    const body = draft.trim();
    if (!body || sending) return;
    setSending(true);
    setError(null);
    try {
      const msg = await chatApi.sendMessage(threadId, body);
      setMessages((prev) => [...prev, msg]);
      setDraft('');
      lastIdRef.current = msg.id;
      scrollToBottom();
    } catch (err) {
      setError(err as ApiError);
    } finally {
      setSending(false);
    }
  }

  function onKeyDown(e: React.KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      void onSend(e as unknown as React.FormEvent);
    }
  }

  if (loading) {
    return (
      <div className="py-10 flex justify-center">
        <Spinner size={28} />
      </div>
    );
  }

  return (
    <div className="flex flex-col h-[calc(100dvh-72px)] -mx-4 -mt-6">
      <div className="px-4 py-3 border-b border-border bg-bg-elevated/50 flex items-center gap-3 sticky top-[60px] z-10 backdrop-blur">
        <Link href="/chat" className="text-text-muted hover:text-text">
          ←
        </Link>
        <div className="flex-1 min-w-0">
          <div className="font-medium truncate">{thread?.otherPartyName ?? '—'}</div>
          <div className="text-xs text-text-dim">
            {thread?.otherPartyRole === 'coach' ? 'Antrenör' : 'Oyuncu'}
          </div>
        </div>
      </div>

      <div ref={scrollRef} className="flex-1 overflow-y-auto px-4 py-4 space-y-2">
        <ErrorMessage error={error} />
        {messages.length === 0 ? (
          <div className="text-center text-text-muted py-10 text-sm">
            Mesaj geçmişi boş. İlk mesajı sen yaz.
          </div>
        ) : (
          messages.map((m, idx) => {
            const mine = m.senderId === user?.id;
            const prev = messages[idx - 1];
            const showTimestamp =
              !prev || new Date(m.sentAt).getTime() - new Date(prev.sentAt).getTime() > 5 * 60_000;
            return (
              <div key={m.id}>
                {showTimestamp && (
                  <div className="text-xs text-text-dim text-center my-2">
                    {formatTimestamp(m.sentAt)}
                  </div>
                )}
                <div className={`flex ${mine ? 'justify-end' : 'justify-start'}`}>
                  <div
                    className={`max-w-[80%] rounded-lg px-3 py-2 text-sm ${
                      mine
                        ? 'bg-accent text-bg rounded-br-none'
                        : 'bg-bg-elevated border border-border rounded-bl-none'
                    }`}
                  >
                    <div className="whitespace-pre-wrap break-words">{m.body}</div>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>

      <form
        onSubmit={onSend}
        className="px-4 py-3 border-t border-border bg-bg-elevated/50 backdrop-blur flex gap-2 items-end"
      >
        <textarea
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={onKeyDown}
          placeholder="Mesajını yaz..."
          rows={1}
          className="input resize-none max-h-32 min-h-[44px] py-2.5"
          maxLength={2000}
        />
        <button
          type="submit"
          disabled={sending || !draft.trim()}
          className="btn-primary px-4 py-2.5 shrink-0"
        >
          {sending ? '...' : 'Gönder'}
        </button>
      </form>
    </div>
  );
}

function formatTimestamp(iso: string): string {
  const d = new Date(iso);
  const now = new Date();
  if (d.toDateString() === now.toDateString()) {
    return d.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' });
  }
  return d.toLocaleString('tr-TR', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' });
}
