'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useSession } from '@/lib/session.js';

export default function Landing() {
  const router = useRouter();
  const { user, loading } = useSession();

  useEffect(() => {
    if (!loading && user) {
      router.replace(user.role === 'coach' ? '/dashboard' : '/my-program');
    }
  }, [user, loading, router]);

  return (
    <main className="min-h-dvh flex flex-col">
      <div className="flex-1 flex items-center justify-center px-6">
        <div className="w-full max-w-md">
          <div className="mb-10 text-center">
            <div className="text-accent text-4xl font-bold tracking-tight mb-2">fittrack</div>
            <p className="text-text-muted">
              Alt lig + akademi futbol antrenörleri için
              <br />
              haftalık program üretici + takım yönetimi
            </p>
          </div>

          <div className="space-y-3">
            <Link href="/login" className="btn-primary w-full">
              Giriş yap
            </Link>
            <Link href="/register/coach" className="btn-secondary w-full">
              Antrenör hesabı oluştur
            </Link>
            <Link href="/register/player" className="btn-ghost w-full">
              Oyuncuyum — davet kodum var
            </Link>
          </div>
        </div>
      </div>

      <footer className="text-center text-text-dim text-xs py-6 px-6">
        v0.1 · MVP
      </footer>
    </main>
  );
}
