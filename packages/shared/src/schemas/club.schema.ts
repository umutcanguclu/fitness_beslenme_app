import { z } from 'zod';
import {
  EquipmentItemSchema,
  FacilityTypeSchema,
  LicenseLevelSchema,
  TeamCategorySchema,
} from './enums.schema.js';

export const ClubSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).max(120),
  city: z.string().max(60).nullable().optional(),
  league: z.string().max(80).nullable().optional(),
  foundedYear: z.number().int().min(1850).max(2100).nullable().optional(),
  logoUrl: z.string().url().nullable().optional(),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});
export type Club = z.infer<typeof ClubSchema>;

export const ClubCreateInputSchema = ClubSchema.pick({
  name: true,
  city: true,
  league: true,
  foundedYear: true,
  logoUrl: true,
});
export type ClubCreateInput = z.infer<typeof ClubCreateInputSchema>;

export const CoachSchema = z.object({
  userId: z.string().uuid(),
  clubId: z.string().uuid().nullable(),
  licenseLevel: LicenseLevelSchema.default('none'),
  isClubAdmin: z.boolean().default(false),
  bio: z.string().max(500).nullable().optional(),
  createdAt: z.coerce.date(),
});
export type Coach = z.infer<typeof CoachSchema>;

export const TeamSchema = z.object({
  id: z.string().uuid(),
  clubId: z.string().uuid(),
  name: z.string().min(1).max(120),
  category: TeamCategorySchema,
  season: z.string().min(1).max(20), // "2026-2027"
  active: z.boolean().default(true),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});
export type Team = z.infer<typeof TeamSchema>;

export const TeamCreateInputSchema = TeamSchema.pick({
  name: true,
  category: true,
  season: true,
}).extend({
  clubId: z.string().uuid(),
});
export type TeamCreateInput = z.infer<typeof TeamCreateInputSchema>;

export const FacilitySchema = z.object({
  id: z.string().uuid(),
  clubId: z.string().uuid(),
  type: FacilityTypeSchema,
  name: z.string().min(1).max(80),
  notes: z.string().max(500).nullable().optional(),
});
export type Facility = z.infer<typeof FacilitySchema>;

export const EquipmentSchema = z.object({
  id: z.string().uuid(),
  clubId: z.string().uuid(),
  item: EquipmentItemSchema,
  quantity: z.number().int().min(0).default(1),
  notes: z.string().max(200).nullable().optional(),
});
export type Equipment = z.infer<typeof EquipmentSchema>;

export const InviteSchema = z.object({
  id: z.string().uuid(),
  code: z.string().min(4).max(16),
  invitedById: z.string().uuid(),
  clubId: z.string().uuid(),
  teamId: z.string().uuid().nullable(),
  email: z.string().email().nullable().optional(),
  expiresAt: z.coerce.date(),
  acceptedAt: z.coerce.date().nullable(),
  acceptedBy: z.string().uuid().nullable(),
  createdAt: z.coerce.date(),
});
export type Invite = z.infer<typeof InviteSchema>;

export const CreateInviteInputSchema = z.object({
  clubId: z.string().uuid(),
  teamId: z.string().uuid().optional(),
  email: z.string().email().optional(),
  expiresInDays: z.number().int().min(1).max(60).default(14),
});
export type CreateInviteInput = z.infer<typeof CreateInviteInputSchema>;
