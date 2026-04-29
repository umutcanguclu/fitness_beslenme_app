import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    globals: false,
    include: ['test/**/*.test.ts'],
    setupFiles: ['./test/setup-env.ts'],
    env: {
      // Defaults — DATABASE_URL_TEST set'liyse setup-env.ts override eder.
      NODE_ENV: 'test',
      DATABASE_URL: 'postgresql://stub:stub@localhost:5432/stub',
      JWT_SECRET: 'test-secret-test-secret-test-secret',
      JWT_REFRESH_SECRET: 'test-refresh-secret-test-refresh-secret',
      JWT_ACCESS_TTL: '15m',
      JWT_REFRESH_TTL: '7d',
      LOG_LEVEL: 'error',
    },
    // Postgres'e gerçek bağlantı kuran integration testleri sırayla koşsun ki
    // truncate bir test diğerinin verisini bozmasın.
    poolOptions: {
      threads: { singleThread: true },
    },
  },
});
