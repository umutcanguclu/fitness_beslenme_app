import { describe, expect, it } from 'vitest';
import { hasTestDb, setupIntegrationSuite } from './db.js';

describe.runIf(hasTestDb)('program generation (integration)', () => {
  const ctx = setupIntegrationSuite();

  async function bootstrapCoach(email = 'koc@gen.test') {
    const reg = await ctx.app.inject({
      method: 'POST',
      url: '/auth/register/coach',
      payload: { email, password: 'gizli-1234', fullName: 'Hoca', clubName: 'Test Kulüp' },
    });
    expect(reg.statusCode).toBe(201);
    const body = reg.json() as { tokens: { accessToken: string }; user: { id: string } };
    return { token: body.tokens.accessToken, userId: body.user.id };
  }

  async function provisionClubResources(token: string, clubId: string) {
    // Saha + temel ekipman — engine için minimum.
    await ctx.app.inject({
      method: 'POST',
      url: `/clubs/${clubId}/facilities`,
      headers: { authorization: `Bearer ${token}` },
      payload: { type: 'natural_grass', name: 'Ana Saha' },
    });
    await ctx.app.inject({
      method: 'POST',
      url: `/clubs/${clubId}/equipment`,
      headers: { authorization: `Bearer ${token}` },
      payload: { item: 'cones', quantity: 30 },
    });
  }

  it('koç oyuncu yaratır + program üretir + DB\'ye yazılır', async () => {
    const { token } = await bootstrapCoach();

    const myClub = await ctx.app.inject({
      method: 'GET',
      url: '/clubs/me',
      headers: { authorization: `Bearer ${token}` },
    });
    const clubId = (myClub.json() as { id: string }).id;

    await provisionClubResources(token, clubId);

    const team = await ctx.app.inject({
      method: 'POST',
      url: '/teams',
      headers: { authorization: `Bearer ${token}` },
      payload: { name: 'A Takım', category: 'senior', season: '2026-2027' },
    });
    const teamId = (team.json() as { id: string }).id;

    const playerRes = await ctx.app.inject({
      method: 'POST',
      url: `/teams/${teamId}/players`,
      headers: { authorization: `Bearer ${token}` },
      payload: {
        fullName: 'Ali Veli',
        birthDate: '2000-01-15',
        position: 'midfielder',
        preferredFoot: 'right',
        heightCm: 178,
        weightKg: 72,
        employmentStatus: 'amateur',
      },
    });
    const { player } = playerRes.json() as { player: { id: string } };

    // Program üret — Pazartesi başlangıç tarihi
    const generate = await ctx.app.inject({
      method: 'POST',
      url: `/players/${player.id}/programs/generate`,
      headers: { authorization: `Bearer ${token}` },
      payload: { weekStartDate: '2026-04-27', microcycleType: 'match_week' },
    });
    expect(generate.statusCode).toBe(201);

    const program = generate.json() as {
      id: string;
      sessions: Array<{ category: string; durationMinutes: number; exercises: unknown[] }>;
    };
    expect(program.sessions.length).toBeGreaterThan(0);
    for (const s of program.sessions) {
      expect(s.durationMinutes).toBeGreaterThan(0);
      expect(s.exercises.length).toBeGreaterThan(0);
    }

    // GET /players/:id/programs ile geri okuma
    const list = await ctx.app.inject({
      method: 'GET',
      url: `/players/${player.id}/programs?weekStartDate=2026-04-27`,
      headers: { authorization: `Bearer ${token}` },
    });
    expect(list.statusCode).toBe(200);
    const programs = list.json() as Array<{ id: string }>;
    expect(programs).toHaveLength(1);
    expect(programs[0]!.id).toBe(program.id);

    // Tekrar generate → replace stratejisi: yeni program ID, eski silinir
    const regenerate = await ctx.app.inject({
      method: 'POST',
      url: `/players/${player.id}/programs/generate`,
      headers: { authorization: `Bearer ${token}` },
      payload: { weekStartDate: '2026-04-27', microcycleType: 'match_week' },
    });
    expect(regenerate.statusCode).toBe(201);
    const second = regenerate.json() as { id: string };
    expect(second.id).not.toBe(program.id);

    const listAfter = await ctx.app.inject({
      method: 'GET',
      url: `/players/${player.id}/programs?weekStartDate=2026-04-27`,
      headers: { authorization: `Bearer ${token}` },
    });
    expect((listAfter.json() as unknown[]).length).toBe(1);
  });

  it('kaleci için goalkeeper_specific kategorisi üretilir', async () => {
    const { token } = await bootstrapCoach('gkkoc@gen.test');
    const myClub = await ctx.app.inject({
      method: 'GET',
      url: '/clubs/me',
      headers: { authorization: `Bearer ${token}` },
    });
    const clubId = (myClub.json() as { id: string }).id;
    await provisionClubResources(token, clubId);
    // Kaleci kalesi için ek ekipman
    await ctx.app.inject({
      method: 'POST',
      url: `/clubs/${clubId}/equipment`,
      headers: { authorization: `Bearer ${token}` },
      payload: { item: 'goal', quantity: 2 },
    });
    await ctx.app.inject({
      method: 'POST',
      url: `/clubs/${clubId}/equipment`,
      headers: { authorization: `Bearer ${token}` },
      payload: { item: 'agility_ladder', quantity: 1 },
    });

    const team = await ctx.app.inject({
      method: 'POST',
      url: '/teams',
      headers: { authorization: `Bearer ${token}` },
      payload: { name: 'A Takım', category: 'senior', season: '2026-2027' },
    });
    const teamId = (team.json() as { id: string }).id;

    const playerRes = await ctx.app.inject({
      method: 'POST',
      url: `/teams/${teamId}/players`,
      headers: { authorization: `Bearer ${token}` },
      payload: {
        fullName: 'Mert Kaleci',
        birthDate: '1998-03-10',
        position: 'goalkeeper',
        detailedPosition: 'GK',
        preferredFoot: 'right',
        heightCm: 190,
        weightKg: 85,
        employmentStatus: 'semi_pro',
      },
    });
    const { player } = playerRes.json() as { player: { id: string } };

    const generate = await ctx.app.inject({
      method: 'POST',
      url: `/players/${player.id}/programs/generate`,
      headers: { authorization: `Bearer ${token}` },
      payload: { weekStartDate: '2026-04-27', microcycleType: 'match_week' },
    });
    expect(generate.statusCode).toBe(201);
    const program = generate.json() as {
      sessions: Array<{ category: string; exercises: Array<{ exerciseId: string }> }>;
    };
    // Maç günü hariç en az 1 seansın kategorisi 'goalkeeper_specific' olmalı.
    const gkSession = program.sessions.find((s) => s.category === 'goalkeeper_specific');
    expect(gkSession).toBeDefined();
  });
});
