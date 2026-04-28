/**
 * Curated food catalog. All values are per 100 g (cooked/prepared where
 * relevant, matching USDA / Türkiye Beslenme Bilgi Sistemi conventions).
 * Categories drive meal-plan composition (breakfasts pull from `breakfast_*`,
 * lunches/dinners build around a `protein_*` + `carb_*` + `veg_*`, etc).
 */
export type FoodCategory =
  | 'breakfast_staple' // oats, eggs, yogurt
  | 'breakfast_topping' // peanut butter, honey, jam
  | 'protein_lean' // chicken breast, tuna, turkey
  | 'protein_fatty' // salmon, ground beef 80/20
  | 'protein_veg' // tofu, legumes
  | 'carb_grain' // rice, bulgur, pasta
  | 'carb_starchy' // potato, sweet potato
  | 'carb_bread' // whole wheat bread
  | 'vegetable'
  | 'fruit'
  | 'fat'
  | 'dairy'
  | 'nut_seed'
  | 'snack';

export interface Food {
  id: string;
  nameTr: string;
  nameEn: string;
  category: FoodCategory;
  kcal: number; // per 100 g
  proteinG: number;
  carbsG: number;
  fatG: number;
  /** Typical single serving in grams, used when portioning meals. */
  servingG: number;
}

