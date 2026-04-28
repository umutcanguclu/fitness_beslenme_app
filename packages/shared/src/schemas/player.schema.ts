import { z } from 'zod';
import {
  AvailabilityStatusSchema,
  DetailedPositionSchema,
  EmploymentStatusSchema,
  FootSchema,
  InjurySeveritySchema,
  InjuryTypeSchema,
  PositionGroupSchema,
} from './enums.schema.js';

export const PlayerSchema = z.object({
  userId: z.string().uuid(),
  birthDate: z.coerce.date(),
  position: PositionGroupSchema,
  detailedPosition: DetailedPositionSchema.nullable().optional(),
  secondaryPosition: DetailedPositionSchema.nullable().optional(),
  preferredFoot: FootSchema,
  heightCm: z.number().min(120).max(230),
  weightKg: z.number().min(30).max(150),
  jerseyNumber: z.number().int().min(1).max(99).nullable().optional(),
  employmentStatus: EmploymentStatusSchema.default('amateur'),
  joinedAt: z.coerce.date(),
  notes: z.string().max(2000).nullable().optional(),
});
export type Player = z.infer<typeof PlayerSchema>;

// Antrenör tarafından oyuncu profili oluşturmak için (oyuncu sonra davet kodu ile login olur).
export const CreatePlayerProfileInputSchema = PlayerSchema.omit({
  userId: true,
  joinedAt: true,
}).extend({
  email: z.string().email(),
  fullName: z.string().min(1).max(120),
  teamId: z.string().uuid(),
});
export type CreatePlayerProfileInput = z.infer<typeof CreatePlayerProfileInputSchema>;

export const UpdatePlayerProfileInputSchema = PlayerSchema.omit({
  userId: true,
  joinedAt: true,
}).partial();
export type UpdatePlayerProfileInput = z.infer<typeof UpdatePlayerProfileInputSchema>;

export const PlayerAvailabilitySchema = z.object({
  id: z.string().uuid(),
  playerId: z.string().uuid(),
  date: z.coerce.date(),
  status: AvailabilityStatusSchema,
  note: z.string().max(500).nullable().optional(),
  createdAt: z.coerce.date(),
});
export type PlayerAvailability = z.infer<typeof PlayerAvailabilitySchema>;

export const SetAvailabilityInputSchema = z.object({
  playerId: z.string().uuid(),
  date: z.coerce.date(),
  status: AvailabilityStatusSchema,
  note: z.string().max(500).optional(),
});
export type SetAvailabilityInput = z.infer<typeof SetAvailabilityInputSchema>;

export const InjuryRecordSchema = z.object({
  id: z.string().uuid(),
  playerId: z.string().uuid(),
  type: InjuryTypeSchema,
  severity: InjurySeveritySchema,
  bodyPart: z.string().min(1).max(80),
  startedAt: z.coerce.date(),
  expectedReturn: z.coerce.date().nullable().optional(),
  resolvedAt: z.coerce.date().nullable().optional(),
  description: z.string().max(2000).nullable().optional(),
  createdAt: z.coerce.date(),
});
export type InjuryRecord = z.infer<typeof InjuryRecordSchema>;

export const CreateInjuryInputSchema = InjuryRecordSchema.omit({
  id: true,
  resolvedAt: true,
  createdAt: true,
});
export type CreateInjuryInput = z.infer<typeof CreateInjuryInputSchema>;
