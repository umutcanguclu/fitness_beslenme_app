'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useSession } from '@/lib/session';
import { coachApi, type Club, type Team } from '@/lib/coach-api';
import { Spinner } from '@/components/Spinner';
import { ErrorMessage } from '@/components/ErrorMessage';
import type { ApiError } from '@/lib/api';

export default function DashboardPage() {
  const router = useRouter();
  const { user } = useSession();
  const [club, setClub] = useState<Club | null>(null);
  const [teams, setTeams] = useState<Team[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<ApiError | null>(null);
  const [creatingClub, setCreatingClub] = useState(false);
  const [clubName, setClubName] = useState('');

  useEffect(() => {
    if (user?.role === 'player') {
      router.replace('/my-program');
      return;
    }
    if (!user) return;
    void load();
  }, [user, router]);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const [c, t] = await Promise.all([coachApi.getMyClub(), coachApi.listTeams()]);
      setClub(c);
      setTeams(t);
    } catch (err) {
      setError(err as ApiError);
    } finally {
      setLoading(false);
    }
  }

  async function onCreateClub(e: React.FormEvent) {
    e.preventDefault();
    if (!clubName.trim()) return;
    setCreatingClub(true);
    setError(null);
    try {
      const c = await coachApi.createClub({ name: clubName.trim() });
      setClub(c);
      setClubName('');
    } catch (err) {
      setError(err as ApiError);
    } finally {
      setCreatingClub(false);
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
    <div className="space-y-6">
      <header>
        <h1 className="text-2xl font-semibold">Hoş geldin, {user?.fullName}</h1>
        <p className="text-text-muted text-sm mt-1">Bugün ne çalıştırıyoruz?</p>
      </header>

      <ErrorMessage error={error} />

      {!club ? (
        <section className="card">
          <h2 className="text-lg font-semibold mb-2">Önce bir kulüp oluştur</h2>
          <p className="text-text-muted text-sm mb-4">
            Antrenmanlar, takımlar ve oyuncular bir kulübe bağlı çalışır.
          </p>
          <form onSubmit={onCreateClub} className="flex gap-2">
            <input
              required
              className="input flex-1"
              placeholder="Kulüp adı (örn. Şehir Spor)"
              value={clubName}
              onChange={(e) => setClubName(e.target.value)}
            />
            <button type="submit" className="btn-primary" disabled={creatingClub}>
              {creatingClub ? '...' : 'Oluştur'}
            </button>
          </form>
        </section>
      ) : (
        <section className="card">
          <div className="flex items-start justify-between gap-4">
            <div>
              <div className="text-text-muted text-xs uppercase tracking-wide">Kulüp</div>
              <h2 className="text-xl font-semibold">{club.name}</h2>
              {club.league && <div className="text-text-muted text-sm mt-1">{club.league}</div>}
            </div>
            <span className="badge-accent">Admin</span>
          </div>
          <div className="mt-4 grid grid-cols-2 gap-3 text-center">
            <Link href="/teams" className="bg-bg-elevated border border-border rounded p-3 hover:border-border-strong transition">
              <div className="text-2xl font-semibold text-accent">{teams.length}</div>
              <div className="text-xs text-text-muted">Takım</div>
            </Link>
            <Link href={`/clubs/${club.id}/resources` as any} className="bg-bg-elevated border border-border rounded p-3 hover:border-border-strong transition opacity-50 pointer-events-none">
              <div className="text-2xl font-semibold text-text-muted">—</div>
              <div className="text-xs text-text-muted">Tesis & Ekipman</div>
            </Link>
          </div>
        </section>
      )}

      {club && (
        <section>
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-lg font-semibold">Takımlarım</h3>
            <Link href="/teams" className="btn-ghost text-sm px-3 py-1.5">
              Hepsini gör →
            </Link>
          </div>
          {teams.length === 0 ? (
            <div className="card text-center py-8">
              <p className="text-text-muted text-sm">Henüz takımın yok.</p>
              <Link href="/teams" className="btn-primary mt-4 inline-flex">
                İlk takımını oluştur
              </Link>
            </div>
          ) : (
            <ul className="space-y-2">
              {teams.slice(0, 4).map((team) => (
                <li key={team.id}>
                  <Link
                    href={`/teams/${team.id}`}
                    className="card flex items-center justify-between hover:border-border-strong transition"
                  >
                    <div>
                      <div className="font-medium">{team.name}</div>
                      <div className="text-xs text-text-muted mt-0.5">
                        {team.category.toUpperCase()} · {team.season}
                      </div>
                    </div>
                    <span className="text-text-muted">→</span>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </section>
      )}
    </div>
  );
}
