import type { MicrocycleType, TrainingCategory } from '@fittrack/shared';
import type { DayPlan, MatchContext, PlayerSnapshot } from './types.js';

// Maç haftası MD-X periyodizasyonu (haftada 1 maç varsayımı).
// Maç günü dahil 7 günlük tablo. dayOffset = match'e göre relatif gün.
//   MD-3 → yüksek hacim (kuvvet + dayanıklılık)
//   MD-2 → yüksek şiddet (sürat + taktik)
//   MD-1 → düşük yük, teknik + duran top + tactical recap
//   MD   → maç (off — antrenman yok)
//   MD+1 → recovery (hafif jog + foam roll)
//   MD+2 → off veya çok hafif
//   MD+3 → yeniden yüklenme başlar
const MATCH_WEEK_TABLE: Record<number, Pick<DayPlan, 'categories' | 'intensity' | 'durationMinutes' | 'isOff'> & { notes?: string }> = {
  [-5]: { categories: ['recovery'], intensity: 1, durationMinutes: 30, isOff: false, notes: 'Aktif toparlanma' },
  [-4]: { categories: ['warmup', 'strength', 'endurance', 'cooldown'], intensity: 4, durationMinutes: 90, isOff: false, notes: 'MD-4: yüksek hacim' },
  [-3]: { categories: ['warmup', 'strength', 'endurance', 'cooldown'], intensity: 4, durationMinutes: 90, isOff: false, notes: 'MD-3: yüksek hacim' },
  [-2]: { categories: ['warmup', 'sprint_agility', 'small_sided_game', 'cooldown'], intensity: 4, durationMinutes: 80, isOff: false, notes: 'MD-2: yüksek şiddet' },
  [-1]: { categories: ['warmup', 'technical', 'set_piece', 'cooldown'], intensity: 2, durationMinutes: 60, isOff: false, notes: 'MD-1: aktivasyon + taktik' },
  [0]: { categories: [], intensity: 0, durationMinutes: 0, isOff: true, notes: 'Maç günü' },
  [1]: { categories: ['recovery'], intensity: 1, durationMinutes: 25, isOff: false, notes: 'MD+1: toparlanma' },
};

// Maç olmayan haftada (preseason / off-season) genel günlük dağılım.
const GENERIC_WEEK_TEMPLATE: Record<number, Pick<DayPlan, 'categories' | 'intensity' | 'durationMinutes' | 'isOff'>> = {
  0: { categories: ['warmup', 'strength', 'endurance', 'cooldown'], intensity: 4, durationMinutes: 90, isOff: false },
  1: { categories: ['warmup', 'sprint_agility', 'technical', 'cooldown'], intensity: 3, durationMinutes: 75, isOff: false },
  2: { categories: ['recovery'], intensity: 1, durationMinutes: 30, isOff: false },
  3: { categories: ['warmup', 'plyometric', 'small_sided_game', 'cooldown'], intensity: 4, durationMinutes: 80, isOff: false },
  4: { categories: ['warmup', 'technical', 'tactical', 'cooldown'], intensity: 2, durationMinutes: 60, isOff: false },
  5: { categories: ['warmup', 'endurance', 'cooldown'], intensity: 3, durationMinutes: 70, isOff: false },
  6: { categories: [], intensity: 0, durationMinutes: 0, isOff: true },
};

export function planWeek(opts: {
  weekStartDate: Date; // pazartesi
  microcycleType: MicrocycleType;
  match: MatchContext;
  player: PlayerSnapshot;
}): DayPlan[] {
  const days: DayPlan[] = [];
  for (let i = 0; i < 7; i += 1) {
    const date = addDays(opts.weekStartDate, i);
    const base = pickDayBase(i, opts);
    const adjusted = applyAvailabilityAdjustments(base, opts.player);
    days.push({
      dayOfWeek: i,
      date,
      categories: adjusted.categories,
      intensity: adjusted.intensity,
      durationMinutes: adjusted.durationMinutes,
      isOff: adjusted.isOff,
      notes: adjusted.notes,
    });
  }
  return days;
}

function pickDayBase(dayIndex: number, opts: {
  microcycleType: MicrocycleType;
  match: MatchContext;
}): Pick<DayPlan, 'categories' | 'intensity' | 'durationMinutes' | 'isOff'> & { notes?: string } {
  const fallback = GENERIC_WEEK_TEMPLATE[dayIndex] ?? GENERIC_WEEK_TEMPLATE[0]!;
  if (opts.microcycleType === 'match_week' && opts.match.matchDayOfWeek !== null) {
    const offset = dayIndex - opts.match.matchDayOfWeek;
    return MATCH_WEEK_TABLE[offset] ?? fallback;
  }
  return fallback;
}

// Sakat / şüpheli oyuncuda tüm günü recovery'ye çekme veya yumuşatma.
function applyAvailabilityAdjustments(
  base: ReturnType<typeof pickDayBase>,
  player: PlayerSnapshot,
): typeof base {
  if (base.isOff) return base;

  const status = player.availabilityStatus;
  if (status === 'injured' || status === 'ill' || status === 'away' || status === 'suspended') {
    return { categories: [], intensity: 0, durationMinutes: 0, isOff: true, notes: `Oyuncu durumu: ${status}` };
  }
  if (status === 'doubtful') {
    return {
      categories: filterToLowImpact(base.categories),
      intensity: Math.max(1, base.intensity - 2),
      durationMinutes: Math.round(base.durationMinutes * 0.6),
      isOff: false,
      notes: `${base.notes ?? ''} (şüpheli — yük düşürüldü)`.trim(),
    };
  }
  if (status === 'limited') {
    return {
      categories: filterToLowImpact(base.categories),
      intensity: Math.max(1, base.intensity - 1),
      durationMinutes: Math.round(base.durationMinutes * 0.75),
      isOff: false,
      notes: `${base.notes ?? ''} (kısıtlı — düşük şiddet)`.trim(),
    };
  }

  // Aktif sakatlık varsa (durum henüz availability'ye yansımamışsa) plyometric/sprint çıkar.
  if (player.hasActiveInjury) {
    return {
      ...base,
      categories: base.categories.filter((c) => c !== 'plyometric' && c !== 'sprint_agility'),
      notes: `${base.notes ?? ''} (aktif sakatlık — yüksek riskli kategoriler çıkarıldı)`.trim(),
    };
  }

  return base;
}

const LOW_IMPACT_CATEGORIES = new Set<TrainingCategory>([
  'warmup',
  'recovery',
  'cooldown',
  'technical',
]);

function filterToLowImpact(cats: TrainingCategory[]): TrainingCategory[] {
  const filtered = cats.filter((c) => LOW_IMPACT_CATEGORIES.has(c));
  return filtered.length > 0 ? filtered : ['recovery'];
}

function addDays(date: Date, n: number): Date {
  const d = new Date(date);
  d.setDate(d.getDate() + n);
  return d;
}
