import { z } from 'zod';

export const RecipeCategorySchema = z.enum([
  'soup',
  'main_meat',
  'main_veg',
  'rice',
  'pasta',
  'breakfast',
  'pastry',
  'salad',
  'dessert',
  'drink',
  'meze',
  'student',
]);
export type RecipeCategory = z.infer<typeof RecipeCategorySchema>;

export const RecipeDifficultySchema = z.enum(['easy', 'medium', 'hard']);
export type RecipeDifficulty = z.infer<typeof RecipeDifficultySchema>;

/**
 * Free-form ingredient entry. `amount` is a Turkish-friendly human string
 * (e.g. "2 yemek kaşığı", "1 su bardağı", "3 adet orta boy"). `grams` is
 * an optional rough conversion so meal planners can estimate macros.
 */
export const RecipeIngredientSchema = z.object({
  name: z.string().min(1),
  amount: z.string().min(1),
  grams: z.number().nonnegative().max(5000).nullable().optional(),
});
export type RecipeIngredient = z.infer<typeof RecipeIngredientSchema>;

export const RecipeNutritionSchema = z.object({
  kcal: z.number().int().nonnegative().optional(),
  proteinG: z.number().nonnegative().optional(),
  carbsG: z.number().nonnegative().optional(),
  fatG: z.number().nonnegative().optional(),
});
export type RecipeNutrition = z.infer<typeof RecipeNutritionSchema>;

export const RecipeSchema = z.object({
  id: z.string().min(1),
  nameTr: z.string().min(1),
  nameEn: z.string().optional(),
  category: RecipeCategorySchema,
  cuisine: z.string().default('turkish'),
  servings: z.number().int().positive().max(30),
  prepMinutes: z.number().int().nonnegative().max(600),
  cookMinutes: z.number().int().nonnegative().max(600),
  difficulty: RecipeDifficultySchema,
  tags: z.array(z.string()).default([]),
  ingredients: z.array(RecipeIngredientSchema).min(1),
  steps: z.array(z.string().min(1)).min(1),
  nutritionPerServing: RecipeNutritionSchema.optional(),
  source: z.string().optional(),
});
export type Recipe = z.infer<typeof RecipeSchema>;
