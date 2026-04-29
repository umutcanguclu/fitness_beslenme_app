import type { PrismaClient } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';
import { AppError } from '../../lib/errors.js';
import { loadPlayerSnapshot } from './player-snapshot.js';
import { loadClubResources } from './club-resources.js';
import { planWeek } from './microcycle-planner.js';
import { selectExercisesForCategory, toSelectedExercise } from './exercise-selector.js';
import {
  ENGINE_VERSION,
  type EngineInput,
  type GeneratedProgram,
  type GeneratedSession,
  type MatchContext,
  type SelectedExercise,
} from './types.js';

// Kural tabanlı haftalık program üretici.
// Akış:
//   1. Player snapshot (yaş, mevki, sakatlık, availability)
//   2. Club resources (ekipman, tesisler → kullanılabilir lokasyonlar)
//   3. Bu hafta maç var mı? (Match table)
//   4. Microcycle planner: 7 günlük (kategori + şiddet + süre) iskelet
//   5. Her günde her kategori için Exercise filtresi + seçimi
//   6. GeneratedProgram döner (DB'ye yazma program-writer'da)
export async function generateProgram(
  input: EngineInput,
  db: PrismaClient = prisma,
): Promise<GeneratedProgram> {
  const microcycleType = input.microcycleType ?? 'match_week';

  const player = await loadPlayerSnapshot(input.playerId, input.weekStartDate, db);
  const clubId = await getClubIdForPlayer(input.playerId, db);
  const club = await loadClubResources(clubId, db);
  const match = await loadMatchContext(input.playerId, input.weekStartDate, db);

  const days = planWeek({
    weekStartDate: input.weekStartDate,
    microcycleType,
    match,
    player,
  });

  const usedExerciseIds = new Set<string>();
  const sessions: GeneratedSession[] = [];

  for (const day of days) {
    if (day.isOff || day.categories.length === 0) continue;

    // Her gün için tüm kategorilerin egzersizleri tek session'da toplanır.
    // (Sonra istenirse: her kategori ayrı session olabilir.)
    const dayExercises: SelectedExercise[] = [];
    let order = 0;
    let primaryCategory = day.categories[0]!;

    for (const cat of day.categories) {
      const limit = exerciseCountFor(cat, day.intensity);
      const picked = await selectExercisesForCategory(
        { category: cat, player, club, exclude: usedExerciseIds, limit },
        db,
      );
      for (const ex of picked) {
        dayExercises.push(toSelectedExercise(ex, order, day.intensity));
        usedExerciseIds.add(ex.id);
        order += 1;
      }
      if (picked.length > 0 && cat !== 'warmup' && cat !== 'cooldown') {
        primaryCategory = cat;
      }
    }

    if (dayExercises.length === 0) continue;

    sessions.push({
      date: day.date,
      category: primaryCategory,
      durationMinutes: day.durationMinutes,
      intensity: day.intensity,
      exercises: dayExercises,
      notes: day.notes,
    });
  }

  return {
    weekStartDate: input.weekStartDate,
    microcycleType,
    matchDayOfWeek: match.matchDayOfWeek,
    sessions,
    generationInputs: {
      playerId: input.playerId,
      weekStartDate: input.weekStartDate.toISOString(),
      microcycleType,
      playerSnapshot: {
        ageYears: player.ageYears,
        position: player.position,
        heightCm: player.heightCm,
        weightKg: player.weightKg,
        employmentStatus: player.employmentStatus,
        availabilityStatus: player.availabilityStatus,
        hasActiveInjury: player.hasActiveInjury,
      },
      clubEquipment: [...club.equipment],
      clubFacilities: [...club.facilities],
      availableLocations: [...club.availableLocations],
      matchDayOfWeek: match.matchDayOfWeek,
      rulesetVersion: ENGINE_VERSION,
    },
  };
}

async function getClubIdForPlayer(playerId: string, db: PrismaClient): Promise<string> {
  const player = await db.player.findUnique({
    where: { id: playerId },
    select: { clubId: true },
  });
  if (!player) throw AppError.notFound('Oyuncu bulunamadı');
  return player.clubId;
}

async function loadMatchContext(
  playerId: string,
  weekStartDate: Date,
  db: PrismaClient,
): Promise<MatchContext> {
  const weekEnd = addDays(weekStartDate, 7);
  // Oyuncunun takımlarındaki bu hafta içindeki ilk maç
  const teamPlayers = await db.teamPlayer.findMany({
    where: { playerId, leftAt: null },
    select: { teamId: true },
  });
  if (teamPlayers.length === 0) {
    return { hasMatchThisWeek: false, matchDayOfWeek: null, matchDate: null };
  }
  const teamIds = teamPlayers.map((tp) => tp.teamId);
  const match = await db.match.findFirst({
    where: { teamId: { in: teamIds }, date: { gte: weekStartDate, lt: weekEnd } },
    orderBy: { date: 'asc' },
  });
  if (!match) return { hasMatchThisWeek: false, matchDayOfWeek: null, matchDate: null };
  return {
    hasMatchThisWeek: true,
    matchDate: match.date,
    matchDayOfWeek: dayOfWeekIndex(match.date),
  };
}

// 0=Pzt ... 6=Pzr (JS default: 0=Pzr, 6=Cmt — düzeltiyoruz)
function dayOfWeekIndex(d: Date): number {
  const js = d.getDay();
  return (js + 6) % 7;
}

function addDays(date: Date, n: number): Date {
  const x = new Date(date);
  x.setDate(x.getDate() + n);
  return x;
}

// Kategoriye göre kaç egzersiz seçilsin? Şiddete bağlı kaba ölçek.
function exerciseCountFor(category: string, intensity: number): number {
  if (category === 'warmup' || category === 'cooldown') return 1;
  if (category === 'recovery') return 2;
  if (category === 'small_sided_game') return 1;
  if (category === 'set_piece') return 2;
  if (category === 'goalkeeper_specific') return 3;
  // Ana iş bloğu: şiddete göre 2-4 egzersiz
  return Math.max(2, Math.min(4, Math.round(intensity)));
}

export { ENGINE_VERSION } from './types.js';
export type { EngineInput, GeneratedProgram, GeneratedSession, SelectedExercise } from './types.js';
