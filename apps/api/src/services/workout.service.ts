import type {
  FinishWorkoutInput,
  SetInput,
  StartWorkoutInput,
} from '@fittrack/shared';
import { AppError } from '../lib/errors.js';
import {
  workoutRepository,
  type WorkoutRepository,
  type WorkoutWithSets,
} from '../repositories/workout.repository.js';

export interface ListResult {
  items: Awaited<ReturnType<WorkoutRepository['list']>>;
  nextCursor: string | null;
}

export class WorkoutService {
  constructor(private readonly repo: WorkoutRepository = workoutRepository) {}

  async list(userId: string, limit: number, cursor?: string): Promise<ListResult> {
    const items = await this.repo.list({ userId, limit, cursor });
    const hasMore = items.length > limit;
    const page = hasMore ? items.slice(0, limit) : items;
    const nextCursor = hasMore ? page[page.length - 1]?.id ?? null : null;
    return { items: page, nextCursor };
  }

  async get(id: string, userId: string): Promise<WorkoutWithSets> {
    const workout = await this.repo.findById(id, userId);
    if (!workout) throw AppError.notFound('Workout not found');
    return workout;
  }

  start(userId: string, input: StartWorkoutInput) {
    return this.repo.start({ userId, ...input });
  }

  async finish(id: string, userId: string, input: FinishWorkoutInput) {
    await this.ensureExists(id, userId);
    return this.repo.update(id, userId, {
      finishedAt: new Date(),
      ...(input.notes !== undefined ? { notes: input.notes } : {}),
    });
  }

  async updateNotes(id: string, userId: string, notes: string) {
    await this.ensureExists(id, userId);
    return this.repo.update(id, userId, { notes });
  }

  async delete(id: string, userId: string): Promise<void> {
    await this.ensureExists(id, userId);
    await this.repo.delete(id, userId);
  }

  async addSet(workoutId: string, userId: string, input: SetInput) {
    const workout = await this.repo.findById(workoutId, userId);
    if (!workout) throw AppError.notFound('Workout not found');
    const order = input.order ?? (await this.repo.nextSetOrder(workoutId));
    return this.repo.addSet({
      workoutId,
      exerciseId: input.exerciseId,
      order,
      weightKg: input.weightKg,
      reps: input.reps,
      timeSeconds: input.timeSeconds,
      distanceMeters: input.distanceMeters,
      rpe: input.rpe,
    });
  }

  private async ensureExists(id: string, userId: string): Promise<void> {
    const existing = await this.repo.findById(id, userId);
    if (!existing) throw AppError.notFound('Workout not found');
  }
}

export const workoutService = new WorkoutService();
