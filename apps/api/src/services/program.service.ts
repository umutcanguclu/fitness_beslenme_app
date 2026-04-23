import type {
  Equipment,
  Exercise,
  Goal,
  MuscleGroup,
  ProgramEquipment,
  ProgramGenerateInput,
  ProgramLevel,
} from '@fittrack/shared';
import { exercises as CATALOG } from '@fittrack/exercise-db';
import { AppError } from '../lib/errors.js';
import { prisma } from '../lib/prisma.js';

const MUSCLES_BY_TRAINING_DAY: Record<string, MuscleGroup[]> = {
  push: ['chest', 'shoulders', 'triceps'],
  pull: ['back', 'biceps', 'forearms'],
  legs: ['quads', 'hamstrings', 'glutes', 'calves'],
  upper: ['chest', 'back', 'shoulders', 'biceps', 'triceps'],
  lower: ['quads', 'hamstrings', 'glutes', 'calves'],
  full: ['chest', 'back', 'shoulders', 'biceps', 'triceps', 'quads', 'hamstrings', 'glutes', 'core'],
  core: ['core'],
};

interface SplitPattern {
  days: string[];
  label: string;
}

const SPLITS: Record<number, SplitPattern[]> = {
  2: [{ days: ['full', 'full'], label: 'Full Body 2x' }],
  3: [
    { days: ['push', 'pull', 'legs'], label: 'PPL 3 gün' },
    { days: ['full', 'full', 'full'], label: 'Full Body 3x' },
  ],
  4: [
    { days: ['upper', 'lower', 'upper', 'lower'], label: 'Upper/Lower' },
    { days: ['push', 'pull', 'legs', 'upper'], label: 'PPL + Upper' },
  ],
  5: [
    { days: ['push', 'pull', 'legs', 'upper', 'lower'], label: 'PPL + U/L' },
    { days: ['upper', 'lower', 'push', 'pull', 'legs'], label: 'U/L + PPL' },
  ],
  6: [{ days: ['push', 'pull', 'legs', 'push', 'pull', 'legs'], label: 'PPL 6 gün' }],
};

const EQUIPMENT_ALLOWLIST: Record<ProgramEquipment, Equipment[]> = {
  bodyweight_only: ['bodyweight'],
  dumbbell_only: ['bodyweight', 'dumbbell', 'kettlebell'],
  full_gym: [
    'bodyweight',
    'dumbbell',
    'barbell',
    'machine',
    'cable',
    'kettlebell',
    'resistance_band',
    'cardio_machine',
    'other',
  ],
};

interface RepScheme {
  sets: number;
  reps: number;
  restSec: number;
}

function repSchemeFor(goal: Goal, mechanic: string | null | undefined): RepScheme {
  switch (goal) {
    case 'lose_fat':
      return { sets: 3, reps: 15, restSec: 45 };
    case 'gain_muscle':
      return mechanic === 'compound'
        ? { sets: 4, reps: 8, restSec: 90 }
        : { sets: 3, reps: 12, restSec: 60 };
    case 'maintain':
      return { sets: 3, reps: 10, restSec: 60 };
    case 'general_fitness':
    default:
      return { sets: 3, reps: 12, restSec: 60 };
  }
}

function exerciseCountPerDay(sessionMinutes: number): number {
  if (sessionMinutes <= 30) return 4;
  if (sessionMinutes <= 45) return 5;
  if (sessionMinutes <= 60) return 6;
  if (sessionMinutes <= 90) return 8;
  return 10;
}

function levelAllowed(
  programLevel: ProgramLevel,
  exerciseLevel: string | null | undefined,
): boolean {
  if (!exerciseLevel) return true;
  const order = { beginner: 0, intermediate: 1, expert: 2 } as const;
  const maxByProgram: Record<ProgramLevel, 0 | 1 | 2> = {
    beginner: 0,
    intermediate: 1,
    advanced: 2,
  };
  return order[exerciseLevel as keyof typeof order] <= maxByProgram[programLevel];
}

function pickSplit(daysPerWeek: number, targetMuscles: MuscleGroup[]): SplitPattern {
  const patterns = SPLITS[daysPerWeek] ?? SPLITS[3];
  const wantsCore = targetMuscles.includes('core');
  const preferred =
    patterns.find((p) => {
      const covers = new Set(p.days.flatMap((d) => MUSCLES_BY_TRAINING_DAY[d] ?? []));
      return targetMuscles.every((m) => covers.has(m) || (wantsCore && m === 'core'));
    }) ?? patterns[0];
  return preferred;
}

