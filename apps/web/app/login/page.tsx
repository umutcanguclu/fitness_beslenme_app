'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { AuthShell } from '@/components/AuthShell';
import { ErrorMessage } from '@/components/ErrorMessage';
import { login, loginWithCode } from '@/lib/session';
import type { ApiError } from '@/lib/api';

type Mode = 'email' | 'code';

export default function LoginPage() {
  const router = useRouter();
  const [mode, setMode] = useState<Mode>('email');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [code, setCode] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      const user =
        mode === 'email'
          ? await login(email, password)
          : await loginWithCode(code);
      router.replace(user.role === 'coach' ? '/dashboard' : '/my-program');
    } catch (err) {
      const apiErr = err as ApiError;
      // Kod var ama henüz kayıt olunmamış → otomatik register akışına yönlendir
      if (mode === 'code' && apiErr.code === 'NOT_REGISTERED') {
        router.replace(`/register/player?code=${encodeURIComponent(code.toUpperCase().trim())}`);
        return;
      }
      setError(apiErr);
      setSubmitting(false);
    }
  }

  return (
    <AuthShell
      title="Giriş yap"
      subtitle="Hesabına bağlan ve takımına devam et"
      footer={
        <div className="space-y-2">
          <div>
            Antrenörsen ve hesabın yoksa{' '}
            <Link href="/register/coach" className="text-accent">kayıt ol</Link>
          </div>
          <div>
            İlk kez geliyorsan ve <span className="font-mono text-text">davet kodun</span> varsa{' '}
            <Link href="/register/player" className="text-accent">buradan kayıt ol</Link>
          </div>
        </div>
      }
    >
      <div className="grid grid-cols-2 gap-1.5 mb-5 p-1 bg-bg-elevated border border-border rounded">
        <button
          type="button"
          onClick={() => setMode('email')}
          className={`py-2 rounded text-sm font-medium transition ${
            mode === 'email' ? 'bg-bg-card text-text' : 'text-text-muted hover:text-text'
          }`}
        >
          E-posta + Şifre
        </button>
        <button
          type="button"
          onClick={() => setMode('code')}
          className={`py-2 rounded text-sm font-medium transition ${
            mode === 'code' ? 'bg-bg-card text-text' : 'text-text-muted hover:text-text'
          }`}
        >
          Davet kodu
        </button>
      </div>

      <form onSubmit={onSubmit} className="space-y-4">
        {mode === 'email' ? (
          <>
            <div>
              <label htmlFor="email" className="label">E-posta</label>
              <input
                id="email"
                type="email"
                required
                autoComplete="email"
                inputMode="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="input"
              />
            </div>
            <div>
              <label htmlFor="password" className="label">Şifre</label>
              <input
                id="password"
                type="password"
                required
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="input"
              />
            </div>
          </>
        ) : (
          <div>
            <label htmlFor="code" className="label">Davet kodu</label>
            <input
              id="code"
              type="text"
              required
              minLength={6}
              maxLength={8}
              value={code}
              onChange={(e) => setCode(e.target.value.toUpperCase())}
              className="input font-mono tracking-widest text-2xl uppercase text-center"
              placeholder="XXXXXXXX"
              autoComplete="off"
              autoFocus
            />
            <p className="text-xs text-text-muted mt-2">
              Antrenöründen aldığın 8 karakterli kod.
              <br />
              <span className="text-text-dim">İlk kez geliyorsan otomatik kayıt sayfasına yönlendirileceksin.</span>
            </p>
          </div>
        )}
        <ErrorMessage error={error} />
        <button type="submit" className="btn-primary w-full" disabled={submitting}>
          {submitting ? 'Giriş yapılıyor...' : 'Giriş yap'}
        </button>
      </form>
    </AuthShell>
  );
}
