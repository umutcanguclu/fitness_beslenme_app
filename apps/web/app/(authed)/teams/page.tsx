'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { coachApi, type Team } from '@/lib/coach-api';
import { Spinner } from '@/components/Spinner';
import { ErrorMessage } from '@/components/ErrorMessage';
import type { ApiError } from '@/lib/api';

const CATEGORIES = [
  { value: 'u13', label: 'U13' },
  { value: 'u14', label: 'U14' },
  { value: 'u15', label: 'U15' },
  { value: 'u16', label: 'U16' },
  { value: 'u17', label: 'U17' },
  { value: 'u18', label: 'U18' },
  { value: 'u19', label: 'U19' },
  { value: 'u21', label: 'U21' },
  { value: 'senior', label: 'A Takım' },
  { value: 'amateur', label: 'Amatör' },
  { value: 'veteran', label: 'Masterlar' },
];

const DEFAULT_SEASON = (() => {
  const y = new Date().getFullYear();
  const m = new Date().getMonth();
  // Sezon Temmuz-Haziran arası — şu an Ocak ise önceki sezon hâlâ devam.
  const start = m >= 6 ? y : y - 1;
  return `${start}-${start + 1}`;
})();

export default function TeamsPage() {
  const [teams, setTeams] = useState<Team[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<ApiError | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [creating, setCreating] = useState(false);
  const [includeInactive, setIncludeInactive] = useState(false);
  const [formName, setFormName] = useState('');
  const [formCategory, setFormCategory] = useState('senior');
  const [formSeason, setFormSeason] = useState(DEFAULT_SEASON);

  useEffect(() => {
    void load();
  }, [includeInactive]);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      setTeams(await coachApi.listTeams(includeInactive));
    } catch (err) {
      setError(err as ApiError);
    } finally {
      setLoading(false);
    }
  }

  async function onCreate(e: React.FormEvent) {
    e.preventDefault();
    setCreating(true);
    setError(null);
    try {
      const team = await coachApi.createTeam({
        name: formName,
        category: formCategory,
        season: formSeason,
      });
      setTeams((t) => [team, ...t]);
      setFormName('');
      setShowForm(false);
    } catch (err) {
      setError(err as ApiError);
    } finally {
      setCreating(false);
    }
  }

  return (
    <div className="space-y-6">
      <header className="flex items-center justify-between gap-4">
        <h1 className="text-2xl font-semibold">Takımlar</h1>
        <button
          onClick={() => setShowForm((s) => !s)}
          className={showForm ? 'btn-ghost' : 'btn-primary'}
        >
          {showForm ? 'İptal' : '+ Yeni takım'}
        </button>
      </header>

      <ErrorMessage error={error} />

      <label className="flex items-center gap-2 text-sm text-text-muted">
        <input
          type="checkbox"
          checked={includeInactive}
          onChange={(e) => setIncludeInactive(e.target.checked)}
          className="accent-accent"
        />
        Pasif takımları da göster
      </label>

      {showForm && (
        <form onSubmit={onCreate} className="card space-y-3">
          <div>
            <label className="label">Takım adı</label>
            <input
              required
              className="input"
              value={formName}
              onChange={(e) => setFormName(e.target.value)}
              placeholder="örn. A Takım, U17"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">Kategori</label>
              <select
                required
                className="input"
                value={formCategory}
                onChange={(e) => setFormCategory(e.target.value)}
              >
                {CATEGORIES.map((c) => (
                  <option key={c.value} value={c.value}>
                    {c.label}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="label">Sezon</label>
              <input
                required
                className="input"
                value={formSeason}
                onChange={(e) => setFormSeason(e.target.value)}
                placeholder="2026-2027"
              />
            </div>
          </div>
          <button type="submit" className="btn-primary w-full" disabled={creating}>
            {creating ? 'Oluşturuluyor...' : 'Takımı oluştur'}
          </button>
        </form>
      )}

      {loading ? (
        <div className="py-10 flex justify-center">
          <Spinner size={28} />
        </div>
      ) : teams.length === 0 ? (
        <div className="card text-center py-10">
          <p className="text-text-muted">Henüz takımın yok.</p>
          {!showForm && (
            <button onClick={() => setShowForm(true)} className="btn-primary mt-4">
              İlk takımını oluştur
            </button>
          )}
        </div>
      ) : (
        <ul className="space-y-2">
          {teams.map((team) => (
            <li key={team.id}>
              <Link
                href={`/teams/${team.id}`}
                className="card flex items-center justify-between hover:border-border-strong transition"
              >
                <div>
                  <div className="font-medium flex items-center gap-2">
                    {team.name}
                    {!team.active && <span className="badge">Pasif</span>}
                  </div>
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
    </div>
  );
}