export const FOODS: Food[] = [
  // ── Breakfast staples
  { id: 'oats', nameTr: 'Yulaf (kuru)', nameEn: 'Oats (dry)', category: 'breakfast_staple', kcal: 389, proteinG: 16.9, carbsG: 66.3, fatG: 6.9, servingG: 50 },
  { id: 'egg_whole', nameTr: 'Yumurta', nameEn: 'Whole egg', category: 'breakfast_staple', kcal: 155, proteinG: 13, carbsG: 1.1, fatG: 11, servingG: 100 },
  { id: 'egg_white', nameTr: 'Yumurta beyazı', nameEn: 'Egg white', category: 'breakfast_staple', kcal: 52, proteinG: 11, carbsG: 0.7, fatG: 0.2, servingG: 100 },
  { id: 'yogurt_plain', nameTr: 'Yoğurt (sade, tam yağlı)', nameEn: 'Plain yogurt', category: 'dairy', kcal: 61, proteinG: 3.5, carbsG: 4.7, fatG: 3.3, servingG: 200 },
  { id: 'yogurt_greek', nameTr: 'Yoğurt (süzme)', nameEn: 'Greek yogurt', category: 'dairy', kcal: 97, proteinG: 9, carbsG: 3.6, fatG: 5, servingG: 150 },
  { id: 'yogurt_nonfat', nameTr: 'Yoğurt (yağsız)', nameEn: 'Nonfat yogurt', category: 'dairy', kcal: 59, proteinG: 10, carbsG: 3.6, fatG: 0.4, servingG: 200 },
  { id: 'cottage_cheese', nameTr: 'Lor peyniri', nameEn: 'Cottage cheese', category: 'dairy', kcal: 98, proteinG: 11, carbsG: 3.4, fatG: 4.3, servingG: 100 },
  { id: 'milk_whole', nameTr: 'Süt (tam yağlı)', nameEn: 'Whole milk', category: 'dairy', kcal: 61, proteinG: 3.2, carbsG: 4.8, fatG: 3.3, servingG: 250 },
  { id: 'milk_skim', nameTr: 'Süt (yarım yağlı)', nameEn: 'Low-fat milk', category: 'dairy', kcal: 50, proteinG: 3.4, carbsG: 4.8, fatG: 1.5, servingG: 250 },
  { id: 'cheese_white', nameTr: 'Beyaz peynir', nameEn: 'Feta/white cheese', category: 'dairy', kcal: 264, proteinG: 14, carbsG: 4, fatG: 21, servingG: 40 },
  { id: 'cheese_kasar', nameTr: 'Kaşar peyniri', nameEn: 'Kasar cheese', category: 'dairy', kcal: 365, proteinG: 25, carbsG: 2, fatG: 29, servingG: 30 },

  // ── Breakfast toppings
  { id: 'peanut_butter', nameTr: 'Fıstık ezmesi', nameEn: 'Peanut butter', category: 'breakfast_topping', kcal: 588, proteinG: 25, carbsG: 20, fatG: 50, servingG: 20 },
  { id: 'honey', nameTr: 'Bal', nameEn: 'Honey', category: 'breakfast_topping', kcal: 304, proteinG: 0.3, carbsG: 82, fatG: 0, servingG: 15 },
  { id: 'jam', nameTr: 'Reçel', nameEn: 'Jam', category: 'breakfast_topping', kcal: 278, proteinG: 0.4, carbsG: 69, fatG: 0.1, servingG: 15 },
  { id: 'tahini', nameTr: 'Tahin', nameEn: 'Tahini', category: 'breakfast_topping', kcal: 595, proteinG: 17, carbsG: 21, fatG: 53, servingG: 15 },
  { id: 'olives_green', nameTr: 'Yeşil zeytin', nameEn: 'Green olives', category: 'fat', kcal: 145, proteinG: 1, carbsG: 4, fatG: 15, servingG: 30 },
  { id: 'olives_black', nameTr: 'Siyah zeytin', nameEn: 'Black olives', category: 'fat', kcal: 115, proteinG: 0.8, carbsG: 6, fatG: 11, servingG: 30 },

  // ── Lean proteins
  { id: 'chicken_breast', nameTr: 'Tavuk göğsü (pişmiş)', nameEn: 'Chicken breast', category: 'protein_lean', kcal: 165, proteinG: 31, carbsG: 0, fatG: 3.6, servingG: 150 },
  { id: 'turkey_breast', nameTr: 'Hindi göğsü (pişmiş)', nameEn: 'Turkey breast', category: 'protein_lean', kcal: 135, proteinG: 30, carbsG: 0, fatG: 1, servingG: 150 },
  { id: 'tuna_canned', nameTr: 'Ton balığı (konserve)', nameEn: 'Tuna (canned)', category: 'protein_lean', kcal: 116, proteinG: 26, carbsG: 0, fatG: 1, servingG: 120 },
  { id: 'beef_lean', nameTr: 'Dana (yağsız, pişmiş)', nameEn: 'Lean beef', category: 'protein_lean', kcal: 217, proteinG: 26, carbsG: 0, fatG: 12, servingG: 150 },
  { id: 'shrimp', nameTr: 'Karides', nameEn: 'Shrimp', category: 'protein_lean', kcal: 99, proteinG: 24, carbsG: 0.2, fatG: 0.3, servingG: 120 },

  // ── Fatty proteins
  { id: 'salmon', nameTr: 'Somon (pişmiş)', nameEn: 'Salmon', category: 'protein_fatty', kcal: 208, proteinG: 20, carbsG: 0, fatG: 13, servingG: 150 },
  { id: 'sardines', nameTr: 'Sardalya', nameEn: 'Sardines', category: 'protein_fatty', kcal: 208, proteinG: 25, carbsG: 0, fatG: 11, servingG: 100 },
  { id: 'ground_beef', nameTr: 'Kıyma (orta yağlı)', nameEn: 'Ground beef', category: 'protein_fatty', kcal: 250, proteinG: 26, carbsG: 0, fatG: 17, servingG: 150 },
  { id: 'mackerel', nameTr: 'Uskumru', nameEn: 'Mackerel', category: 'protein_fatty', kcal: 205, proteinG: 19, carbsG: 0, fatG: 14, servingG: 150 },

  // ── Plant proteins
  { id: 'lentils', nameTr: 'Mercimek (pişmiş)', nameEn: 'Lentils', category: 'protein_veg', kcal: 116, proteinG: 9, carbsG: 20, fatG: 0.4, servingG: 150 },
  { id: 'chickpeas', nameTr: 'Nohut (pişmiş)', nameEn: 'Chickpeas', category: 'protein_veg', kcal: 164, proteinG: 9, carbsG: 27, fatG: 2.6, servingG: 150 },
  { id: 'kidney_beans', nameTr: 'Barbunya (pişmiş)', nameEn: 'Kidney beans', category: 'protein_veg', kcal: 127, proteinG: 9, carbsG: 22, fatG: 0.5, servingG: 150 },
  { id: 'white_beans', nameTr: 'Kuru fasulye (pişmiş)', nameEn: 'White beans', category: 'protein_veg', kcal: 139, proteinG: 9, carbsG: 25, fatG: 0.4, servingG: 150 },
  { id: 'tofu', nameTr: 'Tofu', nameEn: 'Tofu', category: 'protein_veg', kcal: 144, proteinG: 15, carbsG: 3, fatG: 9, servingG: 150 },

  // ── Grains / starchy carbs
  { id: 'rice_white', nameTr: 'Pirinç pilavı', nameEn: 'White rice (cooked)', category: 'carb_grain', kcal: 130, proteinG: 2.7, carbsG: 28, fatG: 0.3, servingG: 150 },
  { id: 'rice_brown', nameTr: 'Esmer pirinç (pişmiş)', nameEn: 'Brown rice', category: 'carb_grain', kcal: 123, proteinG: 2.7, carbsG: 26, fatG: 1, servingG: 150 },
  { id: 'bulgur', nameTr: 'Bulgur pilavı', nameEn: 'Bulgur (cooked)', category: 'carb_grain', kcal: 83, proteinG: 3, carbsG: 19, fatG: 0.2, servingG: 200 },
  { id: 'quinoa', nameTr: 'Kinoa (pişmiş)', nameEn: 'Quinoa', category: 'carb_grain', kcal: 120, proteinG: 4.4, carbsG: 21, fatG: 1.9, servingG: 150 },
  { id: 'pasta_whole', nameTr: 'Tam buğday makarna (pişmiş)', nameEn: 'Whole wheat pasta', category: 'carb_grain', kcal: 124, proteinG: 5, carbsG: 27, fatG: 1.1, servingG: 150 },
  { id: 'couscous', nameTr: 'Kuskus (pişmiş)', nameEn: 'Couscous', category: 'carb_grain', kcal: 112, proteinG: 3.8, carbsG: 23, fatG: 0.2, servingG: 150 },

  // ── Starchy
  { id: 'potato', nameTr: 'Patates (haşlanmış)', nameEn: 'Boiled potato', category: 'carb_starchy', kcal: 87, proteinG: 1.9, carbsG: 20, fatG: 0.1, servingG: 200 },
  { id: 'sweet_potato', nameTr: 'Tatlı patates (pişmiş)', nameEn: 'Sweet potato', category: 'carb_starchy', kcal: 86, proteinG: 1.6, carbsG: 20, fatG: 0.1, servingG: 200 },

  // ── Breads
  { id: 'bread_whole', nameTr: 'Tam buğday ekmeği', nameEn: 'Whole wheat bread', category: 'carb_bread', kcal: 247, proteinG: 13, carbsG: 41, fatG: 3.4, servingG: 50 },
  { id: 'bread_white', nameTr: 'Beyaz ekmek', nameEn: 'White bread', category: 'carb_bread', kcal: 265, proteinG: 9, carbsG: 49, fatG: 3.2, servingG: 50 },
  { id: 'simit', nameTr: 'Simit', nameEn: 'Simit', category: 'carb_bread', kcal: 323, proteinG: 9, carbsG: 60, fatG: 5, servingG: 80 },

  // ── Vegetables
  { id: 'broccoli', nameTr: 'Brokoli (pişmiş)', nameEn: 'Broccoli', category: 'vegetable', kcal: 34, proteinG: 2.8, carbsG: 7, fatG: 0.4, servingG: 200 },
  { id: 'spinach', nameTr: 'Ispanak (pişmiş)', nameEn: 'Spinach', category: 'vegetable', kcal: 23, proteinG: 2.9, carbsG: 3.6, fatG: 0.4, servingG: 200 },
  { id: 'green_beans', nameTr: 'Taze fasulye', nameEn: 'Green beans', category: 'vegetable', kcal: 31, proteinG: 1.8, carbsG: 7, fatG: 0.2, servingG: 200 },
  { id: 'carrot', nameTr: 'Havuç', nameEn: 'Carrot', category: 'vegetable', kcal: 41, proteinG: 0.9, carbsG: 10, fatG: 0.2, servingG: 150 },
  { id: 'tomato', nameTr: 'Domates', nameEn: 'Tomato', category: 'vegetable', kcal: 18, proteinG: 0.9, carbsG: 3.9, fatG: 0.2, servingG: 150 },
  { id: 'cucumber', nameTr: 'Salatalık', nameEn: 'Cucumber', category: 'vegetable', kcal: 15, proteinG: 0.7, carbsG: 3.6, fatG: 0.1, servingG: 150 },
  { id: 'pepper', nameTr: 'Biber', nameEn: 'Bell pepper', category: 'vegetable', kcal: 31, proteinG: 1, carbsG: 6, fatG: 0.3, servingG: 150 },
  { id: 'eggplant', nameTr: 'Patlıcan (pişmiş)', nameEn: 'Eggplant', category: 'vegetable', kcal: 35, proteinG: 0.8, carbsG: 9, fatG: 0.2, servingG: 200 },
  { id: 'zucchini', nameTr: 'Kabak (pişmiş)', nameEn: 'Zucchini', category: 'vegetable', kcal: 17, proteinG: 1.2, carbsG: 3.1, fatG: 0.3, servingG: 200 },
  { id: 'salad_greens', nameTr: 'Yeşil salata', nameEn: 'Mixed salad', category: 'vegetable', kcal: 17, proteinG: 1.4, carbsG: 3, fatG: 0.2, servingG: 100 },

  // ── Fruits
  { id: 'apple', nameTr: 'Elma', nameEn: 'Apple', category: 'fruit', kcal: 52, proteinG: 0.3, carbsG: 14, fatG: 0.2, servingG: 180 },
  { id: 'banana', nameTr: 'Muz', nameEn: 'Banana', category: 'fruit', kcal: 89, proteinG: 1.1, carbsG: 22.8, fatG: 0.3, servingG: 120 },
  { id: 'orange', nameTr: 'Portakal', nameEn: 'Orange', category: 'fruit', kcal: 47, proteinG: 0.9, carbsG: 12, fatG: 0.1, servingG: 150 },
  { id: 'strawberry', nameTr: 'Çilek', nameEn: 'Strawberries', category: 'fruit', kcal: 32, proteinG: 0.7, carbsG: 7.7, fatG: 0.3, servingG: 150 },
  { id: 'blueberry', nameTr: 'Yaban mersini', nameEn: 'Blueberries', category: 'fruit', kcal: 57, proteinG: 0.7, carbsG: 14, fatG: 0.3, servingG: 100 },
  { id: 'pear', nameTr: 'Armut', nameEn: 'Pear', category: 'fruit', kcal: 57, proteinG: 0.4, carbsG: 15, fatG: 0.1, servingG: 180 },
  { id: 'grapes', nameTr: 'Üzüm', nameEn: 'Grapes', category: 'fruit', kcal: 69, proteinG: 0.7, carbsG: 18, fatG: 0.2, servingG: 120 },
  { id: 'watermelon', nameTr: 'Karpuz', nameEn: 'Watermelon', category: 'fruit', kcal: 30, proteinG: 0.6, carbsG: 8, fatG: 0.2, servingG: 200 },
  { id: 'fig_dry', nameTr: 'Kuru incir', nameEn: 'Dried figs', category: 'fruit', kcal: 249, proteinG: 3.3, carbsG: 64, fatG: 0.9, servingG: 30 },

  // ── Fats / oils
  { id: 'olive_oil', nameTr: 'Zeytinyağı', nameEn: 'Olive oil', category: 'fat', kcal: 884, proteinG: 0, carbsG: 0, fatG: 100, servingG: 10 },
  { id: 'avocado', nameTr: 'Avokado', nameEn: 'Avocado', category: 'fat', kcal: 160, proteinG: 2, carbsG: 9, fatG: 15, servingG: 100 },
  { id: 'butter', nameTr: 'Tereyağı', nameEn: 'Butter', category: 'fat', kcal: 717, proteinG: 0.9, carbsG: 0.1, fatG: 81, servingG: 10 },

  // ── Nuts/seeds
  { id: 'walnuts', nameTr: 'Ceviz', nameEn: 'Walnuts', category: 'nut_seed', kcal: 654, proteinG: 15, carbsG: 14, fatG: 65, servingG: 30 },
  { id: 'almonds', nameTr: 'Badem', nameEn: 'Almonds', category: 'nut_seed', kcal: 579, proteinG: 21, carbsG: 22, fatG: 50, servingG: 30 },
  { id: 'hazelnuts', nameTr: 'Fındık', nameEn: 'Hazelnuts', category: 'nut_seed', kcal: 628, proteinG: 15, carbsG: 17, fatG: 61, servingG: 30 },
  { id: 'chia', nameTr: 'Chia tohumu', nameEn: 'Chia seeds', category: 'nut_seed', kcal: 486, proteinG: 17, carbsG: 42, fatG: 31, servingG: 15 },

  // ── Snack-ish
  { id: 'dark_chocolate', nameTr: 'Bitter çikolata (%70)', nameEn: 'Dark chocolate 70%', category: 'snack', kcal: 598, proteinG: 7.8, carbsG: 46, fatG: 43, servingG: 20 },
  { id: 'rice_cake', nameTr: 'Pirinç keki', nameEn: 'Rice cake', category: 'snack', kcal: 387, proteinG: 8, carbsG: 82, fatG: 2.8, servingG: 15 },
];

export const FOOD_BY_ID: ReadonlyMap<string, Food> = new Map(
  FOODS.map((f) => [f.id, f]),
);
