import { afterAll, beforeAll, beforeEach } from 'vitest';
import type { FastifyInstance } from 'fastify';

// Bu modül yalnızca entegrasyon testleri tarafından import edilir; eğer
// DATABASE_URL_TEST set değilse describe.runIf(...) ile testler skip olur.

export const hasTestDb = !!process.env.DATABASE_URL_TEST;

export interface TestContext {
  app: FastifyInstance;
}

const ctx: Partial<TestContext> = {};

// Truncate ettiğimiz tablolar — Exercise referans verisi olduğundan korunur.
const USER_DATA_TABLES = ['"User"', '"Club"'];

export function setupIntegrationSuite(): TestContext {
  beforeAll(async () => {
    const { buildApp } = await import('../../src/app.js');
    const { prisma } = await import('../../src/lib/prisma.js');
    const { FOOTBALL_EXERCISES } = await import('../../prisma/seed/exercises.js');

    ctx.app = await buildApp();
    await ctx.app.ready();

    // Exercise tablosu boşsa seed et — testler exerciseSelector'a güvenir.
    const count = await prisma.exercise.count();
    if (count === 0) {
      for (const ex of FOOTBALL_EXERCISES) {
        await prisma.exercise.upsert({ where: { slug: ex.slug }, create: ex, update: ex });
      }
    }
  });

  beforeEach(async () => {
    const { prisma } = await import('../../src/lib/prisma.js');
    // CASCADE: User → Coach/Player/RefreshToken/Invite, Club → Team/Player/Facility/...
    await prisma.$executeRawUnsafe(
      `TRUNCATE TABLE ${USER_DATA_TABLES.join(', ')} RESTART IDENTITY CASCADE`,
    );
  });

  afterAll(async () => {
    const { prisma } = await import('../../src/lib/prisma.js');
    await ctx.app?.close();
    await prisma.$disconnect();
  });

  return new Proxy(ctx as TestContext, {
    get(target, prop) {
      const v = target[prop as keyof TestContext];
      if (v === undefined) {
        throw new Error(`Test context not initialized yet — ${String(prop)} accessed before beforeAll`);
      }
      return v;
    },
  });
}
