'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { AuthShell } from '@/components/AuthShell.js';
import { ErrorMessage } from '@/components/ErrorMessage.js';
import { login } from '@/lib/session.js';
import type { ApiError } from '@/lib/api.js';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      const user = await login(email, password);
      router.replace(user.role === 'coach' ? '/dashboard' : '/my-program');
    } catch (err) {
      setError(err as ApiError);
      setSubmitting(false);
    }
  }

  return (
    <AuthShell
      title="Giriş yap"
      subtitle="Hesabına bağlan ve takımına devam et"
      footer={
        <span>
          Hesabın yok mu?{' '}
          <Link href="/register/coach" className="text-accent">Antrenör olarak kayıt ol</Link>
        </span>
      }
    >
      <form onSubmit={onSubmit} className="space-y-4">
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
        <ErrorMessage error={error} />
        <button type="submit" className="btn-primary w-full" disabled={submitting}>
          {submitting ? 'Giriş yapılıyor...' : 'Giriş yap'}
        </button>
      </form>
    </AuthShell>
  );
}
