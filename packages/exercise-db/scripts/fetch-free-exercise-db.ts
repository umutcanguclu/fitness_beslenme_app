/**
 * Fetches exercises from the free-exercise-db dataset (yuhonas/free-exercise-db)
 * and writes them to packages/exercise-db/src/exercises.json in the shape
 * required by @fittrack/shared ExerciseSchema.
 *
 * Each exercise ships with 2 JPEG frames showing start/end position; we store
 * both as absolute raw.githubusercontent.com URLs in the `images` array so the
 * mobile app can render them directly.
 *
 * Run with: pnpm --filter @fittrack/exercise-db sync
 */
import { writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  type Equipment,
  type Exercise,
  type ExerciseLevel,
  type ExerciseMechanic,
  type ExerciseType,
  type MuscleGroup,
} from '@fittrack/shared';

const DATA_URL =
  'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json';
const IMAGE_BASE = 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/';

interface FedExercise {
  id: string;
  name: string;
  force: 'pull' | 'push' | 'static' | null;
  level: 'beginner' | 'intermediate' | 'expert';
  mechanic: 'compound' | 'isolation' | null;
  equipment: string | null;
  primaryMuscles: string[];
  secondaryMuscles: string[];
  instructions: string[];
  category: string;
  images: string[];
}

const muscleMap: Record<string, MuscleGroup> = {
  abdominals: 'core',
  abductors: 'glutes',
  adductors: 'quads',
  biceps: 'biceps',
  calves: 'calves',
  chest: 'chest',
  forearms: 'forearms',
  glutes: 'glutes',
  hamstrings: 'hamstrings',
  lats: 'back',
  'lower back': 'back',
  'middle back': 'back',
  neck: 'shoulders',
  quadriceps: 'quads',
  shoulders: 'shoulders',
  traps: 'back',
  triceps: 'triceps',
};

const equipmentMap: Record<string, Equipment> = {
  'body only': 'bodyweight',
  barbell: 'barbell',
  dumbbell: 'dumbbell',
  machine: 'machine',
  cable: 'cable',
  kettlebells: 'kettlebell',
  bands: 'resistance_band',
  'e-z curl bar': 'barbell',
  'medicine ball': 'other',
  'exercise ball': 'other',
  'foam roll': 'other',
  other: 'other',
};

const categoryToType: Record<string, ExerciseType> = {
  strength: 'strength',
  stretching: 'stretch',
  plyometrics: 'plyometric',
  cardio: 'cardio',
  powerlifting: 'powerlifting',
  'olympic weightlifting': 'olympic',
  strongman: 'strongman',
};

function mapMuscles(names: string[]): MuscleGroup[] {
  const set = new Set<MuscleGroup>();
  for (const n of names) {
    const m = muscleMap[n];
    if (m) set.add(m);
  }
  return [...set];
}

function mapEquipment(name: string | null): Equipment[] {
  if (name === null || name === undefined) return ['bodyweight'];
  const eq = equipmentMap[name];
  return eq ? [eq] : ['other'];
}

function toExercise(raw: FedExercise): Exercise | null {
  const muscleGroup = mapMuscles(raw.primaryMuscles);
  if (muscleGroup.length === 0) return null;

  const images = raw.images.map((rel) => `${IMAGE_BASE}${rel}`);
  const instructions = raw.instructions.join('\n\n').trim() || null;
  const type = categoryToType[raw.category] ?? 'strength';

  return {
    id: `fed-${raw.id}`,
    nameEn: raw.name.trim(),
    nameTr: raw.name.trim(),
    muscleGroup,
    equipment: mapEquipment(raw.equipment),
    type,
    level: raw.level as ExerciseLevel,
    mechanic: (raw.mechanic ?? null) as ExerciseMechanic | null,
    images,
    mediaUrl: images[0] ?? null,
    instructionsEn: instructions,
    instructionsTr: null,
  };
}

async function main(): Promise<void> {
  process.stdout.write(`Fetching ${DATA_URL}... `);
  const response = await fetch(DATA_URL);
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${await response.text()}`);
  }
  const raw = (await response.json()) as FedExercise[];
  process.stdout.write(`${raw.length} entries\n`);

  const results: Exercise[] = [];
  let skipped = 0;
  for (const r of raw) {
    const mapped = toExercise(r);
    if (mapped) {
      results.push(mapped);
    } else {
      skipped++;
    }
  }
  results.sort((a, b) => a.id.localeCompare(b.id));

  const outPath = resolve(
    fileURLToPath(new URL('../src/exercises.json', import.meta.url)),
  );
  writeFileSync(outPath, JSON.stringify(results, null, 2) + '\n', 'utf8');
  console.log(`Wrote ${results.length} exercises (skipped ${skipped}) to ${outPath}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
