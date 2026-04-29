import type { MicrocycleType, TrainingCategory } from '@fittrack/shared';
import type { DayPlan, MatchContext, PlayerSnapshot } from './types.js';

type DayBase = Pick<DayPlan, 'categories' | 'intensity' | 'durationMinutes' | 'isOff'> & {
  notes?: string;
};

// Maç haftası MD-X periyodizasyonu (haftada 1 maç varsayımı).
//   MD-3 → yüksek hacim (kuvvet + dayanıklılık)
//   MD-2 → yüksek şiddet (sürat + taktik)
//   MD-1 → düşük yük, teknik + duran top + tactical recap
//   MD   → maç (off — antrenman yok)
//   MD+1 → recovery (hafif jog + foam roll)
const MATCH_WEEK_TABLE: Record<number, DayBase> = {
  [-5]: { categories: ['recovery'], intensity: 1, durationMinutes: 30, isOff: false, notes: 'Aktif toparlanma' },
  [-4]: { categories: ['warmup', 'strength', 'endurance', 'cooldown'], intensity: 4, durationMinutes: 90, isOff: false, notes: 'MD-4: yüksek hacim' },
  [-3]: { categories: ['warmup', 'strength', 'endurance', 'cooldown'], intensity: 4, durationMinutes: 90, isOff: false, notes: 'MD-3: yüksek hacim' },
  [-2]: { categories: ['warmup', 'sprint_agility', 'small_sided_game', 'cooldown'], intensity: 4, durationMinutes: 80, isOff: false, notes: 'MD-2: yüksek şiddet' },
  [-1]: { categories: ['warmup', 'technical', 'set_piece', 'cooldown'], intensity: 2, durationMinutes: 60, isOff: false, notes: 'MD-1: aktivasyon + taktik' },
  [0]: { categories: [], intensity: 0, durationMinutes: 0, isOff: true, notes: 'Maç günü' },
  [1]: { categories: ['recovery'], intensity: 1, durationMinutes: 25, isOff: false, notes: 'MD+1: toparlanma' },
};

// Maç olmayan haftada (in-season ama maç yok) genel günlük dağılım.
const GENERIC_WEEK_TEMPLATE: Record<number, DayBase> = {
  0: { categories: ['warmup', 'strength', 'endurance', 'cooldown'], intensity: 4, durationMinutes: 90, isOff: false },
  1: { categories: ['warmup', 'sprint_agility', 'technical', 'cooldown'], intensity: 3, durationMinutes: 75, isOff: false },
  2: { categories: ['recovery'], intensity: 1, durationMinutes: 30, isOff: false },
  3: { categories: ['warmup', 'plyometric', 'small_sided_game', 'cooldown'], intensity: 4, durationMinutes: 80, isOff: false },
  4: { categories: ['warmup', 'technical', 'tactical', 'cooldown'], intensity: 2, durationMinutes: 60, isOff: false },
  5: { categories: ['warmup', 'endurance', 'cooldown'], intensity: 3, durationMinutes: 70, isOff: false },
  6: { categories: [], intensity: 0, durationMinutes: 0, isOff: true },
};

// Preseason: yüksek hacim, fiziksel temel ağırlıklı.
const PRESEASON_TEMPLATE: Record<number, DayBase> = {
  0: { categories: ['warmup', 'strength', 'endurance', 'cooldown'], intensity: 5, durationMinutes: 100, isOff: false, notes: 'Preseason: yüksek hacim güç' },
  1: { categories: ['warmup', 'sprint_agility', 'plyometric', 'cooldown'], intensity: 4, durationMinutes: 90, isOff: false, notes: 'Preseason: sürat + plyo' },
  2: { categories: ['warmup', 'endurance', 'cooldown'], intensity: 4, durationMinutes: 85, isOff: false, notes: 'Preseason: aerobik baz' },
  3: { categories: ['recovery'], intensity: 1, durationMinutes: 30, isOff: false, notes: 'Toparlanma' },
  4: { categories: ['warmup', 'strength', 'small_sided_game', 'cooldown'], intensity: 4, durationMinutes: 95, isOff: false, notes: 'Preseason: güç + maç simülasyonu' },
  5: { categories: ['warmup', 'technical', 'tactical', 'cooldown'], intensity: 3, durationMinutes: 75, isOff: false, notes: 'Preseason: teknik + taktik' },
  6: { categories: [], intensity: 0, durationMinutes: 0, isOff: true },
};

