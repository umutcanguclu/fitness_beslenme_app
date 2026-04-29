const TR_DAY_NAMES = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Pzr'];
const TR_MONTH_NAMES = [
  'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
  'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
];

export function formatDateShort(d: Date | string): string {
  const date = typeof d === 'string' ? new Date(d) : d;
  return `${date.getDate()} ${TR_MONTH_NAMES[date.getMonth()]}`;
}

export function formatDayName(d: Date | string): string {
  const date = typeof d === 'string' ? new Date(d) : d;
  // JS getDay: 0=Pzr ... 6=Cmt — Pazartesi başlangıç için kayır.
  const idx = (date.getDay() + 6) % 7;
  return TR_DAY_NAMES[idx]!;
}

export function formatBirthDateAge(birthDate: Date | string): { age: number; iso: string } {
  const d = typeof birthDate === 'string' ? new Date(birthDate) : birthDate;
  const today = new Date();
  let age = today.getFullYear() - d.getFullYear();
  const m = today.getMonth() - d.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < d.getDate())) age -= 1;
  return { age, iso: d.toISOString().slice(0, 10) };
}

// Pazartesi'ye yuvarla (engine programı haftanın başına yazıyor).
export function mondayOf(date: Date = new Date()): Date {
  const d = new Date(date);
  const offset = (d.getDay() + 6) % 7;
  d.setDate(d.getDate() - offset);
  d.setHours(0, 0, 0, 0);
  return d;
}

export function isoDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

const CATEGORY_LABELS_TR: Record<string, string> = {
  warmup: 'Isınma',
  endurance: 'Dayanıklılık',
  sprint_agility: 'Sürat & Çeviklik',
  strength: 'Kuvvet',
  plyometric: 'Plyometric',
  technical: 'Teknik',
  tactical: 'Taktik',
  goalkeeper_specific: 'Kaleci',
  recovery: 'Toparlanma',
  cooldown: 'Soğuma',
  small_sided_game: 'Mini Maç',
  set_piece: 'Duran Top',
};

export function categoryLabel(c: string): string {
  return CATEGORY_LABELS_TR[c] ?? c;
}

const POSITION_LABELS_TR: Record<string, string> = {
  goalkeeper: 'Kaleci',
  defender: 'Defans',
  midfielder: 'Orta Saha',
  forward: 'Forvet',
};

export function positionLabel(p: string): string {
  return POSITION_LABELS_TR[p] ?? p;
}
