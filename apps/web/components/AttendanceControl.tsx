'use client';

import { useState } from 'react';
import { coachApi, type AttendanceStatus, type TrainingAttendance } from '@/lib/coach-api';

interface Props {
  sessionId: string;
  playerId: string;
  attendance: TrainingAttendance | null;
  onChange: (attendance: TrainingAttendance) => void;
}

const OPTIONS: Array<{ value: AttendanceStatus; label: string; cls: string }> = [
  { value: 'present', label: 'Geldi', cls: 'bg-success/20 text-success border-success/40' },
  { value: 'late', label: 'Geç', cls: 'bg-warn/20 text-warn border-warn/40' },
  { value: 'excused', label: 'İzinli', cls: 'bg-bg-elevated text-text-muted border-border-strong' },
  { value: 'absent', label: 'Yok', cls: 'bg-danger/20 text-danger border-danger/40' },
];

const STATUS_LABEL: Record<AttendanceStatus, string> = {
  present: '✓ Geldi',
  absent: '× Yok',
  late: '⏰ Geç geldi',
  excused: '✋ İzinli',
};

export function AttendanceControl({ sessionId, playerId, attendance, onChange }: Props) {
  const [submitting, setSubmitting] = useState<AttendanceStatus | null>(null);
  const [editing, setEditing] = useState(false);

  async function pick(status: AttendanceStatus) {
    setSubmitting(status);
    try {
      const result = await coachApi.setAttendance(sessionId, playerId, status);
      // bulk endpoint dizi döner — bizim ekliyorduğumuz tek entry'i alıyoruz
      const entry = result[0];
      if (entry) onChange(entry);
      setEditing(false);
    } finally {
      setSubmitting(null);
    }
  }

  // Kayıtlı bir attendance varsa rozet + "değiştir" linki
  if (attendance && !editing) {
    const opt = OPTIONS.find((o) => o.value === attendance.status);
    return (
      <div className="flex items-center gap-2 text-sm">
        <span className={`px-2 py-1 rounded border text-xs font-medium ${opt?.cls ?? 'badge'}`}>
          {STATUS_LABEL[attendance.status]}
        </span>
        <button onClick={() => setEditing(true)} className="text-text-dim hover:text-text text-xs underline">
          değiştir
        </button>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-4 gap-1.5">
      {OPTIONS.map((o) => (
        <button
          key={o.value}
          onClick={() => pick(o.value)}
          disabled={submitting !== null}
          className={`py-2 rounded text-xs font-medium border transition ${
            submitting === o.value
              ? 'opacity-50'
              : `bg-bg-elevated text-text-muted border-border hover:${o.cls}`
          }`}
        >
          {submitting === o.value ? '...' : o.label}
        </button>
      ))}
    </div>
  );
}
