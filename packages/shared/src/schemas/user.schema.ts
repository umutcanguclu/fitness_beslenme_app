import { z } from 'zod';

export const LocaleSchema = z.enum(['tr', 'en']);
export type Locale = z.infer<typeof LocaleSchema>;

export const UserRoleSchema = z.enum(['coach', 'player']);
export type UserRole = z.infer<typeof UserRoleSchema>;

export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  fullName: z.string().min(1).max(120),
  role: UserRoleSchema,
  locale: LocaleSchema.default('tr'),
  phone: z.string().max(32).nullable().optional(),
  avatarUrl: z.string().url().nullable().optional(),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});
export type User = z.infer<typeof UserSchema>;

export const RegisterCoachInputSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(128),
  fullName: z.string().min(1).max(120),
  locale: LocaleSchema.optional(),
  phone: z.string().max(32).optional(),
  clubName: z.string().min(1).max(120).optional(), // varsa kulüp de oluştur
});
export type RegisterCoachInput = z.infer<typeof RegisterCoachInputSchema>;

// Oyuncu davet kodu ile kayıt olur — koç önce Invite oluşturur.
export const RegisterPlayerInputSchema = z.object({
  inviteCode: z.string().min(4).max(16),
  email: z.string().email(),
  password: z.string().min(8).max(128),
  fullName: z.string().min(1).max(120),
  locale: LocaleSchema.optional(),
  phone: z.string().max(32).optional(),
});
export type RegisterPlayerInput = z.infer<typeof RegisterPlayerInputSchema>;

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
