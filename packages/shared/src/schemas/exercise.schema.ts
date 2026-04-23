import { z } from 'zod';

export const MuscleGroupSchema = z.enum([
  'chest',
  'back',
  'shoulders',
  'biceps',
  'triceps',
  'forearms',
  'core',
  'quads',
  'hamstrings',
  'glutes',
  'calves',
  'cardio',
  'full_body',
]);
export type MuscleGroup = z.infer<typeof MuscleGroupSchema>;

export const EquipmentSchema = z.enum([
  'barbell',
  'dumbbell',
  'machine',
  'cable',
  'bodyweight',
  'kettlebell',
  'resistance_band',
  'cardio_machine',
  'other',
]);
export type Equipment = z.infer<typeof EquipmentSchema>;

export const ExerciseTypeSchema = z.enum([
  'strength',
  'cardio',
  'stretch',
  'plyometric',
  'powerlifting',
  'olympic',
  'strongman',
]);
export type ExerciseType = z.infer<typeof ExerciseTypeSchema>;

export const ExerciseLevelSchema = z.enum(['beginner', 'intermediate', 'expert']);
export type ExerciseLevel = z.infer<typeof ExerciseLevelSchema>;

export const ExerciseMechanicSchema = z.enum(['compound', 'isolation']);
export type ExerciseMechanic = z.infer<typeof ExerciseMechanicSchema>;

export const ExerciseSchema = z.object({
  id: z.string(),
  nameEn: z.string().min(1),
  nameTr: z.string().min(1),
  muscleGroup: z.array(MuscleGroupSchema).min(1),
  equipment: z.array(EquipmentSchema).min(1),
  type: ExerciseTypeSchema,
  level: ExerciseLevelSchema.nullable().optional(),
  mechanic: ExerciseMechanicSchema.nullable().optional(),
  images: z.array(z.string().url()).default([]),
  mediaUrl: z.string().url().nullable().optional(),
  instructionsEn: z.string().nullable().optional(),
  instructionsTr: z.string().nullable().optional(),
});
export type Exercise = z.infer<typeof ExerciseSchema>;
