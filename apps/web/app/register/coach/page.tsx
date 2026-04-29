'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { AuthShell } from '@/components/AuthShell.js';
import { ErrorMessage } from '@/components/ErrorMessage.js';
import { registerCoach } from '@/lib/session.js';
import type { ApiError } from '@/lib/api.js';

export default function RegisterCoachPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [fullName, setFullName] = useState('');
  const [password, setPassword] = useState('');
  const [clubName, setClubName] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await registerCoach({
        email,
        password,
        fullName,
        clubName: clubName.trim() || undefined,
      });
      router.replace('/dashboard');
    } catch (err) {
      setError(err as ApiError);
      setSubmitting(false);
    }
  }

  return (
    <AuthShell
      title="Antrenör hesabı"
      subtitle="Kulübünü, takımlarını ve oyuncularını burada yönet"
      footer={
        <span>
          Zaten hesabın var mı?{' '}
          <Link href="/login" className="text-accent">Giriş yap</Link>
        </span>
      }
    >
      <form onSubmit={onSubmit} className="space-y-4">
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
        <div>
          <label htmlFor="clubName" className="label">
            Kulüp adı <span className="text-text-dim">(opsiyonel — sonra ekleyebilirsin)</span>
          </label>
          <input
            id="clubName"
            type="text"
            value={clubName}
            onChange={(e) => setClubName(e.target.value)}
            className="input"
            placeholder="Örn. Şehir Spor Kulübü"
          />
        </div>
        <ErrorMessage error={error} />
        <button type="submit" className="btn-primary w-full" disabled={submitting}>
          {submitting ? 'Hesap oluşturuluyor...' : 'Hesabımı oluştur'}
        </button>
      </form>
    </AuthShell>
  );
}
