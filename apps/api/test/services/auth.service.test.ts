import { beforeEach, describe, expect, it, vi } from 'vitest';
import { AuthService } from '../../src/services/auth.service.js';
import { AppError } from '../../src/lib/errors.js';
import { hashPassword } from '../../src/lib/password.js';
import type { RefreshToken, User } from '@prisma/client';

function buildUser(overrides: Partial<User> = {}): User {
  return {
    id: 'user-1',
    email: 'a@b.co',
    passwordHash: 'placeholder',
    name: 'Ada',
    locale: 'en',
    unitSystem: 'metric',
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    ...overrides,
  };
}

function stubRepos() {
  const users = {
    findByEmail: vi.fn(),
    findById: vi.fn(),
    create: vi.fn(),
  };
  const refreshTokens = {
    create: vi.fn(async (input: { tokenHash: string; userId: string; expiresAt: Date }) => ({
      id: 'rt-1',
      revokedAt: null,
      createdAt: new Date(),
      ...input,
    })),
    findActiveByHash: vi.fn(),
    revoke: vi.fn(),
    revokeAllForUser: vi.fn(),
  };
  return {
    users,
    refreshTokens,
    service: new AuthService(users as never, refreshTokens as never),
  };
}

describe('AuthService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('register — rejects duplicate email', async () => {
    const { users, service } = stubRepos();
    users.findByEmail.mockResolvedValue(buildUser());

    await expect(
      service.register({ email: 'a@b.co', password: 'password123', name: 'Ada' }),
    ).rejects.toMatchObject({ code: 'CONFLICT' });
  });

  it('register — hashes password and issues tokens', async () => {
    const { users, refreshTokens, service } = stubRepos();
    users.findByEmail.mockResolvedValue(null);
    users.create.mockImplementation(async (input) =>
      buildUser({ id: 'new-id', email: input.email, passwordHash: input.passwordHash, name: input.name }),
    );

    const result = await service.register({
      email: 'NEW@EXAMPLE.co',
      password: 'password123',
      name: 'Ada',
    });

    expect(users.create).toHaveBeenCalledOnce();
    const createInput = users.create.mock.calls[0][0];
    expect(createInput.passwordHash).not.toBe('password123');
    expect(result.tokens.accessToken.split('.').length).toBe(3);
    expect(refreshTokens.create).toHaveBeenCalledOnce();
  });

  it('login — rejects unknown email with 401', async () => {
    const { users, service } = stubRepos();
    users.findByEmail.mockResolvedValue(null);
    await expect(
      service.login({ email: 'nope@example.co', password: 'password123' }),
    ).rejects.toMatchObject({ code: 'UNAUTHORIZED' });
  });

  it('login — rejects wrong password with 401', async () => {
    const { users, service } = stubRepos();
    users.findByEmail.mockResolvedValue(
      buildUser({ passwordHash: await hashPassword('real-password') }),
    );
    await expect(
      service.login({ email: 'a@b.co', password: 'wrong-password' }),
    ).rejects.toMatchObject({ code: 'UNAUTHORIZED' });
  });

  it('login — returns tokens on correct credentials', async () => {
    const { users, service } = stubRepos();
    users.findByEmail.mockResolvedValue(
      buildUser({ passwordHash: await hashPassword('real-password') }),
    );
    const result = await service.login({ email: 'a@b.co', password: 'real-password' });
    expect(result.user.id).toBe('user-1');
    expect(result.tokens.refreshToken.length).toBeGreaterThan(40);
  });

  it('refresh — rotates active token', async () => {
    const { users, refreshTokens, service } = stubRepos();
    const active: RefreshToken = {
      id: 'rt-1',
      userId: 'user-1',
      tokenHash: 'hash-placeholder',
      expiresAt: new Date(Date.now() + 60_000),
      createdAt: new Date(),
      revokedAt: null,
    };
    refreshTokens.findActiveByHash.mockResolvedValue(active);
    users.findById.mockResolvedValue(buildUser());

    await service.refresh('raw-token');
    expect(refreshTokens.revoke).toHaveBeenCalledWith('rt-1');
    expect(refreshTokens.create).toHaveBeenCalledOnce();
  });

  it('refresh — rejects unknown token', async () => {
    const { refreshTokens, service } = stubRepos();
    refreshTokens.findActiveByHash.mockResolvedValue(null);
    await expect(service.refresh('raw-token')).rejects.toMatchObject({
      code: 'UNAUTHORIZED',
    });
  });

  it('getById — throws 404 when user missing', async () => {
    const { users, service } = stubRepos();
    users.findById.mockResolvedValue(null);
    await expect(service.getById('missing')).rejects.toBeInstanceOf(AppError);
  });
});
