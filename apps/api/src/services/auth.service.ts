import type { User } from '@prisma/client';
import {
  type AuthTokens,
  type LoginInput,
  type RegisterCoachInput,
  type RegisterPlayerInput,
  type User as SharedUser,
} from '@fittrack/shared';
import { prisma } from '../lib/prisma.js';
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

  async registerCoach(input: RegisterCoachInput): Promise<AuthResult> {
    const existing = await this.users.findByEmail(input.email);
    if (existing) {
      throw AppError.conflict('Bu e-posta zaten kayıtlı');
    }
    const passwordHash = await hashPassword(input.password);

    const user = await prisma.$transaction(async (tx) => {
      const createdUser = await tx.user.create({
        data: {
          email: input.email.toLowerCase(),
          passwordHash,
          fullName: input.fullName,
          role: 'coach',
          locale: input.locale ?? 'tr',
          phone: input.phone,
        },
      });

      // Opsiyonel: kulüp ismi verilmişse kulüp + coach kaydı oluştur
      if (input.clubName) {
        const club = await tx.club.create({
          data: { name: input.clubName },
        });
        await tx.coach.create({
          data: {
            userId: createdUser.id,
            clubId: club.id,
            isClubAdmin: true,
          },
        });
      } else {
        await tx.coach.create({
          data: { userId: createdUser.id },
        });
      }

      return createdUser;
    });

    const tokens = await this.issueTokens(user);
    return { user: toSharedUser(user), tokens };
  }

  async registerPlayer(input: RegisterPlayerInput): Promise<AuthResult> {
    const invite = await prisma.invite.findUnique({
      where: { code: input.inviteCode.toUpperCase() },
      include: { player: true },
    });
    if (!invite) {
      throw AppError.notFound('Davet kodu bulunamadı');
    }
    if (invite.acceptedAt) {
      throw AppError.conflict('Bu davet kodu zaten kullanıldı');
    }
    if (invite.expiresAt < new Date()) {
      throw AppError.unauthorized('Davet kodu süresi dolmuş');
    }

    const existing = await this.users.findByEmail(input.email);
    if (existing) {
      throw AppError.conflict('Bu e-posta zaten kayıtlı');
    }

    const passwordHash = await hashPassword(input.password);

    const user = await prisma.$transaction(async (tx) => {
      const createdUser = await tx.user.create({
        data: {
          email: input.email.toLowerCase(),
          passwordHash,
          fullName: input.fullName,
          role: 'player',
          locale: input.locale ?? 'tr',
          phone: input.phone,
        },
      });

      // Davete bağlı player profili varsa oyuncuyla eşle
      if (invite.playerId) {
        await tx.player.update({
          where: { id: invite.playerId },
          data: { userId: createdUser.id },
        });
      }

      await tx.invite.update({
        where: { id: invite.id },
        data: { acceptedAt: new Date(), acceptedBy: createdUser.id },
      });

      return createdUser;
    });

    const tokens = await this.issueTokens(user);
    return { user: toSharedUser(user), tokens };
  }

  async login(input: LoginInput): Promise<AuthResult> {
    const user = await this.users.findByEmail(input.email);
    if (!user || !(await verifyPassword(input.password, user.passwordHash))) {
      throw AppError.unauthorized('E-posta veya şifre hatalı');
    }
    const tokens = await this.issueTokens(user);
    return { user: toSharedUser(user), tokens };
  }

  async refresh(rawRefreshToken: string): Promise<AuthTokens> {
    const tokenHash = hashRefreshToken(rawRefreshToken);
    const stored = await this.refreshTokens.findActiveByHash(tokenHash);
    if (!stored) {
      throw AppError.unauthorized('Refresh token geçersiz veya süresi dolmuş');
    }
    const user = await this.users.findById(stored.userId);
    if (!user) {
      await this.refreshTokens.revoke(stored.id);
      throw AppError.unauthorized('Kullanıcı artık mevcut değil');
    }
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
    if (!user) throw AppError.notFound('Kullanıcı bulunamadı');
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
    fullName: user.fullName,
    role: user.role,
    locale: user.locale,
    phone: user.phone,
    avatarUrl: user.avatarUrl,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

export const authService = new AuthService();
