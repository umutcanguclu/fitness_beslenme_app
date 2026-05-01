# fittrack

Alt lig + akademi futbol antrenörleri için "antrenör + oyuncu" platformu. Antrenör oyuncu profillerini ve kulüp kaynaklarını girer, kural tabanlı engine her oyuncuya **haftalık antrenman programı** üretir. Oyuncu telefonundan programını görür, RPE / katılım girer.

> Agent çalışma kuralları ve güncel vizyon: [CONTEXT.md](./CONTEXT.md)
> [GDD.md](./GDD.md) — eski genel-fitness vizyonu, futbol pivotundan önce; referans amaçlı duruyor.

## Mimari

```
fittrack/
├── apps/
│   ├── api/                          # Fastify + Prisma + Postgres (TypeScript)
│   │   ├── src/
│   │   │   ├── routes/               # Fastify route handler'lar
│   │   │   ├── services/             # business logic
│   │   │   │   ├── auth.service.ts
│   │   │   │   └── program-engine/   # kural tabanlı program üretici
│   │   │   ├── repositories/         # Prisma wrapper'lar
│   │   │   ├── plugins/auth.ts       # requireAuth hook
│   │   │   └── lib/                  # env, errors, prisma, password, tokens
│   │   ├── prisma/
│   │   │   ├── schema.prisma
│   │   │   ├── seed.ts
│   │   │   └── seed/exercises.ts     # ~190 futbol egzersizi
│   │   └── test/                     # vitest
│   └── mobile/                       # Flutter (Android, iskelet — auth/HTTP/state mgmt henüz yok)
│       ├── lib/main.dart
│       ├── pubspec.yaml
│       └── test/widget_test.dart
└── packages/
    └── shared/                       # @fittrack/shared (Zod schemas + types)
```

**Frontend: Flutter** (mobil-first Android, iOS ikincil) — iskelet `apps/mobile/` altında. Şu an default `flutter create` çıktısı + futbol context'ine göre yeniden yazılmış `main.dart`/`widget_test.dart`. Auth/HTTP/state mgmt dependency'leri henüz eklenmedi; ilk gerçek özellikle birlikte tek tek değerlendirilecek.

Android Studio + emulator + flutter run için: `studio.bat` (root). Default'ta:
1. Android Studio'yu açar
2. İlk AVD'yi (örn. `Medium_Phone`) arka planda başlatır
3. `adb shell getprop sys.boot_completed` ile emulator boot olmasını bekler (max 180s)
4. Yeni cmd penceresinde `flutter run apps/mobile` başlatır (hot reload için pencere açık kalır)

Modlar:
- `studio.bat` — Studio + AVD + flutter run zinciri
- `studio.bat --check` — durum raporu (Studio / SDK / adb / AVD / apps/mobile), aksiyon yok
- `studio.bat --install` — Studio yoksa winget ile kurar
- `studio.bat --no-app` — Studio + AVD, flutter run atla
- `studio.bat --no-emu` — sadece Studio (AVD + flutter run atla)
- `studio.bat --avd <ad>` — belirli bir AVD'yi başlat

Manuel mobil çalıştırma:
```cmd
cd apps\mobile
flutter run
```

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

### Entegrasyon testleri için ayrı test DB

`pnpm test:api` varsayılan olarak yalnızca unit testleri koşar (lib/password, lib/tokens). Entegrasyon testleri (auth flow, program generation) `DATABASE_URL_TEST` ortam değişkeni olmadan otomatik skip olur.

Ayrı bir test veritabanı oluşturduktan sonra:

```powershell
# 1) Test DB oluştur (bir defalık)
"C:\Program Files\PostgreSQL\17\bin\createdb.exe" -U postgres fittrack_test

# 2) Schema'yı push et
$env:DATABASE_URL = "postgresql://postgres:postgres@localhost:5432/fittrack_test?schema=public"
pnpm --filter @fittrack/api db:push

# 3) Test DB'sini test koşumlarında kullan
$env:DATABASE_URL_TEST = "postgresql://postgres:postgres@localhost:5432/fittrack_test?schema=public"
pnpm test:api
```

Test setup'ı her testten önce User + Club tablolarını CASCADE truncate eder; Exercise tablosu (referans veri) korunur ve boşsa otomatik seed'lenir.

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
