'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { coachApi, type RosterEntry, type Team } from '@/lib/coach-api';
import { Spinner } from '@/components/Spinner';
import { ErrorMessage } from '@/components/ErrorMessage';
import { InviteCard } from '@/components/InviteCard';
import { formatBirthDateAge, positionLabel } from '@/lib/format';
import type { ApiError } from '@/lib/api';

const POSITIONS = [
  { value: 'goalkeeper', label: 'Kaleci' },
  { value: 'defender', label: 'Defans' },
  { value: 'midfielder', label: 'Orta Saha' },
  { value: 'forward', label: 'Forvet' },
];

const FOOT = [
  { value: 'right', label: 'Sağ' },
  { value: 'left', label: 'Sol' },
  { value: 'both', label: 'Her ikisi' },
];

const EMPLOYMENT = [
  { value: 'amateur', label: 'Amatör' },
  { value: 'semi_pro', label: 'Yarı pro' },
  { value: 'full_time_pro', label: 'Profesyonel' },
  { value: 'student', label: 'Öğrenci' },
  { value: 'working', label: 'Çalışan' },
];

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

export default function TeamDetailPage() {
  const params = useParams<{ teamId: string }>();
  const router = useRouter();
  const teamId = params.teamId;

  const [team, setTeam] = useState<Team | null>(null);
  const [roster, setRoster] = useState<RosterEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<ApiError | null>(null);

  // Player ekleme formu
  const [showPlayerForm, setShowPlayerForm] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [lastInvite, setLastInvite] = useState<{ name: string; code: string } | null>(null);
  const [fullName, setFullName] = useState('');
  const [birthDate, setBirthDate] = useState('');
  const [position, setPosition] = useState('midfielder');
  const [preferredFoot, setPreferredFoot] = useState<'left' | 'right' | 'both'>('right');
  const [heightCm, setHeightCm] = useState('178');
  const [weightKg, setWeightKg] = useState('72');
  const [jerseyNumber, setJerseyNumber] = useState('');
  const [employmentStatus, setEmploymentStatus] = useState('amateur');

  // Takım düzenleme
  const [editing, setEditing] = useState(false);
  const [editName, setEditName] = useState('');
  const [editCategory, setEditCategory] = useState('');
  const [editSeason, setEditSeason] = useState('');
  const [editActive, setEditActive] = useState(true);
  const [savingEdit, setSavingEdit] = useState(false);

  // Silme
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    if (!teamId) return;
    void load();
  }, [teamId]);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const [t, r] = await Promise.all([coachApi.getTeam(teamId), coachApi.listRoster(teamId)]);
      setTeam(t);
      setRoster(r);
    } catch (err) {
      setError(err as ApiError);
    } finally {
      setLoading(false);
    }
  }

  function startEdit() {
    if (!team) return;
    setEditName(team.name);
    setEditCategory(team.category);
    setEditSeason(team.season);
    setEditActive(team.active);
    setEditing(true);
  }

  async function saveEdit(e: React.FormEvent) {
    e.preventDefault();
    if (!team) return;
    setSavingEdit(true);
    setError(null);
    try {
      const updated = await coachApi.updateTeam(teamId, {
        name: editName,
        category: editCategory,
        season: editSeason,
        active: editActive,
      });
      setTeam(updated);
      setEditing(false);
    } catch (err) {
      setError(err as ApiError);
    } finally {
      setSavingEdit(false);
    }
  }

  async function deleteTeam() {
    if (!team) return;
    const confirmed = window.confirm(
      `"${team.name}" takımı silinsin mi?\n\nTüm kadro, programlar ve maçlar geri alınamaz şekilde silinir.`,
    );
    if (!confirmed) return;
    setDeleting(true);
    setError(null);
    try {
      await coachApi.deleteTeam(teamId);
      router.replace('/teams');
    } catch (err) {
      setError(err as ApiError);
      setDeleting(false);
    }
  }

  async function removePlayer(playerId: string, name: string) {
    if (!window.confirm(`${name} bu takımın kadrosundan çıkarılsın mı?\n\nOyuncu profili silinmez, sadece kadro üyeliği biter.`)) return;
    try {
      await coachApi.removeFromRoster(teamId, playerId);
      setRoster((r) => r.filter((entry) => entry.playerId !== playerId));
    } catch (err) {
      setError(err as ApiError);
    }
  }

  function resetPlayerForm() {
    setFullName('');
    setBirthDate('');
    setPosition('midfielder');
    setPreferredFoot('right');
    setHeightCm('178');
    setWeightKg('72');
    setJerseyNumber('');
    setEmploymentStatus('amateur');
  }

  async function onCreatePlayer(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const result = await coachApi.createPlayer(teamId, {
        fullName,
        birthDate,
        position,
        preferredFoot,
        heightCm: Number(heightCm),
        weightKg: Number(weightKg),
        jerseyNumber: jerseyNumber ? Number(jerseyNumber) : null,
        employmentStatus,
      });
      setLastInvite({ name: result.player.fullName, code: result.invite.code });
      setRoster((r) => [
        ...r,
        { teamId, playerId: result.player.id, isCaptain: false, player: result.player },
      ]);
      resetPlayerForm();
      setShowPlayerForm(false);
    } catch (err) {
      setError(err as ApiError);
    } finally {
      setSubmitting(false);
    }
  }

  if (loading) {
    return (
      <div className="py-10 flex justify-center">
        <Spinner size={28} />
      </div>
    );
  }

  if (!team) {
    return <ErrorMessage error={error ?? 'Takım bulunamadı'} />;
  }

  return (
    <div className="space-y-6">
      <header>
        <Link href="/teams" className="text-text-muted text-sm hover:text-text">
          ← Takımlar
        </Link>
        {editing ? (
          <form onSubmit={saveEdit} className="card mt-2 space-y-3">
            <div>
              <label className="label">Takım adı</label>
              <input required className="input" value={editName} onChange={(e) => setEditName(e.target.value)} />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="label">Kategori</label>
                <select className="input" value={editCategory} onChange={(e) => setEditCategory(e.target.value)}>
                  {CATEGORIES.map((c) => (
                    <option key={c.value} value={c.value}>{c.label}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="label">Sezon</label>
                <input className="input" value={editSeason} onChange={(e) => setEditSeason(e.target.value)} />
              </div>
            </div>
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={editActive}
                onChange={(e) => setEditActive(e.target.checked)}
                className="accent-accent"
              />
              Aktif
            </label>
            <div className="flex gap-2">
              <button type="submit" className="btn-primary flex-1" disabled={savingEdit}>
                {savingEdit ? 'Kaydediliyor...' : 'Kaydet'}
              </button>
              <button type="button" className="btn-ghost" onClick={() => setEditing(false)}>
                İptal
              </button>
            </div>
          </form>
        ) : (
          <div className="flex items-start justify-between gap-3 mt-2">
            <div>
              <h1 className="text-2xl font-semibold flex items-center gap-2">
                {team.name}
                {!team.active && <span className="badge">Pasif</span>}
              </h1>
              <div className="text-text-muted text-sm">
                {team.category.toUpperCase()} · {team.season}
              </div>
            </div>
            <div className="flex flex-col gap-1.5 shrink-0">
              <button onClick={startEdit} className="btn-secondary text-sm px-3 py-1.5">
                Düzenle
              </button>
              <button onClick={deleteTeam} className="btn-danger text-sm px-3 py-1.5" disabled={deleting}>
                {deleting ? 'Siliniyor...' : 'Sil'}
              </button>
            </div>
          </div>
        )}
      </header>

      <ErrorMessage error={error} />

      {lastInvite && <InviteCard invite={lastInvite} onClose={() => setLastInvite(null)} />}

      <section>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-lg font-semibold">Kadro <span className="text-text-muted text-sm font-normal">({roster.length})</span></h2>
          <button
            onClick={() => setShowPlayerForm((s) => !s)}
            className={showPlayerForm ? 'btn-ghost text-sm px-3 py-1.5' : 'btn-primary text-sm px-3 py-1.5'}
          >
            {showPlayerForm ? 'İptal' : '+ Oyuncu'}
          </button>
        </div>

        {showPlayerForm && (
          <form onSubmit={onCreatePlayer} className="card space-y-3 mb-4">
            <div>
              <label className="label">Ad Soyad</label>
              <input required className="input" value={fullName} onChange={(e) => setFullName(e.target.value)} />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="label">Doğum tarihi</label>
                <input type="date" required className="input" value={birthDate} onChange={(e) => setBirthDate(e.target.value)} />
              </div>
              <div>
                <label className="label">Forma no</label>
                <input
                  type="number"
                  inputMode="numeric"
                  min={1}
                  max={99}
                  className="input"
                  value={jerseyNumber}
                  onChange={(e) => setJerseyNumber(e.target.value)}
                  placeholder="opsiyonel"
                />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="label">Mevki</label>
                <select className="input" value={position} onChange={(e) => setPosition(e.target.value)}>
                  {POSITIONS.map((p) => (
                    <option key={p.value} value={p.value}>{p.label}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="label">Tercih ettiği ayak</label>
                <select className="input" value={preferredFoot} onChange={(e) => setPreferredFoot(e.target.value as 'left' | 'right' | 'both')}>
                  {FOOT.map((f) => (
                    <option key={f.value} value={f.value}>{f.label}</option>
                  ))}
                </select>
              </div>
            </div>
            <div className="grid grid-cols-3 gap-3">
              <div>
                <label className="label">Boy (cm)</label>
                <input type="number" inputMode="numeric" min={120} max={230} required className="input" value={heightCm} onChange={(e) => setHeightCm(e.target.value)} />
              </div>
              <div>
                <label className="label">Kilo (kg)</label>
                <input type="number" inputMode="decimal" step="0.1" min={30} max={150} required className="input" value={weightKg} onChange={(e) => setWeightKg(e.target.value)} />
              </div>
              <div>
                <label className="label">Statü</label>
                <select className="input" value={employmentStatus} onChange={(e) => setEmploymentStatus(e.target.value)}>
                  {EMPLOYMENT.map((e) => (
                    <option key={e.value} value={e.value}>{e.label}</option>
                  ))}
                </select>
              </div>
            </div>
            <button type="submit" className="btn-primary w-full" disabled={submitting}>
              {submitting ? 'Oluşturuluyor...' : 'Oyuncu profilini oluştur + davet üret'}
            </button>
          </form>
        )}

        {roster.length === 0 ? (
          <div className="card text-center py-8">
            <p className="text-text-muted">Henüz kadroda kimse yok.</p>
          </div>
        ) : (
          <ul className="space-y-2">
            {roster.map((entry) => {
              const { age } = formatBirthDateAge(entry.player.birthDate);
              return (
                <li key={entry.playerId} className="card flex items-center gap-3 hover:border-border-strong transition group">
                  <Link
                    href={`/players/${entry.playerId}`}
                    className="flex items-center gap-3 flex-1 min-w-0"
                  >
                    <div className="w-10 h-10 rounded-full bg-bg-elevated border border-border flex items-center justify-center font-mono text-sm shrink-0">
                      {entry.player.jerseyNumber ?? '—'}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="font-medium truncate">{entry.player.fullName}</div>
                      <div className="text-xs text-text-muted">
                        {positionLabel(entry.player.position)} · {age} yaş
                        {entry.player.userId ? '' : ' · davet bekliyor'}
                      </div>
                    </div>
                  </Link>
                  <button
                    onClick={() => removePlayer(entry.playerId, entry.player.fullName)}
                    className="btn-ghost text-text-dim hover:text-danger px-2 py-1 text-lg leading-none shrink-0"
                    aria-label="Kadrodan çıkar"
                    title="Kadrodan çıkar"
                  >
                    ×
                  </button>
                </li>
              );
            })}
          </ul>
        )}
      </section>
    </div>
  );
}
