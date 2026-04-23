# FitTrack

Kişisel fitness takip uygulaması. pnpm monorepo — Expo React Native mobile + Fastify + PostgreSQL backend.

> Vizyon, kapsam ve roadmap için [GDD.md](./GDD.md).
> Agent çalışma kuralları için [CONTEXT.md](./CONTEXT.md).
> Kurulum adımları için [KURULUM.md](./KURULUM.md).

## Monorepo yapısı

```
fittrack/
├── apps/
│   ├── api/        Fastify + Prisma + PostgreSQL
│   └── mobile/     Expo Router + NativeWind + i18n
└── packages/
    ├── shared/        Zod schemas + paylaşımlı tipler
    └── exercise-db/   Egzersiz veritabanı (wger.de kaynağı)
```

## Ön gereksinimler

- Node.js 20+ (`.nvmrc` dosyası var)
- pnpm 10+
- PostgreSQL 15+ (backend için — lokal veya Docker)
- Expo Go (telefonda mobile test için)

## İlk kurulum

```cmd
pnpm install
```

Backend env:
```cmd
copy apps\api\.env.example apps\api\.env
```
`.env` içindeki `JWT_SECRET`, `JWT_REFRESH_SECRET` ve `DATABASE_URL` değerlerini doldur.

Prisma client generate et, veritabanını oluştur:
```cmd
pnpm --filter @fittrack/api db:generate
pnpm --filter @fittrack/api db:push
```

Mobile env (opsiyonel, varsayılan `http://localhost:3000`):
```cmd
copy apps\mobile\.env.example apps\mobile\.env
```

## Geliştirme

Backend:
```cmd
pnpm dev:api
```
→ `http://localhost:3000/health`

Mobile:
```cmd
pnpm dev:mobile
```
→ Expo Dev Tools açılır, QR kodu Expo Go ile tara.

## Kalite kontrolleri

```cmd
pnpm typecheck
pnpm lint
pnpm format:check
```

## Dokümantasyon

- [GDD.md](./GDD.md) — vizyon, kapsam, faz planı
- [CONTEXT.md](./CONTEXT.md) — agent ve geliştirme kuralları
- [KURULUM.md](./KURULUM.md) — adım adım kurulum ve prompt örnekleri
