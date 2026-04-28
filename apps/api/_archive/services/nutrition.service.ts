import type {
  ActivityLevel,
  Gender,
  Goal,
  Meal,
  MealItem,
  NutritionGenerateInput,
  Recipe,
  RecipeCategory,
} from '@fittrack/shared';
import { recipes } from '@fittrack/recipe-db';
import { AppError } from '../lib/errors.js';
import { prisma } from '../lib/prisma.js';

/* -------------------------------------------------------------------------- */
/* Energy + macro math                                                        */
/* -------------------------------------------------------------------------- */

const ACTIVITY_MULTIPLIERS: Record<ActivityLevel, number> = {
  sedentary: 1.2,
  light: 1.375,
  moderate: 1.55,
  active: 1.725,
  very_active: 1.9,
};

const GOAL_KCAL_OFFSET: Record<Goal, number> = {
  lose_fat: -500,
  maintain: 0,
  gain_muscle: 300,
  general_fitness: 0,
};

const PROTEIN_PER_KG: Record<Goal, number> = {
  lose_fat: 2.2,
  gain_muscle: 2.0,
  maintain: 1.6,
  general_fitness: 1.6,
};

function bmrMifflinStJeor(input: NutritionGenerateInput): number {
  const base = 10 * input.weightKg + 6.25 * input.heightCm - 5 * input.age;
  return Math.round(base + offsetForGender(input.gender));
}

function offsetForGender(gender: Gender): number {
  switch (gender) {
    case 'male':
      return 5;
    case 'female':
      return -161;
    default:
      return -78;
  }
}

function macroTargets(targetKcal: number, weightKg: number, goal: Goal) {
  const proteinG = Math.round(PROTEIN_PER_KG[goal] * weightKg);
  const fatKcal = Math.round(targetKcal * 0.25);
  const fatG = Math.round(fatKcal / 9);
  const remainingKcal = targetKcal - proteinG * 4 - fatG * 9;
  const carbsG = Math.max(0, Math.round(remainingKcal / 4));
  return { proteinG, carbsG, fatG };
}

/* -------------------------------------------------------------------------- */
/* Recipe classification                                                      */
/* -------------------------------------------------------------------------- */

type MealSlotType = 'breakfast' | 'snack' | 'lunch' | 'dinner';

/**
 * Which meal slots each recipe category fits into. Desserts and drinks are
 * deliberately excluded from auto-generated plans — they show up in the
 * recipes browser but not in the diet.
 */
const CATEGORY_TO_SLOTS: Partial<Record<RecipeCategory, MealSlotType[]>> = {
  breakfast: ['breakfast'],
  soup: ['lunch', 'dinner', 'snack'],
  main_meat: ['lunch', 'dinner'],
  main_veg: ['lunch', 'dinner'],
  rice: ['lunch', 'dinner'],
  pasta: ['lunch', 'dinner'],
  salad: ['snack', 'lunch'],
  meze: ['snack'],
  pastry: ['snack', 'breakfast'],
  student: ['lunch', 'dinner', 'snack'],
};

/** Hard-excluded categories (desserts, sugary drinks, too-dense pastries). */
const EXCLUDED_FOR_PLANS = new Set<RecipeCategory>(['dessert', 'drink']);

function slotsFor(recipe: Recipe): MealSlotType[] {
  if (EXCLUDED_FOR_PLANS.has(recipe.category)) return [];
  return CATEGORY_TO_SLOTS[recipe.category] ?? [];
}

function goalsFor(recipe: Recipe): Goal[] {
  const kcal = recipe.nutritionPerServing?.kcal ?? 0;
  const protein = recipe.nutritionPerServing?.proteinG ?? 0;
  const fat = recipe.nutritionPerServing?.fatG ?? 0;

  const fits: Goal[] = ['maintain', 'general_fitness'];

  // Fat loss: reasonably lean + respectable protein. Excludes pastries and
  // anything with huge fat load.
  if (kcal > 0 && kcal <= 500 && protein >= 12 && fat <= 22) {
    fits.push('lose_fat');
  }
  // Muscle gain: calorie-dense or protein-dense. A 520 kcal main with 35g P
  // is perfect for bulking.
  if (kcal >= 350 && protein >= 18) {
    fits.push('gain_muscle');
  }
  return fits;
}

interface ClassifiedRecipe {
  recipe: Recipe;
  slots: MealSlotType[];
  goals: Goal[];
}

const CLASSIFIED: ClassifiedRecipe[] = recipes
  .map((r) => ({ recipe: r, slots: slotsFor(r), goals: goalsFor(r) }))
  .filter((c) => c.slots.length > 0 && c.recipe.nutritionPerServing?.kcal);

function candidateRecipes(
  slot: MealSlotType,
  goal: Goal,
  usedRecipeIds: Set<string>,
): Recipe[] {
  const strict = CLASSIFIED.filter(
    (c) =>
      c.slots.includes(slot) &&
      c.goals.includes(goal) &&
      !usedRecipeIds.has(c.recipe.id),
  ).map((c) => c.recipe);
  if (strict.length > 0) return strict;

  // Relax 1: drop the no-reuse rule (small goal pools).
  const relaxed = CLASSIFIED.filter(
    (c) => c.slots.includes(slot) && c.goals.includes(goal),
  ).map((c) => c.recipe);
  if (relaxed.length > 0) return relaxed;

  // Relax 2: drop the goal filter but keep the slot filter.
  return CLASSIFIED.filter((c) => c.slots.includes(slot)).map(
    (c) => c.recipe,
  );
}

