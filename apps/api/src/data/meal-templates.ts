/**
 * Curated meal templates. Each template is a hand-designed recipe (real
 * dietitian-style combinations: Türk kahvaltısı, tavuk-pilav, somon-kinoa, …)
 * with fixed ingredient ratios at BASE portions. The generator picks a
 * template per slot and scales every ingredient by the same factor to hit
 * the slot's target kcal, preserving the recipe's character.
 *
 * References synthesized from Turkish dietitian meal plans (Supplementler,
 * Alife Sağlık Grubu, Tugba Yaprak), US sports nutrition programs
 * (FeastGood 3000 kcal bulking, Strongr Fastr, MSU sports nutrition), and
 * Mediterranean-diet guidance (Mayo Clinic, Cleveland Clinic).
 */
import type { Goal } from '@fittrack/shared';

export type MealType = 'breakfast' | 'snack' | 'lunch' | 'dinner';

export interface TemplateItem {
  foodId: string;
  /** Portion in grams at the template's baseline kcal. The selector scales all items proportionally. */
  baseG: number;
}

export interface MealTemplate {
  id: string;
  nameTr: string;
  nameEn: string;
  type: MealType;
  /** Which user goals this template is appropriate for. */
  goals: Goal[];
  items: TemplateItem[];
  /** Short tagline shown in UI. */
  tagline?: string;
}

/* -------------------------------------------------------------------------- */
/* BREAKFAST                                                                  */
/* -------------------------------------------------------------------------- */

const breakfastTemplates: MealTemplate[] = [
  {
    id: 'tr_breakfast_classic',
    nameTr: 'Klasik Türk Kahvaltısı',
    nameEn: 'Classic Turkish Breakfast',
    type: 'breakfast',
    goals: ['maintain', 'gain_muscle', 'general_fitness'],
    tagline: 'Yumurta, peynir, zeytin, ekmek',
    items: [
      { foodId: 'egg_whole', baseG: 100 },
      { foodId: 'cheese_white', baseG: 40 },
      { foodId: 'olives_black', baseG: 20 },
      { foodId: 'bread_whole', baseG: 40 },
      { foodId: 'tomato', baseG: 80 },
      { foodId: 'cucumber', baseG: 50 },
    ],
  },
  {
    id: 'oat_bowl_classic',
    nameTr: 'Yulaf Ezmesi Kasesi',
    nameEn: 'Classic Oat Bowl',
    type: 'breakfast',
    goals: ['lose_fat', 'maintain', 'gain_muscle', 'general_fitness'],
    tagline: 'Yulaf, süt, muz, fıstık ezmesi',
    items: [
      { foodId: 'oats', baseG: 60 },
      { foodId: 'milk_skim', baseG: 200 },
      { foodId: 'banana', baseG: 100 },
      { foodId: 'peanut_butter', baseG: 15 },
    ],
  },
  {
    id: 'protein_oat_bowl',
    nameTr: 'Proteinli Yulaf Kasesi',
    nameEn: 'Protein Oat Bowl',
    type: 'breakfast',
    goals: ['gain_muscle', 'general_fitness'],
    tagline: 'Yulaf, Yunan yoğurt, yumurta beyazı, muz',
    items: [
      { foodId: 'oats', baseG: 60 },
      { foodId: 'yogurt_greek', baseG: 150 },
      { foodId: 'egg_white', baseG: 90 },
      { foodId: 'banana', baseG: 100 },
      { foodId: 'almonds', baseG: 15 },
    ],
  },
  {
    id: 'spinach_omelette',
    nameTr: 'Ispanaklı Omlet',
    nameEn: 'Spinach Omelette',
    type: 'breakfast',
    goals: ['lose_fat', 'maintain', 'general_fitness'],
    tagline: 'Yumurta, ıspanak, beyaz peynir, tam buğday ekmek',
    items: [
      { foodId: 'egg_whole', baseG: 150 },
      { foodId: 'spinach', baseG: 100 },
      { foodId: 'cheese_white', baseG: 30 },
      { foodId: 'bread_whole', baseG: 30 },
      { foodId: 'olive_oil', baseG: 5 },
    ],
  },
  {
    id: 'greek_yogurt_bowl',
    nameTr: 'Yoğurt Meyve Kasesi',
    nameEn: 'Greek Yogurt Bowl',
    type: 'breakfast',
    goals: ['lose_fat', 'maintain'],
    tagline: 'Yunan yoğurt, çilek, ceviz, bal',
    items: [
      { foodId: 'yogurt_greek', baseG: 200 },
      { foodId: 'strawberry', baseG: 100 },
      { foodId: 'walnuts', baseG: 20 },
      { foodId: 'honey', baseG: 10 },
    ],
  },
  {
    id: 'mediterranean_breakfast',
    nameTr: 'Akdeniz Kahvaltısı',
    nameEn: 'Mediterranean Breakfast',
    type: 'breakfast',
    goals: ['maintain', 'general_fitness'],
    tagline: 'Yumurta, avokado, domates, zeytin, ekmek',
    items: [
      { foodId: 'egg_whole', baseG: 100 },
      { foodId: 'bread_whole', baseG: 30 },
      { foodId: 'avocado', baseG: 50 },
      { foodId: 'tomato', baseG: 80 },
      { foodId: 'olives_green', baseG: 20 },
    ],
  },
  {
    id: 'cottage_cheese_toast',
    nameTr: 'Lor Peynirli Tost',
    nameEn: 'Cottage Cheese Toast',
    type: 'breakfast',
    goals: ['lose_fat', 'maintain'],
    tagline: 'Lor peyniri, tam buğday ekmek, domates',
    items: [
      { foodId: 'cottage_cheese', baseG: 120 },
      { foodId: 'bread_whole', baseG: 50 },
      { foodId: 'tomato', baseG: 100 },
      { foodId: 'cucumber', baseG: 60 },
    ],
  },
];

