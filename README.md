# FitTrack

Kişisel fitness takip uygulaması. Flutter mobile + Fastify/PostgreSQL backend.

> Vizyon, kapsam ve roadmap için [GDD.md](./GDD.md).
> Agent çalışma kuralları için [CONTEXT.md](./CONTEXT.md).
> Kurulum adımları için [KURULUM.md](./KURULUM.md).

## Mimari

```
fittrack/
├── apps/
│   ├── api/        Fastify + Prisma + PostgreSQL (TypeScript)
│   └── mobile/     Flutter + Riverpod + go_router + Material 3 (Dart)
└── packages/
    ├── shared/        Zod schemas + paylaşımlı tipler (backend)
    └── exercise-db/   Egzersiz veritabanı (backend + mobile asset kaynağı)
```

Backend ve paketler pnpm workspace'i; mobile bağımsız bir Flutter projesi (pub ile bağımlılık yönetir). Mobile, `packages/exercise-db`'den `exercises.json`'u build zamanında `assets/`'e kopyalar.

## Ön gereksinimler

- Node.js 20+ (`.nvmrc`)
- pnpm 10+
- PostgreSQL 15+ (lokal veya Docker)
- Flutter 3.41+ / Dart 3.11+
- Android Studio (Android emülatör/cihaz için) ya da bağlı Android telefon
- iOS build için macOS + Xcode

Kontrol:
```cmd
node --version
pnpm --version
flutter --version
flutter doctor
```

## İlk kurulum

### Backend + paketler

```cmd
pnpm install
copy apps\api\.env.example apps\api\.env
```
`apps/api/.env` içindeki `JWT_SECRET`, `JWT_REFRESH_SECRET`, `DATABASE_URL` değerlerini doldur.

Prisma:
```cmd
pnpm --filter @fittrack/api db:generate
pnpm --filter @fittrack/api db:push
```

### Mobile

```cmd
cd apps\mobile
flutter pub get
flutter gen-l10n
```

İsteğe bağlı env:
```cmd
copy apps\mobile\.env.example apps\mobile\.env
```

## Geliştirme

Backend (3000 portu):
```cmd
pnpm dev:api
```
Test: `curl http://localhost:3000/health`

Mobile (Android/iOS):
```cmd
pnpm dev:mobile
```
Özel API URL ile:
```cmd
cd apps\mobile
flutter run --dart-define=API_URL=http://10.0.2.2:3000
```
> Android emülatörden `localhost` backend'e erişmek için `10.0.2.2` kullan.
> `.env` dosyasıyla: `flutter run --dart-define-from-file=.env`

## Kalite kontrolleri

Backend + paketler:
```cmd
pnpm typecheck
pnpm lint
pnpm format:check
```

Mobile:
```cmd
pnpm mobile:analyze
pnpm mobile:format
```

i18n regenerate (ARB değişince):
```cmd
pnpm mobile:l10n
```

Android APK:
```cmd
pnpm mobile:build:android
```

## Klasör haritası (mobile)

```
apps/mobile/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── api/          # dio client + auth interceptor
│   │   ├── i18n/         # locale controller
│   │   ├── router/       # go_router config
│   │   ├── storage/      # secure storage + preferences
│   │   ├── theme/        # Material 3 + FitTrackColors extension
│   │   └── env.dart      # compile-time env
│   ├── features/
│   │   ├── auth/         # application, domain, presentation
│   │   └── landing/
│   └── l10n/
│       ├── app_en.arb
│       ├── app_tr.arb
│       └── generated/    # AppLocalizations (gen-l10n çıktısı)
├── assets/
│   └── exercises.json
├── l10n.yaml
└── pubspec.yaml
```

## Dokümantasyon

- [GDD.md](./GDD.md) — vizyon, kapsam, faz planı
- [CONTEXT.md](./CONTEXT.md) — agent ve geliştirme kuralları
- [KURULUM.md](./KURULUM.md) — detaylı kurulum ve prompt örnekleri
