import { describe, expect, it } from 'vitest';
import {
  generateRefreshToken,
  hashRefreshToken,
  signAccessToken,
  verifyAccessToken,
} from '../../src/lib/tokens.js';

describe('tokens', () => {
  it('signs and verifies access tokens', () => {
    const token = signAccessToken({ sub: 'user-1', email: 'a@b.co' });
    const payload = verifyAccessToken(token);
    expect(payload.sub).toBe('user-1');
    expect(payload.email).toBe('a@b.co');
  });

  it('rejects tampered access tokens', () => {
    const token = signAccessToken({ sub: 'user-1', email: 'a@b.co' });
    const tampered = token.slice(0, -2) + 'xx';
    expect(() => verifyAccessToken(tampered)).toThrow();
  });

  it('generates unique refresh tokens with consistent hashing', () => {
    const a = generateRefreshToken();
    const b = generateRefreshToken();
    expect(a.token).not.toBe(b.token);
    expect(hashRefreshToken(a.token)).toBe(a.tokenHash);
    expect(a.expiresAt.getTime()).toBeGreaterThan(Date.now());
  });
});
