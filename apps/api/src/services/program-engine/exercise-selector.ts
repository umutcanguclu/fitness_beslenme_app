import type { Exercise, PrismaClient } from '@prisma/client';
import type { TrainingCategory } from '@fittrack/shared';
import { prisma } from '../../lib/prisma.js';
import type { ClubResources, PlayerSnapshot, SelectedExercise } from './types.js';

interface SelectInput {
  category: TrainingCategory;
  player: PlayerSnapshot;
  club: ClubResources;
  exclude?: Set<string>; // tekrar etmemesi için
  limit: number;
}

// Egzersizleri kulüp ekipmanı + oyuncu yaşı/mevkisi ile filtreler ve seçer.
export async function selectExercisesForCategory(
  input: SelectInput,
  db: PrismaClient = prisma,
): Promise<Exercise[]> {
  const candidates = await db.exercise.findMany({
    where: {
      category: input.category,
      AND: [
        { OR: [{ minAge: null }, { minAge: { lte: input.player.ageYears } }] },
        { OR: [{ maxAge: null }, { maxAge: { gte: input.player.ageYears } }] },
        // Mevki targeted ya boş ya da oyuncunun mevkisini içermeli
        {
          OR: [
            { positionsTargeted: { isEmpty: true } },
            { positionsTargeted: { has: input.player.position } },
          ],
        },
      ],
    },
  });

  const usable = candidates.filter((ex) => isUsable(ex, input));
  // Şimdilik basit: zorlukla artan, sonra rastgele tie-break.
  // Sonra: çeşitlilik (önceki haftaları, primaryMuscles çakışmasını) hesaba kat.
  const shuffled = [...usable].sort((a, b) => a.difficulty - b.difficulty + (Math.random() - 0.5));
  return shuffled.slice(0, input.limit);
}

function isUsable(ex: Exercise, input: SelectInput): boolean {
  if (input.exclude?.has(ex.id)) return false;
  // Ekipman kontrolü: AND mantığı — her required item kulüpte var mı?
  for (const req of ex.requiredEquipment) {
    if (!input.club.equipment.has(req)) return false;
  }
  // Lokasyon kontrolü: en az birinin kulüpte uygun olması
  if (ex.locations.length > 0) {
    const anyMatch = ex.locations.some((loc) => input.club.availableLocations.has(loc));
    if (!anyMatch) return false;
  }
  return true;
}

// Exercise'i SessionExercise input'una çevirir, defaults uygular,
// günün şiddetine göre set/rep modüle eder. Şimdilik basit kopya.
export function toSelectedExercise(
  ex: Exercise,
  order: number,
  dayIntensity: number,
): SelectedExercise {
  const intensityFactor = clamp(dayIntensity / 3, 0.6, 1.4); // şiddet ↑ → set ↑
  const sets = ex.defaultSets ? Math.max(1, Math.round(ex.defaultSets * intensityFactor)) : undefined;
  return {
    exerciseId: ex.id,
    order,
    sets,
    reps: ex.defaultReps ?? undefined,
    durationSeconds: ex.defaultDurationSeconds ?? undefined,
    distanceMeters: ex.defaultDistanceMeters ?? undefined,
    restSeconds: ex.defaultRestSeconds ?? undefined,
    intensity: dayIntensity || undefined,
  };
}

function clamp(n: number, lo: number, hi: number): number {
  return Math.max(lo, Math.min(hi, n));
}
