import type {
  Prisma,
  SessionExercise,
  SessionLog,
  TrainingAttendance,
  TrainingProgram,
  TrainingSession,
} from '@prisma/client';
import type { MicrocycleType } from '@fittrack/shared';
import { prisma } from '../lib/prisma.js';
import { AppError } from '../lib/errors.js';
import {
  generateAndWriteProgram,
  type WrittenProgram,
} from './program-engine/program-writer.js';

export type ProgramWithSessions = TrainingProgram & {
  sessions: (TrainingSession & { exercises: SessionExercise[] })[];
};

export interface GenerateForPlayerInput {
  playerId: string;
  weekStartDate: Date;
  microcycleType?: MicrocycleType;
}

export interface AttendanceEntry {
  playerId: string;
  status: 'present' | 'absent' | 'late' | 'excused';
  arrivedAt?: Date | null;
  note?: string | null;
}

export interface BulkAttendanceInput {
  entries: AttendanceEntry[];
}

export interface SessionLogInput {
  rpe?: number | null;
  fatigue?: number | null;
  mood?: number | null;
  sleepHours?: number | null;
  notes?: string | null;
}

export const programService = {
  generateForPlayer(input: GenerateForPlayerInput): Promise<WrittenProgram> {
    return generateAndWriteProgram({
      playerId: input.playerId,
      weekStartDate: input.weekStartDate,
      microcycleType: input.microcycleType,
    });
  },

  async listForPlayer(
    playerId: string,
    range: { weekStartDate?: Date; from?: Date; to?: Date },
  ): Promise<ProgramWithSessions[]> {
    const where: Prisma.TrainingProgramWhereInput = { playerId };
    if (range.weekStartDate) {
      where.weekStartDate = range.weekStartDate;
    } else if (range.from || range.to) {
      where.weekStartDate = {
        ...(range.from ? { gte: range.from } : {}),
        ...(range.to ? { lte: range.to } : {}),
      };
    }
    return prisma.trainingProgram.findMany({
      where,
      include: {
        sessions: {
          include: { exercises: { orderBy: { order: 'asc' } } },
          orderBy: { date: 'asc' },
        },
      },
      orderBy: { weekStartDate: 'desc' },
    });
  },

  async getProgramSessionWithProgram(
    sessionId: string,
  ): Promise<TrainingSession & { program: TrainingProgram }> {
    const session = await prisma.trainingSession.findUnique({
      where: { id: sessionId },
      include: { program: true },
    });
    if (!session) throw AppError.notFound('Antrenman seansı bulunamadı');
    return session;
  },

  async setAttendanceBulk(
    sessionId: string,
    input: BulkAttendanceInput,
  ): Promise<TrainingAttendance[]> {
    return prisma.$transaction(
      input.entries.map((entry) =>
        prisma.trainingAttendance.upsert({
          where: { sessionId_playerId: { sessionId, playerId: entry.playerId } },
          create: {
            sessionId,
            playerId: entry.playerId,
            status: entry.status,
            arrivedAt: entry.arrivedAt ?? null,
            note: entry.note ?? null,
          },
          update: {
            status: entry.status,
            arrivedAt: entry.arrivedAt ?? null,
            note: entry.note ?? null,
          },
        }),
      ),
    );
  },

  async listAttendance(sessionId: string): Promise<TrainingAttendance[]> {
    return prisma.trainingAttendance.findMany({
      where: { sessionId },
      orderBy: { createdAt: 'asc' },
    });
  },

  async upsertSessionLog(
    sessionId: string,
    playerId: string,
    input: SessionLogInput,
  ): Promise<SessionLog> {
    return prisma.sessionLog.upsert({
      where: { sessionId_playerId: { sessionId, playerId } },
      create: {
        sessionId,
        playerId,
        rpe: input.rpe ?? null,
        fatigue: input.fatigue ?? null,
        mood: input.mood ?? null,
        sleepHours: input.sleepHours ?? null,
        notes: input.notes ?? null,
      },
      update: {
        rpe: input.rpe ?? null,
        fatigue: input.fatigue ?? null,
        mood: input.mood ?? null,
        sleepHours: input.sleepHours ?? null,
        notes: input.notes ?? null,
      },
    });
  },

  async listSessionLogs(sessionId: string): Promise<SessionLog[]> {
    return prisma.sessionLog.findMany({ where: { sessionId } });
  },
};
