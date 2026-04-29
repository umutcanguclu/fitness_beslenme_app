import type { ProgramWithSessions } from '@/lib/coach-api';

// Bu hafta için "programa uyum" özeti — koç bakar.
// 4 metrik: katılım %, log girişi %, ortalama RPE, ortalama yorgunluk
export function ComplianceSummary({
  program,
  playerId,
}: {
  program: ProgramWithSessions;
  playerId: string;
}) {
  const trainingSessions = program.sessions.filter((s) => s.category !== 'recovery');
  const totalSessions = program.sessions.length;
  if (totalSessions === 0) return null;

  let presentCount = 0;
  let absentCount = 0;
  let logCount = 0;
  let rpeSum = 0;
  let rpeN = 0;
  let fatigueSum = 0;
  let fatigueN = 0;

  for (const s of program.sessions) {
    const att = s.attendance.find((a) => a.playerId === playerId);
    if (att?.status === 'present' || att?.status === 'late') presentCount += 1;
    if (att?.status === 'absent') absentCount += 1;

    const log = s.logs.find((l) => l.playerId === playerId);
    if (log) {
      logCount += 1;
      if (log.rpe != null) {
        rpeSum += log.rpe;
        rpeN += 1;
      }
      if (log.fatigue != null) {
        fatigueSum += log.fatigue;
        fatigueN += 1;
      }
    }
  }

  const attendanceRate = totalSessions > 0 ? presentCount / totalSessions : 0;
  const logRate = totalSessions > 0 ? logCount / totalSessions : 0;
  const avgRpe = rpeN > 0 ? rpeSum / rpeN : null;
  const avgFatigue = fatigueN > 0 ? fatigueSum / fatigueN : null;

  return (
    <div className="card">
      <h3 className="text-sm uppercase tracking-wide text-text-muted mb-3">Bu hafta uyum</h3>
      <div className="grid grid-cols-2 gap-3">
        <Metric
          label="Katılım"
          value={`${presentCount}/${totalSessions}`}
          sub={`${Math.round(attendanceRate * 100)}%`}
          tone={attendanceRate >= 0.8 ? 'good' : attendanceRate >= 0.5 ? 'warn' : 'bad'}
        />
        <Metric
          label="RPE girişi"
          value={`${logCount}/${totalSessions}`}
          sub={`${Math.round(logRate * 100)}%`}
          tone={logRate >= 0.8 ? 'good' : logRate >= 0.5 ? 'warn' : 'bad'}
        />
        <Metric
          label="Ort. RPE"
          value={avgRpe != null ? avgRpe.toFixed(1) : '—'}
          sub={avgRpe != null ? rpeLabel(avgRpe) : 'veri yok'}
          tone="neutral"
        />
        <Metric
          label="Ort. yorgunluk"
          value={avgFatigue != null ? avgFatigue.toFixed(1) : '—'}
          sub={`${fatigueN} giriş`}
          tone="neutral"
        />
      </div>
      {absentCount > 0 && (
        <div className="mt-3 text-xs text-danger">
          {absentCount} antrenmana gelmedi
        </div>
      )}
      <div className="mt-3 text-xs text-text-dim">
        Toplam {trainingSessions.length} antrenman + {totalSessions - trainingSessions.length} toparlanma seansı
      </div>
    </div>
  );
}

function Metric({
  label,
  value,
  sub,
  tone,
}: {
  label: string;
  value: string;
  sub: string;
  tone: 'good' | 'warn' | 'bad' | 'neutral';
}) {
  const toneCls = {
    good: 'text-success',
    warn: 'text-warn',
    bad: 'text-danger',
    neutral: 'text-text',
  }[tone];
  return (
    <div className="bg-bg-elevated border border-border rounded p-3">
      <div className="text-xs text-text-muted">{label}</div>
      <div className={`text-2xl font-semibold mt-1 ${toneCls}`}>{value}</div>
      <div className="text-xs text-text-dim mt-0.5">{sub}</div>
    </div>
  );
}

function rpeLabel(rpe: number): string {
  if (rpe < 4) return 'düşük yük';
  if (rpe < 7) return 'orta yük';
  if (rpe < 8.5) return 'ağır yük';
  return 'çok ağır';
}
