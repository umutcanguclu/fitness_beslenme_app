import { z } from 'zod';
import { GenderSchema, GoalSchema } from './user.schema.js';

export const ActivityLevelSchema = z.enum([
  'sedentary',
  'light',
  'moderate',
  'active',
  'very_active',
]);
export type ActivityLevel = z.infer<typeof ActivityLevelSchema>;

export const NutritionGenerateInputSchema = z.object({
  age: z.number().int().min(14).max(90),
  gender: GenderSchema,
  heightCm: z.number().positive().min(120).max(230),
  weightKg: z.number().positive().min(30).max(250),
  activityLevel: ActivityLevelSchema,
  goal: GoalSchema,
});
export type NutritionGenerateInput = z.infer<typeof NutritionGenerateInputSchema>;

export const MealItemSchema = z.object({
  foodId: z.string(),
  grams: z.number().int().min(1),
  kcal: z.number().int(),
  proteinG: z.number(),
  carbsG: z.number(),
  fatG: z.number(),
});
export type MealItem = z.infer<typeof MealItemSchema>;

export const MealSchema = z.object({
  key: z.string(),
  name: z.string(),
  targetKcal: z.number().int(),
  items: z.array(MealItemSchema),
  kcal: z.number().int(),
  proteinG: z.number(),
  carbsG: z.number(),
  fatG: z.number(),
});
export type Meal = z.infer<typeof MealSchema>;

export const NutritionPlanSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  name: z.string(),
  goal: GoalSchema,
  activityLevel: ActivityLevelSchema,
  gender: GenderSchema,
  age: z.number().int(),
  heightCm: z.number(),
  weightKg: z.number(),
  bmr: z.number().int(),
  tdee: z.number().int(),
  targetKcal: z.number().int(),
  proteinG: z.number().int(),
  carbsG: z.number().int(),
  fatG: z.number().int(),
  meals: z.array(MealSchema),
  active: z.boolean(),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});
export type NutritionPlan = z.infer<typeof NutritionPlanSchema>;
