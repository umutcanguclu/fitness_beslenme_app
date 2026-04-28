import { z } from 'zod';

export const MatchSchema = z.object({
  id: z.string().uuid(),
  teamId: z.string().uuid(),
  opponent: z.string().min(1).max(120),
  date: z.coerce.date(),
  isHome: z.boolean(),
  competition: z.string().max(80).nullable().optional(),
  scoreUs: z.number().int().min(0).max(50).nullable().optional(),
  scoreThem: z.number().int().min(0).max(50).nullable().optional(),
  notes: z.string().max(2000).nullable().optional(),
  createdAt: z.coerce.date(),
});
export type Match = z.infer<typeof MatchSchema>;

export const CreateMatchInputSchema = MatchSchema.pick({
  teamId: true,
  opponent: true,
  date: true,
  isHome: true,
  competition: true,
});
export type CreateMatchInput = z.infer<typeof CreateMatchInputSchema>;

export const MatchAppearanceSchema = z.object({
  id: z.string().uuid(),
  matchId: z.string().uuid(),
  playerId: z.string().uuid(),
  startingXi: z.boolean().default(false),
  minutes: z.number().int().min(0).max(150).default(0),
  goals: z.number().int().min(0).max(20).default(0),
  assists: z.number().int().min(0).max(20).default(0),
  yellowCards: z.number().int().min(0).max(2).default(0),
  redCards: z.number().int().min(0).max(1).default(0),
  rating: z.number().min(0).max(10).nullable().optional(),
  notes: z.string().max(500).nullable().optional(),
});
export type MatchAppearance = z.infer<typeof MatchAppearanceSchema>;
