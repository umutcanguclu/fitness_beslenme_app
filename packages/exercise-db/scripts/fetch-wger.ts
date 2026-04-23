/**
 * Fetches exercises from wger.de public API and writes them to
 * packages/exercise-db/src/exercises.json in the shape required by
 * @fittrack/shared ExerciseSchema.
 *
 * Run with: pnpm --filter @fittrack/exercise-db sync
 *
 * This is a scaffold — the full mapping from wger categories/equipment to
 * our MuscleGroup and Equipment enums is intentionally minimal here; extend
 * the lookup tables below as you fold real wger data into the seed file.
 */
import { writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  type Equipment,
  type Exercise,
  type ExerciseType,
  type MuscleGroup,
} from '@fittrack/shared';

const WGER_BASE = 'https://wger.de/api/v2';
const LANGUAGE_EN = 2;
const PAGE_LIMIT = 200;

interface WgerExerciseInfo {
  id: number;
  category: { id: number; name: string };
  muscles: Array<{ id: number; name: string; name_en: string | null }>;
  equipment: Array<{ id: number; name: string }>;
  translations: Array<{ language: number; name: string; description: string }>;
}

const categoryToMuscleGroup: Record<string, MuscleGroup> = {
  Arms: 'biceps',
  Legs: 'quads',
  Abs: 'core',
  Chest: 'chest',
  Back: 'back',
  Shoulders: 'shoulders',
  Calves: 'calves',
  Cardio: 'cardio',
};

const equipmentLookup: Record<string, Equipment> = {
  Barbell: 'barbell',
  Dumbbell: 'dumbbell',
  'Gym mat': 'bodyweight',
  'Swiss Ball': 'other',
  'Pull-up bar': 'bodyweight',
  'none (bodyweight exercise)': 'bodyweight',
  Bench: 'other',
  'Incline bench': 'other',
  'Kettlebell': 'kettlebell',
  'SZ-Bar': 'barbell',
};

function pickType(category: string): ExerciseType {
  if (category === 'Cardio') return 'cardio';
  return 'strength';
}

async function fetchPage(offset: number): Promise<WgerExerciseInfo[]> {
  const url = `${WGER_BASE}/exerciseinfo/?language=${LANGUAGE_EN}&limit=${PAGE_LIMIT}&offset=${offset}`;
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`wger ${response.status}: ${await response.text()}`);
  }
  const data = (await response.json()) as { results: WgerExerciseInfo[] };
  return data.results;
}

function toExercise(raw: WgerExerciseInfo): Exercise | null {
  const translation = raw.translations.find((t) => t.language === LANGUAGE_EN);
  if (!translation) return null;

  const muscleGroup = categoryToMuscleGroup[raw.category.name];
  if (!muscleGroup) return null;

  const equipment = raw.equipment
    .map((e) => equipmentLookup[e.name])
    .filter((e): e is Equipment => Boolean(e));

  return {
    id: `wger-${raw.id}`,
    nameEn: translation.name,
    nameTr: translation.name,
    muscleGroup: [muscleGroup],
    equipment: equipment.length > 0 ? equipment : ['bodyweight'],
    type: pickType(raw.category.name),
  };
}

async function main(): Promise<void> {
  const results: Exercise[] = [];
  let offset = 0;
  while (offset < 1000) {
    const page = await fetchPage(offset);
    if (page.length === 0) break;
    for (const raw of page) {
      const parsed = toExercise(raw);
      if (parsed) results.push(parsed);
    }
    if (page.length < PAGE_LIMIT) break;
    offset += PAGE_LIMIT;
  }

  const outPath = resolve(
    fileURLToPath(new URL('../src/exercises.json', import.meta.url)),
  );
  writeFileSync(outPath, JSON.stringify(results, null, 2) + '\n', 'utf8');
  console.log(`Wrote ${results.length} exercises to ${outPath}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
