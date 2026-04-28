import { z } from 'zod';
import {
  AttendanceStatusSchema,
  MicrocycleTypeSchema,
  SessionTypeSchema,
  TrainingCategorySchema,
} from './enums.schema.js';

export const TrainingProgramSchema = z.object({
  id: z.string().uuid(),
  playerId: z.string().uuid().nullable(),
  teamId: z.string().uuid().nullable(),
  weekStartDate: z.coerce.date(),
  matchDayOfWeek: z.number().int().min(0).max(6).nullable().optional(),
  microcycleType: MicrocycleTypeSchema.default('match_week'),
  generatedBy: z.string().min(1).max(80),
  generationInputs: z.unknown(),
  notes: z.string().max(2000).nullable().optional(),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});
export type TrainingProgram = z.infer<typeof TrainingProgramSchema>;

export const TrainingSessionSchema = z.object({
  id: z.string().uuid(),
  programId: z.string().uuid(),
  date: z.coerce.date(),
  type: SessionTypeSchema,
  category: TrainingCategorySchema,
  durationMinutes: z.number().int().min(5).max(300),
  intensity: z.number().int().min(1).max(5),
  notes: z.string().max(2000).nullable().optional(),
  createdAt: z.coerce.date(),
});
export type TrainingSession = z.infer<typeof TrainingSessionSchema>;

export const SessionExerciseSchema = z.object({
  id: z.string().uuid(),
  sessionId: z.string().uuid(),
  exerciseId: z.string().uuid(),
  order: z.number().int().min(0),
  sets: z.number().int().min(1).max(20).nullable().optional(),
  reps: z.number().int().min(1).max(200).nullable().optional(),
  durationSeconds: z.number().int().min(1).max(7200).nullable().optional(),
  distanceMeters: z.number().int().min(1).max(20000).nullable().optional(),
  restSeconds: z.number().int().min(0).max(600).nullable().optional(),
  intensity: z.number().int().min(1).max(5).nullable().optional(),
  notes: z.string().max(500).nullable().optional(),
});
export type SessionExercise = z.infer<typeof SessionExerciseSchema>;

export const TrainingAttendanceSchema = z.object({
  id: z.string().uuid(),
  sessionId: z.string().uuid(),
  playerId: z.string().uuid(),
  status: AttendanceStatusSchema,
  arrivedAt: z.coerce.date().nullable().optional(),
  note: z.string().max(500).nullable().optional(),
  createdAt: z.coerce.date(),
});
export type TrainingAttendance = z.infer<typeof TrainingAttendanceSchema>;

export const SetAttendanceInputSchema = z.object({
  sessionId: z.string().uuid(),
  entries: z
    .array(
      z.object({
        playerId: z.string().uuid(),
        status: AttendanceStatusSchema,
        note: z.string().max(500).optional(),
      }),
    )
    .min(1),
});
export type SetAttendanceInput = z.infer<typeof SetAttendanceInputSchema>;

export const SessionLogSchema = z.object({
  id: z.string().uuid(),
  sessionId: z.string().uuid(),
  playerId: z.string().uuid(),
  rpe: z.number().int().min(1).max(10).nullable().optional(),
  fatigue: z.number().int().min(1).max(5).nullable().optional(),
  mood: z.number().int().min(1).max(5).nullable().optional(),
  sleepHours: z.number().min(0).max(24).nullable().optional(),
  notes: z.string().max(2000).nullable().optional(),
  loggedAt: z.coerce.date(),
});
export type SessionLog = z.infer<typeof SessionLogSchema>;

export const LogSessionInputSchema = SessionLogSchema.pick({
  sessionId: true,
  rpe: true,
  fatigue: true,
  mood: true,
  sleepHours: true,
  notes: true,
});
export type LogSessionInput = z.infer<typeof LogSessionInputSchema>;

// Engine girdileri — generationInputs JSON içine snapshot olarak yazılır.
export const ProgramGenerationInputsSchema = z.object({
  playerId: z.string().uuid().optional(),
  teamId: z.string().uuid().optional(),
  weekStartDate: z.coerce.date(),
  matchDayOfWeek: z.number().int().min(0).max(6).nullable(),
  microcycleType: MicrocycleTypeSchema,
  playerSnapshot: z
    .object({
      ageYears: z.number().int(),
      position: z.string(),
      heightCm: z.number(),
      weightKg: z.number(),
      employmentStatus: z.string(),
      availabilityStatus: z.string().optional(),
      activeInjuries: z.array(z.string()).default([]),
    })
    .optional(),
  clubEquipment: z.array(z.string()).default([]),
  clubFacilities: z.array(z.string()).default([]),
  rulesetVersion: z.string(),
});
export type ProgramGenerationInputs = z.infer<typeof ProgramGenerationInputsSchema>;

export const GenerateProgramInputSchema = z.object({
  playerId: z.string().uuid().optional(),
  teamId: z.string().uuid().optional(),
  weekStartDate: z.coerce.date(),
  microcycleType: MicrocycleTypeSchema.default('match_week'),
});
export type GenerateProgramInput = z.infer<typeof GenerateProgramInputSchema>;