// Recovery week: yorgun bir periyod sonrası 1 hafta hafif yükle deload.
const RECOVERY_WEEK_TEMPLATE: Record<number, DayBase> = {
  0: { categories: ['recovery'], intensity: 1, durationMinutes: 30, isOff: false, notes: 'Toparlanma haftası: aktif recovery' },
  1: { categories: ['warmup', 'technical', 'cooldown'], intensity: 2, durationMinutes: 50, isOff: false, notes: 'Hafif teknik' },
  2: { categories: ['recovery'], intensity: 1, durationMinutes: 25, isOff: false },
  3: { categories: ['warmup', 'sprint_agility', 'cooldown'], intensity: 2, durationMinutes: 45, isOff: false, notes: 'Hafif çeviklik' },
  4: { categories: ['recovery'], intensity: 1, durationMinutes: 30, isOff: false, notes: 'Mobilite + foam roll' },
  5: { categories: [], intensity: 0, durationMinutes: 0, isOff: true },
  6: { categories: [], intensity: 0, durationMinutes: 0, isOff: true },
};

// GK substitution map: takım çalışması yerine kaleciye özel iş.
// Kaleci de teknik gerek duyar ama o teknik = el-ayak hassasiyeti, distribution, plonjon
// — ki bunlar bizim taxonomy'de goalkeeper_specific kategorisinin altında.
const GK_CATEGORY_SUBSTITUTIONS: Partial<Record<TrainingCategory, TrainingCategory>> = {
  small_sided_game: 'goalkeeper_specific',
  tactical: 'goalkeeper_specific',
  technical: 'goalkeeper_specific',
};

// Antrenman içi sıralama: ısınma ilk, ana iş bloğu ortada, soğuma son.
// Orchestrator bu sıraya göre egzersizleri yerleştirir.
const CATEGORY_PRIORITY: Record<TrainingCategory, number> = {
  warmup: 0,
  strength: 10,
  plyometric: 11,
  sprint_agility: 12,
  endurance: 13,
  technical: 14,
  goalkeeper_specific: 15,
  tactical: 16,
  set_piece: 17,
  small_sided_game: 18,
  recovery: 90,
  cooldown: 100,
};

export function planWeek(opts: {
  weekStartDate: Date;
  microcycleType: MicrocycleType;
  match: MatchContext;
  player: PlayerSnapshot;
}): DayPlan[] {
  const days: DayPlan[] = [];
  for (let i = 0; i < 7; i += 1) {
    const date = addDays(opts.weekStartDate, i);
    const base = pickDayBase(i, opts);
    const withAvailability = applyAvailabilityAdjustments(base, opts.player);
    const withAge = applyAgeAdjustments(withAvailability, opts.player);
    const withPosition = applyPositionAdjustments(withAge, opts.player);
    const ordered = sortCategories(withPosition.categories);
    days.push({
      dayOfWeek: i,
      date,
      categories: ordered,
      intensity: withPosition.intensity,
      durationMinutes: withPosition.durationMinutes,
      isOff: withPosition.isOff,
      notes: withPosition.notes,
    });
  }
  return days;
}

