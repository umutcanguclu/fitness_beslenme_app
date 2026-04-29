'use client';

import { useEffect, useState } from 'react';
import { useSession } from '@/lib/session';
import { coachApi, type ProgramWithSessions } from '@/lib/coach-api';
import { playerApi, type MePlayerResponse } from '@/lib/player-api';
import { Spinner } from '@/components/Spinner';
import { ErrorMessage } from '@/components/ErrorMessage';
import { ProgramViewer, microcycleLabel } from '@/components/ProgramViewer';
import { isoDate, mondayOf, positionLabel } from '@/lib/format';
import type { ApiError } from '@/lib/api';

export default function MyProgramPage() {
  const { user } = useSession();
  const [me, setMe] = useState<MePlayerResponse | null>(null);
  const [program, setProgram] = useState<ProgramWithSessions | null>(null);
  const [weekStart, setWeekStart] = useState(isoDate(mondayOf()));
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<ApiError | null>(null);

  useEffect(() => {
    if (!user) return;
    void load();
  }, [user, weekStart]);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const meData = await playerApi.getMe();
      setMe(meData);
      if (!meData.playerId) {
        setLoading(false);
        return;
      }
      const programs = await coachApi.listPrograms(meData.playerId, weekStart);
      setProgram(programs[0] ?? null);
    } catch (err) {
      setError(err as ApiError);
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="py-10 flex justify-center">
        <Spinner size={28} />
      </div>
    );
  }

  // Henüz player profile bağlı değil — coach tarafından oluşturulmamış olabilir.
  if (!me?.playerId || !me.player) {
    return (
      <div className="space-y-4">
        <h1 className="text-2xl font-semibold">Programım</h1>
        <div className="card text-center py-10">
          <p className="text-text-muted">
            Oyuncu profilin henüz takıma bağlı değil.
            <br />
            Antrenörünle konuş, davet kodunla yeniden eşleşmen gerekebilir.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <header>
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-full bg-bg-elevated border border-border flex items-center justify-center font-mono text-lg shrink-0">
            {me.player.jerseyNumber ?? '—'}
          </div>
          <div className="flex-1 min-w-0">
            <h1 className="text-xl font-semibold leading-tight">{me.player.fullName}</h1>
            <div className="text-text-muted text-sm">{positionLabel(me.player.position)}</div>
          </div>
        </div>
      </header>

      <ErrorMessage error={error} />

      <div>
        <label className="label">Hafta başı (Pzt)</label>
        <input
          type="date"
          className="input"
          value={weekStart}
          onChange={(e) => setWeekStart(e.target.value)}
        />
      </div>

      {program ? (
        <>
          <div className="text-sm text-text-muted">
            {microcycleLabel(program.microcycleType)} · {program.sessions.length} seans
          </div>
          <ProgramViewer program={program} loggable playerId={me.player.id} />
          <div className="text-xs text-text-dim text-center pt-2">
            Antrenman bitince RPE'ni gir — antrenörün haftalık yükünü görür.
          </div>
        </>
      ) : (
        <div className="card text-center py-10">
          <p className="text-text-muted">
            Bu hafta için henüz program üretilmedi.
            <br />
            Antrenörün hazırlayınca burada görünecek.
          </p>
        </div>
      )}
    </div>
  );
}
