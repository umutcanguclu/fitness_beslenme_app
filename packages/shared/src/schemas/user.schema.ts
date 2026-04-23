import { z } from 'zod';

export const LocaleSchema = z.enum(['en', 'tr']);
export type Locale = z.infer<typeof LocaleSchema>;

export const UnitSystemSchema = z.enum(['metric', 'imperial']);
export type UnitSystem = z.infer<typeof UnitSystemSchema>;

export const GenderSchema = z.enum(['male', 'female', 'other', 'prefer_not_to_say']);
export type Gender = z.infer<typeof GenderSchema>;

export const GoalSchema = z.enum(['lose_fat', 'gain_muscle', 'maintain', 'general_fitness']);
export type Goal = z.infer<typeof GoalSchema>;

export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1).max(80),
  locale: LocaleSchema.default('en'),
  unitSystem: UnitSystemSchema.default('metric'),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});
export type User = z.infer<typeof UserSchema>;

export const RegisterInputSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(128),
  name: z.string().min(1).max(80),
  locale: LocaleSchema.optional(),
});
export type RegisterInput = z.infer<typeof RegisterInputSchema>;

export const LoginInputSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1).max(128),
});
export type LoginInput = z.infer<typeof LoginInputSchema>;

export const AuthTokensSchema = z.object({
  accessToken: z.string(),
  refreshToken: z.string(),
});
export type AuthTokens = z.infer<typeof AuthTokensSchema>;

export const ProfileSchema = z.object({
  userId: z.string().uuid(),
  heightCm: z.number().positive().max(300).nullable(),
  weightKg: z.number().positive().max(500).nullable(),
  age: z.number().int().min(10).max(120).nullable(),
  gender: GenderSchema.nullable(),
  goal: GoalSchema.nullable(),
  updatedAt: z.coerce.date(),
});
export type Profile = z.infer<typeof ProfileSchema>;

export const ProfileUpdateInputSchema = ProfileSchema.omit({
  userId: true,
  updatedAt: true,
}).partial();
export type ProfileUpdateInput = z.infer<typeof ProfileUpdateInputSchema>;
