'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { AuthShell } from '@/components/AuthShell.js';
import { ErrorMessage } from '@/components/ErrorMessage.js';
import { registerPlayer } from '@/lib/session.js';
import type { ApiError } from '@/lib/api.js';

export default function RegisterPlayerPage() {
  const router = useRouter();
  const [inviteCode, setInviteCode] = useState('');
  const [email, setEmail] = useState('');
  const [fullName, setFullName] = useState('');
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await registerPlayer({
        email,
        password,
        fullName,
        inviteCode: inviteCode.toUpperCase().trim(),
      });
      router.replace('/my-program');
    } catch (err) {
      setError(err as ApiError);
      setSubmitting(false);
    }
  }

  return (
    <AuthShell
      title="Oyuncu kaydı"
      subtitle="Antrenörünün verdiği davet koduyla hesabını oluştur"
      footer={
        <span>
          Hesabın var mı?{' '}
          <Link href="/login" className="text-accent">Giriş yap</Link>
        </span>
      }
    >
      <form onSubmit={onSubmit} className="space-y-4">
        <div>
          <label htmlFor="inviteCode" className="label">Davet kodu (8 karakter)</label>
          <input
            id="inviteCode"
            type="text"
            required
            minLength={6}
            maxLength={8}
            value={inviteCode}
            onChange={(e) => setInviteCode(e.target.value.toUpperCase())}
            className="input font-mono tracking-widest text-lg uppercase"
            placeholder="XXXXXXXX"
            autoComplete="off"
          />
        </div>
        <div>
          <label htmlFor="fullName" className="label">Ad Soyad</label>
          <input
            id="fullName"
            type="text"
            required
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            className="input"
            autoComplete="name"
          />
        </div>
        <div>
          <label htmlFor="email" className="label">E-posta</label>
          <input
            id="email"
            type="email"
            required
            inputMode="email"
            autoComplete="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="input"
          />
        </div>
        <div>
          <label htmlFor="password" className="label">Şifre (en az 8 karakter)</label>
          <input
            id="password"
            type="password"
            required
            minLength={8}
            autoComplete="new-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="input"
          />
        </div>
        <ErrorMessage error={error} />
        <button type="submit" className="btn-primary w-full" disabled={submitting}>
          {submitting ? 'Kayıt yapılıyor...' : 'Hesabımı oluştur'}
        </button>
      </form>
    </AuthShell>
  );
}
