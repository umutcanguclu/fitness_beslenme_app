# CONTEXT.md — Claude Code / Cursor için çalışma talimatları

> Bu dosya, AI agent'lar bu projede çalışırken her oturumda okunur. Mimari, kurallar, kod stilini tanımlar.

---

## Proje: fittrack

Alt lig (TFF 2./3. Lig, BAL, bölgesel amatör) ve akademi (U13–U21) **futbol antrenörleri** için "antrenör + oyuncu" platformu. Antrenör oyuncu profillerini ve kulüp kaynaklarını girer; **kural tabanlı engine** her oyuncuya haftalık antrenman programı üretir. Oyuncu telefonundan programını görür, RPE / katılım girer.

Vizyon ve kapsam için `GDD.md`. Bu **bir genel fitness app'i değil** — geçmişte FitTrack adıyla başlayıp futbol odağına döndürüldü. Eski fitness kodu `apps/api/_archive/` ve `packages/shared/_archive/` altında, referans için duruyor — silme.

## Hedef kullanıcı gerçekliği (HER kararda buna göre düşün)

- Alt lig kulübünde antrenör tek başına: TD + fitness koçu + analist.
- Bütçe yok: GPS yelek, biyometrik tracker, fizyoterapist YOK. Veri MANUEL.
- Gym genelde yok ya da çok sınırlı; programlar bodyweight + saha ağırlıklı olabilmeli.
- Saha günde 1.5–2 saat, akşam, kötü zemin, kış aylarında ışık problemi.
- Kadro heterojen: 17–35 yaş, yarı pro + amatör + iş yoğun oyuncular bir arada.
- Bir koç çoğunlukla 2–3 yaş kategorisi çalıştırır.
- WhatsApp birinci iletişim kanalı; PDF/görsel paylaşım kritik.
- Türkçe BİRİNCİ dil, sade UI, mobile-first, offline tolerant.
- Premier League / elit kulüp varsayımı YAPMA. Sensör/wearable/AI taktik analizi KAPSAM DIŞI.

## Mimari

```
fittrack/
├── apps/
│   └── api/                          # Fastify + Prisma + Postgres
│       ├── src/
│       │   ├── routes/               # Fastify route handler'lar (thin)
│       │   ├── services/             # business logic
│       │   │   ├── auth.service.ts
│       │   │   └── program-engine/   # kural tabanlı program üretici
│       │   ├── repositories/         # Prisma wrapper'lar
│       │   ├── plugins/              # auth plugin (requireAuth hook)
│       │   ├── lib/                  # env, errors, prisma, password, tokens
│       │   ├── app.ts                # Fastify build
│       │   └── server.ts             # entrypoint
│       ├── prisma/
│       │   ├── schema.prisma
│       │   ├── seed.ts
│       │   └── seed/exercises.ts     # ~190 futbol egzersizi (idempotent upsert)
│       └── test/                     # vitest (lib + entegrasyon testleri)
├── packages/
│   └── shared/                       # @fittrack/shared
│       └── src/schemas/              # Zod schemas (.ts olarak doğrudan export, build yok)
│           ├── enums.schema.ts
│           ├── user.schema.ts
│           ├── club.schema.ts
│           ├── player.schema.ts
│           ├── exercise.schema.ts
│           ├── program.schema.ts
│           ├── match.schema.ts
│           └── performance.schema.ts
└── _archive (apps/api/, packages/shared/) — eski FitTrack kodu, silme
```

## Stack (kesinleşmiş)

- Node.js 20+, pnpm 10+ workspace
- Fastify 5 + TypeScript strict mode + Prisma 5.22 + PostgreSQL 17
- JWT access + refresh, bcrypt, plugins/auth.ts içinde `requireAuth` hook
- Zod (validation) — schemalar `@fittrack/shared`'dan, frontend ile paylaşılır
- Pino (logging), Vitest (test)
- Frontend stack kararı VERİLMEDİ. UI kodu yazma.

## DB (Postgres lokal)

