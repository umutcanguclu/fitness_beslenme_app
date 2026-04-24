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
import { FOOD_BY_ID, FOODS, type Food } from '../data/foods.js';
import {
  MEAL_TEMPLATES,
  templatesFor,
  type MealTemplate,
  type MealType,
} from '../data/meal-templates.js';

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
/* Meal slot spec                                                             */
/* -------------------------------------------------------------------------- */

interface SlotSpec {
  key: string;
  name: string;
  type: MealType;
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

/* -------------------------------------------------------------------------- */
/* Template selection + scaling                                               */
/* -------------------------------------------------------------------------- */

function pickTemplate(
  type: MealType,
  goal: Goal,
  usedTemplateIds: Set<string>,
): MealTemplate | null {
  // Prefer templates matching the exact meal type and goal.
  const exact = templatesFor(type, goal).filter((t) => !usedTemplateIds.has(t.id));
  if (exact.length > 0) return randomPick(exact);

  // Lunch/dinner are interchangeable pools — try the sibling type.
  if (type === 'lunch' || type === 'dinner') {
    const sibling = type === 'lunch' ? 'dinner' : 'lunch';
    const siblingPool = MEAL_TEMPLATES.filter(
      (t) => t.type === sibling && t.goals.includes(goal) && !usedTemplateIds.has(t.id),
    );
    if (siblingPool.length > 0) return randomPick(siblingPool);
  }

  // Still nothing? Drop the "unused" constraint.
  const any = templatesFor(type, goal);
  if (any.length > 0) return randomPick(any);

  // Absolute fallback: any template of the right type.
  const anyType = MEAL_TEMPLATES.filter((t) => t.type === type);
  return anyType.length > 0 ? randomPick(anyType) : null;
}

function randomPick<T>(arr: readonly T[]): T {
  if (arr.length === 0) {
    throw new Error('randomPick called on empty array');
  }
  return arr[Math.floor(Math.random() * arr.length)]!;
}

function roundGrams(grams: number, increment = 5): number {
  if (grams <= 0) return 0;
  return Math.max(increment, Math.round(grams / increment) * increment);
}

function baselineKcal(template: MealTemplate): number {
  return template.items.reduce((sum, it) => {
    const food = FOOD_BY_ID.get(it.foodId);
    if (!food) return sum;
    return sum + (food.kcal * it.baseG) / 100;
  }, 0);
}

/**
 * Scales a template's ingredient portions so total kcal ≈ target. Uniform
 * scalar preserves the recipe's character (tavuk miktarı ile pilav miktarı
 * aynı oranda değişir). Clamped to [0.6, 1.8] to prevent absurd portions.
 */
function buildMealFromTemplate(
  template: MealTemplate,
  targetKcal: number,
): Meal {
  const baseline = baselineKcal(template);
  const rawScalar = baseline > 0 ? targetKcal / baseline : 1;
  const scalar = Math.min(1.8, Math.max(0.6, rawScalar));

  const items: MealItem[] = [];
  let kcal = 0;
  let proteinG = 0;
  let carbsG = 0;
  let fatG = 0;

  for (const it of template.items) {
    const food = FOOD_BY_ID.get(it.foodId);
    if (!food) continue;
    const grams = roundGrams(it.baseG * scalar);
    const scale = grams / 100;
    const itemKcal = Math.round(food.kcal * scale);
    const itemP = +(food.proteinG * scale).toFixed(1);
    const itemC = +(food.carbsG * scale).toFixed(1);
    const itemF = +(food.fatG * scale).toFixed(1);
    items.push({
      foodId: it.foodId,
      grams,
      kcal: itemKcal,
      proteinG: itemP,
      carbsG: itemC,
      fatG: itemF,
    });
    kcal += itemKcal;
    proteinG += itemP;
    carbsG += itemC;
    fatG += itemF;
  }

  // If we hit the clamp ceiling (huge target, small baseline recipe),
  // top up with an extra grain + protein serving so the meal isn't anemic.
  const gap = targetKcal - kcal;
  if (gap > 200 && rawScalar > 1.8) {
    const topUp = pickTopUp(template, items);
    if (topUp) {
      const grams = roundGrams(Math.min((gap / topUp.kcal) * 100, topUp.servingG * 2));
      const scale = grams / 100;
      items.push({
        foodId: topUp.id,
        grams,
        kcal: Math.round(topUp.kcal * scale),
        proteinG: +(topUp.proteinG * scale).toFixed(1),
        carbsG: +(topUp.carbsG * scale).toFixed(1),
        fatG: +(topUp.fatG * scale).toFixed(1),
      });
      const last = items[items.length - 1]!;
      kcal += last.kcal;
      proteinG += last.proteinG;
      carbsG += last.carbsG;
      fatG += last.fatG;
    }
  }

  return {
    key: template.id,
    name: template.nameTr,
    targetKcal,
    items,
    kcal: Math.round(kcal),
    proteinG: +proteinG.toFixed(1),
    carbsG: +carbsG.toFixed(1),
    fatG: +fatG.toFixed(1),
  };
}

function pickTopUp(template: MealTemplate, items: MealItem[]): Food | null {
  const used = new Set(items.map((i) => i.foodId));
  const needsProtein = template.type === 'lunch' || template.type === 'dinner';
  const preferredCat = needsProtein ? 'carb_grain' : 'nut_seed';
  const food = FOODS.find((f) => f.category === preferredCat && !used.has(f.id));
  return food ?? null;
}

/* -------------------------------------------------------------------------- */
/* Plan assembly                                                              */
/* -------------------------------------------------------------------------- */

function buildDayPlan(targetKcal: number, goal: Goal): Meal[] {
  const usedTemplateIds = new Set<string>();
  return SLOTS.map((slot) => {
    const template = pickTemplate(slot.type, goal, usedTemplateIds);
    if (!template) {
      return {
        key: slot.key,
        name: slot.name,
        targetKcal: Math.round(targetKcal * slot.share),
        items: [],
        kcal: 0,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
      } satisfies Meal;
    }
    usedTemplateIds.add(template.id);
    const meal = buildMealFromTemplate(
      template,
      Math.round(targetKcal * slot.share),
    );
    // Override the key/name to the slot's label so the UI maps to icons cleanly
    // while keeping the template id accessible if we ever need provenance.
    return { ...meal, key: slot.key, name: `${slot.name} · ${template.nameTr}` };
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

export { FOODS, FOOD_BY_ID };
