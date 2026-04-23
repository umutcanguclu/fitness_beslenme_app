import { z } from 'zod';

export const SetMetricSchema = z.enum(['weight_reps', 'reps_only', 'time', 'distance_time']);
export type SetMetric = z.infer<typeof SetMetricSchema>;

export const SetSchema = z
  .object({
    id: z.string().uuid(),
    workoutId: z.string().uuid(),
    exerciseId: z.string(),
    order: z.number().int().nonnegative(),
    weightKg: z.number().nonnegative().max(1000).nullable(),
    reps: z.number().int().nonnegative().max(1000).nullable(),
    timeSeconds: z.number().nonnegative().max(86400).nullable(),
    distanceMeters: z.number().nonnegative().max(1000000).nullable(),
    rpe: z.number().min(1).max(10).nullable(),
    completedAt: z.coerce.date().nullable(),
  })
  .superRefine((data, ctx) => {
    const hasWeightReps = data.weightKg !== null || data.reps !== null;
    const hasTime = data.timeSeconds !== null;
    const hasDistance = data.distanceMeters !== null;
    if (!hasWeightReps && !hasTime && !hasDistance) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'A set must record at least one of: weight/reps, time, or distance.',
      });
    }
  });
export type Set = z.infer<typeof SetSchema>;

export const SetInputSchema = z.object({
  exerciseId: z.string(),
  order: z.number().int().nonnegative().optional(),
  weightKg: z.number().nonnegative().max(1000).nullable().optional(),
  reps: z.number().int().nonnegative().max(1000).nullable().optional(),
  timeSeconds: z.number().nonnegative().max(86400).nullable().optional(),
  distanceMeters: z.number().nonnegative().max(1000000).nullable().optional(),
  rpe: z.number().min(1).max(10).nullable().optional(),
});
export type SetInput = z.infer<typeof SetInputSchema>;

export const WorkoutSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  templateId: z.string().uuid().nullable(),
  name: z.string().min(1).max(120).nullable(),
  notes: z.string().max(2000).nullable(),
  startedAt: z.coerce.date(),
  finishedAt: z.coerce.date().nullable(),
  createdAt: z.coerce.date(),
});
export type Workout = z.infer<typeof WorkoutSchema>;

export const WorkoutWithSetsSchema = WorkoutSchema.extend({
  sets: z.array(SetSchema),
});
export type WorkoutWithSets = z.infer<typeof WorkoutWithSetsSchema>;

export const StartWorkoutInputSchema = z.object({
  name: z.string().min(1).max(120).optional(),
  templateId: z.string().uuid().optional(),
  notes: z.string().max(2000).optional(),
});
export type StartWorkoutInput = z.infer<typeof StartWorkoutInputSchema>;

export const FinishWorkoutInputSchema = z.object({
  notes: z.string().max(2000).optional(),
});
export type FinishWorkoutInput = z.infer<typeof FinishWorkoutInputSchema>;

export const TemplateExerciseSchema = z.object({
  exerciseId: z.string(),
  order: z.number().int().nonnegative(),
  targetSets: z.number().int().positive().max(50).nullable(),
  targetReps: z.number().int().positive().max(1000).nullable(),
});
export type TemplateExercise = z.infer<typeof TemplateExerciseSchema>;

export const TemplateSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  name: z.string().min(1).max(120),
  exercises: z.array(TemplateExerciseSchema),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});
export type Template = z.infer<typeof TemplateSchema>;
