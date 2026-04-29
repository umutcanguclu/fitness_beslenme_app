import { describe, expect, it } from 'vitest';
import { hasTestDb, setupIntegrationSuite } from './db.js';

describe.runIf(hasTestDb)('auth flow (integration)', () => {
  const ctx = setupIntegrationSuite();

  it('koç kayıt + login + me akışı', async () => {
    const register = await ctx.app.inject({
      method: 'POST',
      url: '/auth/register/coach',
      payload: {
        email: 'koc@test.local',
        password: 'gizli-1234',
        fullName: 'Test Hoca',
        clubName: 'Test Kulübü',
      },
    });
    expect(register.statusCode).toBe(201);
    const registerBody = register.json() as {
      tokens: { accessToken: string; refreshToken: string };
      user: { id: string; email: string; role: string };
    };
    expect(registerBody.user.role).toBe('coach');
    expect(registerBody.tokens.accessToken).toBeTruthy();

    const login = await ctx.app.inject({
      method: 'POST',
      url: '/auth/login',
      payload: { email: 'koc@test.local', password: 'gizli-1234' },
    });
    expect(login.statusCode).toBe(200);

    const me = await ctx.app.inject({
      method: 'GET',
      url: '/auth/me',
      headers: { authorization: `Bearer ${registerBody.tokens.accessToken}` },
    });
    expect(me.statusCode).toBe(200);
    expect((me.json() as { email: string }).email).toBe('koc@test.local');

    const myClub = await ctx.app.inject({
      method: 'GET',
      url: '/clubs/me',
      headers: { authorization: `Bearer ${registerBody.tokens.accessToken}` },
    });
    expect(myClub.statusCode).toBe(200);
    expect((myClub.json() as { name: string }).name).toBe('Test Kulübü');
  });

  it('davet kodu olmadan oyuncu kaydı reddedilir', async () => {
    const res = await ctx.app.inject({
      method: 'POST',
      url: '/auth/register/player',
      payload: {
        email: 'oyuncu@test.local',
        password: 'gizli-1234',
        fullName: 'Test Oyuncu',
        inviteCode: 'YOKBÖYLE',
      },
    });
    expect(res.statusCode).toBe(404);
  });

  it('oyuncu davet kodu ile kayıt olur ve player profiline bağlanır', async () => {
    // 1) Koç kaydı
    const reg = await ctx.app.inject({
      method: 'POST',
      url: '/auth/register/coach',
      payload: {
        email: 'koc2@test.local',
        password: 'gizli-1234',
        fullName: 'Test Hoca 2',
        clubName: 'Test Kulübü 2',
      },
    });
    const { tokens } = reg.json() as { tokens: { accessToken: string } };

    // 2) Takım oluştur
    const team = await ctx.app.inject({
      method: 'POST',
      url: '/teams',
      headers: { authorization: `Bearer ${tokens.accessToken}` },
      payload: { name: 'A Takım', category: 'senior', season: '2026-2027' },
    });
    expect(team.statusCode).toBe(201);
    const teamId = (team.json() as { id: string }).id;

    // 3) Oyuncu profili + invite üret
    const newPlayer = await ctx.app.inject({
      method: 'POST',
      url: `/teams/${teamId}/players`,
      headers: { authorization: `Bearer ${tokens.accessToken}` },
      payload: {
        fullName: 'Ahmet Yılmaz',
        birthDate: '2000-05-12',
        position: 'midfielder',
        preferredFoot: 'right',
        heightCm: 178,
        weightKg: 72,
        employmentStatus: 'amateur',
      },
    });
    expect(newPlayer.statusCode).toBe(201);
    const created = newPlayer.json() as {
      player: { id: string; fullName: string };
      invite: { code: string; expiresAt: string };
    };
    expect(created.invite.code).toMatch(/^[A-Z0-9]{8}$/);

    // 4) Oyuncu invite ile kayıt olur
    const playerReg = await ctx.app.inject({
      method: 'POST',
      url: '/auth/register/player',
      payload: {
        email: 'ahmet@test.local',
        password: 'gizli-1234',
        fullName: 'Ahmet Yılmaz',
        inviteCode: created.invite.code,
      },
    });
    expect(playerReg.statusCode).toBe(201);

    // 5) İkinci kez aynı kodla deneyince conflict
    const dupe = await ctx.app.inject({
      method: 'POST',
      url: '/auth/register/player',
      payload: {
        email: 'baska@test.local',
        password: 'gizli-1234',
        fullName: 'Başka',
        inviteCode: created.invite.code,
      },
    });
    expect(dupe.statusCode).toBe(409);
  });
});