- Servis: `"C:\Program Files\PostgreSQL\17\bin\pg_ctl.exe" -D "$env:USERPROFILE\dev\pgdata" start`
- DB: `fittrack` (bağlantı: `apps/api/.env` içinde `DATABASE_URL`)
- Schema PUSH edildi, ~190 egzersiz seed'lendi
- Yeni migration: `prisma migrate dev --name <ad>` (artık prod'a yaklaşıyoruz, history isteriz)
- Prisma binary (pnpm yoksa): `apps/api/node_modules/.bin/prisma.cmd`
- DB'yi reset etme — seed'lenmiş egzersizleri koru. Seed `upsert` ile idempotent; yeniden çalıştırmak güvenli.

## Engine (apps/api/src/services/program-engine/)

Kural tabanlı, ML YOK, şeffaf if-else. Versiyon: `rule_engine_v1`.

**Akış** (`index.ts` → `generateProgram`):
1. `loadPlayerSnapshot` → yaş + mevki + boy/kilo + son availability + aktif sakatlıklar
2. `loadClubResources` → ekipman + tesis → `availableLocations` (`bodyweight_anywhere` ve `home` her zaman açık)
3. `loadMatchContext` → bu hafta maç var mı, hangi gün
4. `planWeek` → 7 günlük (kategori + intensity 1-5 + süre + isOff) iskelet
   - `match_week`: MD-3 yüksek hacim, MD-2 yüksek şiddet, MD-1 hafif teknik+set_piece, MD off, MD+1 recovery
   - `generic_week`: Pzt güç, Salı sürat+teknik, Çar recovery, Per plio+SSG vs.
   - Availability adjustment: `injured/ill/away` → off; `doubtful` → %60 yük + low impact; `limited` → %75 yük; aktif sakatlık → `plyometric` ve `sprint_agility` çıkar
5. Her gün için `selectExercisesForCategory`:
   - kategori eşleşir + yaş aralığı + mevki (boş ya da içeriyor)
   - `requiredEquipment ⊆ club.equipment` (AND)
   - `locations ∩ availableLocations ≠ ∅`
   - Aynı egzersiz hafta içinde tekrar etmez
6. `toSelectedExercise` → defaults uygular + günün şiddetine göre set sayısı modüle eder
7. `GeneratedProgram` döner. DB yazımı: `program-writer.ts`

**Versiyonlama**: `ENGINE_VERSION = 'rule_engine_v1'`. Kural değişikliklerinde versiyon bumplanır; eski programlar audit için `generationInputs` JSON snapshot ile saklanır.

Kalibrasyon notları: `apps/api/src/services/program-engine/README.md`.

## Kod kuralları

### TypeScript
- `strict: true` zorunlu. `any` kullanma, `unknown` tercih et.
- Paylaşımlı tipler `packages/shared/src/types/`, şemalar `packages/shared/src/schemas/`.
- Zod şemalarından tip türet: `export type X = z.infer<typeof XSchema>`.

### Backend katmanları
- Route handler'lar **thin**: Zod parse + service çağrısı + reply, başka mantık yok.
- Business logic → service layer.
- DB erişimi → repository layer (Prisma wrap).
- Hatalar: `AppError` class (`apps/api/src/lib/errors.ts`) — `validation/unauthorized/forbidden/notFound/conflict/internal` factory'leri var.
- Validation: tüm input'larda `@fittrack/shared` Zod schema parse et.

### Naming
- TypeScript: `camelCase` dosya, `PascalCase` sınıf, Zod şemaları `XxxSchema`, tipler `Xxx`.

### Yetkilendirme kuralları (CRUD'lar yazılırken)
- `coach`: kendi kulübünün kapsamı dışına çıkamaz (Club/Team/Player/Facility/Equipment/Match/Program).
- `coach`: `isClubAdmin === true` ise kulüp ayarlarına yazabilir; değilse sadece okuyabilir + kendi takımlarına dair işlem yapar.
- `player`: sadece kendi `Player` profilini, kendi `Programları`nı, kendi `SessionLog/Attendance`'ını görür/yazar.
- `requireAuth` hook + ek role check serviste yapılır.

## Dil ve lokalizasyon

- Hata mesajları, kullanıcıya dönen metinler **Türkçe**.
- Logging mesajları İngilizce (operasyonel).
- Kod yorumları İngilizce.

## Test politikası

- Backend: kritik service için unit test (Vitest), endpoint happy path için entegrasyon testi.
- Test DB stratejisi: ya ayrı schema ya transaction-rollback per test. `apps/api/test/lib/{password,tokens}.test.ts` saf unit, dokunma.
- TS strict + Zod ilk savunma hattı.

## Git workflow

- Ana branch: `main`. Feature: `feat/xxx`, fix: `fix/xxx`.
- Commit: Conventional Commits (`feat:`, `fix:`, `chore:`, `refactor:`).
- `.gitignore`: `node_modules`, `.env`, `dist`, `*.iml`, `logs/`, `.dart_tool/` (bekletici).

## Environment

- `.env` ASLA commit edilmez. `.env.example` her zaman güncel.
- Secrets: `DATABASE_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET`.
- Agent kuralı: `.env` veya secret dosyalarını okuma/yazma.

## Agent davranış kuralları

1. **Asla otomatik `git push` yapma.** Commit'e kadar olur, push'u kullanıcı yapar.
2. **`.env` veya secret dosyalarını okuma/yazma.**
3. **Büyük refactor'ları parçalara böl.** Tek PR'da 500+ satır değişiklik yapma.
4. **Yeni dependency eklerken sor.** `pnpm add` öncesi gerekçeyi açıkla.
5. **Dil:** Kod yorumları İngilizce, commit mesajları İngilizce, kullanıcıya cevaplar Türkçe.
6. **Platform:** Geliştirici Windows. PowerShell'de native exe'lere `2>&1` kullanma; stderr zaten yakalanır. Bash'te `&&` çalışır, CMD'de chain'leri ayır.
7. **Üretim kalitesi:** "TODO" ve placeholder bırakma. Bilmiyorsan sor.
8. **DB reset / migration etmeden önce sor.** Seed'lenmiş egzersizleri koru.
9. **Yorum minimum.** Sadece WHY açıklayan satırlar. İsimler kendini açıklar.
10. **`_archive/` altına dokunma.** Referans için duruyor.
11. **Yeni .md oluşturma.** Mevcut README/GDD/CONTEXT'i gerekirse güncelle.
12. **Frontend stack yok.** UI kodu yazma. API + engine + test odakla.
