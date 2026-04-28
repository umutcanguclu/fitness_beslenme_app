import type { PrismaClient } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';
import { AppError } from '../../lib/errors.js';
import type { PlayerSnapshot } from './types.js';

export async function loadPlayerSnapshot(
  playerId: string,
  asOf: Date,
  db: PrismaClient = prisma,
): Promise<PlayerSnapshot> {
  const player = await db.player.findUnique({
    where: { id: playerId },
    include: {
      availabilities: {
        where: { date: { lte: asOf } },
        orderBy: { date: 'desc' },
        take: 1,
      },
      injuries: {
        where: { resolvedAt: null },
      },
    },
  });

  if (!player) throw AppError.notFound('Oyuncu bulunamadı');

  return {
    playerId: player.id,
    ageYears: yearsBetween(player.birthDate, asOf),
    position: player.position,
    heightCm: player.heightCm,
    weightKg: player.weightKg,
    employmentStatus: player.employmentStatus,
    availabilityStatus: player.availabilities[0]?.status ?? null,
    hasActiveInjury: player.injuries.length > 0,
    activeInjuryBodyParts: player.injuries.map((i) => i.bodyPart),
  };
}

function yearsBetween(birth: Date, asOf: Date): number {
  let years = asOf.getFullYear() - birth.getFullYear();
  const m = asOf.getMonth() - birth.getMonth();
  if (m < 0 || (m === 0 && asOf.getDate() < birth.getDate())) years -= 1;
  return years;
}
