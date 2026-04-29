'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { chatApi, type ChatThreadSummary } from '@/lib/chat-api';
import { Spinner } from '@/components/Spinner';
import { ErrorMessage } from '@/components/ErrorMessage';
import type { ApiError } from '@/lib/api';

export default function ChatThreadsPage() {
  const [threads, setThreads] = useState<ChatThreadSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<ApiError | null>(null);

  useEffect(() => {
    void load();
    const t = setInterval(() => void load(true), 10000);
    return () => clearInterval(t);
  }, []);

  async function load(silent = false) {
    if (!silent) setLoading(true);
    try {
      setThreads(await chatApi.listThreads());
      setError(null);
    } catch (err) {
      setError(err as ApiError);
    } finally {
      if (!silent) setLoading(false);
    }
  }

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-semibold">Mesajlar</h1>
      <ErrorMessage error={error} />
      {loading ? (
        <div className="py-10 flex justify-center">
          <Spinner size={28} />
        </div>
      ) : threads.length === 0 ? (
        <div className="card text-center py-10">
          <p className="text-text-muted">
            Henüz mesajlaşma yok.
            <br />
            Antrenör oyuncu sayfasından "Mesajlaş" butonuyla başlatabilir.
          </p>
        </div>
      ) : (
        <ul className="space-y-2">
          {threads.map((t) => (
            <li key={t.id}>
              <Link
                href={`/chat/${t.id}`}
                className="card flex items-center gap-3 hover:border-border-strong transition"
              >
                <div className="w-10 h-10 rounded-full bg-bg-elevated border border-border flex items-center justify-center text-sm shrink-0">
                  {t.otherPartyName.charAt(0).toUpperCase()}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-2">
                    <div className="font-medium truncate">{t.otherPartyName}</div>
                    {t.lastMessage && (
                      <div className="text-xs text-text-dim shrink-0">
                        {formatTime(t.lastMessage.sentAt)}
                      </div>
                    )}
                  </div>
                  <div className="flex items-center justify-between gap-2 mt-0.5">
                    <div className="text-sm text-text-muted truncate">
                      {t.lastMessage?.body ?? <span className="italic text-text-dim">henüz mesaj yok</span>}
                    </div>
                    {t.unreadCount > 0 && (
                      <span className="ml-2 text-xs bg-accent text-bg font-bold rounded-full min-w-[20px] h-5 px-1.5 inline-flex items-center justify-center shrink-0">
                        {t.unreadCount}
                      </span>
                    )}
                  </div>
                </div>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

// Akıllı zaman formatı: bugün → saat:dakika, bu hafta → gün adı, eski → tarih
function formatTime(iso: string): string {
  const d = new Date(iso);
  const now = new Date();
  const diffMs = now.getTime() - d.getTime();
  const oneDay = 24 * 60 * 60 * 1000;

  if (now.toDateString() === d.toDateString()) {
    return d.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' });
  }
  if (diffMs < 7 * oneDay) {
    return d.toLocaleDateString('tr-TR', { weekday: 'short' });
  }
  return d.toLocaleDateString('tr-TR', { day: '2-digit', month: 'short' });
}
