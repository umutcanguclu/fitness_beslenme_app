import { randomBytes } from 'node:crypto';
import { prisma } from '../lib/prisma.js';
import { AppError } from '../lib/errors.js';
import { hashPassword } from '../lib/password.js';

// In-memory token store. For production: use Redis or DB table with TTL.
// Token format: 32-char URL-safe random string. TTL: 1 hour.
interface ResetEntry {
  userId: string;
  expiresAt: Date;
}

const RESET_TTL_MS = 60 * 60 * 1000; // 1 hour

export class PasswordResetService {
  private readonly store = new Map<string, ResetEntry>();

  // Returns the token. In dev, the route prints it to logs and returns it
  // in the API response. In prod, you'd email it instead.
  async createResetToken(email: string): Promise<{ token: string; userExists: boolean }> {
    this.cleanup();
    const user = await prisma.user.findUnique({ where: { email: email.toLowerCase() } });
    // For security: do not reveal whether email exists. Always succeed externally.
    if (!user) {
      return { token: '', userExists: false };
    }
    const token = randomBytes(24).toString('base64url');
    this.store.set(token, {
      userId: user.id,
      expiresAt: new Date(Date.now() + RESET_TTL_MS),
    });
    return { token, userExists: true };
  }

  async resetPassword(token: string, newPassword: string): Promise<void> {
    this.cleanup();
    const entry = this.store.get(token);
    if (!entry) {
      throw AppError.unauthorized('Sıfırlama bağlantısı geçersiz veya süresi dolmuş');
    }
    if (entry.expiresAt < new Date()) {
      this.store.delete(token);
      throw AppError.unauthorized('Sıfırlama bağlantısı süresi dolmuş');
    }
    const hashed = await hashPassword(newPassword);
    await prisma.user.update({
      where: { id: entry.userId },
      data: { passwordHash: hashed },
    });
    // Single-use token.
    this.store.delete(token);
  }

  private cleanup(): void {
    const now = new Date();
    for (const [token, entry] of this.store.entries()) {
      if (entry.expiresAt < now) this.store.delete(token);
    }
  }
}

export const passwordResetService = new PasswordResetService();
