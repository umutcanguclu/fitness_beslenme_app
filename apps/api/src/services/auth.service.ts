import type { User } from '@prisma/client';
import {
  type AuthTokens,
  type LoginInput,
  type RegisterInput,
  type User as SharedUser,
} from '@fittrack/shared';
import { AppError } from '../lib/errors.js';
import { hashPassword, verifyPassword } from '../lib/password.js';
import {
  generateRefreshToken,
  hashRefreshToken,
  signAccessToken,
} from '../lib/tokens.js';
import {
  refreshTokenRepository,
  type RefreshTokenRepository,
} from '../repositories/refresh-token.repository.js';
import { userRepository, type UserRepository } from '../repositories/user.repository.js';

export interface AuthResult {
  user: SharedUser;
  tokens: AuthTokens;
}

export class AuthService {
  constructor(
    private readonly users: UserRepository = userRepository,
    private readonly refreshTokens: RefreshTokenRepository = refreshTokenRepository,
  ) {}

  async register(input: RegisterInput): Promise<AuthResult> {
    const existing = await this.users.findByEmail(input.email);
    if (existing) {
      throw AppError.conflict('Email is already registered');
    }
    const passwordHash = await hashPassword(input.password);
    const user = await this.users.create({
      email: input.email,
      passwordHash,
      name: input.name,
      locale: input.locale,
    });
    const tokens = await this.issueTokens(user);
    return { user: toSharedUser(user), tokens };
  }

  async login(input: LoginInput): Promise<AuthResult> {
    const user = await this.users.findByEmail(input.email);
    if (!user || !(await verifyPassword(input.password, user.passwordHash))) {
      throw AppError.unauthorized('Invalid credentials');
    }
    const tokens = await this.issueTokens(user);
    return { user: toSharedUser(user), tokens };
  }

  async refresh(rawRefreshToken: string): Promise<AuthTokens> {
    const tokenHash = hashRefreshToken(rawRefreshToken);
    const stored = await this.refreshTokens.findActiveByHash(tokenHash);
    if (!stored) {
      throw AppError.unauthorized('Refresh token is invalid or expired');
    }
    const user = await this.users.findById(stored.userId);
    if (!user) {
      await this.refreshTokens.revoke(stored.id);
      throw AppError.unauthorized('User no longer exists');
    }
    // Rotate: revoke old, issue new pair.
    await this.refreshTokens.revoke(stored.id);
    return this.issueTokens(user);
  }

  async logout(rawRefreshToken: string): Promise<void> {
    const tokenHash = hashRefreshToken(rawRefreshToken);
    const stored = await this.refreshTokens.findActiveByHash(tokenHash);
    if (stored) {
      await this.refreshTokens.revoke(stored.id);
    }
  }

  async getById(id: string): Promise<SharedUser> {
    const user = await this.users.findById(id);
    if (!user) throw AppError.notFound('User not found');
    return toSharedUser(user);
  }

  private async issueTokens(user: User): Promise<AuthTokens> {
    const access = signAccessToken({ sub: user.id, email: user.email });
    const refresh = generateRefreshToken();
    await this.refreshTokens.create({
      userId: user.id,
      tokenHash: refresh.tokenHash,
      expiresAt: refresh.expiresAt,
    });
    return { accessToken: access, refreshToken: refresh.token };
  }
}

function toSharedUser(user: User): SharedUser {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    locale: user.locale,
    unitSystem: user.unitSystem,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

export const authService = new AuthService();
