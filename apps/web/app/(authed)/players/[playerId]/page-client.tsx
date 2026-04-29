'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { coachApi, type Player, type ProgramWithSessions } from '@/lib/coach-api';
import { chatApi } from '@/lib/chat-api';
import { Spinner } from '@/components/Spinner';
import { ErrorMessage } from '@/components/ErrorMessage';
import { ProgramViewer, microcycleLabel } from '@/components/ProgramViewer';
import { ComplianceSummary } from '@/components/ComplianceSummary';
import { formatBirthDateAge, isoDate, mondayOf, positionLabel } from '@/lib/format';
import type { ApiError } from '@/lib/api';

export default function PlayerDetailPage() {
  const params = useParams<{ playerId: string }>();
  const router = useRouter();
  const playerId = params.playerId;

  const [player, setPlayer] = useState<Player | null>(null);
  const [program, setProgram] = useState<ProgramWithSessions | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<ApiError | null>(null);

  const [microcycle, setMicrocycle] = useState('match_week');
  const [generating, setGenerating] = useState(false);
  const [openingChat, setOpeningChat] = useState(false);
  const [weekStart, setWeekStart] = useState(isoDate(mondayOf()));

  useEffect(() => {
    if (!playerId) return;
    void load();
  }, [playerId, weekStart]);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const [p, programs] = await Promise.all([
        coachApi.getPlayer(playerId),
        coachApi.listPrograms(playerId, weekStart),
      ]);
      setPlayer(p);
      setProgram(programs[0] ?? null);
    } catch (err) {
      setError(err as ApiError);
    } finally {
      setLoading(false);
    }
  }

  async function onGenerate() {
    setGenerating(true);
    setError(null);
    try {
      const p = await coachApi.generateProgram(playerId, {
        weekStartDate: weekStart,
        microcycleType: microcycle,
      });
      setProgram(p);
    } catch (err) {
      setError(err as ApiError);
    } finally {
      setGenerating(false);
    }
  }

  async function onOpenChat() {
    setOpeningChat(true);
    setError(null);
    try {
      const thread = await chatApi.startThreadWithPlayer(playerId);
      router.push(`/chat/${thread.id}`);
    } catch (err) {
      setError(err as ApiError);
      setOpeningChat(false);
    }
  }

  if (loading) {
    return (
      <div className="py-10 flex justify-center">
        <Spinner size={28} />
      </div>
    );
  }

  if (!player) {
    return <ErrorMessage error={error ?? 'Oyuncu bulunamadı'} />;
  }

  const { age } = formatBirthDateAge(player.birthDate);

  return (
    <div className="space-y-6">
      <header>
        <button onClick={() => router.back()} className="text-text-muted text-sm hover:text-text">
          ← Geri
        </button>
        <div className="flex items-start gap-4 mt-2">
          <div className="w-14 h-14 rounded-full bg-bg-elevated border border-border flex items-center justify-center font-mono text-lg shrink-0">
            {player.jerseyNumber ?? '—'}
          </div>
          <div className="flex-1 min-w-0">
            <h1 className="text-2xl font-semibold leading-tight">{player.fullName}</h1>
            <div className="flex flex-wrap items-center gap-2 mt-1.5 text-sm text-text-muted">
              <span>{positionLabel(player.position)}</span>
              {player.detailedPosition && <span className="badge">{player.detailedPosition}</span>}
              <span>·</span>
              <span>{age} yaş</span>
              <span>·</span>
              <span>{player.heightCm}cm / {player.weightKg}kg</span>
              {!player.userId && <span className="badge-warn">davet bekliyor</span>}
            </div>
          </div>
          <button
            onClick={onOpenChat}
            className="btn-secondary text-sm px-3 py-1.5 shrink-0"
            disabled={openingChat}
            title="Bu oyuncuyla mesajlaş"
          >
            {openingChat ? '...' : '✉ Mesajlaş'}
          </button>
        </div>
      </header>

      <ErrorMessage error={error} />

      <section className="card">
        <div className="flex items-start justify-between gap-3 mb-3">
          <div>
            <h2 className="text-lg font-semibold">Haftalık Program</h2>
            <p className="text-text-muted text-xs mt-0.5">
              Pazartesi başlangıç. Engine kulüp ekipmanı + oyuncu durumuna göre üretir.
            </p>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3 mb-4">
          <div>
            <label className="label">Hafta başı (Pzt)</label>
            <input
              type="date"
              className="input"
              value={weekStart}
              onChange={(e) => setWeekStart(e.target.value)}
            />
          </div>
          <div>
            <label className="label">Mikro döngü</label>
            <select className="input" value={microcycle} onChange={(e) => setMicrocycle(e.target.value)}>
              <option value="match_week">Maç haftası</option>
              <option value="preseason">Hazırlık dönemi</option>
              <option value="recovery_week">Toparlanma haftası</option>
              <option value="off_season">Sezon arası</option>
            </select>
          </div>
        </div>

        <button onClick={onGenerate} className="btn-primary w-full" disabled={generating}>
          {generating ? 'Üretiliyor...' : program ? 'Tekrar üret (eski silinir)' : 'Programı üret'}
        </button>

        {program && (
          <div className="mt-4 text-xs text-text-muted">
            Mevcut program: {microcycleLabel(program.microcycleType)} · {program.sessions.length}{' '}
            seans · engine v{program.generatedBy.split('_').pop()}
          </div>
        )}
      </section>

      {program ? (
        <>
          <ComplianceSummary program={program} playerId={player.id} />
          <ProgramViewer program={program} trackable playerId={player.id} />
        </>
      ) : (
        <div className="card text-center py-8">
          <p className="text-text-muted">Bu hafta için henüz program üretilmedi.</p>
        </div>
      )}
    </div>
  );
}
