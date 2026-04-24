/**
 * Writes the merged seed recipes as a flat JSON array to
 *   packages/recipe-db/src/recipes.json
 * and mirrors it to
 *   apps/mobile/assets/recipes.json
 * so Flutter can load it via rootBundle.
 *
 * Run with: pnpm --filter @fittrack/recipe-db build:json
 */
import { writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { recipes } from '../src/index.js';

const here = fileURLToPath(new URL('.', import.meta.url));

const jsonText = JSON.stringify(recipes, null, 2) + '\n';

const targets = [
  resolve(here, '../src/recipes.json'),
  resolve(here, '../../../apps/mobile/assets/recipes.json'),
];

for (const target of targets) {
  writeFileSync(target, jsonText, 'utf8');
  console.log(`wrote ${recipes.length} recipes → ${target}`);
}
