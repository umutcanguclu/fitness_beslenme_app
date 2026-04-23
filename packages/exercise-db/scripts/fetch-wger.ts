/**
 * Fetches exercises from wger.de public API and writes them to
 * packages/exercise-db/src/exercises.json in the shape required by
 * @fittrack/shared ExerciseSchema.
 *
 * Run with: pnpm --filter @fittrack/exercise-db sync
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
  muscles: Array<{ id: number; name: string; name_en: string | null; is_front: boolean }>;
  muscles_secondary: Array<{ id: number; name: string; name_en: string | null }>;
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

// Individual muscle names (wger's `muscles` array) → our MuscleGroup.
const muscleNameToGroup: Record<string, MuscleGroup> = {
  'Biceps brachii': 'biceps',
  'Triceps brachii': 'triceps',
  'Anterior deltoid': 'shoulders',
  'Pectoralis major': 'chest',
  'Latissimus dorsi': 'back',
  Trapezius: 'back',
  'Quadriceps femoris': 'quads',
  'Biceps femoris': 'hamstrings',
  Gluteus: 'glutes',
  'Gluteus maximus': 'glutes',
  'Gastrocnemius': 'calves',
  Soleus: 'calves',
  'Serratus anterior': 'core',
  'Rectus abdominis': 'core',
  'Obliquus externus abdominis': 'core',
  'Brachialis': 'biceps',
  'Brachioradialis': 'forearms',
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
  Kettlebell: 'kettlebell',
  'SZ-Bar': 'barbell',
  'Resistance band': 'resistance_band',
  Cable: 'cable',
};

function pickType(category: string): ExerciseType {
  if (category === 'Cardio') return 'cardio';
  return 'strength';
}

function pickMuscleGroups(raw: WgerExerciseInfo): MuscleGroup[] {
  const groups = new Set<MuscleGroup>();
  for (const m of raw.muscles) {
    const mapped = muscleNameToGroup[m.name_en ?? m.name];
    if (mapped) groups.add(mapped);
  }
  const fallback = categoryToMuscleGroup[raw.category.name];
  if (fallback && groups.size === 0) groups.add(fallback);
  return [...groups];
}

function stripHtml(input: string): string {
  return input
    .replace(/<br\s*\/?>(?:\s)?/gi, '\n')
    .replace(/<\/(p|li)>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/\s+\n/g, '\n')
    .trim();
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
  if (!translation || !translation.name.trim()) return null;

  const muscleGroup = pickMuscleGroups(raw);
  if (muscleGroup.length === 0) return null;

  const equipment = raw.equipment
    .map((e) => equipmentLookup[e.name])
    .filter((e): e is Equipment => Boolean(e));

  const instructions = translation.description
    ? stripHtml(translation.description)
    : null;

  return {
    id: `wger-${raw.id}`,
    nameEn: translation.name.trim(),
    nameTr: translation.name.trim(),
    muscleGroup,
    equipment: equipment.length > 0 ? equipment : ['bodyweight'],
    type: pickType(raw.category.name),
    instructionsEn: instructions,
    instructionsTr: null,
  };
}

async function main(): Promise<void> {
  const results: Exercise[] = [];
  const seenIds = new Set<string>();
  let offset = 0;
  while (offset < 2000) {
    process.stdout.write(`Fetching offset=${offset}... `);
    const page = await fetchPage(offset);
    if (page.length === 0) break;
    let added = 0;
    for (const raw of page) {
      const parsed = toExercise(raw);
      if (!parsed || seenIds.has(parsed.id)) continue;
      seenIds.add(parsed.id);
      results.push(parsed);
      added++;
    }
    process.stdout.write(`${added} added (running total: ${results.length})\n`);
    if (page.length < PAGE_LIMIT) break;
    offset += PAGE_LIMIT;
  }

  // Deterministic ordering so diffs are stable.
  results.sort((a, b) => a.id.localeCompare(b.id));

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