/* -------------------------------------------------------------------------- */
/* SNACK                                                                      */
/* -------------------------------------------------------------------------- */

const snackTemplates: MealTemplate[] = [
  {
    id: 'snack_yogurt_berry',
    nameTr: 'Yoğurt & Yaban Mersini',
    nameEn: 'Yogurt & Blueberries',
    type: 'snack',
    goals: ['lose_fat', 'maintain', 'gain_muscle', 'general_fitness'],
    items: [
      { foodId: 'yogurt_greek', baseG: 150 },
      { foodId: 'blueberry', baseG: 80 },
      { foodId: 'honey', baseG: 10 },
    ],
  },
  {
    id: 'snack_banana_pb',
    nameTr: 'Muz & Fıstık Ezmesi',
    nameEn: 'Banana & Peanut Butter',
    type: 'snack',
    goals: ['gain_muscle', 'general_fitness'],
    items: [
      { foodId: 'banana', baseG: 120 },
      { foodId: 'peanut_butter', baseG: 20 },
    ],
  },
  {
    id: 'snack_apple_almond',
    nameTr: 'Elma & Badem',
    nameEn: 'Apple & Almonds',
    type: 'snack',
    goals: ['lose_fat', 'maintain', 'general_fitness'],
    items: [
      { foodId: 'apple', baseG: 180 },
      { foodId: 'almonds', baseG: 25 },
    ],
  },
  {
    id: 'snack_cottage_pear',
    nameTr: 'Lor Peyniri & Armut',
    nameEn: 'Cottage Cheese & Pear',
    type: 'snack',
    goals: ['lose_fat', 'maintain', 'gain_muscle'],
    items: [
      { foodId: 'cottage_cheese', baseG: 100 },
      { foodId: 'pear', baseG: 150 },
    ],
  },
  {
    id: 'snack_oats_milk',
    nameTr: 'Sütlü Yulaf & Muz',
    nameEn: 'Milky Oats & Banana',
    type: 'snack',
    goals: ['gain_muscle'],
    tagline: 'Antrenman sonrası önerilir',
    items: [
      { foodId: 'milk_skim', baseG: 250 },
      { foodId: 'banana', baseG: 120 },
      { foodId: 'oats', baseG: 40 },
    ],
  },
  {
    id: 'snack_simit_cheese',
    nameTr: 'Simit & Beyaz Peynir',
    nameEn: 'Simit & Feta',
    type: 'snack',
    goals: ['maintain', 'gain_muscle', 'general_fitness'],
    items: [
      { foodId: 'simit', baseG: 60 },
      { foodId: 'cheese_white', baseG: 40 },
      { foodId: 'tomato', baseG: 80 },
    ],
  },
  {
    id: 'snack_pear_walnut',
    nameTr: 'Armut & Ceviz',
    nameEn: 'Pear & Walnuts',
    type: 'snack',
    goals: ['maintain', 'general_fitness'],
    items: [
      { foodId: 'pear', baseG: 180 },
      { foodId: 'walnuts', baseG: 20 },
    ],
  },
  {
    id: 'snack_tuna_rice_cake',
    nameTr: 'Ton Balığı & Pirinç Keki',
    nameEn: 'Tuna & Rice Cakes',
    type: 'snack',
    goals: ['lose_fat', 'gain_muscle'],
    items: [
      { foodId: 'tuna_canned', baseG: 80 },
      { foodId: 'rice_cake', baseG: 20 },
      { foodId: 'cucumber', baseG: 60 },
    ],
  },
  {
    id: 'snack_yogurt_fig',
    nameTr: 'Yoğurt & Kuru İncir',
    nameEn: 'Yogurt & Dried Figs',
    type: 'snack',
    goals: ['gain_muscle', 'general_fitness'],
    items: [
      { foodId: 'yogurt_nonfat', baseG: 200 },
      { foodId: 'fig_dry', baseG: 30 },
      { foodId: 'hazelnuts', baseG: 15 },
    ],
  },
];

