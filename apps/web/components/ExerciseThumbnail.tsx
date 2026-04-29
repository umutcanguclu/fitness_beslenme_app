'use client';

import { useEffect, useState } from 'react';
import type { ExerciseSummary } from '@/lib/coach-api';

interface Props {
  exercise: Pick<ExerciseSummary, 'imageUrls' | 'thumbnailUrl' | 'category' | 'nameTr'>;
  size?: 'sm' | 'md' | 'lg';
  /** İmage interval'ı (ms). Sadece imageUrls > 1 ise oynar. */
  intervalMs?: number;
}

const SIZE_CLS: Record<NonNullable<Props['size']>, string> = {
  sm: 'w-10 h-10',
  md: 'w-14 h-14',
  lg: 'w-24 h-24',
};

// free-exercise-db arka planı beyaz; koyu temada beyaz panel iyi durur.
const IMG_WRAPPER = 'bg-white rounded overflow-hidden flex items-center justify-center';

export function ExerciseThumbnail({ exercise, size = 'sm', intervalMs = 700 }: Props) {
  const sizeCls = SIZE_CLS[size];
  const has = exercise.imageUrls.length > 0;
  const [idx, setIdx] = useState(0);

  useEffect(() => {
    if (exercise.imageUrls.length <= 1) return;
    const t = setInterval(() => {
      setIdx((i) => (i + 1) % exercise.imageUrls.length);
    }, intervalMs);
    return () => clearInterval(t);
  }, [exercise.imageUrls.length, intervalMs]);

  if (has) {
    const src = exercise.imageUrls[idx] ?? exercise.thumbnailUrl ?? exercise.imageUrls[0];
    return (
      <div className={`${sizeCls} ${IMG_WRAPPER} shrink-0`}>
        <img
          src={src}
          alt={exercise.nameTr}
          loading="lazy"
          className="w-full h-full object-cover"
        />
      </div>
    );
  }

  // Görselsiz egzersizler için kategori-bazlı renkli placeholder
  return <CategoryFallback category={exercise.category} sizeCls={sizeCls} />;
}

const CATEGORY_VISUAL: Record<string, { label: string; bg: string; fg: string }> = {
  warmup:              { label: 'IS',  bg: 'bg-warn/15',     fg: 'text-warn' },
  endurance:           { label: 'DA',  bg: 'bg-success/15',  fg: 'text-success' },
  sprint_agility:      { label: 'SP',  bg: 'bg-accent/15',   fg: 'text-accent' },
  strength:            { label: 'KV',  bg: 'bg-danger/15',   fg: 'text-danger' },
  plyometric:          { label: 'PL',  bg: 'bg-warn/15',     fg: 'text-warn' },
  technical:           { label: 'TK',  bg: 'bg-accent/15',   fg: 'text-accent' },
  tactical:            { label: 'TA',  bg: 'bg-bg-elevated', fg: 'text-text-muted' },
  goalkeeper_specific: { label: 'GK',  bg: 'bg-success/15',  fg: 'text-success' },
  recovery:            { label: 'TR',  bg: 'bg-success/10',  fg: 'text-success' },
  cooldown:            { label: 'SO',  bg: 'bg-bg-elevated', fg: 'text-text-muted' },
  small_sided_game:    { label: 'SSG', bg: 'bg-accent/10',   fg: 'text-accent' },
  set_piece:           { label: 'DT',  bg: 'bg-warn/10',     fg: 'text-warn' },
};

function CategoryFallback({ category, sizeCls }: { category: string; sizeCls: string }) {
  const v = CATEGORY_VISUAL[category] ?? CATEGORY_VISUAL.tactical!;
  return (
    <div
      className={`${sizeCls} ${v.bg} ${v.fg} rounded flex items-center justify-center font-mono text-xs font-bold shrink-0`}
      aria-hidden
    >
      {v.label}
    </div>
  );
}
