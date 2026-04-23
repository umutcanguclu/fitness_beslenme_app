import { createHash, randomBytes } from 'node:crypto';
import jwt, { type SignOptions } from 'jsonwebtoken';
import { env } from './env.js';

export interface AccessTokenPayload {
  sub: string;
  email: string;
}

export function signAccessToken(payload: AccessTokenPayload): string {
  return jwt.sign(payload, env.JWT_SECRET, {
    expiresIn: env.JWT_ACCESS_TTL as SignOptions['expiresIn'],
  });
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  const decoded = jwt.verify(token, env.JWT_SECRET);
  if (typeof decoded !== 'object' || decoded === null) {
    throw new Error('Malformed access token');
  }
  const { sub, email } = decoded as Record<string, unknown>;
  if (typeof sub !== 'string' || typeof email !== 'string') {
    throw new Error('Access token missing required claims');
  }
  return { sub, email };
}

export interface GeneratedRefreshToken {
  token: string;
  tokenHash: string;
  expiresAt: Date;
}

export function generateRefreshToken(): GeneratedRefreshToken {
  const token = randomBytes(48).toString('base64url');
  const tokenHash = hashRefreshToken(token);
  const expiresAt = addDuration(new Date(), env.JWT_REFRESH_TTL);
  return { token, tokenHash, expiresAt };
}

export function hashRefreshToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

function addDuration(from: Date, ttl: string): Date {
  const match = ttl.match(/^(\d+)\s*([smhd])$/);
  if (!match) {
    throw new Error(`Invalid JWT TTL format: "${ttl}" (expected e.g. "15m", "7d")`);
  }
  const amount = Number(match[1]);
  const unit = match[2];
  const ms = amount * { s: 1000, m: 60_000, h: 3_600_000, d: 86_400_000 }[unit as 's' | 'm' | 'h' | 'd'];
  return new Date(from.getTime() + ms);
}
