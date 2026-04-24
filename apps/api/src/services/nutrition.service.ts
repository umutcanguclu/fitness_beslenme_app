import type {
  ActivityLevel,
  Gender,
  Goal,
  Meal,
  MealItem,
  NutritionGenerateInput,
} from '@fittrack/shared';
import { AppError } from '../lib/errors.js';
import { prisma } from '../lib/prisma.js';
import { FOOD_BY_ID, FOODS, type Food, type FoodCategory } from '../data/foods.js';

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

/** Protein grams per kg bodyweight based on goal. */
const PROTEIN_PER_KG: Record<Goal, number> = {
  lose_fat: 2.2,
  gain_muscle: 2.0,
  maintain: 1.6,
  general_fitness: 1.6,
};

/** Mifflin–St Jeor basal metabolic rate. */
function bmrMifflinStJeor(input: NutritionGenerateInput): number {
  const base = 10 * input.weightKg + 6.25 * input.heightCm - 5 * input.age;
  // Non-binary / prefer-not-to-say: average between male/female offsets.
  const offset = offsetForGender(input.gender);
  return Math.round(base + offset);
}

function offsetForGender(gender: Gender): number {
  switch (gender) {
    case 'male':
      return 5;
    case 'female':
      return -161;
    default:
      return -78; // mean of 5 and −161
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
/* Meal-plan composition                                                      */
/* -------------------------------------------------------------------------- */

interface MealSpec {
  key: string;
  name: string;
  share: number; // portion of daily kcal
  /** Ordered list of category slots the meal should try to fill. */
  slots: FoodCategory[];
}

const MEAL_SPECS: MealSpec[] = [
  { key: 'breakfast', name: 'Kahvaltı', share: 0.25, slots: ['breakfast_staple', 'dairy', 'breakfast_topping', 'fruit'] },
  { key: 'snack1',    name: 'Ara Öğün', share: 0.10, slots: ['fruit', 'nut_seed'] },
  { key: 'lunch',     name: 'Öğle',      share: 0.30, slots: ['protein_lean', 'carb_grain', 'vegetable', 'fat'] },
  { key: 'snack2',    name: 'İkindi',    share: 0.10, slots: ['dairy', 'fruit'] },
  { key: 'dinner',    name: 'Akşam',     share: 0.25, slots: ['protein_lean', 'carb_grain', 'vegetable', 'fat'] },
];

function pickFoodForSlot(
  category: FoodCategory,
  used: Set<string>,
  prefer: 'lean' | 'balanced',
): Food | null {
  const pool = FOODS.filter((f) => f.category === category && !used.has(f.id));
  if (pool.length === 0) return null;
  // Prefer lean options when protein slot and goal is lose_fat (done at caller via category swap).
  if (prefer === 'lean') {
    pool.sort((a, b) => a.fatG - b.fatG);
  } else {
    // Shuffle a bit for variety.
    pool.sort(() => Math.random() - 0.5);
  }
  return pool[0] ?? null;
}

function roundGrams(grams: number, increment = 10): number {
  if (grams <= 0) return 0;
  return Math.max(increment, Math.round(grams / increment) * increment);
}

function applyPortion(food: Food, grams: number) {
  const scale = grams / 100;
  return {
    kcal: Math.round(food.kcal * scale),
    proteinG: +(food.proteinG * scale).toFixed(1),
    carbsG: +(food.carbsG * scale).toFixed(1),
    fatG: +(food.fatG * scale).toFixed(1),
  };
}

/**
 * Builds a single meal by filling its category slots, sizing each portion so
 * that total kcal approaches `mealKcal`. Protein-dense slots are anchored
 * near their default serving; carbs/fats flex to hit the target.
 */
function buildMeal(
  spec: MealSpec,
  mealKcal: number,
  globalUsed: Set<string>,
  preferLean: boolean,
): Meal {
  const items: MealItem[] = [];
  let remainingKcal = mealKcal;
  const localUsed = new Set<string>(globalUsed);
  const preference = preferLean ? 'lean' : 'balanced';

  for (let i = 0; i < spec.slots.length; i++) {
    const slot = spec.slots[i];
    const food = pickFoodForSlot(slot, localUsed, preference);
    if (!food) continue;
    localUsed.add(food.id);
    globalUsed.add(food.id);

    // Kcal share for this slot: protein/carb first slots get most; last fills remainder.
    const slotsLeft = spec.slots.length - i;
    const targetKcalForSlot = slotsLeft === 1
      ? Math.max(0, remainingKcal)
      : Math.round(remainingKcal / slotsLeft);

    const gramsForTarget = (targetKcalForSlot / food.kcal) * 100;
    // Bound the portion so we don't get absurd amounts.
    const minG = Math.max(food.servingG * 0.4, 15);
    const maxG = food.servingG * 3;
    const grams = roundGrams(Math.min(Math.max(gramsForTarget, minG), maxG));
    const macros = applyPortion(food, grams);
    items.push({ foodId: food.id, grams, ...macros });
    remainingKcal -= macros.kcal;
  }

  const total = items.reduce(
    (acc, it) => ({
      kcal: acc.kcal + it.kcal,
      proteinG: acc.proteinG + it.proteinG,
      carbsG: acc.carbsG + it.carbsG,
      fatG: acc.fatG + it.fatG,
    }),
    { kcal: 0, proteinG: 0, carbsG: 0, fatG: 0 },
  );

  return {
    key: spec.key,
    name: spec.name,
    targetKcal: mealKcal,
    items,
    kcal: total.kcal,
    proteinG: +total.proteinG.toFixed(1),
    carbsG: +total.carbsG.toFixed(1),
    fatG: +total.fatG.toFixed(1),
  };
}

function buildMealPlan(targetKcal: number, goal: Goal): Meal[] {
  const used = new Set<string>();
  const preferLean = goal === 'lose_fat';
  return MEAL_SPECS.map((spec) =>
    buildMeal(spec, Math.round(targetKcal * spec.share), used, preferLean),
  );
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
    const meals = buildMealPlan(targetKcal, input.goal);

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
    return prisma.nutritionPlan.findFirst({
      where: { userId, active: true },
    });
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

/** Re-export catalog for routes that want to return food metadata. */
export { FOODS, FOOD_BY_ID };
