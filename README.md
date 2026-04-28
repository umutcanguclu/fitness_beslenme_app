# fittrack

Alt lig + akademi futbol antrenörleri için "antrenör + oyuncu" platformu. Antrenör oyuncu profillerini ve kulüp kaynaklarını girer, kural tabanlı engine her oyuncuya **haftalık antrenman programı** üretir. Oyuncu telefonundan programını görür, RPE / katılım girer.

> Vizyon ve faz planı: [GDD.md](./GDD.md)
> Agent çalışma kuralları: [CONTEXT.md](./CONTEXT.md)

## Mimari

```
fittrack/
├── apps/
│   └── api/                          # Fastify + Prisma + Postgres (TypeScript)
│       ├── src/
│       │   ├── routes/               # Fastify route handler'lar
│       │   ├── services/             # business logic
│       │   │   ├── auth.service.ts
│       │   │   └── program-engine/   # kural tabanlı program üretici
│       │   ├── repositories/         # Prisma wrapper'lar
│       │   ├── plugins/auth.ts       # requireAuth hook
│       │   └── lib/                  # env, errors, prisma, password, tokens
│       ├── prisma/
│       │   ├── schema.prisma
│       │   ├── seed.ts
│       │   └── seed/exercises.ts     # ~190 futbol egzersizi
│       └── test/                     # vitest
└── packages/
    └── shared/                       # @fittrack/shared (Zod schemas + types)
```

Frontend stack kararı henüz verilmedi — bu repo şimdilik **API + engine + test** içerir.

## Ön gereksinimler

- Node.js 20+ (`.nvmrc`)
- pnpm 10+
- PostgreSQL 17 (lokal: `localhost:5432`, db: `fittrack`)

Kontrol:
```cmd
node --version
pnpm --version
```

## İlk kurulum

```cmd
pnpm install
copy apps\api\.env.example apps\api\.env
```

`apps/api/.env` içine `JWT_SECRET`, `JWT_REFRESH_SECRET`, `DATABASE_URL` doldur.

Postgres lokal başlatma (servis modu):
```powershell
"C:\Program Files\PostgreSQL\17\bin\pg_ctl.exe" -D "$env:USERPROFILE\dev\pgdata" start
```

Prisma:
```cmd
pnpm --filter @fittrack/api db:generate
pnpm --filter @fittrack/api db:push
pnpm --filter @fittrack/api db:seed
```

Seed `upsert` ile idempotent — yeniden çalıştırmak güvenli.

## Geliştirme

```cmd
pnpm dev:api
```
Test: `curl http://localhost:3000/health`

Hızlı doğrulama (typecheck + vitest + api start):
```cmd
dev.bat
```
Sadece kontroller: `dev.bat check`

## Kalite kontrolleri

```cmd
pnpm typecheck
pnpm test:api
pnpm format:check
```

## DB iş akışları

```cmd
pnpm --filter @fittrack/api db:studio       # Prisma Studio
pnpm --filter @fittrack/api db:migrate      # migration üret + uygula (dev)
pnpm --filter @fittrack/api db:seed         # egzersizleri upsert et
```

> Production'a yaklaşırken `db:push` yerine `db:migrate` kullan — migration history isteriz.

## Engine

`apps/api/src/services/program-engine/` — kural tabanlı haftalık program üretici. Akış ve kalibrasyon notları için: [program-engine/README.md](./apps/api/src/services/program-engine/README.md).

Versiyon: `rule_engine_v1`. Eski programlar `TrainingProgram.generationInputs` snapshot'ı ile audit için saklanır.
