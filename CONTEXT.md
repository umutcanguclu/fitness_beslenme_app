# CONTEXT.md — Claude Code Çalışma Talimatları

> Bu dosya, Claude Code ve Cursor gibi AI agent'lar tarafından bu projede çalışırken okunur. Projenin mimarisi, kuralları ve kod stilini tanımlar. Her oturumda bu dosyayı tekrar oku.

---

## Proje: FitTrack

Kapsamlı mobil fitness takip uygulaması. Detay için `GDD.md` dosyasına bak.
**Mimari:** Hibrit monorepo — `apps/mobile` (Flutter/Dart) + `apps/api` (Fastify/TS) + `packages/shared` + `packages/exercise-db`. Backend ve paketler pnpm workspace'inde; mobile tarafı bağımsız bir Flutter projesi (pub ile bağımlılık yönetir).

## Stack (kesinleşmiş, değiştirme)

**Mobile:** Flutter 3.41+ · Dart 3.11+ · Material 3 · Riverpod 2 · go_router · dio · freezed + json_serializable · flutter_localizations + intl (ARB) · flutter_secure_storage · shared_preferences · fl_chart · google_fonts
**Backend:** Node.js 20+ · Fastify · TypeScript · Prisma · PostgreSQL · JWT · Zod · Pino
**Tooling:** pnpm (backend + paketler) · Flutter CLI (mobile) · ESLint · Prettier · TypeScript strict mode · `flutter analyze` + `dart format`

## Dil ve lokalizasyon

- **Kullanıcıya gösterilen tüm metinler i18n anahtarları üzerinden gelir.** Widget ağacında veya string birleştirmelerde ham Türkçe/İngilizce metin kullanma.
- Kaynak diller: `en` (base) ve `tr`.
- Çeviri dosyaları: `apps/mobile/lib/l10n/app_{en,tr}.arb` — `flutter gen-l10n` ile `AppLocalizations` sınıfı üretilir.
- Her yeni feature için hem `app_en.arb` hem `app_tr.arb` güncellenmeli — biri eksikse kod review'da reddet.
- Tarih/sayı formatları `intl` (DateFormat, NumberFormat) üzerinden `Locale.languageCode`'a göre; hard-code etme.

## Kod kuralları

### TypeScript
- `strict: true` zorunlu. `any` kullanma, `unknown` tercih et.
- Paylaşımlı tipler `packages/shared/src/types/` altında.
- Zod şemalarından tip türet: `export type User = z.infer<typeof UserSchema>`.

