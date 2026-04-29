import { z } from 'zod';
import {
  EquipmentItemSchema,
  ExerciseLocationSchema,
  PositionGroupSchema,
  TrainingCategorySchema,
} from './enums.schema.js';

export const ExerciseSchema = z.object({
  id: z.string().uuid(),
  slug: z.string().min(1).max(80),
  nameTr: z.string().min(1).max(120),
  nameEn: z.string().min(1).max(120),
  category: TrainingCategorySchema,
  description: z.string().max(2000).nullable().optional(),
  videoUrl: z.string().url().nullable().optional(),
  thumbnailUrl: z.string().url().nullable().optional(),
  imageUrls: z.array(z.string().url()).default([]),
  primaryMuscles: z.array(z.string()).default([]),
  positionsTargeted: z.array(PositionGroupSchema).default([]),
  minAge: z.number().int().min(8).max(60).nullable().optional(),
  maxAge: z.number().int().min(8).max(60).nullable().optional(),
  requiredEquipment: z.array(EquipmentItemSchema).default([]),
  locations: z.array(ExerciseLocationSchema).default([]),
  difficulty: z.number().int().min(1).max(5).default(1),
  defaultSets: z.number().int().min(1).max(20).nullable().optional(),
  defaultReps: z.number().int().min(1).max(200).nullable().optional(),
  defaultDurationSeconds: z.number().int().min(1).max(7200).nullable().optional(),
  defaultDistanceMeters: z.number().int().min(1).max(20000).nullable().optional(),
  defaultRestSeconds: z.number().int().min(0).max(600).nullable().optional(),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});
export type Exercise = z.infer<typeof ExerciseSchema>;

// Seed/import için kullanılan input — id/timestamps yok.
export const ExerciseSeedInputSchema = ExerciseSchema.omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});
export type ExerciseSeedInput = z.infer<typeof ExerciseSeedInputSchema>;
