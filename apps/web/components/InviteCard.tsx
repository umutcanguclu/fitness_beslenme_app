'use client';

import { useState } from 'react';

interface Props {
  invite: { name: string; code: string };
  onClose?: () => void;
}

export function InviteCard({ invite, onClose }: Props) {
  const [copied, setCopied] = useState<'code' | 'link' | null>(null);

  // Tarayıcı origin'i — WhatsApp'tan paylaşılan link bu host'a yönlenir.
  // Telefondaki kullanıcı app deploy edilince gerçek domain'i görecek.
  const origin = typeof window !== 'undefined' ? window.location.origin : '';
  const shareUrl = `${origin}/register/player?code=${invite.code}`;
  const shareText = `Selam ${invite.name}, fittrack hesabını şuradan açabilirsin:\n${shareUrl}\n\n(Davet kodu: ${invite.code})`;
  const whatsappUrl = `https://wa.me/?text=${encodeURIComponent(shareText)}`;

  async function copy(value: string, kind: 'code' | 'link') {
    try {
      await navigator.clipboard.writeText(value);
      setCopied(kind);
      setTimeout(() => setCopied(null), 2000);
    } catch { /* clipboard yoksa sessiz geç */ }
  }

  return (
    <div className="card border-accent/40 bg-accent/5">
      <div className="flex items-center justify-between gap-3 mb-3">
        <div className="text-sm text-text-muted">{invite.name} için davet:</div>
        {onClose && (
          <button onClick={onClose} className="btn-ghost text-xs px-2 py-1">
            Kapat
          </button>
        )}
      </div>

      <div className="flex items-center gap-3 flex-wrap">
        <div className="font-mono text-2xl tracking-widest text-accent">{invite.code}</div>
        <button onClick={() => copy(invite.code, 'code')} className="btn-secondary text-sm px-3 py-1.5">
          {copied === 'code' ? '✓ Kopyalandı' : 'Kodu kopyala'}
        </button>
      </div>

      <div className="mt-3 pt-3 border-t border-accent/20 space-y-2">
        <div className="text-xs text-text-muted">Direkt link (kod otomatik dolar):</div>
        <div className="flex items-center gap-2 flex-wrap">
          <code className="text-xs text-text-muted bg-bg-elevated px-2 py-1 rounded flex-1 truncate min-w-0">
            {shareUrl}
          </code>
          <button onClick={() => copy(shareUrl, 'link')} className="btn-secondary text-sm px-3 py-1.5">
            {copied === 'link' ? '✓' : 'Linki kopyala'}
          </button>
        </div>
        <a
          href={whatsappUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="btn-primary w-full text-sm"
        >
          WhatsApp ile paylaş
        </a>
      </div>

      <p className="text-xs text-text-muted mt-3">
        Kod 14 gün geçerli. Oyuncu kodla veya linkle hesap açar; mevcut kod tekrar kullanılamaz.
      </p>
    </div>
  );
}