### Dosya organizasyonu
- Mobile: feature-based klasörleme (`lib/features/workouts/...` gibi), tip-based değil.
- Her feature klasörü: `data/` (api + repository), `domain/` (modeller + validasyon), `presentation/` (ekranlar + widget'lar + controller'lar), `providers.dart` (Riverpod provider export'ları).
- Backend: route → controller → service → repository katmanları ayrı.

### Naming (Dart / Flutter)
- Dosyalar: `snake_case.dart` (Dart resmi stili).
- Sınıflar / enum'lar / typedef: `PascalCase`.
- Değişkenler, metodlar, fonksiyonlar: `lowerCamelCase`.
- Sabitler: `lowerCamelCase` (`const kApiTimeout = ...`) — `SCREAMING_SNAKE_CASE` kullanma, bu JS/TS geleneği.
- Freezed modelleri: `WorkoutModel`, `AuthState` gibi; JSON adapter dosyaları codegen tarafından üretilir (`*.freezed.dart`, `*.g.dart` — commit edilir).
- Riverpod provider'lar: `xxxProvider` (`authControllerProvider`, `workoutRepositoryProvider`).

### Naming (Backend — değişmedi)
- TypeScript: camelCase dosya, PascalCase sınıf, Zod şemaları `XxxSchema`.

### State management (Flutter)
- **Tüm async veri (server state dahil)** → Riverpod `AsyncNotifier` / `FutureProvider` / `StreamProvider`. Cache + invalidation Riverpod'un `ref.invalidate` / `ref.refresh` ile yönetilir.
- **Client UI state** (auth, theme, active workout) → Riverpod `Notifier` / `AsyncNotifier`.
- Widget lokal state → `StatefulWidget` + `setState` (küçük UI detayları için).
- Inherited widget elle yazma — Riverpod bunun yerine geçiyor.

### Styling (Flutter)
- `ThemeData` (Material 3) + özel `ThemeExtension` ile token'lar: `primary`, `accent`, `background`, `surface`, `border`, `text`, `textMuted`, `textDim`.
- Renk / tipografi değerleri hard-code edilmez — `Theme.of(context).extension<FitTrackColors>()!` üzerinden okunur.
- Koyu tema default; light tema ileri fazda.
- Stil dağılımı için `const TextStyle` / `Container` içinde magic sayı yerine `Theme.of(context).textTheme` + extension.

### Forms
- Her form: `Form` widget + `TextFormField` + `FormFieldValidator`.
- Validasyon kuralları `lib/core/validation/` altında saf Dart fonksiyonlar; mesajlar `AppLocalizations` anahtarı döndürür.
- Backend ile paylaşım yok (Zod şemaları sadece backend'de) — mobilde kurallar elle tutulur; değişiklik olduğunda iki tarafı birlikte güncelle.

### API katmanı (mobile)
- Tüm backend çağrıları `lib/core/api/api_client.dart` üzerinden — dio instance + auth interceptor + refresh interceptor.
- Feature'a özgü endpoint'ler `lib/features/<feature>/data/<feature>_api.dart`, repository `<feature>_repository.dart`.
- Riverpod provider'ları `providers.dart` dosyasında toplanır; UI doğrudan repository'ye değil, provider'a bakar.

### Backend
- Route handler'lar thin — sadece input parse + service çağrısı.
- Business logic → service layer.
- DB erişimi → repository layer (Prisma wrap).
- Her endpoint Zod ile input/output validate eder.
- Error handling: custom `AppError` class, Fastify error handler yakalar.

## Git workflow

- Ana branch: `main`. Feature'lar: `feat/xxx`, fix'ler: `fix/xxx`.
- Commit mesajları: Conventional Commits (`feat:`, `fix:`, `chore:`, `refactor:`).
- **Büyük dosyalar commit etme.** `.gitignore`: `node_modules`, `.env`, `*.keystore`, `ios/Pods`, `android/build`, `android/.gradle`, `dist`, `build/` (Flutter), `.dart_tool/`, `.flutter-plugins*`, `*.iml`.

## Environment

- `.env` dosyaları asla commit edilmez. `.env.example` her zaman güncel tutulur.
- Secret'lar: JWT_SECRET, DATABASE_URL, REFRESH_SECRET.
- Mobile env: `apps/mobile/.env` — `--dart-define-from-file=.env` ile build sırasında inject edilir. Runtime okuması `String.fromEnvironment('API_URL', defaultValue: ...)` ile.

## Test politikası (MVP aşamasında hafif)

- Backend: kritik service fonksiyonları için unit test (Vitest). Endpoint happy path testi.
- Mobile: MVP'de test yazma, Faz 2'den sonra ekle (`flutter_test` + `mocktail`).
- TypeScript strict + Zod (backend) ve Dart null safety + freezed (mobile) ilk savunma hattı.

## Agent davranış kuralları

1. **Asla otomatik `git push` yapma.** Commit'e kadar olur, push'u kullanıcı yapar.
2. **Asla `.env` veya secret dosyalarını okuma/yazma.**
3. **Büyük refactor'ları parçalara böl.** Tek bir PR'da 500+ satır değişiklik yapma.
4. **Yeni dependency eklerken sor.** `pnpm add` veya `flutter pub add` koşmadan önce gerekçesini açıkla.
5. **Dil talimatı:** Kod yorumları İngilizce, commit mesajları İngilizce, ama kullanıcıya (Garrosh'a) cevaplar Türkçe.
6. **Platform:** Geliştirici Windows CMD kullanıyor. `&&` yerine ayrı komutlar ver, gerekirse `.bat` dosyaları öner.
7. **Üretim kalitesi:** Placeholder veya "TODO" bırakma. Bir şeyi bilmiyorsan sor, uydurma.
8. **Exercise DB:** `packages/exercise-db/src/exercises.json` tek gerçek kaynak. Mobile build zamanı bu dosyayı `apps/mobile/assets/exercises.json` olarak kopyalar (pubspec'te asset referansı). Kodun içinde egzersiz listesi tanımlama.
9. **Codegen dosyaları commit edilir.** `*.freezed.dart`, `*.g.dart`, `AppLocalizations` çıktıları git'te tutulur — CI'de yeniden üretme maliyetini kaldırır.

## Klasör haritası (hedef)

```
fitness-app/
├── apps/
│   ├── mobile/                     # Flutter app
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── core/
│   │   │   │   ├── api/            # dio client, interceptors
│   │   │   │   ├── router/         # go_router config + guards
│   │   │   │   ├── storage/        # secure + prefs wrappers
│   │   │   │   ├── theme/          # ThemeData + ThemeExtension
│   │   │   │   ├── validation/     # reusable validators
│   │   │   │   └── env.dart        # compile-time env
│   │   │   ├── features/           # auth, workouts, exercises, progress, profile
│   │   │   └── l10n/               # app_en.arb, app_tr.arb (+ generated)
│   │   ├── assets/                 # fonts, exercises.json mirror
│   │   ├── android/
│   │   ├── ios/
│   │   ├── l10n.yaml
│   │   └── pubspec.yaml
│   └── api/
│       ├── src/
│       │   ├── routes/             # Fastify route handlers
│       │   ├── services/           # business logic
│       │   ├── repositories/       # Prisma wrappers
│       │   ├── lib/                # auth, errors, logger
│       │   └── server.ts
│       ├── prisma/
│       │   └── schema.prisma
│       └── package.json
├── packages/
│   ├── shared/
│   │   └── src/
│   │       ├── schemas/            # Zod schemas (User, Workout, Set, ...)
│   │       └── types/
│   └── exercise-db/
│       ├── src/exercises.json
│       └── src/index.ts            # Typed export (backend consumer)
├── CONTEXT.md
├── GDD.md
├── README.md
├── package.json                    # backend + paketler (pnpm workspace root)
├── pnpm-workspace.yaml
└── tsconfig.base.json
```

## MVP Yol Haritası (aktif faz)

**Şu anda:** Faz 0 — Proje kurulumu
**Sonraki:** Faz 1 — Auth + Exercise Library + Workout CRUD

Her görev tamamlandığında bu dosyadaki checkbox'lar güncellenir.
