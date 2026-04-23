import type { PrismaClient, RefreshToken } from '@prisma/client';
import { prisma } from '../lib/prisma.js';

export interface CreateRefreshTokenInput {
  userId: string;
  tokenHash: string;
  expiresAt: Date;
}

export class RefreshTokenRepository {
  constructor(private readonly db: PrismaClient = prisma) {}

  create(input: CreateRefreshTokenInput): Promise<RefreshToken> {
    return this.db.refreshToken.create({ data: input });
  }

  findActiveByHash(tokenHash: string): Promise<RefreshToken | null> {
    return this.db.refreshToken.findFirst({
      where: {
        tokenHash,
        revokedAt: null,
        expiresAt: { gt: new Date() },
      },
    });
  }

  revoke(id: string): Promise<RefreshToken> {
    return this.db.refreshToken.update({
      where: { id },
      data: { revokedAt: new Date() },
    });
  }

  revokeAllForUser(userId: string): Promise<{ count: number }> {
    return this.db.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }
}

export const refreshTokenRepository = new RefreshTokenRepository();
