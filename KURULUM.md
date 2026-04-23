# Başlangıç Kılavuzu — FitTrack Projesi

Bu dosya, projeyi sıfırdan ayağa kaldırmak için adım adım rehberdir. Her komutu sırayla Windows CMD'de çalıştır.

---

## 0. Ön gereksinimler

Kontrol et, eksikse yükle:

```cmd
node --version
```
→ v20.x veya üstü olmalı. Yoksa https://nodejs.org

```cmd
npm install -g pnpm
pnpm --version
```
→ pnpm 9+ olmalı.

```cmd
git --version
```

PostgreSQL (backend için, sonradan da kurabilirsin):
- Lokal geliştirme için: https://www.postgresql.org/download/windows/ (pgAdmin de gelir)
- Alternatif: Docker Desktop + `docker run postgres` (daha temiz)

Expo için:
- Telefonuna **Expo Go** uygulamasını indir (App Store / Play Store) → geliştirme sırasında QR kod ile tarayarak uygulamayı canlı test edeceksin.

---

## 1. Projeyi GitHub'a bağla

```cmd
cd C:\Projects
mkdir fitness-app
cd fitness-app
git init
git branch -M main
```

(GitHub'da boş bir repo aç, remote ekle — `git remote add origin ...`)

GDD.md ve CONTEXT.md dosyalarını bu klasöre koy (indirilen dosyalar).

---

## 2. Monorepo iskeleti

```cmd
echo packages: > pnpm-workspace.yaml
echo   - "apps/*" >> pnpm-workspace.yaml
echo   - "packages/*" >> pnpm-workspace.yaml
```

`package.json` (kök):
```json
{
  "name": "fittrack",
  "private": true,
  "version": "0.1.0",
  "scripts": {
    "dev:api": "pnpm --filter api dev",
    "dev:mobile": "pnpm --filter mobile start",
    "build": "pnpm -r build",
    "lint": "pnpm -r lint",
    "typecheck": "pnpm -r typecheck"
  },
  "devDependencies": {
    "typescript": "^5.6.0",
    "prettier": "^3.3.0"
  }
}
```

`tsconfig.base.json`:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "isolatedModules": true
  }
}
```

```cmd
mkdir apps
mkdir apps\api
mkdir apps\mobile
mkdir packages
mkdir packages\shared
mkdir packages\exercise-db
```

---

## 3. Backend iskeleti (apps/api)

```cmd
cd apps\api
pnpm init
```

```cmd
pnpm add fastify @fastify/cors @fastify/jwt @fastify/helmet
pnpm add @prisma/client bcrypt zod pino pino-pretty dotenv
pnpm add -D typescript tsx @types/node @types/bcrypt prisma vitest
```

```cmd
npx prisma init
```

`apps/api/src/server.ts` için Claude Code'a prompt vereceğiz (aşağıda).

---

## 4. Mobile iskeleti (apps/mobile)

Köke dön, Expo projesini oluştur:

```cmd
cd ..\..
pnpm create expo-app apps/mobile --template default
cd apps\mobile
```

```cmd
pnpm add nativewind zustand @tanstack/react-query react-hook-form zod @hookform/resolvers
pnpm add i18next react-i18next expo-localization
pnpm add react-native-mmkv victory-native
pnpm add -D tailwindcss
```

Expo Router Expo SDK 54+ ile zaten default geliyor.

---

## 5. İlk Claude Code oturumu

`fitness-app` klasörünün içinde:

```cmd
claude
```

**İlk komut (sana önerdiğim prompt):**

```
Oku: CONTEXT.md ve GDD.md.

Bu projede Faz 0'dayız. Görevlerin:

1. Monorepo yapısını kur: pnpm-workspace.yaml, tsconfig.base.json,
   kök package.json (yukarıdaki spec'e göre).
2. packages/shared iskeletini oluştur: Zod şemaları için yer hazırla,
   User ve Workout için başlangıç şemalarını yaz.
3. apps/api iskeletini kur: Fastify + TypeScript + health endpoint.
   Prisma schema.prisma'da User ve Workout modelleri.
4. apps/mobile için NativeWind config + i18n kurulumu.
5. README.md yaz.

Her adımı bittiğinde dur ve onay iste. Commit mesajlarını sen hazırla
ama `git commit` komutunu çalıştırma — sadece öner.
```

---

## 6. Exercise DB hazırlama (paralel)

Bu adımı Claude Code'a delege edebilirsin:

```
packages/exercise-db içinde:

1. wger.de public API'sinden egzersiz listesini çek.
   URL: https://wger.de/api/v2/exerciseinfo/?language=2&limit=200
2. Türkçe çevirileri için language=14 parametresini dene, yoksa
   İngilizce isimle bırak.
3. Her egzersizi şu schema'ya dönüştür:
   { id, nameEn, nameTr, muscleGroup[], equipment[], type }
4. Sonucu exercises.json olarak yaz.
5. src/index.ts'te typed export et.
```

---

## 7. Faz 1 için prompt'lar (sırayla)

### 7.1 Auth endpoint'leri
```
apps/api'de auth sistemini kur:
- POST /auth/register (email, password, name)
- POST /auth/login
- POST /auth/refresh
- GET /auth/me (protected)

bcrypt ile hash, JWT access (15dk) + refresh (7gün).
Zod ile input validate. Error handling AppError class ile.
packages/shared'daki User schema'sını kullan.
```

### 7.2 Mobile auth akışı
```
apps/mobile'da auth akışını kur:
- (auth) group: login, register ekranları
- (tabs) group: dashboard, workouts, exercises, progress, profile
- Zustand auth store (token persistence: MMKV)
- AuthGuard: giriş yapmamış kullanıcı (auth) grubuna yönlenir
- TanStack Query + fetch wrapper (auth header auto-inject)
- Form validation: React Hook Form + Zod
- i18n anahtarlarıyla tüm metinler
```

### 7.3 Workout CRUD
```
Backend:
- GET /workouts (kullanıcının workout'ları, pagination)
- POST /workouts (yeni workout başlat)
- PATCH /workouts/:id (finish, notes)
- POST /workouts/:id/sets (set ekle)
- DELETE /workouts/:id

Mobile:
- Active workout ekranı (Zustand'da aktif workout state)
- Egzersiz seçim modal (exercise-db'den arama)
- Set ekleme formu (weight/reps veya time/distance)
- Rest timer component
- Workout geçmişi ekranı
```

---

## 8. Deployment (Faz 1 sonrası)

Google Cloud e2-micro'ya backend deploy:
```
Claude Code'a sor:
"Backend için Google Cloud Compute Engine deployment kılavuzu yaz.
PM2 ecosystem.config.js, nginx reverse proxy, Let's Encrypt SSL,
GitHub Actions CI/CD. fittrack-api.your-domain.com subdomain'i için."
```

Mobile için:
- Development: Expo Go ile QR
- Internal testing: EAS Build + TestFlight / Play Internal
- Store: sonraki milestone

---

## İpuçları

- Her Claude Code oturumu başında "CONTEXT.md'yi oku" de.
- Büyük feature'ları tek seferde istemektense 2-3 alt adıma böl.
- `pnpm typecheck` ve `pnpm lint` sık çalıştır.
- Commit'leri küçük tut, her commit build edilebilir olsun.
- Mobile test için gerçek telefonu USB ile bağla, Expo Go yeterli.

Başarılar. Takıldığın noktada bir sonraki prompt'u birlikte tasarlayabiliriz.
