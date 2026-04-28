import type {
  Equipment,
  Goal,
  MuscleGroup,
  ProgramEquipment,
  ProgramGenerateInput,
  ProgramLevel,
} from '@fittrack/shared';
import { AppError } from '../lib/errors.js';
import { prisma } from '../lib/prisma.js';
import {
  CURATED_BY_ID,
  CURATED_EXERCISES,
  type CuratedExercise,
  type PrimaryMuscle,
  type Tier,
} from '../data/curated-exercises.js';
import {
  SESSION_TEMPLATES,
  SPLITS,
  type SessionSlot,
  type Split,
} from '../data/session-templates.js';

/* -------------------------------------------------------------------------- */
/* Constants                                                                  */
/* -------------------------------------------------------------------------- */

const EQUIPMENT_ALLOWLIST: Record<ProgramEquipment, Set<Equipment>> = {
  bodyweight_only: new Set(['bodyweight']),
  dumbbell_only: new Set(['bodyweight', 'dumbbell', 'kettlebell']),
  full_gym: new Set([
    'bodyweight',
    'dumbbell',
    'barbell',
    'machine',
    'cable',
    'kettlebell',
    'resistance_band',
    'other',
  ]),
};

const LEVEL_ORDER: Record<ProgramLevel, number> = {
  beginner: 0,
  intermediate: 1,
  advanced: 2,
};

const EX_LEVEL_ORDER = { beginner: 0, intermediate: 1, expert: 2 } as const;

/**
 * User-facing wizard muscle groups → the internal primary movers that our
 * curated catalog keys on. Selecting "back" in the wizard activates both
 * lat- and mid-back-focused slots.
 */
const MUSCLE_GROUP_TO_PRIMARY: Record<MuscleGroup, PrimaryMuscle[]> = {
  chest: ['chest'],
  back: ['back_lats', 'back_upper'],
  shoulders: ['delts_front', 'delts_side', 'delts_rear'],
  biceps: ['biceps'],
  triceps: ['triceps'],
  forearms: ['forearms'],
  core: ['core'],
  quads: ['quads'],
  hamstrings: ['hamstrings'],
  glutes: ['glutes'],
  calves: ['calves'],
  cardio: [],
  full_body: [
    'chest',
    'back_lats',
    'back_upper',
    'delts_front',
    'delts_side',
    'quads',
    'hamstrings',
    'glutes',
    'core',
  ],
};

/* -------------------------------------------------------------------------- */
/* Selection helpers                                                          */
/* -------------------------------------------------------------------------- */

function levelOk(level: ProgramLevel, exLevel: CuratedExercise['level']): boolean {
  return EX_LEVEL_ORDER[exLevel] <= LEVEL_ORDER[level];
}

function equipmentOk(allowed: Set<Equipment>, ex: CuratedExercise): boolean {
  return ex.equipment.some((e) => allowed.has(e));
}

/**
 * Try the slot's preferred list in order, picking the first exercise that
 * satisfies every hard constraint *and* hasn't been used yet this program.
 * Falls back to any pattern-matching curated entry when the preferred chain
 * is exhausted.
 */
function pickForSlot(
  slot: SessionSlot,
  level: ProgramLevel,
  allowedEquipment: Set<Equipment>,
  globalUsed: Set<string>,
): CuratedExercise | null {
  const viable = (ex: CuratedExercise | undefined) =>
    !!ex &&
    levelOk(level, ex.level) &&
    equipmentOk(allowedEquipment, ex) &&
    !globalUsed.has(ex.id);

  // Preferred chain — coach's top pick first.
  for (const id of slot.preferred) {
    const ex = CURATED_BY_ID.get(id);
    if (viable(ex)) return ex!;
  }

  // Fallback: any curated exercise matching the slot's pattern.
  const fallbackPool = CURATED_EXERCISES.filter(
    (ex) =>
      ex.pattern === slot.fallbackPattern &&
      levelOk(level, ex.level) &&
      equipmentOk(allowedEquipment, ex) &&
      !globalUsed.has(ex.id),
  );
  if (fallbackPool.length > 0) return fallbackPool[0]!;

  // Last-resort: relax the "no reuse" rule for tiny pools (e.g. bodyweight
  // pull has very few options). Still honor equipment + level.
  const relaxed = CURATED_EXERCISES.filter(
    (ex) =>
      ex.pattern === slot.fallbackPattern &&
      levelOk(level, ex.level) &&
      equipmentOk(allowedEquipment, ex),
  );
  return relaxed[0] ?? null;
}

