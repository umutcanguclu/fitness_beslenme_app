# fittrack

> Alt lig + akademi futbol antrenörleri için **antrenör + oyuncu platformu**. Antrenör oyuncu profillerini ve kulüp kaynaklarını girer; **kural tabanlı engine** her oyuncuya haftalık antrenman programı üretir. Oyuncu telefonundan programını görür, RPE / katılım girer.

**Hedef kullanıcı gerçekliği:** Alt lig kulübünde tek başına antrenör (TD + fitness koçu + analist), bütçe yok (GPS yelek/wearable yok), saha 1.5–2 saat akşam, 17–35 yaş heterojen kadro, WhatsApp birinci iletişim. Premier League / wearable / AI taktik analizi **kapsam dışı**.

---

## 📦 İçindekiler

- [Stack](#stack)
- [Mimari](#mimari)
- [Özellikler](#özellikler)
- [Mobil ekranlar (rehberli tur)](#mobil-ekranlar-rehberli-tur)
- [Backend API endpoint'leri](#backend-api-endpointleri)
- [Engine](#engine)
- [Kurulum](#kurulum)
- [Test hesapları](#test-hesapları)
- [Geliştirme komutları](#geliştirme-komutları)
- [studio.bat — tek tıkla çalıştırma](#studiobat--tek-tıkla-çalıştırma)
- [Bilinen sınırlamalar](#bilinen-sınırlamalar)
- [Sonraki adımlar](#sonraki-adımlar)

---

## Stack

**Backend (apps/api):**
- Node.js 20+ · TypeScript strict mode · Fastify 5
- Prisma 5.22 · PostgreSQL 17
- JWT access + refresh · bcrypt
- Zod (`@fittrack/shared`'dan paylaşılan şema, frontend ile tip eşleşmesi)
- Pino (logging) · Vitest (test)

**Mobile (apps/mobile):**
- Flutter 3.41 · Dart 3.11
- Material 3 + Türkçe locale (`flutter_localizations`)
- Light + **Dark mode** (sistem ayarı + manuel toggle, persisted)
- HTTP: `dio` 5.x (auth interceptor + 401 → otomatik token refresh)
- Storage: `flutter_secure_storage` 10.x (Android Keystore'da token + tema)
- State management: yok — `StatefulWidget` + callback (basit yeterli)
- Android only (applicationId `app.fittrack`); iOS sonradan `flutter create --platforms=ios .` ile eklenir

**Workspace:** pnpm 10+ workspace (apps/* + packages/*)

---

## Mimari

```
fittrack/
├── apps/
│   ├── api/                            # Backend (Fastify)
│   │   ├── src/
│   │   │   ├── routes/                 # auth/clubs/teams/players/programs/matches/chat/...
│   │   │   ├── services/               # business logic (auth, club, team, player, program, match, chat, ...)
│   │   │   │   └── program-engine/     # kural tabanlı haftalık program üretici
│   │   │   ├── repositories/           # Prisma wrapper'lar
│   │   │   ├── plugins/auth.ts         # requireAuth hook
│   │   │   ├── lib/                    # env, errors, prisma, password, tokens
│   │   │   ├── app.ts                  # Fastify build
│   │   │   └── server.ts               # entrypoint
│   │   ├── prisma/
│   │   │   ├── schema.prisma
│   │   │   ├── seed.ts
│   │   │   └── seed/exercises.ts       # ~190 futbol egzersizi (idempotent upsert)
│   │   └── test/                       # vitest (lib unit + entegrasyon)
│   │
│   └── mobile/                         # Flutter (Android, applicationId: app.fittrack)
│       ├── lib/
│       │   ├── main.dart               # FittrackApp + theme state + role-based routing
│       │   ├── api/                    # 9 service + api_exception
│       │   │   ├── api_client.dart     # Dio + auth interceptor + 401 → refresh + retry
│       │   │   ├── api_exception.dart  # DioException → ApiException (Türkçe mesaj)
│       │   │   ├── auth_api.dart       # login/register/refresh/me/logout
│       │   │   ├── chat_api.dart       # threads/messages/send/read
│       │   │   ├── clubs_api.dart      # getMyClub/listFacilities/listEquipment
│       │   │   ├── health_api.dart     # availability + injuries + performance tests
│       │   │   ├── matches_api.dart    # CRUD + skor güncelleme
│       │   │   ├── players_api.dart    # getMyPlayer/getPlayer/updatePlayer
│       │   │   ├── programs_api.dart   # generate/list/logSession
│       │   │   └── teams_api.dart      # CRUD + roster + create/remove player
│       │   ├── models/                 # 11 Dart model (manuel JSON parse)
│       │   ├── screens/                # 20 ekran (login, home, club, team, player, program, ...)
│       │   ├── storage/                # token_storage (tokens + tema modu)
│       │   └── util/
│       │       ├── labels.dart         # 14 enum sözlüğü Türkçe
│       │       └── exercise_visuals.dart # kategori → ikon + renk + yoğunluk rengi
│       ├── pubspec.yaml                # 3 pub dep: dio + flutter_secure_storage + flutter_localizations
│       ├── android/                    # Android proje (cleartext HTTP dev için açık)
│       └── test/widget_test.dart
│
├── packages/
│   └── shared/                         # @fittrack/shared
│       └── src/schemas/                # Zod schemas (.ts olarak doğrudan export, build yok)
│           ├── enums.schema.ts         # tüm enum'lar (Prisma şemasıyla 1-1 senkron)
│           ├── user.schema.ts
│           ├── club.schema.ts
│           ├── player.schema.ts
│           ├── exercise.schema.ts
│           ├── program.schema.ts
│           ├── match.schema.ts
│           ├── performance.schema.ts
│           └── chat.schema.ts
│
├── studio.bat                          # Studio + AVD + flutter run zinciri
├── dev.bat                             # API dev runner (typecheck + vitest + start)
├── CONTEXT.md                          # AI agent çalışma kuralları
└── GDD.md                              # Eski FitTrack vizyonu (referans)
```

---

## Özellikler

### Antrenör akışı

| Alan | Durum | Açıklama |
|------|-------|----------|
| Auth | ✅ | Email + şifre kayıt/login, opsiyonel kulüp adıyla beraber kulüp oluşturma |
| Kulüp görüntüleme | ✅ | Kulüp bilgisi (ad, şehir, lig, kuruluş yılı) + tesisler + ekipman |
| Takım yönetimi | ✅ | Liste + Oluştur (ad, kategori U13-A Takımı, sezon) + Düzenle + Sil |
| Oyuncu yönetimi | ✅ | Roster + Oluştur (form 11 alan) + Düzenle (PATCH) + Kadrodan çıkar |
| **Davet kodu** | ✅ | Oyuncu oluşturulunca 8 karakter kod modal'da gösterilir (kopyala butonu, son kullanma) |
| Program üretme | ✅ | Engine ile **haftalık 7-günlük** plan otomatik üretimi |
| Program görüntüleme | ✅ | Expandable haftalık takvim, gün tıklayınca seans detayı |
| Seans detayı | ✅ | Egzersiz listesi + metric chip'leri (set×reps, dakika, mesafe, dinlenme, şiddet) + kategori-renkli görsel |
| Sakatlık kayıt | ✅ | Tür + şiddet + bölge + tarih + tahmini dönüş + açıklama; resolve butonu |
| Performans testi | ✅ | 17 test türü (sürat, çeviklik, dayanıklılık, kuvvet, esneklik, vücut yağı) + delta ve geçmiş |
| Hazırbulunuşluk görüntü | ✅ | Oyuncunun bildirdiği son 30 günlük durum (renkli kartlar) |
| Maç fikstürü | ✅ | Liste + Oluştur (rakip, tarih+saat, ev/deplasman, lig) + Skor güncelleme + Sil |
| **Mesajlaşma** | ✅ | Oyuncu ile birebir chat — 5s polling ile yarı-realtime, mesaj balonları, okundu işareti |
| Oyuncu istatistikleri | ✅ | RPE trendi (bar chart), antrenman dağılımı (kategori), hazırbulunuşluk dağılımı (son 30 gün) |

### Oyuncu akışı

| Alan | Durum | Açıklama |
|------|-------|----------|
| Davet ile kayıt | ✅ | Antrenörden aldığı kod + email + şifre + ad → otomatik login |
| Profil görüntüleme | ✅ | Forma no, mevki, takım üyeliği |
| Haftalık program | ✅ | Kendi programını okuma (üretemez) |
| Seans detayı | ✅ | Egzersiz listesi (görsel + metric'ler) |
| **RPE girişi** | ✅ | Antrenman sonrası: 1-10 efor + 1-5 yorgunluk + 1-5 mood + opsiyonel not |
| Hazırbulunuşluk | ✅ | Tarih + 7 durum seçeneği (Hazır/Şüpheli/Sınırlı/Sakat/Hasta/Cezalı/İzinli) + not |
| **Mesajlaşma** | ✅ | Antrenör ile chat (aynı thread, 5s polling) |
| İstatistikler | ✅ | Kişisel RPE trendi + antrenman dağılımı + hazırbulunuşluk özeti |

### Sistem geneli

| Alan | Durum | Açıklama |
|------|-------|----------|
| **Dark mode** | ✅ | 3 mod: Sistem / Açık / Koyu — `flutter_secure_storage`'da kalıcı |
| Türkçe i18n | ✅ | Tüm metin Türkçe + Türkçe date picker (`flutter_localizations`) |
| Modern UI | ✅ | Material 3 + custom theme (16dp card radius, 12dp button radius, gradient hero header'lar) |
| Token refresh | ✅ | 401 yakalanır → `/auth/refresh` → orijinal istek retry; refresh fail → otomatik logout |
| Hata yönetimi | ✅ | DioException → ApiException (Türkçe mesaj), her ekranda Loading/Error/Empty/Data |
| Pull-to-refresh | ✅ | Tüm liste ekranlarında |
| Settings | ✅ | Profil + tema seçici + uygulama bilgisi + güvenli logout |
| Animasyonlar | ✅ | Boot → login fade transition, FAB extended animation |

---

## Mobil ekranlar (rehberli tur)

> Tüm 20 ekran ve aralarındaki navigation. Sıralama tipik kullanım akışına göre.

### Auth

1. **LoginScreen** — fittrack başlık + email/şifre form + "Antrenör olarak kayıt ol" + "Davet kodum var (oyuncu)"
2. **RegisterScreen** — antrenör kaydı: ad/email/şifre + opsiyonel kulüp adı (varsa kulüp de otomatik açılır)
3. **PlayerRegisterScreen** — büyük monospace davet kodu alanı + ad/email/şifre

### Antrenör

4. **HomeScreen** — SliverAppBar hero (200px gradient, dekoratif daireler, avatar + "Hoş geldin"), iki büyük ActionCard (Kulübüm + Mesajlar), 4'lü mini grid (Programlar/Maçlar/Sakatlıklar/Performans hızlı erişim), AppBar'da ⚙ → Settings
5. **ClubScreen** — kulüp kartı (logo, ad, lig, şehir, kuruluş yılı), Takımlar/Tesisler/Ekipman bölümleri, "+ Takım" FAB, takım uzun-bas → menü (Düzenle/Sil)
6. **TeamCreateScreen** — ad + kategori dropdown + sezon (YYYY-YYYY format validation); aynı ekran edit modunda da kullanılır
7. **TeamDetailScreen** — takım meta + kadro (forma no'ya göre sıralı), AppBar'da ⚽ → Maçlar, "+ Oyuncu" FAB, oyuncu tıkla → bottom sheet (8 aksiyon: profil, programlar, istatistikler, sakatlıklar, performans, hazırbulunuşluk, mesaj, düzenle), uzun-bas → kadrodan çıkar
8. **PlayerCreateScreen** — 11 alanlı form (ad/doğum/mevki/detay mevki/ayak/boy/kilo/forma no/statü/email opsiyonel) → submit → davet kodu modal'ı (büyük monospace + 📋 kopyala + son kullanma)
9. **PlayerEditScreen** — sadece güncellenebilir alanlar (PATCH endpoint'ine uygun)
10. **MatchesScreen** — fikstür kartları (G/B/M renk rozetleri), "+ Maç" FAB modal (rakip/tarih/saat/ev-deplasman/lig), tıkla → skor güncelleme modal, uzun-bas → sil
11. **InjuriesScreen** — sakatlık kartları (aktif/iyileşmiş ayrımı), "+ Yeni" FAB modal, "Kapat" → resolve
12. **PerfTestsScreen** — gruplandırılmış kartlar (her test türü için en güncel + delta + son 5 geçmiş), "+ Test" FAB modal (17 test, default birim auto-fill)

### Oyuncu

13. **PlayerHomeScreen** — Hero'da büyük forma numarası dairesi + ad + mevki, 4 ActionCard (Programım, Hazırbulunuşluk, İstatistiklerim, Mesajlar)
14. **AvailabilityScreen** — bildirim formu (tarih + 7 durum + not) + son 30 günlük renkli liste

### Ortak

15. **ProgramViewScreen** — haftalık program kartları (expandable), gün satırlarında özet (kategori + tip + dakika + şiddet + log işareti), antrenörse "Bu haftaya üret" FAB
16. **SessionDetailScreen** — kategori-renkli gradient header (kategori + tarih) + 3 metric kutu (süre/şiddet/tip) + egzersiz listesi (gradient ikon kutu + index badge + metric chip'leri) + RPE form (oyuncu) veya log read-only kart (koç)
17. **PlayerStatsScreen** — 4 kartlık özet (toplam antrenman, dakika, ort RPE, geri bildirim oranı) + RPE trend bar chart + antrenman dağılımı (kategori bar'ları) + hazırbulunuşluk dağılımı
18. **ChatThreadsScreen** — thread listesi (avatar + son mesaj preview + unread badge + göreceli zaman "5dk")
19. **ChatRoomScreen** — WhatsApp-style mesaj balonları (mine=sağ yeşil, theirs=sol gri), klavye gönder, 5s polling, otomatik scroll-to-bottom, mark-read on open
20. **SettingsScreen** — profil kartı + tema seçici (3 selectable card) + uygulama bilgisi + logout (errorContainer rengi)

---

## Backend API endpoint'leri

> 36 endpoint, hepsi mobile'da tüketiliyor (chat dahil).

### Auth (`/auth/*`)
- `POST /register/coach` body `{email, password, fullName, clubName?}` → `{user, tokens}`
- `POST /register/player` body `{inviteCode, email, password, fullName}` → `{user, tokens}`
- `POST /login` body `{email, password}` → `{user, tokens}`
- `POST /login/code` body `{code}` → `{user, tokens}` (kalıcı PIN, oyuncu hızlı login için)
- `POST /refresh` body `{refreshToken}` → `{accessToken, refreshToken}`
- `POST /logout` body `{refreshToken}` → 204
- `GET /me` → User
- `GET /me/player` → `{playerId, player}` (oyuncunun kendi profil meta'sı)

### Clubs (`/clubs/*`)
- `POST /clubs` (coach) → Club
- `GET /clubs/me` (coach) → Club | null
- `PATCH /clubs/:clubId` (coach + admin)
- `GET/POST/DELETE /clubs/:clubId/facilities`
- `GET/POST/DELETE /clubs/:clubId/equipment`

### Teams (`/teams/*`)
- `GET /teams?includeInactive=` (coach) → Team[]
- `POST /teams` (coach) body `{name, category, season}`
- `GET/PATCH/DELETE /teams/:teamId`
- `GET /teams/:teamId/players` → roster (TeamPlayer + Player)
- `POST /teams/:teamId/players` → Player + invite
- `POST /teams/:teamId/players/:playerId` (mevcut oyuncuyu kadroya al)
- `DELETE /teams/:teamId/players/:playerId` (kadrodan çıkar)

### Players (`/players/*`)
- `GET /players/:playerId` (coach + own)
- `PATCH /players/:playerId` (coach only)
- `GET/POST /players/:playerId/availability`
- `GET/POST /players/:playerId/injuries`
- `PATCH /players/:playerId/injuries/:injuryId` (resolve, coach only)
- `GET/POST /players/:playerId/performance-tests`
- `GET /players/:playerId/programs?weekStartDate=&from=&to=`
- `POST /players/:playerId/programs/generate` (coach only)

### Sessions (`/sessions/*`)
- `GET/POST /sessions/:sessionId/attendance` (coach bulk)
- `GET /sessions/:sessionId/logs`
- `POST /sessions/:sessionId/log` (player only, kendi seansı)

### Matches (`/matches/*` + `/teams/:id/matches`)
- `GET /teams/:teamId/matches` → Match[]
- `POST /teams/:teamId/matches` body `{opponent, date, isHome, competition?, notes?}`
- `PATCH /matches/:matchId` (skor + diğer alanlar)
- `DELETE /matches/:matchId`

### Chat (`/chat/*`)
- `GET /chat/threads` → ChatThreadSummary[]
- `POST /chat/threads` (coach starts) body `{playerId}` → ChatThread
- `GET /chat/threads/:threadId/messages?before=&limit=` → ChatMessage[]
- `POST /chat/threads/:threadId/messages` body `{body}` → ChatMessage
- `POST /chat/threads/:threadId/read` → 204

### Health
- `GET /health` → `{status, uptimeSeconds, timestamp}`

---

## Engine

`apps/api/src/services/program-engine/` — **kural tabanlı**, ML yok, şeffaf if-else. Versiyon: `rule_engine_v1`.

**Akış** (`index.ts` → `generateProgram`):

1. `loadPlayerSnapshot` → yaş + mevki + boy/kilo + son availability + aktif sakatlıklar
2. `loadClubResources` → ekipman + tesis → `availableLocations` (`bodyweight_anywhere` ve `home` her zaman açık)
3. `loadMatchContext` → bu hafta maç var mı, hangi gün
4. `planWeek` → 7 günlük (kategori + intensity 1-5 + süre + isOff) iskelet
   - **match_week:** MD-3 yüksek hacim, MD-2 yüksek şiddet, MD-1 hafif teknik+set_piece, MD off, MD+1 recovery
   - **generic_week:** Pzt güç, Salı sürat+teknik, Çar recovery, Per plio+SSG vs.
   - **Availability adjustment:** `injured/ill/away` → off; `doubtful` → %60 yük + low impact; `limited` → %75 yük; aktif sakatlık → `plyometric` ve `sprint_agility` çıkar
5. Her gün için `selectExercisesForCategory`:
   - kategori eşleşir + yaş aralığı + mevki (boş ya da içeriyor)
   - `requiredEquipment ⊆ club.equipment` (AND)
   - `locations ∩ availableLocations ≠ ∅`
   - Aynı egzersiz hafta içinde tekrar etmez
6. `toSelectedExercise` → defaults uygular + günün şiddetine göre set sayısı modüle eder
7. `GeneratedProgram` döner. DB yazımı: `program-writer.ts`.

**Audit:** Eski programlar `TrainingProgram.generationInputs` JSON snapshot'ı ile saklanır. Kural değişikliklerinde versiyon bumplanır (`rule_engine_v2`).

Detaylı: [`apps/api/src/services/program-engine/README.md`](./apps/api/src/services/program-engine/README.md)

---

## Kurulum

### Ön gereksinimler

- Node.js 20+ (`.nvmrc`)
- pnpm 10+
- PostgreSQL 17 (lokal: `localhost:5432`, db: `fittrack`)
- Flutter 3.41+ / Dart 3.11+ (Android için)
- Android Studio + Android SDK + en az bir AVD

### İlk kurulum

```cmd
pnpm install
copy apps\api\.env.example apps\api\.env
```

`apps/api/.env` içine `JWT_SECRET`, `JWT_REFRESH_SECRET`, `DATABASE_URL` doldur.

### Postgres başlatma

```powershell
"C:\Program Files\PostgreSQL\17\bin\pg_ctl.exe" -D "$env:USERPROFILE\dev\pgdata" start
```

### Prisma + seed

```cmd
pnpm --filter @fittrack/api db:generate
pnpm --filter @fittrack/api db:push
pnpm --filter @fittrack/api db:seed
```

Seed `upsert` ile idempotent — yeniden çalıştırmak güvenli. ~190 futbol egzersizi yüklenir.

### Mobile (ilk seferde)

```cmd
cd apps\mobile
flutter pub get
```

---

## Test hesapları

> Geliştirme DB'sinde otomatik mevcut. Reset edilirse tekrar oluşturulması gerekir.

**Antrenör:**
```
E-posta : test@fittrack.app
Şifre   : Test1234
Kulüp   : Test Kulup
Takım   : "00"
```

**Oyuncu:**
```
E-posta : oyuncu@fittrack.app
Şifre   : Oyuncu1234
Profil  : Test Oyuncu, 17 yaş, CM, sağ ayak, 178cm/72kg, forma 10
```

Bu oyuncu için bu hafta otomatik **6 seanslık match_week programı** üretildi → giriş yapınca dolu takvim göreceksin.

---

## Geliştirme komutları

```cmd
pnpm dev:api                                # API başlat (http://localhost:3000)
pnpm typecheck                              # TS strict check
pnpm test:api                               # backend unit testleri
pnpm format:check                           # prettier kontrolü

pnpm --filter @fittrack/api db:studio       # Prisma Studio (görsel DB)
pnpm --filter @fittrack/api db:migrate      # migration üret + uygula
pnpm --filter @fittrack/api db:seed         # egzersizleri upsert et

cd apps\mobile
flutter analyze                             # statik analiz
flutter test                                # widget testleri
flutter run                                 # debug build, hot reload
flutter run --release                       # release build
```

### Hızlı doğrulama (toolchain + DB + typecheck + vitest + API start)

```cmd
dev.bat
```

Sadece kontroller (API başlatmadan): `dev.bat check`

### Entegrasyon testleri için ayrı test DB

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

---

## studio.bat — tek tıkla çalıştırma

Android Studio + emulator + flutter run zinciri. Default akış:

1. Android Studio'yu açar
2. İlk AVD'yi (örn. `Medium_Phone`) arka planda başlatır
3. `adb shell getprop sys.boot_completed` ile boot bekler (max 180s)
4. Yeni cmd penceresinde `flutter run apps/mobile` başlatır (hot reload için açık kalır)

```cmd
studio.bat                  REM tam zincir
studio.bat --check          REM durum raporu, aksiyon yok
studio.bat --install        REM Studio yoksa winget ile kur
studio.bat --no-app         REM Studio + AVD, flutter run atla
studio.bat --no-emu         REM sadece Studio
studio.bat --avd Medium_Phone   REM belirli AVD
```

**Akıllı kısa devreler:**
- Çalışan emulator varsa (qemu-system process'i) yeniden başlatmaz
- adb yoksa "manuel `flutter run`" mesajı basar
- apps/mobile yoksa atlar
- flutter PATH'te yoksa atlar

---

## Bilinen sınırlamalar

> Production öncesi kapatılması gerekenler.

| Sorun | Etkilenen yer | Çözüm |
|-------|---------------|-------|
| API base URL hardcoded `10.0.2.2:3000` | `lib/api/api_client.dart` | Build flavor / `.env` config |
| `usesCleartextTraffic="true"` | Android Manifest | HTTPS + bayrak kaldır |
| Egzersiz görselleri yok | Backend seed (`thumbnailUrl: null`) | ExerciseDB API entegre, Wikimedia Commons CC-BY-SA görseller, ya da kendi CDN |
| Real-time chat = polling 5s | `ChatRoomScreen` | WebSocket / SSE / Firebase Realtime |
| Push notification yok | — | Firebase Cloud Messaging entegrasyonu |
| Avatar upload yok | — | Backend `/users/:id/avatar` + multipart + S3/Cloudinary |
| Şifremi unuttum | — | Backend `/auth/forgot-password` endpoint + email service |
| iOS desteği | — | `flutter create --platforms=ios .` + macOS build |
| Bireysel program attendance UI | `apps/mobile` | Şu an bireysel programda anlamsız (1 oyuncu); team programları gelince eklenir |
| State management LIB yok | — | StatefulWidget + callback yetiyor; ekran sayısı 30+ olursa Riverpod düşün |
| Token süresi kısa (~9s access, ~18s refresh dev'de) | `apps/api/.env` | Dev için yeterli; prod'da ayarla |

---

## Sonraki adımlar

**Kısa vadeli (1-2 gün iş):**
- Egzersiz GIF/görsellerini backend seed'e ekle (ExerciseDB API'den çek + cache)
- Push notification (yeni mesaj, program üretildi, maç hatırlatıcı)
- `flutter create --platforms=ios .` + iOS build doğrulama
- Avatar upload (multipart + Cloudinary CDN)

**Orta vadeli (1-2 hafta):**
- Real-time chat: polling → WebSocket (örn. `web_socket_channel` paketi + Fastify ws plugin)
- Player profile self-edit (boy/kilo güncelleme)
- Şifremi unuttum flow + email service (Resend / SendGrid)
- Coach takım programı (bireysel yerine team-level program — engine zaten destekliyor)
- Attendance bulk UI (takım programı seansında roster picker)

**Uzun vadeli:**
- Onboarding tutorial (ilk login için tour overlay)
- Goal tracking (oyuncu kendi hedefi: kilo, mevki performans, vb.)
- Comparative stats (oyuncuyu takım ortalamasıyla karşılaştır)
- WhatsApp share (program PDF / görsel export → WhatsApp)
- Tactical board (digital playbook drawing)

---

## Bağlantılı dosyalar

- [CONTEXT.md](./CONTEXT.md) — AI agent çalışma kuralları + mimari kuralları
- [GDD.md](./GDD.md) — eski FitTrack vizyonu (futbol pivotundan önce, referans amaçlı)
- [`apps/api/src/services/program-engine/README.md`](./apps/api/src/services/program-engine/README.md) — engine kalibrasyon notları

---

## Lisans

İç proje. Üçüncü partilerle paylaşmadan önce hak sahipleriyle anlaş.
