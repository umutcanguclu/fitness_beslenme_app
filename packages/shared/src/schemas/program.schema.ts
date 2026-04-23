import { z } from 'zod';
import { GoalSchema } from './user.schema.js';
import { MuscleGroupSchema } from './exercise.schema.js';

export const ProgramLevelSchema = z.enum(['beginner', 'intermediate', 'advanced']);
export type ProgramLevel = z.infer<typeof ProgramLevelSchema>;

export const ProgramEquipmentSchema = z.enum([
  'bodyweight_only',
  'dumbbell_only',
  'full_gym',
]);
export type ProgramEquipment = z.infer<typeof ProgramEquipmentSchema>;

export const ProgramGenerateInputSchema = z.object({
  goal: GoalSchema,
  level: ProgramLevelSchema,
  equipment: ProgramEquipmentSchema,
  daysPerWeek: z.number().int().min(2).max(6),
  sessionMinutes: z.number().int().min(20).max(120),
  targetMuscles: z.array(MuscleGroupSchema).min(1).max(13),
  name: z.string().min(1).max(80).optional(),
});
export type ProgramGenerateInput = z.infer<typeof ProgramGenerateInputSchema>;

export const ProgramExerciseSchema = z.object({
  exerciseId: z.string(),
  order: z.number().int().min(0),
  targetSets: z.number().int().min(1).max(10),
  targetReps: z.number().int().min(1).max(50).nullable(),
  targetTimeSeconds: z.number().int().min(5).max(600).nullable(),
  restSeconds: z.number().int().min(0).max(600),
});
export type ProgramExercise = z.infer<typeof ProgramExerciseSchema>;

export const ProgramDaySchema = z.object({
  id: z.string().uuid(),
  dayIndex: z.number().int().min(0).max(6),
  name: z.string(),
  exercises: z.array(ProgramExerciseSchema),
});
export type ProgramDay = z.infer<typeof ProgramDaySchema>;

export const ProgramSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  name: z.string(),
  goal: GoalSchema,
  level: ProgramLevelSchema,
  equipment: ProgramEquipmentSchema,
  daysPerWeek: z.number().int(),
  sessionMinutes: z.number().int(),
  targetMuscles: z.array(MuscleGroupSchema),
  active: z.boolean(),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
  days: z.array(ProgramDaySchema),
});
export type Program = z.infer<typeof ProgramSchema>;
