import type {
  AvailabilityStatus,
  InjuryRecord,
  InjurySeverity,
  InjuryType,
  Player,
  PlayerAvailability,
} from '@prisma/client';
import type { UpdatePlayerProfileInput } from '@fittrack/shared';
import { prisma } from '../lib/prisma.js';
import { AppError } from '../lib/errors.js';

export interface SetAvailabilityInput {
  date: Date;
  status: AvailabilityStatus;
  note?: string | null;
}

export interface CreateInjuryInput {
  type: InjuryType;
  severity: InjurySeverity;
  bodyPart: string;
  startedAt: Date;
  expectedReturn?: Date | null;
  description?: string | null;
}

export interface ListAvailabilityRange {
  from?: Date;
  to?: Date;
}

export const playerService = {
  async getPlayer(playerId: string): Promise<Player> {
    const player = await prisma.player.findUnique({ where: { id: playerId } });
    if (!player) throw AppError.notFound('Oyuncu bulunamadı');
    return player;
  },

  async updateProfile(playerId: string, input: UpdatePlayerProfileInput): Promise<Player> {
    return prisma.player.update({
      where: { id: playerId },
      data: {
        birthDate: input.birthDate,
        position: input.position,
        detailedPosition: input.detailedPosition,
        secondaryPosition: input.secondaryPosition,
        preferredFoot: input.preferredFoot,
        heightCm: input.heightCm,
        weightKg: input.weightKg,
        jerseyNumber: input.jerseyNumber,
        employmentStatus: input.employmentStatus,
        notes: input.notes,
      },
    });
  },

  // Aynı playerId+date için unique constraint var; coach veya oyuncu güncellerse upsert.
  async setAvailability(
    playerId: string,
    input: SetAvailabilityInput,
  ): Promise<PlayerAvailability> {
    return prisma.playerAvailability.upsert({
      where: { playerId_date: { playerId, date: input.date } },
      create: {
        playerId,
        date: input.date,
        status: input.status,
        note: input.note ?? null,
      },
      update: {
        status: input.status,
        note: input.note ?? null,
      },
    });
  },

  async listAvailability(
    playerId: string,
    range: ListAvailabilityRange,
  ): Promise<PlayerAvailability[]> {
    return prisma.playerAvailability.findMany({
      where: {
        playerId,
        ...(range.from || range.to
          ? {
              date: {
                ...(range.from ? { gte: range.from } : {}),
                ...(range.to ? { lte: range.to } : {}),
              },
            }
          : {}),
      },
      orderBy: { date: 'desc' },
    });
  },

  async createInjury(playerId: string, input: CreateInjuryInput): Promise<InjuryRecord> {
    return prisma.injuryRecord.create({
      data: {
        playerId,
        type: input.type,
        severity: input.severity,
        bodyPart: input.bodyPart,
        startedAt: input.startedAt,
        expectedReturn: input.expectedReturn ?? null,
        description: input.description ?? null,
      },
    });
  },

  async listInjuries(playerId: string, includeResolved: boolean): Promise<InjuryRecord[]> {
    return prisma.injuryRecord.findMany({
      where: { playerId, ...(includeResolved ? {} : { resolvedAt: null }) },
      orderBy: { startedAt: 'desc' },
    });
  },

  async resolveInjury(playerId: string, injuryId: string, resolvedAt?: Date): Promise<InjuryRecord> {
    const injury = await prisma.injuryRecord.findUnique({ where: { id: injuryId } });
    if (!injury || injury.playerId !== playerId) throw AppError.notFound('Sakatlık kaydı bulunamadı');
    if (injury.resolvedAt) throw AppError.conflict('Sakatlık zaten kapatılmış');
    return prisma.injuryRecord.update({
      where: { id: injuryId },
      data: { resolvedAt: resolvedAt ?? new Date() },
    });
  },
};
