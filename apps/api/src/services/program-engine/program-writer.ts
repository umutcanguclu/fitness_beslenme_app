import type {
  Prisma,
  PrismaClient,
  SessionExercise,
  TrainingProgram,
  TrainingSession,
} from '@prisma/client';
import { prisma } from '../../lib/prisma.js';
import { generateProgram } from './index.js';
import { ENGINE_VERSION, type EngineInput, type GeneratedProgram } from './types.js';

export type WrittenProgram = TrainingProgram & {
  sessions: (TrainingSession & { exercises: SessionExercise[] })[];
};

export interface WriteProgramOptions {
  playerId: string;
  generatedBy?: string;
}

// Replace strategy: aynı playerId+weekStartDate için var olan program ve onun
// tüm seans/egzersiz/attendance/log kayıtları cascade ile silinir, yeni baştan yazılır.
// Hafta içinde program yeniden üretilirse attendance/RPE kayıtları kaybolur — UI
// katmanında "X kayıt silinecek" uyarısıyla dengelenmesi planlanıyor.
export async function writeProgram(
  program: GeneratedProgram,
  options: WriteProgramOptions,
  db: PrismaClient = prisma,
): Promise<WrittenProgram> {
  return db.$transaction(async (tx) => {
    await tx.trainingProgram.deleteMany({
      where: { playerId: options.playerId, weekStartDate: program.weekStartDate },
    });

    return tx.trainingProgram.create({
      data: {
        playerId: options.playerId,
        weekStartDate: program.weekStartDate,
        matchDayOfWeek: program.matchDayOfWeek,
        microcycleType: program.microcycleType,
        generatedBy: options.generatedBy ?? ENGINE_VERSION,
        generationInputs: program.generationInputs as Prisma.InputJsonValue,
        sessions: {
          create: program.sessions.map((s) => ({
            date: s.date,
            type: 'individual',
            category: s.category,
            durationMinutes: s.durationMinutes,
            intensity: s.intensity,
            notes: s.notes,
            exercises: {
              create: s.exercises.map((ex) => ({
                exerciseId: ex.exerciseId,
                order: ex.order,
                sets: ex.sets,
                reps: ex.reps,
                durationSeconds: ex.durationSeconds,
                distanceMeters: ex.distanceMeters,
                restSeconds: ex.restSeconds,
                intensity: ex.intensity,
              })),
            },
          })),
        },
      },
      include: {
        sessions: {
          include: { exercises: { orderBy: { order: 'asc' } } },
          orderBy: { date: 'asc' },
        },
      },
    });
  });
}

export async function generateAndWriteProgram(
  input: EngineInput,
  db: PrismaClient = prisma,
): Promise<WrittenProgram> {
  const generated = await generateProgram(input, db);
  return writeProgram(generated, { playerId: input.playerId }, db);
}