function filterCandidates(
  dayMuscles: MuscleGroup[],
  equipmentAllowed: Equipment[],
  programLevel: ProgramLevel,
): Exercise[] {
  const allowed = new Set<Equipment>(equipmentAllowed);
  return CATALOG.filter((ex) => {
    if (!levelAllowed(programLevel, ex.level)) return false;
    if (!ex.equipment.some((eq) => allowed.has(eq))) return false;
    return ex.muscleGroup.some((m) => dayMuscles.includes(m));
  });
}

function chooseExercisesForDay(
  dayMuscles: MuscleGroup[],
  equipmentAllowed: Equipment[],
  programLevel: ProgramLevel,
  count: number,
  wantsCore: boolean,
): Exercise[] {
  const candidates = filterCandidates(dayMuscles, equipmentAllowed, programLevel);
  if (candidates.length === 0) return [];

  const byMuscle = new Map<MuscleGroup, Exercise[]>();
  for (const m of dayMuscles) byMuscle.set(m, []);
  for (const ex of candidates) {
    for (const m of ex.muscleGroup) {
      if (byMuscle.has(m)) byMuscle.get(m)!.push(ex);
    }
  }

  const picked = new Set<string>();
  const result: Exercise[] = [];

  const compoundsFirst = (arr: Exercise[]) =>
    [...arr].sort((a, b) => {
      const aa = a.mechanic === 'compound' ? 0 : 1;
      const bb = b.mechanic === 'compound' ? 0 : 1;
      if (aa !== bb) return aa - bb;
      return a.nameEn.localeCompare(b.nameEn);
    });

  let cursor = 0;
  while (result.length < count) {
    let added = false;
    for (const m of dayMuscles) {
      if (result.length >= count) break;
      const pool = compoundsFirst(byMuscle.get(m) ?? []);
      for (let i = cursor; i < pool.length; i++) {
        const ex = pool[i];
        if (!picked.has(ex.id)) {
          picked.add(ex.id);
          result.push(ex);
          added = true;
          break;
        }
      }
    }
    if (!added) break;
    cursor++;
  }

  if (wantsCore && !dayMuscles.includes('core') && result.length < count + 1) {
    const coreEx = filterCandidates(['core'], equipmentAllowed, programLevel).find(
      (e) => !picked.has(e.id),
    );
    if (coreEx) result.push(coreEx);
  }

  return result.slice(0, count + (wantsCore && !dayMuscles.includes('core') ? 1 : 0));
}

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
    const split = pickSplit(input.daysPerWeek, input.targetMuscles);
    const exercisesPerDay = exerciseCountPerDay(input.sessionMinutes);
    const equipmentAllowed = EQUIPMENT_ALLOWLIST[input.equipment];
    const wantsCore = input.targetMuscles.includes('core');

    const days: GeneratedProgramDay[] = split.days.map((dayKey, idx) => {
      const muscles = MUSCLES_BY_TRAINING_DAY[dayKey] ?? ['full_body'];
      const filtered = muscles.filter((m) =>
        input.targetMuscles.includes(m) || dayKey === 'full' || input.targetMuscles.length >= 6,
      );
      const finalMuscles = filtered.length > 0 ? filtered : muscles;
      const picks = chooseExercisesForDay(
        finalMuscles,
        equipmentAllowed,
        input.level,
        exercisesPerDay,
        wantsCore,
      );

      return {
        dayIndex: idx,
        name: `${labelForDay(dayKey)}`,
        exercises: picks.map((ex, order) => {
          const scheme = repSchemeFor(input.goal, ex.mechanic);
          const isTimed = ex.type === 'cardio' || ex.type === 'stretch';
          return {
            exerciseId: ex.id,
            order,
            targetSets: scheme.sets,
            targetReps: isTimed ? null : scheme.reps,
            targetTimeSeconds: isTimed ? 30 : null,
            restSeconds: scheme.restSec,
          };
        }),
      };
    });

    await prisma.program.updateMany({
      where: { userId, active: true },
      data: { active: false },
    });

    const created = await prisma.program.create({
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

    return created;
  }

  async getActive(userId: string) {
    const program = await prisma.program.findFirst({
      where: { userId, active: true },
      include: { days: { orderBy: { dayIndex: 'asc' } } },
    });
    return program;
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

function labelForDay(dayKey: string): string {
  const map: Record<string, string> = {
    push: 'İtiş (Göğüs/Omuz/Triceps)',
    pull: 'Çekiş (Sırt/Biceps)',
    legs: 'Bacak',
    upper: 'Üst Gövde',
    lower: 'Alt Gövde',
    full: 'Full Body',
    core: 'Core',
  };
  return map[dayKey] ?? dayKey;
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
