'use client';

import { useState } from 'react';
import type {
  ProgramWithSessions,
  SessionLog,
  TrainingAttendance,
  TrainingSession,
} from '@/lib/coach-api';
import { categoryLabel, formatDayName } from '@/lib/format';
import { SessionLogForm } from './SessionLogForm';
import { AttendanceControl } from './AttendanceControl';
import { ExerciseThumbnail } from './ExerciseThumbnail';

interface Props {
  program: ProgramWithSessions;
  /** Oyuncu ekranında true: her seansa RPE log formu eklenir. */
  loggable?: boolean;
  /** Koç ekranında true: her seansa attendance butonları + log read-only görünür. */
  trackable?: boolean;
  /** trackable veya loggable ise hangi oyuncu için. */
  playerId?: string;
}

const INTENSITY_BAR: Record<number, string> = {
  0: '',
  1: 'bg-success/40',
  2: 'bg-success/60',
  3: 'bg-warn/60',
  4: 'bg-warn/80',
  5: 'bg-danger/70',
};

export function ProgramViewer({ program, loggable = false, trackable = false, playerId }: Props) {
  const [logs, setLogs] = useState<Map<string, SessionLog>>(() => {
    const initial = new Map<string, SessionLog>();
    for (const s of program.sessions) {
      const own = playerId ? s.logs.find((l) => l.playerId === playerId) : s.logs[0];
      if (own) initial.set(s.id, own);
    }
    return initial;
  });

  const [attendance, setAttendance] = useState<Map<string, TrainingAttendance>>(() => {
    const initial = new Map<string, TrainingAttendance>();
    for (const s of program.sessions) {
      const own = playerId ? s.attendance.find((a) => a.playerId === playerId) : s.attendance[0];
      if (own) initial.set(s.id, own);
    }
    return initial;
  });

  const sessionsByDay = new Map<string, TrainingSession>();
  for (const s of program.sessions) {
    sessionsByDay.set(s.date.slice(0, 10), s);
  }

  const weekStart = new Date(program.weekStartDate);
  const days: { date: Date; iso: string }[] = [];
  for (let i = 0; i < 7; i += 1) {
    const d = new Date(weekStart);
    d.setDate(d.getDate() + i);
    days.push({ date: d, iso: d.toISOString().slice(0, 10) });
  }

  return (
    <div className="space-y-3">
      {days.map(({ date, iso }) => {
        const session = sessionsByDay.get(iso);
        const log = session ? logs.get(session.id) : null;
        const att = session ? attendance.get(session.id) : null;
        return (
          <div key={iso} className={`card ${session ? '' : 'opacity-50'}`}>
            <div className="flex items-center gap-3">
              <div className="text-center w-12 shrink-0">
                <div className="text-xs text-text-muted uppercase">{formatDayName(date)}</div>
                <div className="text-lg font-semibold">{date.getDate()}</div>
              </div>
              <div className="flex-1 min-w-0">
                {session ? (
                  <>
                    <div className="font-medium flex items-center gap-2 flex-wrap">
                      {categoryLabel(session.category)}
                      {log && (
                        <span className="badge-accent text-[10px]">
                          RPE {log.rpe ?? '—'}{log.fatigue != null ? ` · F${log.fatigue}` : ''}
                        </span>
                      )}
                    </div>
                    <div className="text-xs text-text-muted">
                      {session.durationMinutes} dk · {session.exercises.length} egzersiz
                      {session.notes ? ` · ${session.notes}` : ''}
                    </div>
                  </>
                ) : (
                  <div className="text-sm text-text-muted">İzin günü</div>
                )}
              </div>
              {session && (
                <div className="flex gap-0.5">
                  {[1, 2, 3, 4, 5].map((lvl) => (
                    <div
                      key={lvl}
                      className={`w-1.5 h-6 rounded-sm ${
                        lvl <= session.intensity ? INTENSITY_BAR[session.intensity] : 'bg-bg-elevated'
                      }`}
                    />
                  ))}
                </div>
              )}
            </div>

            {/* Attendance — koç ekranında her zaman görünür */}
            {trackable && session && playerId && (
              <div className="mt-3">
                <AttendanceControl
                  sessionId={session.id}
                  playerId={playerId}
                  attendance={att ?? null}
                  onChange={(a) =>
                    setAttendance((prev) => {
                      const next = new Map(prev);
                      next.set(a.sessionId, a);
                      return next;
                    })
                  }
                />
              </div>
            )}

            {/* Koç ekranında oyuncu RPE'sini read-only göster */}
            {trackable && session && log && (
              <div className="mt-3 pt-3 border-t border-border text-xs space-y-1">
                <div className="text-text-muted uppercase tracking-wide">Oyuncunun girişi</div>
                <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-text">
                  <span>RPE: <span className="font-medium">{log.rpe ?? '—'}</span></span>
                  <span>Yorgunluk: <span className="font-medium">{log.fatigue ?? '—'}</span></span>
                  <span>Ruh hali: <span className="font-medium">{log.mood ?? '—'}</span></span>
                  <span>Uyku: <span className="font-medium">{log.sleepHours != null ? `${log.sleepHours} sa` : '—'}</span></span>
                </div>
                {log.notes && <div className="text-text-muted italic">"{log.notes}"</div>}
              </div>
            )}

            {session && session.exercises.length > 0 && (
              <details className="mt-3">
                <summary className="text-sm text-accent cursor-pointer select-none">
                  Egzersizleri göster
                </summary>
                <ol className="mt-2 space-y-2 text-sm">
                  {session.exercises.map((ex) => {
                    const parts: string[] = [];
                    if (ex.sets) parts.push(`${ex.sets} set`);
                    if (ex.reps) parts.push(`${ex.reps} tekrar`);
                    if (ex.durationSeconds) parts.push(formatDuration(ex.durationSeconds));
                    if (ex.distanceMeters) parts.push(`${ex.distanceMeters}m`);
                    if (ex.restSeconds) parts.push(`${ex.restSeconds}sn dinlenme`);
                    return (
                      <li key={ex.id} className="flex gap-3 items-start">
                        <span className="text-text-dim font-mono text-xs w-5 shrink-0 mt-3 text-right">
                          {ex.order + 1}.
                        </span>
                        <ExerciseThumbnail exercise={ex.exercise} size="md" />
                        <div className="flex-1 min-w-0 pt-0.5">
                          <div className="font-medium">{ex.exercise.nameTr}</div>
                          {parts.length > 0 && (
                            <div className="text-xs text-text-muted mt-0.5">{parts.join(' · ')}</div>
                          )}
                        </div>
                      </li>
                    );
                  })}
                </ol>
              </details>
            )}

            {/* Oyuncu kendi RPE'sini girer */}
            {loggable && session && (
              <SessionLogForm
                sessionId={session.id}
                existing={log ?? null}
                onSaved={(saved) =>
                  setLogs((prev) => {
                    const next = new Map(prev);
                    next.set(saved.sessionId, saved);
                    return next;
                  })
                }
              />
            )}
          </div>
        );
      })}
    </div>
  );
}

function formatDuration(seconds: number): string {
  if (seconds >= 60) {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return s ? `${m}dk ${s}sn` : `${m} dk`;
  }
  return `${seconds} sn`;
}

export function microcycleLabel(t: string): string {
  const labels: Record<string, string> = {
    match_week: 'Maç haftası',
    preseason: 'Hazırlık dönemi',
    recovery_week: 'Toparlanma haftası',
    off_season: 'Sezon arası',
  };
  return labels[t] ?? t;
}