function pickDayBase(
  dayIndex: number,
  opts: { microcycleType: MicrocycleType; match: MatchContext },
): DayBase {
  if (opts.microcycleType === 'preseason') {
    return PRESEASON_TEMPLATE[dayIndex] ?? GENERIC_WEEK_TEMPLATE[dayIndex] ?? GENERIC_WEEK_TEMPLATE[0]!;
  }
  if (opts.microcycleType === 'recovery_week') {
    return RECOVERY_WEEK_TEMPLATE[dayIndex] ?? GENERIC_WEEK_TEMPLATE[6]!;
  }
  if (opts.microcycleType === 'off_season') {
    return RECOVERY_WEEK_TEMPLATE[dayIndex] ?? GENERIC_WEEK_TEMPLATE[6]!;
  }
  // match_week: maç günü tespiti varsa MD-X tablosu, yoksa generic.
  const fallback = GENERIC_WEEK_TEMPLATE[dayIndex] ?? GENERIC_WEEK_TEMPLATE[0]!;
  if (opts.match.matchDayOfWeek !== null) {
    const offset = dayIndex - opts.match.matchDayOfWeek;
    return MATCH_WEEK_TABLE[offset] ?? fallback;
  }
  return fallback;
}

function applyAvailabilityAdjustments(base: DayBase, player: PlayerSnapshot): DayBase {
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

  if (player.hasActiveInjury) {
    return {
      ...base,
      categories: base.categories.filter((c) => c !== 'plyometric' && c !== 'sprint_agility'),
      notes: `${base.notes ?? ''} (aktif sakatlık — yüksek riskli kategoriler çıkarıldı)`.trim(),
    };
  }

  return base;
}

// Yaş bazlı yük sınırı: gençlerde yüksek hacim/şiddet sakatlık riski.
// U13 (10-13) — şiddet max 3, süre max 70 dk
// U14-U15 (14-15) — şiddet max 4, süre max 80 dk
// 16+ — sınır yok
function applyAgeAdjustments(base: DayBase, player: PlayerSnapshot): DayBase {
  if (base.isOff) return base;
  if (player.ageYears < 14) {
    const intensity = Math.min(base.intensity, 3);
    const duration = Math.min(base.durationMinutes, 70);
    if (intensity === base.intensity && duration === base.durationMinutes) return base;
    return {
      ...base,
      intensity,
      durationMinutes: duration,
      notes: `${base.notes ?? ''} (yaş ${player.ageYears} — gençlere göre yük sınırlı)`.trim(),
    };
  }
  if (player.ageYears < 16) {
    const intensity = Math.min(base.intensity, 4);
    const duration = Math.min(base.durationMinutes, 80);
    if (intensity === base.intensity && duration === base.durationMinutes) return base;
    return { ...base, intensity, durationMinutes: duration };
  }
  return base;
}

// Mevki bazlı kategori değişikliği. Şu an: kaleci için takım çalışması yerine GK iş.
// İlerde santraforu shooting ağırlıklı, ortasaha pas&pos ağırlıklı vb. eklenebilir.
function applyPositionAdjustments(base: DayBase, player: PlayerSnapshot): DayBase {
  if (base.isOff) return base;
  if (player.position !== 'goalkeeper') return base;

  const newCats = new Set<TrainingCategory>();
  for (const cat of base.categories) {
    newCats.add(GK_CATEGORY_SUBSTITUTIONS[cat] ?? cat);
  }
  const noteFlag = base.categories.some((c) => GK_CATEGORY_SUBSTITUTIONS[c]) ? ' (kaleci özel)' : '';
  return {
    ...base,
    categories: [...newCats],
    notes: `${base.notes ?? ''}${noteFlag}`.trim(),
  };
}

// Bir gün içindeki kategorileri standart sıraya koyar: warmup → ana iş → cooldown.
// Aynı seansta birden fazla ana kategori varsa CATEGORY_PRIORITY içindeki sırayla.
function sortCategories(cats: TrainingCategory[]): TrainingCategory[] {
  return [...cats].sort((a, b) => (CATEGORY_PRIORITY[a] ?? 50) - (CATEGORY_PRIORITY[b] ?? 50));
}

const LOW_IMPACT_CATEGORIES = new Set<TrainingCategory>([
  'warmup',
  'recovery',
  'cooldown',
  'technical',
  'goalkeeper_specific',
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
