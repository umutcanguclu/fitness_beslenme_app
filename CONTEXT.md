# CONTEXT.md — Claude Code Çalışma Talimatları

> Bu dosya, Claude Code ve Cursor gibi AI agent'lar tarafından bu projede çalışırken okunur. Projenin mimarisi, kuralları ve kod stilini tanımlar. Her oturumda bu dosyayı tekrar oku.

---

## Proje: FitTrack

Kapsamlı mobil fitness takip uygulaması. Detay için `GDD.md` dosyasına bak.
**Mimari:** pnpm monorepo — `apps/mobile` (Expo RN) + `apps/api` (Fastify) + `packages/shared` + `packages/exercise-db`.

## Stack (kesinleşmiş, değiştirme)

**Mobile:** Expo SDK 54+ · Expo Router · TypeScript · NativeWind · Zustand · TanStack Query · React Hook Form + Zod · i18next · MMKV
**Backend:** Node.js 20+ · Fastify · TypeScript · Prisma · PostgreSQL · JWT · Zod · Pino
**Tooling:** pnpm · ESLint · Prettier · TypeScript strict mode

## Dil ve lokalizasyon

- **Kullanıcıya gösterilen tüm metinler i18next anahtarları üzerinden gelir.** Hiçbir zaman JSX veya template'te ham string kullanma.
- Kaynak diller: `en` (base) ve `tr`.
- Çeviri dosyaları: `apps/mobile/src/i18n/locales/{en,tr}/*.json`
- Her yeni feature için hem `en.json` hem `tr.json` güncellenmeli — biri eksikse kod review'da reddet.
- Tarih/sayı formatları `expo-localization` üzerinden, hard-code etme.

## Kod kuralları

### TypeScript
- `strict: true` zorunlu. `any` kullanma, `unknown` tercih et.
- Paylaşımlı tipler `packages/shared/src/types/` altında.
- Zod şemalarından tip türet: `export type User = z.infer<typeof UserSchema>`.

### Dosya organizasyonu
- Mobile: feature-based klasörleme (`src/features/workouts/...` gibi), teknoloji-based değil (`src/components/`, `src/hooks/` ayrımı yok).
- Her feature klasörü: `components/`, `hooks/`, `api/`, `types.ts`, `index.ts` export'u.
- Backend: route → controller → service → repository katmanları ayrı.

### Naming
- React componentleri: `PascalCase.tsx`
- Hook'lar: `useXxx.ts`
- Utils: `camelCase.ts`
- Sabitler: `SCREAMING_SNAKE_CASE` (ayrı bir `constants.ts` dosyasında)
- Zod şemaları: `XxxSchema` (örn: `WorkoutSchema`)

### State management
- **Server state** → TanStack Query (invalidation + cache + retry)
- **Client UI state** → Zustand (auth, theme, active workout)
- Component state → useState (küçük local state için)
- React Context sadece theme provider için

### Styling (NativeWind)
- Tüm stiller Tailwind class'ları ile.
- Tema token'ları `tailwind.config.js` içinde: `primary`, `accent`, `background`, `surface`, `text`.
- Inline `style={{}}` kullanma, sadece dinamik width/animated değerler için.
- Dark mode default, `useColorScheme` ile dinamik.

### Forms
- Her form: React Hook Form + Zod resolver.
- Validation şemaları `packages/shared` içinden import edilir (backend ile aynı).
- Error mesajları i18next anahtarı döndürür.

### API katmanı (mobil)
- Tüm backend çağrıları `src/lib/api/` altında, her feature kendi dosyası (`workouts.api.ts`).
- TanStack Query hook'ları `use-xxx-query.ts` / `use-xxx-mutation.ts` olarak ayrı.
- Axios yerine `fetch` + ince wrapper. Auth header otomatik inject.

### Backend
- Route handler'lar thin — sadece input parse + service çağrısı.
- Business logic → service layer.
- DB erişimi → repository layer (Prisma wrap).
- Her endpoint Zod ile input/output validate eder.
- Error handling: custom `AppError` class, Fastify error handler yakalar.

## Git workflow

- Ana branch: `main`. Feature'lar: `feat/xxx`, fix'ler: `fix/xxx`.
- Commit mesajları: Conventional Commits (`feat:`, `fix:`, `chore:`, `refactor:`).
- **Büyük dosyalar commit etme.** `.gitignore`: `node_modules`, `.env`, `*.keystore`, `ios/Pods`, `android/build`, `dist`, `.expo`.

## Environment

- `.env` dosyaları asla commit edilmez. `.env.example` her zaman güncel tutulur.
- Secret'lar: JWT_SECRET, DATABASE_URL, REFRESH_SECRET.
- Mobile env: `EXPO_PUBLIC_API_URL` prefix'i (Expo kuralı).

## Test politikası (MVP aşamasında hafif)

- Backend: kritik service fonksiyonları için unit test (Vitest). Endpoint happy path testi.
- Mobile: MVP'de test yazma, Faz 2'den sonra ekle.
- Type safety + Zod validation zaten ilk savunma hattı.

## Agent davranış kuralları

1. **Asla otomatik `git push` yapma.** Commit'e kadar olur, push'u kullanıcı yapar.
2. **Asla `.env` veya secret dosyalarını okuma/yazma.**
3. **Büyük refactor'ları parçalara böl.** Tek bir PR'da 500+ satır değişiklik yapma.
4. **Yeni dependency eklerken sor.** `pnpm add` koşmadan önce gerekçesini açıkla.
5. **Dil talimatı:** Kod yorumları İngilizce, commit mesajları İngilizce, ama kullanıcıya (Garrosh'a) cevaplar Türkçe.
6. **Platform:** Geliştirici Windows CMD kullanıyor. `&&` yerine ayrı komutlar ver, gerekirse `.bat` dosyaları öner.
7. **Üretim kalitesi:** Placeholder veya "TODO" bırakma. Bir şeyi bilmiyorsan sor, uydurma.
8. **Exercise DB:** `packages/exercise-db/exercises.json` tek gerçek kaynak. Kodun içinde egzersiz listesi tanımlama.

## Klasör haritası (hedef)

```
fitness-app/
├── apps/
│   ├── mobile/
│   │   ├── app/                    # Expo Router rotaları
│   │   ├── src/
│   │   │   ├── features/           # workouts, exercises, progress, auth, profile
│   │   │   ├── lib/                # api client, storage, utils
│   │   │   ├── i18n/               # locales, config
│   │   │   ├── stores/             # Zustand stores
│   │   │   └── theme/              # tailwind config, tokens
│   │   ├── app.config.ts
│   │   └── package.json
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
│       ├── exercises.json
│       └── src/index.ts            # Typed export
├── CONTEXT.md
├── GDD.md
├── README.md
├── package.json
├── pnpm-workspace.yaml
└── tsconfig.base.json
```

## MVP Yol Haritası (aktif faz)

**Şu anda:** Faz 0 — Proje kurulumu
**Sonraki:** Faz 1 — Auth + Exercise Library + Workout CRUD

Her görev tamamlandığında bu dosyadaki checkbox'lar güncellenir.
