'use client';

import { useState } from 'react';
import { playerApi } from '@/lib/player-api';
import type { SessionLog } from '@/lib/coach-api';
import type { ApiError } from '@/lib/api';

interface Props {
  sessionId: string;
  existing: SessionLog | null;
  onSaved: (log: SessionLog) => void;
}

const RPE_DESCRIPTIONS: Record<number, string> = {
  1: 'Çok kolay',
  2: 'Kolay',
  3: 'Hafif',
  4: 'Orta',
  5: 'Biraz zor',
  6: 'Zor',
  7: 'Çok zor',
  8: 'Çok çok zor',
  9: 'Maksimuma yakın',
  10: 'Maksimum çaba',
};

export function SessionLogForm({ sessionId, existing, onSaved }: Props) {
  const [rpe, setRpe] = useState<number | null>(existing?.rpe ?? null);
  const [fatigue, setFatigue] = useState<number | null>(existing?.fatigue ?? null);
  const [mood, setMood] = useState<number | null>(existing?.mood ?? null);
  const [sleepHours, setSleepHours] = useState<string>(
    existing?.sleepHours != null ? String(existing.sleepHours) : '',
  );
  const [notes, setNotes] = useState(existing?.notes ?? '');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      const log = await playerApi.logSession(sessionId, {
        rpe,
        fatigue,
        mood,
        sleepHours: sleepHours ? Number(sleepHours) : null,
        notes: notes.trim() || null,
      });
      onSaved(log);
    } catch (err) {
      setError(err as ApiError);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="space-y-4 mt-4 pt-4 border-t border-border">
      {/* RPE 1-10 — büyük tıklanabilir butonlar (saha kenarında parmakla) */}
      <div>
        <div className="flex items-baseline justify-between mb-2">
          <label className="text-sm font-medium">Algılanan zorluk (RPE)</label>
          {rpe !== null && <span className="text-xs text-text-muted">{RPE_DESCRIPTIONS[rpe]}</span>}
        </div>
        <div className="grid grid-cols-10 gap-1">
          {Array.from({ length: 10 }, (_, i) => i + 1).map((n) => (
            <button
              key={n}
              type="button"
              onClick={() => setRpe(n)}
              className={`py-3 rounded text-sm font-medium border transition ${
                rpe === n
                  ? 'bg-accent text-bg border-accent'
                  : 'bg-bg-elevated text-text-muted border-border hover:border-border-strong'
              }`}
            >
              {n}
            </button>
          ))}
        </div>
      </div>

      {/* Fatigue 1-5 ve Mood 1-5 yan yana */}
      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="text-sm font-medium block mb-2">Yorgunluk (1-5)</label>
          <div className="flex gap-1">
            {[1, 2, 3, 4, 5].map((n) => (
              <button
                key={n}
                type="button"
                onClick={() => setFatigue(n)}
                className={`flex-1 py-2 rounded text-sm font-medium border ${
                  fatigue === n
                    ? 'bg-warn/20 text-warn border-warn/50'
                    : 'bg-bg-elevated text-text-muted border-border'
                }`}
              >
                {n}
              </button>
            ))}
          </div>
        </div>
        <div>
          <label className="text-sm font-medium block mb-2">Ruh hali (1-5)</label>
          <div className="flex gap-1">
            {[1, 2, 3, 4, 5].map((n) => (
              <button
                key={n}
                type="button"
                onClick={() => setMood(n)}
                className={`flex-1 py-2 rounded text-sm font-medium border ${
                  mood === n
                    ? 'bg-success/20 text-success border-success/50'
                    : 'bg-bg-elevated text-text-muted border-border'
                }`}
              >
                {n}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="text-sm font-medium block mb-2">Uyku (saat)</label>
          <input
            type="number"
            inputMode="decimal"
            step="0.5"
            min={0}
            max={14}
            className="input"
            value={sleepHours}
            onChange={(e) => setSleepHours(e.target.value)}
            placeholder="örn. 7.5"
          />
        </div>
        <div>
          <label className="text-sm font-medium block mb-2">Not</label>
          <input
            className="input"
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="opsiyonel"
            maxLength={200}
          />
        </div>
      </div>

      {error && <div className="text-sm text-danger">{error.message}</div>}

      <button type="submit" className="btn-primary w-full" disabled={submitting}>
        {submitting ? 'Kaydediliyor...' : existing ? 'Güncelle' : 'Kaydet'}
      </button>
    </form>
  );
}
