import {
  RecipeSchema,
  type Recipe,
  type RecipeCategory,
} from '@fittrack/shared';

import { soups } from './seed/soups.js';
import { meatMains } from './seed/meat-mains.js';
import { vegMains } from './seed/veg-mains.js';
import { rice } from './seed/rice.js';
import { pasta } from './seed/pasta.js';
import { breakfast } from './seed/breakfast.js';
import { pastry } from './seed/pastry.js';
import { salads } from './seed/salads.js';
import { desserts } from './seed/desserts.js';
import { drinks } from './seed/drinks.js';
import { meze } from './seed/meze.js';
import { student } from './seed/student.js';

const seeds: Recipe[] = [
  ...soups,
  ...meatMains,
  ...vegMains,
  ...rice,
  ...pasta,
  ...breakfast,
  ...pastry,
  ...salads,
  ...desserts,
  ...drinks,
  ...meze,
  ...student,
];

export const recipes: readonly Recipe[] = Object.freeze(
  seeds.map((r) => RecipeSchema.parse(r)),
);

export const recipeById: ReadonlyMap<string, Recipe> = new Map(
  recipes.map((recipe) => [recipe.id, recipe]),
);

export function getRecipeById(id: string): Recipe | undefined {
  return recipeById.get(id);
}

export function recipesByCategory(category: RecipeCategory): Recipe[] {
  return recipes.filter((r) => r.category === category);
}

export function recipesByTag(tag: string): Recipe[] {
  return recipes.filter((r) => r.tags.includes(tag));
}

export type { Recipe, RecipeCategory } from '@fittrack/shared';