/* -------------------------------------------------------------------------- */
/* LUNCH / DINNER                                                             */
/* -------------------------------------------------------------------------- */

const mainMealTemplates: MealTemplate[] = [
  {
    id: 'chicken_bulgur_salad',
    nameTr: 'Tavuk Göğsü & Bulgur Pilavı & Salata',
    nameEn: 'Chicken + Bulgur + Salad',
    type: 'lunch',
    goals: ['lose_fat', 'maintain', 'gain_muscle', 'general_fitness'],
    items: [
      { foodId: 'chicken_breast', baseG: 150 },
      { foodId: 'bulgur', baseG: 200 },
      { foodId: 'salad_greens', baseG: 100 },
      { foodId: 'olive_oil', baseG: 5 },
      { foodId: 'tomato', baseG: 100 },
    ],
  },
  {
    id: 'chicken_rice_broccoli',
    nameTr: 'Tavuk & Pirinç Pilavı & Brokoli',
    nameEn: 'Chicken + Rice + Broccoli',
    type: 'lunch',
    goals: ['gain_muscle', 'maintain'],
    items: [
      { foodId: 'chicken_breast', baseG: 180 },
      { foodId: 'rice_white', baseG: 200 },
      { foodId: 'broccoli', baseG: 150 },
      { foodId: 'olive_oil', baseG: 5 },
    ],
  },
  {
    id: 'salmon_quinoa_zucchini',
    nameTr: 'Somon & Kinoa & Kabak',
    nameEn: 'Salmon + Quinoa + Zucchini',
    type: 'dinner',
    goals: ['maintain', 'lose_fat', 'general_fitness'],
    tagline: 'Akdeniz tarzı, omega-3 zengini',
    items: [
      { foodId: 'salmon', baseG: 150 },
      { foodId: 'quinoa', baseG: 150 },
      { foodId: 'zucchini', baseG: 150 },
      { foodId: 'olive_oil', baseG: 5 },
    ],
  },
  {
    id: 'tuna_sandwich',
    nameTr: 'Ton Balıklı Tam Buğday Sandviç',
    nameEn: 'Tuna Whole-Wheat Sandwich',
    type: 'lunch',
    goals: ['lose_fat', 'maintain'],
    items: [
      { foodId: 'tuna_canned', baseG: 100 },
      { foodId: 'bread_whole', baseG: 60 },
      { foodId: 'tomato', baseG: 80 },
      { foodId: 'cucumber', baseG: 50 },
      { foodId: 'avocado', baseG: 30 },
    ],
  },
  {
    id: 'lentil_soup_bread',
    nameTr: 'Mercimek Çorbası & Salata & Ekmek',
    nameEn: 'Lentil Soup + Salad + Bread',
    type: 'lunch',
    goals: ['lose_fat', 'maintain', 'general_fitness'],
    tagline: 'Klasik Türk öğle yemeği',
    items: [
      { foodId: 'lentils', baseG: 180 },
      { foodId: 'salad_greens', baseG: 100 },
      { foodId: 'bread_whole', baseG: 40 },
      { foodId: 'olive_oil', baseG: 5 },
      { foodId: 'carrot', baseG: 50 },
    ],
  },
  {
    id: 'beef_pasta',
    nameTr: 'Kıymalı Tam Buğday Makarna',
    nameEn: 'Ground Beef Whole-Wheat Pasta',
    type: 'dinner',
    goals: ['gain_muscle', 'maintain'],
    items: [
      { foodId: 'ground_beef', baseG: 150 },
      { foodId: 'pasta_whole', baseG: 200 },
      { foodId: 'tomato', baseG: 100 },
      { foodId: 'olive_oil', baseG: 5 },
    ],
  },
  {
    id: 'turkey_sweetpotato_broccoli',
    nameTr: 'Hindi Göğsü & Tatlı Patates & Brokoli',
    nameEn: 'Turkey + Sweet Potato + Broccoli',
    type: 'dinner',
    goals: ['lose_fat', 'maintain', 'gain_muscle', 'general_fitness'],
    items: [
      { foodId: 'turkey_breast', baseG: 150 },
      { foodId: 'sweet_potato', baseG: 200 },
      { foodId: 'broccoli', baseG: 150 },
      { foodId: 'olive_oil', baseG: 5 },
    ],
  },
  {
    id: 'chicken_couscous_veg',
    nameTr: 'Tavuk & Kuskus & Sebze',
    nameEn: 'Chicken + Couscous + Vegetables',
    type: 'lunch',
    goals: ['maintain', 'gain_muscle'],
    items: [
      { foodId: 'chicken_breast', baseG: 150 },
      { foodId: 'couscous', baseG: 180 },
      { foodId: 'pepper', baseG: 100 },
      { foodId: 'zucchini', baseG: 100 },
      { foodId: 'olive_oil', baseG: 5 },
    ],
  },
  {
    id: 'shrimp_bulgur_spinach',
    nameTr: 'Karides & Bulgur & Ispanak',
    nameEn: 'Shrimp + Bulgur + Spinach',
    type: 'dinner',
    goals: ['lose_fat', 'maintain'],
    items: [
      { foodId: 'shrimp', baseG: 150 },
      { foodId: 'bulgur', baseG: 150 },
      { foodId: 'spinach', baseG: 150 },
      { foodId: 'olive_oil', baseG: 5 },
    ],
  },
  {
    id: 'chickpea_rice_yogurt',
    nameTr: 'Nohut & Pirinç & Yoğurt',
    nameEn: 'Chickpea + Rice + Yogurt',
    type: 'lunch',
    goals: ['lose_fat', 'maintain', 'gain_muscle', 'general_fitness'],
    tagline: 'Vejetaryen dostu, protein kombinasyonu',
    items: [
      { foodId: 'chickpeas', baseG: 150 },
      { foodId: 'rice_white', baseG: 150 },
      { foodId: 'yogurt_plain', baseG: 100 },
      { foodId: 'olive_oil', baseG: 5 },
    ],
  },
  {
    id: 'mackerel_potato_salad',
    nameTr: 'Uskumru & Patates & Salata',
    nameEn: 'Mackerel + Potato + Salad',
    type: 'dinner',
    goals: ['maintain', 'general_fitness'],
    items: [
      { foodId: 'mackerel', baseG: 150 },
      { foodId: 'potato', baseG: 200 },
      { foodId: 'salad_greens', baseG: 100 },
      { foodId: 'olive_oil', baseG: 5 },
    ],
  },
  {
    id: 'beef_brown_rice_green_beans',
    nameTr: 'Dana Eti & Esmer Pirinç & Taze Fasulye',
    nameEn: 'Lean Beef + Brown Rice + Green Beans',
    type: 'lunch',
    goals: ['gain_muscle', 'maintain'],
    items: [
      { foodId: 'beef_lean', baseG: 150 },
      { foodId: 'rice_brown', baseG: 180 },
      { foodId: 'green_beans', baseG: 150 },
      { foodId: 'olive_oil', baseG: 5 },
    ],
  },
  {
    id: 'kidneybean_bulgur_salad',
    nameTr: 'Barbunya & Bulgur & Salata',
    nameEn: 'Kidney Beans + Bulgur + Salad',
    type: 'dinner',
    goals: ['lose_fat', 'general_fitness'],
    items: [
      { foodId: 'kidney_beans', baseG: 150 },
      { foodId: 'bulgur', baseG: 150 },
      { foodId: 'salad_greens', baseG: 100 },
      { foodId: 'tomato', baseG: 80 },
      { foodId: 'olive_oil', baseG: 5 },
    ],
  },
];

/* -------------------------------------------------------------------------- */
/* Registry                                                                   */
/* -------------------------------------------------------------------------- */

export const MEAL_TEMPLATES: readonly MealTemplate[] = [
  ...breakfastTemplates,
  ...snackTemplates,
  ...mainMealTemplates,
];

export function templatesFor(type: MealType, goal: Goal): MealTemplate[] {
  return MEAL_TEMPLATES.filter((t) => t.type === type && t.goals.includes(goal));
}