function buildDay(
  templateKey: string,
  exerciseCount: number,
  level: ProgramLevel,
  allowedEquipment: Set<Equipment>,
  requestedPrimaries: Set<PrimaryMuscle>,
  globalUsed: Set<string>,
): { name: string; picks: { slot: SessionSlot; ex: CuratedExercise }[] } {
  const template = SESSION_TEMPLATES[templateKey] ?? SESSION_TEMPLATES.full_a;
  if (!template) {
    throw new Error(`Unknown session template: ${templateKey}`);
  }
  const picks: { slot: SessionSlot; ex: CuratedExercise }[] = [];

  for (const slot of template.slots) {
    if (picks.length >= exerciseCount) break;
    // Skip optional slots for muscles the user didn't select.
    if (!slot.required && !requestedPrimaries.has(slot.muscle)) continue;
    const ex = pickForSlot(slot, level, allowedEquipment, globalUsed);
    if (ex) {
      picks.push({ slot, ex });
      globalUsed.add(ex.id);
    }
  }

  // If exerciseCount is higher than the template's slots, fill with additional
  // isolation work for requested muscles (or core if none requested).
  if (picks.length < exerciseCount) {
    for (const slot of template.slots) {
      if (picks.length >= exerciseCount) break;
      const ex = pickForSlot(slot, level, allowedEquipment, globalUsed);
      if (ex && !picks.some((p) => p.ex.id === ex.id)) {
        picks.push({ slot, ex });
        globalUsed.add(ex.id);
      }
    }
  }

  return { name: template.name, picks };
}

/* -------------------------------------------------------------------------- */
/* Rep scheme                                                                 */
/* -------------------------------------------------------------------------- */

interface RepScheme {
  sets: number;
  reps: number;
  restSec: number;
}

function repSchemeFor(goal: Goal, tier: Tier): RepScheme {
  switch (goal) {
    case 'lose_fat':
      // Circuit-ish: moderate loads, short rest, higher reps.
      return tier === 'primary'
        ? { sets: 3, reps: 12, restSec: 60 }
        : { sets: 3, reps: 15, restSec: 45 };
    case 'gain_muscle':
      // Hypertrophy: progressive overload per tier.
      if (tier === 'primary') return { sets: 4, reps: 8, restSec: 90 };
      if (tier === 'secondary') return { sets: 3, reps: 10, restSec: 75 };
      return { sets: 3, reps: 12, restSec: 60 };
    case 'maintain':
      return tier === 'primary'
        ? { sets: 3, reps: 8, restSec: 75 }
        : { sets: 3, reps: 12, restSec: 60 };
    case 'general_fitness':
    default:
      if (tier === 'primary') return { sets: 3, reps: 10, restSec: 75 };
      if (tier === 'secondary') return { sets: 3, reps: 12, restSec: 60 };
      return { sets: 3, reps: 12, restSec: 60 };
  }
}

function exerciseCountPerDay(sessionMinutes: number): number {
  if (sessionMinutes <= 30) return 4;
  if (sessionMinutes <= 45) return 5;
  if (sessionMinutes <= 60) return 6;
  if (sessionMinutes <= 90) return 8;
  return 9;
}

/* -------------------------------------------------------------------------- */
/* Split selection                                                            */
/* -------------------------------------------------------------------------- */

function pickSplit(
  daysPerWeek: number,
  requestedPrimaries: Set<PrimaryMuscle>,
): Split {
  const options = SPLITS[daysPerWeek] ?? SPLITS[3];
  if (!options || options.length === 0) {
    throw new Error(`No split defined for ${daysPerWeek} days/week`);
  }
  const first = options[0]!;
  if (options.length === 1) return first;

  // Pick the split whose union of template-required muscles best matches
  // what the user asked for. Full-body splits win when user requests many
  // muscle groups but few days; split routines win when many days exist.
  let bestScore = -1;
  let best: Split = first;
  for (const opt of options) {
    const hit = new Set<PrimaryMuscle>();
    for (const dayKey of opt.days) {
      for (const slot of SESSION_TEMPLATES[dayKey]?.slots ?? []) {
        hit.add(slot.muscle);
      }
    }
    let score = 0;
    for (const m of requestedPrimaries) if (hit.has(m)) score++;
    if (score > bestScore) {
      bestScore = score;
      best = opt;
    }
  }
  return best;
}