function randomPick<T>(arr: readonly T[]): T | null {
  if (arr.length === 0) return null;
  return arr[Math.floor(Math.random() * arr.length)]!;
}

/* -------------------------------------------------------------------------- */
/* Meal composition                                                           */
/* -------------------------------------------------------------------------- */

interface SlotSpec {
  key: string;
  name: string;
  type: MealSlotType;
  /** Share of daily kcal for this slot. */
  share: number;
}

const SLOTS: SlotSpec[] = [
  { key: 'breakfast', name: 'Kahvaltı', type: 'breakfast', share: 0.25 },
  { key: 'snack1',    name: 'Ara Öğün', type: 'snack',     share: 0.10 },
  { key: 'lunch',     name: 'Öğle',     type: 'lunch',     share: 0.30 },
  { key: 'snack2',    name: 'İkindi',   type: 'snack',     share: 0.10 },
  { key: 'dinner',    name: 'Akşam',    type: 'dinner',    share: 0.25 },
];

/**
 * Rounds servings to whole / half values that humans actually eat. Clamped to
 * [0.5, 3] so we never tell someone to eat "6 servings of lentil soup".
 */
function roundServings(raw: number): number {
  const clamped = Math.min(3, Math.max(0.5, raw));
  return Math.round(clamped * 2) / 2;
}

function mealFromRecipe(
  slot: SlotSpec,
  recipe: Recipe,
  targetKcal: number,
): Meal {
  const perServing = recipe.nutritionPerServing ?? {
    kcal: targetKcal,
    proteinG: 0,
    carbsG: 0,
    fatG: 0,
  };
  const servings = roundServings(targetKcal / (perServing.kcal || 1));
  const kcal = Math.round((perServing.kcal ?? 0) * servings);
  const proteinG = +((perServing.proteinG ?? 0) * servings).toFixed(1);
  const carbsG = +((perServing.carbsG ?? 0) * servings).toFixed(1);
  const fatG = +((perServing.fatG ?? 0) * servings).toFixed(1);

  // Expose ingredients as display-only items so the dashboard can preview
  // what the meal contains without having to fetch the recipe up front.
  const items: MealItem[] = recipe.ingredients.slice(0, 6).map((ing) => ({
    foodId: ing.name,
    grams: Math.round((ing.grams ?? 0) * servings),
    kcal: 0,
    proteinG: 0,
    carbsG: 0,
    fatG: 0,
    label: servings === 1
      ? ing.amount
      : `${ing.amount} × ${formatServings(servings)}`,
  }));

  return {
    key: slot.key,
    name: recipe.nameTr,
    targetKcal,
    items,
    kcal,
    proteinG,
    carbsG,
    fatG,
    recipeId: recipe.id,
    recipeNameTr: recipe.nameTr,
    servings,
  };
}

function formatServings(n: number): string {
  return n === Math.trunc(n) ? `${n}` : n.toFixed(1).replace('.0', '');
}

function buildDayPlan(targetKcal: number, goal: Goal): Meal[] {
  const used = new Set<string>();
  return SLOTS.map((slot) => {
    const pool = candidateRecipes(slot.type, goal, used);
    const recipe = randomPick(pool);
    const slotTarget = Math.round(targetKcal * slot.share);
    if (!recipe) {
      return {
        key: slot.key,
        name: slot.name,
        targetKcal: slotTarget,
        items: [],
        kcal: 0,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
      } satisfies Meal;
    }
    used.add(recipe.id);
    return mealFromRecipe(slot, recipe, slotTarget);
  });
}

function labelForGoal(goal: Goal): string {
  switch (goal) {
    case 'lose_fat':
      return 'Yağ Yakma';
    case 'gain_muscle':
      return 'Kas Kazanma';
    case 'maintain':
      return 'Koruma';
    default:
      return 'Genel Beslenme';
  }
}

/* -------------------------------------------------------------------------- */
/* Service                                                                    */
/* -------------------------------------------------------------------------- */

export class NutritionService {
  async generate(userId: string, input: NutritionGenerateInput) {
    const bmr = bmrMifflinStJeor(input);
    const tdee = Math.round(bmr * ACTIVITY_MULTIPLIERS[input.activityLevel]);
    const targetKcal = Math.max(1200, tdee + GOAL_KCAL_OFFSET[input.goal]);
    const { proteinG, carbsG, fatG } = macroTargets(targetKcal, input.weightKg, input.goal);
    const meals = buildDayPlan(targetKcal, input.goal);

    await prisma.nutritionPlan.updateMany({
      where: { userId, active: true },
      data: { active: false },
    });

    return prisma.nutritionPlan.create({
      data: {
        userId,
        name: `${labelForGoal(input.goal)} · ${targetKcal} kcal`,
        goal: input.goal,
        activityLevel: input.activityLevel,
        gender: input.gender,
        age: input.age,
        heightCm: input.heightCm,
        weightKg: input.weightKg,
        bmr,
        tdee,
        targetKcal,
        proteinG,
        carbsG,
        fatG,
        meals,
        active: true,
      },
    });
  }

  async getActive(userId: string) {
    return prisma.nutritionPlan.findFirst({ where: { userId, active: true } });
  }

  async delete(userId: string, planId: string) {
    const owned = await prisma.nutritionPlan.findFirst({
      where: { id: planId, userId },
    });
    if (!owned) throw AppError.notFound('Plan not found');
    await prisma.nutritionPlan.delete({ where: { id: planId } });
  }
}

export const nutritionService = new NutritionService();

// Re-export food catalog for the legacy /nutrition/foods endpoint so older
// mobile builds keep working. Not used by the new recipe-based generator.
export { FOODS, FOOD_BY_ID } from '../data/foods.js';
