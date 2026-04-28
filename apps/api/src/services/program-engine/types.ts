import type {
  AvailabilityStatus,
  EquipmentItem,
  ExerciseLocation,
  FacilityType,
  MicrocycleType,
  PositionGroup,
  TrainingCategory,
} from '@fittrack/shared';

// Engine'in kararlarını alırken baktığı ham snapshot.
export interface PlayerSnapshot {
  playerId: string;
  ageYears: number;
  position: PositionGroup;
  heightCm: number;
  weightKg: number;
  employmentStatus: string;
  availabilityStatus: AvailabilityStatus | null;
  hasActiveInjury: boolean;
  activeInjuryBodyParts: string[];
}

export interface ClubResources {
  clubId: string;
  equipment: Set<EquipmentItem>;
  facilities: Set<FacilityType>;
  // Egzersiz seçimi için engine'in destekleyeceği lokasyon listesi
  // (kulübün tesislerinden türetilir).
  availableLocations: Set<ExerciseLocation>;
}

export interface MatchContext {
  hasMatchThisWeek: boolean;
  matchDayOfWeek: number | null; // 0=pazartesi ... 6=pazar
  matchDate: Date | null;
}

// Gün başı planı — engine her gün için bunu üretir, sonra exercise seçimi yapılır.
export interface DayPlan {
  dayOfWeek: number; // 0..6
  date: Date;
  categories: TrainingCategory[];
  intensity: number; // 1..5
  durationMinutes: number;
  isOff: boolean;
  notes?: string;
}

export interface SelectedExercise {
  exerciseId: string;
  order: number;
  sets?: number;
  reps?: number;
  durationSeconds?: number;
  distanceMeters?: number;
  restSeconds?: number;
  intensity?: number;
}

export interface GeneratedSession {
  date: Date;
  category: TrainingCategory;
  durationMinutes: number;
  intensity: number;
  exercises: SelectedExercise[];
  notes?: string;
}

export interface GeneratedProgram {
  weekStartDate: Date;
  microcycleType: MicrocycleType;
  matchDayOfWeek: number | null;
  sessions: GeneratedSession[];
  generationInputs: unknown; // audit snapshot
}

export interface EngineInput {
  playerId: string;
  weekStartDate: Date;
  microcycleType?: MicrocycleType;
}

export const ENGINE_VERSION = 'rule_engine_v1';