/* -------------------------------------------------------------------------- */
/* Service                                                                    */
/* -------------------------------------------------------------------------- */

export interface GeneratedProgramDay {
  dayIndex: number;
  name: string;
  exercises: Array<{
    exerciseId: string;
    order: number;
    targetSets: number;
    targetReps: number | null;
    targetTimeSeconds: number | null;
    restSeconds: number;
  }>;
}

export class ProgramService {
  async generate(userId: string, input: ProgramGenerateInput) {
    const requestedPrimaries = new Set<PrimaryMuscle>();
    for (const m of input.targetMuscles) {
      for (const p of MUSCLE_GROUP_TO_PRIMARY[m] ?? []) requestedPrimaries.add(p);
    }

    const split = pickSplit(input.daysPerWeek, requestedPrimaries);
    const count = exerciseCountPerDay(input.sessionMinutes);
    const allowedEquipment = EQUIPMENT_ALLOWLIST[input.equipment];

    const globalUsed = new Set<string>();
    const days: GeneratedProgramDay[] = split.days.map((templateKey, idx) => {
      const { name, picks } = buildDay(
        templateKey,
        count,
        input.level,
        allowedEquipment,
        requestedPrimaries,
        globalUsed,
      );
      return {
        dayIndex: idx,
        name,
        exercises: picks.map(({ slot, ex }, order) => {
          const scheme = repSchemeFor(input.goal, slot.tier);
          return {
            exerciseId: ex.id,
            order,
            targetSets: scheme.sets,
            targetReps: scheme.reps,
            targetTimeSeconds: null,
            restSeconds: scheme.restSec,
          };
        }),
      };
    });

    await prisma.program.updateMany({
      where: { userId, active: true },
      data: { active: false },
    });

    return prisma.program.create({
      data: {
        userId,
        name: input.name ?? `${split.label} · ${labelForGoal(input.goal)}`,
        goal: input.goal,
        level: input.level,
        equipment: input.equipment,
        daysPerWeek: input.daysPerWeek,
        sessionMinutes: input.sessionMinutes,
        targetMuscles: input.targetMuscles,
        active: true,
        days: {
          create: days.map((d) => ({
            dayIndex: d.dayIndex,
            name: d.name,
            exercises: d.exercises,
          })),
        },
      },
      include: { days: { orderBy: { dayIndex: 'asc' } } },
    });
  }

  async getActive(userId: string) {
    return prisma.program.findFirst({
      where: { userId, active: true },
      include: { days: { orderBy: { dayIndex: 'asc' } } },
    });
  }

  async list(userId: string) {
    return prisma.program.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: { days: { orderBy: { dayIndex: 'asc' } } },
    });
  }

  async activate(userId: string, programId: string) {
    const owned = await prisma.program.findFirst({ where: { id: programId, userId } });
    if (!owned) throw AppError.notFound('Program not found');
    await prisma.program.updateMany({
      where: { userId, active: true },
      data: { active: false },
    });
    return prisma.program.update({
      where: { id: programId },
      data: { active: true },
      include: { days: { orderBy: { dayIndex: 'asc' } } },
    });
  }

  async delete(userId: string, programId: string) {
    const owned = await prisma.program.findFirst({ where: { id: programId, userId } });
    if (!owned) throw AppError.notFound('Program not found');
    await prisma.program.delete({ where: { id: programId } });
  }
}

function labelForGoal(goal: Goal): string {
  switch (goal) {
    case 'lose_fat':
      return 'Yağ Yakma';
    case 'gain_muscle':
      return 'Kas Kazanma';
    case 'maintain':
      return 'Koruma';
    case 'general_fitness':
    default:
      return 'Genel Fitness';
  }
}

export const programService = new ProgramService();
