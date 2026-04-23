import { ExerciseSchema, type Exercise } from '@fittrack/shared';
import raw from './exercises.json' with { type: 'json' };

export const exercises: readonly Exercise[] = Object.freeze(
  (raw as unknown[]).map((item) => ExerciseSchema.parse(item)),
);

export const exerciseById: ReadonlyMap<string, Exercise> = new Map(
  exercises.map((exercise) => [exercise.id, exercise]),
);

export function getExerciseById(id: string): Exercise | undefined {
  return exerciseById.get(id);
}

export type { Exercise } from '@fittrack/shared';
