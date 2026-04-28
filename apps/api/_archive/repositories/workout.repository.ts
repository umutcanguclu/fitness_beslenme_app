import type { Prisma, PrismaClient, Workout, WorkoutSet } from '@prisma/client';
import { prisma } from '../lib/prisma.js';

export interface ListWorkoutsArgs {
  userId: string;
  limit: number;
  cursor?: string;
}

export type WorkoutWithSets = Workout & { sets: WorkoutSet[] };

export class WorkoutRepository {
  constructor(private readonly db: PrismaClient = prisma) {}

  list({ userId, limit, cursor }: ListWorkoutsArgs): Promise<Workout[]> {
    return this.db.workout.findMany({
      where: { userId },
      orderBy: { startedAt: 'desc' },
      take: limit + 1,
      ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
    });
  }

  findById(id: string, userId: string): Promise<WorkoutWithSets | null> {
    return this.db.workout.findFirst({
      where: { id, userId },
      include: { sets: { orderBy: { order: 'asc' } } },
    });
  }

  start(input: {
    userId: string;
    name?: string;
    templateId?: string;
    notes?: string;
  }): Promise<Workout> {
    return this.db.workout.create({
      data: {
        userId: input.userId,
        name: input.name,
        templateId: input.templateId,
        notes: input.notes,
      },
    });
  }

  update(
    id: string,
    userId: string,
    data: Prisma.WorkoutUpdateInput,
  ): Promise<Workout> {
    return this.db.workout.update({
      where: { id, userId },
      data,
    });
  }

  delete(id: string, userId: string): Promise<Workout> {
    return this.db.workout.delete({ where: { id, userId } });
  }

  async nextSetOrder(workoutId: string): Promise<number> {
    const last = await this.db.workoutSet.findFirst({
      where: { workoutId },
      orderBy: { order: 'desc' },
      select: { order: true },
    });
    return (last?.order ?? -1) + 1;
  }

  addSet(input: {
    workoutId: string;
    exerciseId: string;
    order: number;
    weightKg?: number | null;
    reps?: number | null;
    timeSeconds?: number | null;
    distanceMeters?: number | null;
    rpe?: number | null;
  }): Promise<WorkoutSet> {
    return this.db.workoutSet.create({
      data: {
        workoutId: input.workoutId,
        exerciseId: input.exerciseId,
        order: input.order,
        weightKg: input.weightKg ?? null,
        reps: input.reps ?? null,
        timeSeconds: input.timeSeconds ?? null,
        distanceMeters: input.distanceMeters ?? null,
        rpe: input.rpe ?? null,
        completedAt: new Date(),
      },
    });
  }
}

export const workoutRepository = new WorkoutRepository();
