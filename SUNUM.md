# fittrack — Sunum Rehberi

> Bu dosya, `fittrack` mobil uygulamasını sunarken (mülakat, portfolyo, mentor toplantısı, jüri, paydaş demo) kullanılması için hazırlanmıştır. Hem **vizyon + tasarım kararları**, hem **kod düzeyinde teknik açıklamalar**, hem de **emulator'de çalıştırma adım-adım rehberi** içerir.
>
> **Tek dosyada her şey** — sunum sırasında ekrana açıp paragraf paragraf okuyabilirsin.

---

## 📑 İçindekiler

1. [Tek paragraflık özet (elevator pitch)](#1-tek-paragraflık-özet)
2. [Vizyon ve hedef kullanıcı](#2-vizyon-ve-hedef-kullanıcı)
3. [Tasarım kararları (neden böyle yapıldı)](#3-tasarım-kararları)
4. [Teknoloji yığını (stack) — detaylı](#4-teknoloji-yığını)
5. [Mimari ve veri akışı](#5-mimari-ve-veri-akışı)
6. [Klasör yapısı + dosya dosya açıklama](#6-klasör-yapısı--dosya-dosya-açıklama)
7. [Veri modeli (DB schema özeti)](#7-veri-modeli)
8. [Backend endpoint dökümü (38 endpoint + 1 WS)](#8-backend-endpoint-dökümü)
9. [Mobil ekranlar (22 ekran tek tek)](#9-mobil-ekranlar)
10. [Emulator'de çalıştırma el rehberi (sıfırdan)](#10-emulatorde-çalıştırma-el-rehberi)
11. [Demo senaryosu (15-20 dakikalık sunum akışı)](#11-demo-senaryosu)
12. [Test hesapları](#12-test-hesapları)
13. [SSS (sıkça sorulan sorular)](#13-sss)
14. [Bilinen sınırlamalar ve sonraki adımlar](#14-bilinen-sınırlamalar)

---

## 1. Tek paragraflık özet

> **fittrack**, alt lig + akademi futbol antrenörleri için tasarlanmış bir mobil platformdur. Antrenör; kulüp, takım ve oyuncu profillerini girer. Sistem, **kural tabanlı bir engine** ile her oyuncuya yaş, mevki, sakatlık geçmişi, kulüp ekipmanı ve maç haftası bağlamına göre **kişiye özel haftalık antrenman programı** üretir. Oyuncu, telefondan programını görür; antrenmandan sonra RPE (efor seviyesi) ve hazırbulunuşluk bildirir. Antrenör, oyuncuyla **gerçek zamanlı (WebSocket)** mesajlaşır, sakatlık ve performans testlerini takip eder, fikstürü yönetir. Tüm UI Türkçe, dark mode'lu, modern Material 3 tasarımı. Backend Fastify + Prisma + Postgres, mobile Flutter (Android + iOS scaffolding). 22 ekran, 38 REST endpoint + 1 WebSocket, ~7200 satır mobile kod.

---

## 2. Vizyon ve hedef kullanıcı

**Hedef kullanıcı gerçekliği** — bu kararı şekillendiren tüm faktörler:

- Alt lig kulübünde antrenör **tek başına**: TD + fitness koçu + analist roller bir kişide
- **Bütçe yok**: GPS yelek, biyometrik tracker, fizyoterapist YOK. Tüm veri MANUEL girilir
- **Gym genelde yok** ya da çok sınırlı; programlar bodyweight + saha ağırlıklı olabilmeli
- **Saha günde 1.5–2 saat**, akşam saatleri, kötü zemin, kış aylarında ışık problemi
- Kadro **heterojen**: 17–35 yaş arası yarı pro + amatör + iş yoğun oyuncular bir arada
- Bir koç çoğunlukla **2–3 yaş kategorisi** çalıştırır (örn. U17 + U19 + Senior)
- **WhatsApp birinci iletişim kanalı** — oyuncularla yazışmak zaten oradan yapılır
- **Türkçe birinci dil**, sade UI, mobile-first, offline-tolerant olmak zorunda

**Bu app NE DEĞİLDİR:**
- Genel fitness/beslenme uygulaması değil
- Premier League / elit kulüp için tasarlanmadı
- Wearable / sensör entegrasyonu YOK
- AI-tabanlı taktik analizi YOK
- Sosyal özellik (paylaşım, takip) YOK

**Bu app NEYİ HEDEFLER:**
- Tek koçun **manuel veri girişi yükünü minimize etmek**
- Engine ile **program yazma zamanını** dakikalardan **saniyelere** indirmek
- Oyuncu-koç iletişimini **WhatsApp'tan ayrı, yapılandırılmış** bir kanala taşımak
- Sakatlık ve performans verilerini **karşılaştırılabilir formatta** saklamak

---

## 3. Tasarım kararları

> Her teknik karar **neden** alındığı bilgisiyle birlikte. Mülakatta sorulduğunda hazır olun.

### Backend kararları

**Neden Fastify (Express değil)?**
Daha hızlı (5x throughput), TypeScript desteği daha iyi, plugin sistemi daha modern, `validateStatus` gibi düşük seviye Dio uyumu daha kolay.

**Neden Prisma (raw SQL değil)?**
Type-safe queries (TS strict ile uyumlu), schema'dan migration üretme, Studio UI bedava, ekibin diğer üyeleri için öğrenme maliyeti düşük.

**Neden Postgres (MongoDB değil)?**
Veri ilişkisel: Coach-Club-Team-Player-Program-Session-Exercise zinciri SQL ile doğal. JSON alanlar için `jsonb` zaten var (örn. `generationInputs` snapshot).

**Neden JWT (session değil)?**
Mobile + multiple devices destekli, stateless, refresh token ile geçici güvenlik. Backend horizontal scale kolay.

**Neden Zod (Joi/Yup değil)?**
Statik tip + runtime validation **aynı şemada**. `z.infer<typeof Schema>` ile TS tipi otomatik üretiyor. Mobile tarafına **şema paylaşmak** kolay (packages/shared).

**Neden monorepo (pnpm workspace)?**
`packages/shared` Zod şemalarını backend ile mobile arasında tek kaynak yapar. (Mobile Dart kullansa bile şemalar referans olarak okunabilir.)

**Neden in-memory (Redis değil) chat hub + password reset?**
Production'da Redis önerilir. Şu an single-instance dev için memory yeterli, dependency yükünü azaltıyor. README'de migration yolu yazılı.

**Neden kural tabanlı engine (ML değil)?**
Şeffaflık. Antrenör neden "Salı=sürat" çıktığını görmek ister. Kural bazlı if-else **explain edilebilir**, ML kara kutu. Versiyonlama (`rule_engine_v1` → `v2`) ile audit kolay.

### Mobile kararları

**Neden Flutter (React Native değil)?**
Tek codebase Android+iOS, Material 3 destek üst düzey, Dart strict mode TS'ten katı, build tooling daha az kırılgan.

**Neden Dio (built-in http değil)?**
Interceptor desteği — token refresh-on-401 logic için kritik. http paketinde manuel wrapper yazmak zorunda kalırdın.

**Neden flutter_secure_storage?**
Refresh token uzun ömürlü; SharedPreferences güvensiz (root'lu cihazda okunabilir). Android Keystore ile şifreli.

**Neden state management LIB yok (Riverpod/Bloc değil)?**
Şu an 22 ekran var, çoğu birbirinden bağımsız. `StatefulWidget` + callback yetiyor. State paylaşımı çoğunlukla constructor üzerinden. **Karmaşıklığı erken eklemenin maliyeti** Riverpod'un faydasından yüksek. 30+ ekran olunca Riverpod düşünülebilir.

**Neden manual JSON parse (freezed/json_serializable değil)?**
Codegen step (`dart run build_runner watch`) ekibe ek kompleksite. Modeller küçük ve sade, manuel `factory fromJson` okunaklı. Modeller patlarsa freezed'e geçilir.

**Neden 5s polling DEĞİL — WebSocket?**
İlk turda 5s polling vardı. Sonra `@fastify/websocket` + `web_socket_channel` ile **gerçek real-time** yapıldı. Polling network/battery israfıydı. WS = anında push.

**Neden token refresh interceptor?**
Access token süresi kısa (~9k saniye dev). Süresi dolarsa kullanıcı manuel relogin yapmak zorunda kalmasın → Dio interceptor 401 yakalar, otomatik `/auth/refresh` çağırır, orijinal isteği retry eder. Refresh de fail olursa logout state.

**Neden dark mode?**
Antrenörler **akşam saha kenarında** çalışıyor. Beyaz ekran karanlıkta zor. ThemeMode.system default + manuel toggle.

**Neden Türkçe sabit kodda (i18n LIB değil)?**
ARB dosyaları + codegen + l10n.yaml = ek karmaşa. Hedef kitle %100 Türkçe konuşuyor. İngilizce versiyon gerekiyorsa `flutter_localizations` zaten kurulu, `intl` ile kolay geçiş.

**Neden in-app egzersiz görselleri yerine kategori-renkli ikonlar?**
Backend seed'de görsel URL yok. Random internet URL'leri lisans riski. Infrastructure (`Image.network` + errorBuilder) ekledim → backend GIF eklenince otomatik render. Şimdi kategori-renkli ikonlar fallback (yine de görsel anlamlı: koşu=mavi, kuvvet=kırmızı, recovery=yeşil...).

---

## 4. Teknoloji yığını

### Backend (apps/api)

| Katman | Teknoloji | Sürüm | Niye |
|--------|-----------|-------|------|
| Runtime | Node.js | 20+ | LTS, modern ES features |
| Dil | TypeScript | strict mode | Tip güvenliği |
| Framework | Fastify | 5.1 | Hız + plugin sistemi |
| ORM | Prisma | 5.22 | Type-safe + Studio + migration |
| DB | PostgreSQL | 17 | İlişkisel + JSON desteği |
| Validation | Zod | latest | Şema = tip + runtime |
| Auth | JWT (jsonwebtoken) | latest | Access + refresh token |
| Hash | bcrypt | latest | Password hashing |
| WebSocket | @fastify/websocket | latest | Real-time chat |
| Logger | Pino | latest | JSON log + pino-pretty (dev) |
| Test | Vitest | latest | Hızlı, ESM-first |
| Workspace | pnpm | 10+ | Monorepo workspaces |

### Mobile (apps/mobile)

| Katman | Teknoloji | Sürüm | Niye |
|--------|-----------|-------|------|
| Framework | Flutter | 3.41 | Cross-platform, Material 3 |
| Dil | Dart | 3.11 | Strict mode, modern syntax |
| HTTP client | dio | 5.9 | Interceptor (token refresh) |
| Secure storage | flutter_secure_storage | 10.0 | Android Keystore |
| Localizations | flutter_localizations | SDK | Türkçe date picker |
| WebSocket | web_socket_channel | 3.0 | Real-time chat client |
| Test | flutter_test | SDK | Widget testing |
| Lint | flutter_lints | 6.0 | Standart Flutter lints |

**Toplam mobile dependency: 4 third-party paket** (cupertino_icons hariç). State management LIB yok (StatefulWidget yetti). i18n LIB yok (sabitler widget içinde).

### Geliştirme aletleri

- **Android Studio** — IDE, AVD Manager, SDK
- **Flutter SDK** — `flutter run`, `flutter analyze`, `flutter test`
- **PostgreSQL 17** — local instance, `pg_ctl start/stop`
- **Postman / curl** — API test
- **Prisma Studio** — DB görsel client (`pnpm db:studio`)
- **adb** — Android Debug Bridge

---

## 5. Mimari ve veri akışı

### Üst düzey diyagram

```
┌─────────────────────────────────────────────────────────────┐
│                    ANDROID EMULATOR                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  fittrack mobile (Flutter)                           │   │
│  │  - 22 ekran                                          │   │
│  │  - Dio HTTP client (auth interceptor)                │   │
│  │  - WebSocket client (chat)                           │   │
│  │  - flutter_secure_storage (token + tema)             │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      │ HTTP (REST + WebSocket)
                      │ http://10.0.2.2:3000
                      │ (emulator → host)
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                  HOST MACHINE (Windows)                     │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Fastify API (port 3000)                             │   │
│  │  - 38 REST endpoint                                  │   │
│  │  - 1 WebSocket route (/ws/chat)                      │   │
│  │  - JWT verify + Zod parse + service call             │   │
│  └──────────────────────────────────────────────────────┘   │
│                      │                                       │
│                      ▼                                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Services (business logic)                           │   │
│  │  - auth, club, team, player, program-engine,         │   │
│  │  - match, chat, chat-hub, password-reset, ...        │   │
│  └──────────────────────────────────────────────────────┘   │
│                      │                                       │
│                      ▼                                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Repositories (Prisma wrappers)                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                      │                                       │
│                      ▼                                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  PostgreSQL 17 (port 5432, db: fittrack)             │   │
│  │  - 18 tablo                                          │   │
│  │  - ~190 egzersiz seed'lenmiş                         │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### İstek akışı (örnek: oyuncu RPE girer)

```
Player ChatRoom               Mobile                Backend                   DB
     │                          │                     │                        │
     │  RPE form: "8/10 efor"   │                     │                        │
     │ ────────────────────────►│                     │                        │
     │                          │ POST /sessions/:id/log
     │                          │   Bearer + JSON     │                        │
     │                          │ ───────────────────►│                        │
     │                          │                     │  Zod parse             │
     │                          │                     │  authorize player      │
     │                          │                     │  prisma.sessionLog.upsert
     │                          │                     │ ──────────────────────►│
     │                          │                     │                        │
     │                          │                     │◄──────────────────────│
     │                          │  201 + SessionLog   │                        │
     │                          │◄────────────────────│                        │
     │  "Geri bildirim kaydedildi" snackbar           │                        │
     │◄─────────────────────────│                     │                        │
```

### WebSocket akışı (real-time chat)

```
Coach phone           Mobile          Backend (chat-hub)          Player phone
    │                   │                    │                         │
    │  open ChatRoom    │                    │                         │
    │ ─────────────────►│                    │                         │
    │                   │ WS connect ──────►│                         │
    │                   │                    │ subscribe(threadId)     │
    │                   │ ◄─────── ready    │                         │
    │                   │                    │ ◄────── WS connect      │
    │                   │                    │ subscribe(threadId)     │
    │                   │                    │ ──── ready ────────────►│
    │  type "Yarın 18:00"│                   │                         │
    │ ─────────────────►│                    │                         │
    │                   │ POST /chat/.../msg │                         │
    │                   │ ──────────────────►│                         │
    │                   │                    │ DB save                 │
    │                   │                    │ broadcast(threadId, msg)│
    │                   │ ◄── push (WS) ────│ ── push (WS) ──────────►│
    │  "msg gönderildi" │                    │  message bubble         │
    │◄──────────────────│                    │                         │
                                                                  ◄────│
                                                                  görür
```

Polling YOK — Coach mesaj atınca Player'da **anında** balon belirir.

---

## 6. Klasör yapısı + dosya dosya açıklama

> Her dosyanın **ne içerdiği** ve **ne işe yaradığı**.

```
fittrack/
├── apps/
│   ├── api/         ← Backend
│   └── mobile/      ← Flutter mobile
├── packages/
│   └── shared/      ← Zod şemaları (mobile + backend ortak)
├── studio.bat       ← Tek tıkla Studio + AVD + flutter run
├── dev.bat          ← Backend dev runner (typecheck + test + start)
├── README.md        ← Genel proje dökümantasyonu
├── SUNUM.md         ← Bu dosya
├── CONTEXT.md       ← AI agent çalışma kuralları
└── GDD.md           ← Eski FitTrack vizyonu (referans)
```

### Backend — `apps/api/`

```
apps/api/
├── src/
│   ├── server.ts                          ← Entrypoint: env + buildApp + listen
│   ├── app.ts                             ← Fastify instance + plugin + route register
│   ├── lib/
│   │   ├── env.ts                         ← .env okuma + validation
│   │   ├── errors.ts                      ← AppError class (validation/unauthorized/forbidden/...)
│   │   ├── prisma.ts                      ← PrismaClient singleton
│   │   ├── password.ts                    ← bcrypt hash + verify
│   │   ├── tokens.ts                      ← JWT sign + verify (access + refresh)
│   │   └── auth-context.ts                ← requireCoach/requirePlayer/authorizePlayerAccess
│   ├── plugins/
│   │   └── auth.ts                        ← requireAuth Fastify hook (JWT verify)
│   ├── routes/                            ← HTTP route handler'lar (thin layer)
│   │   ├── health.ts                      ← GET /health
│   │   ├── auth.ts                        ← /auth/* (login, register, me, refresh, logout, forgot-password, reset-password)
│   │   ├── clubs.ts                       ← /clubs/* (CRUD, facilities, equipment)
│   │   ├── teams.ts                       ← /teams/* (CRUD, roster, player CRUD-on-team)
│   │   ├── players.ts                     ← /players/* (GET/PATCH, availability, injuries)
│   │   ├── programs.ts                    ← /players/:id/programs/* + /sessions/:id/log
│   │   ├── matches.ts                     ← /teams/:id/matches + /matches/:id
│   │   ├── performance-tests.ts           ← /players/:id/performance-tests
│   │   ├── chat.ts                        ← /chat/threads + /messages + /read
│   │   └── chat-ws.ts                     ← GET /ws/chat?threadId=&token= (WebSocket route)
│   ├── services/                          ← Business logic
│   │   ├── auth.service.ts                ← AuthService class: login/register/refresh/logout
│   │   ├── password-reset.service.ts      ← In-memory token store (1h TTL)
│   │   ├── club.service.ts                ← getMyClub/listFacilities/...
│   │   ├── team.service.ts                ← createTeam/listMyTeams/createPlayerProfile (invite üretir)
│   │   ├── player.service.ts              ← getPlayer/setAvailability/createInjury/...
│   │   ├── program.service.ts             ← generateForPlayer/listForPlayer + RPE log
│   │   ├── program-engine/                ← ⭐ KURAL TABANLI ENGINE
│   │   │   ├── index.ts                   ← generateProgram() ana giriş
│   │   │   ├── load-snapshot.ts           ← Oyuncu profili snapshot
│   │   │   ├── load-club-resources.ts     ← Ekipman + tesis envanteri
│   │   │   ├── plan-week.ts               ← 7-günlük iskelet (match_week / generic_week)
│   │   │   ├── select-exercises.ts        ← Egzersiz havuzundan filtrele
│   │   │   ├── program-writer.ts          ← DB'ye yaz + snapshot kaydet
│   │   │   └── README.md                  ← Engine kalibrasyon notları
│   │   ├── match.service.ts               ← Maç CRUD
│   │   ├── chat.service.ts                ← Thread/message CRUD + ensureThreadAccess
│   │   ├── chat-hub.ts                    ← In-memory pub/sub (broadcast)
│   │   └── performance-test.service.ts    ← Performans testi CRUD
│   └── repositories/                      ← Prisma wrapper'lar
│       ├── user.repository.ts
│       └── refresh-token.repository.ts
├── prisma/
│   ├── schema.prisma                      ← 18 tablo modeli (User, Club, Team, Player, Program, ...)
│   ├── seed.ts                            ← Egzersizleri DB'ye yükler
│   └── seed/
│       └── exercises.ts                   ← ~190 futbol egzersizi (idempotent upsert)
├── test/                                  ← Vitest
│   ├── lib/
│   │   ├── password.test.ts               ← bcrypt unit
│   │   └── tokens.test.ts                 ← JWT unit
│   └── (entegrasyon testleri DATABASE_URL_TEST gerektirir)
└── package.json                           ← deps: fastify + prisma + zod + jsonwebtoken + bcrypt + ...
```

**Önemli backend dosya açıklamaları:**

- **`src/services/program-engine/index.ts`** — Tüm engine'in ana orchestrator'ı. `generateProgram(playerId, weekStart)` çağrılır → `loadPlayerSnapshot` → `loadClubResources` → `planWeek` → `selectExercisesForCategory` → `toSelectedExercise` → `WrittenProgram`. Pure function (DB write `program-writer.ts`'de).

- **`src/services/chat-hub.ts`** — Singleton class. `subscribe(threadId, sub)` ile kayıt, `broadcast(threadId, message)` ile yayın. WebSocket route ve chat.service'in birbiriyle konuşma noktası. Multi-instance deploy için Redis pub/sub'a değiştirilmesi gerekir (kod yorumu var).

- **`src/services/password-reset.service.ts`** — In-memory `Map<token, {userId, expiresAt}>`. 1 saat TTL, auto cleanup. Production'da DB tablosu veya Redis istenir.

- **`src/lib/auth-context.ts`** — `requireCoach(authUser)`, `requirePlayer(authUser)`, `authorizePlayerAccess(authUser, playerId)` — yetki kontrolü helper'ları. Her route handler bunu çağırır.

### Mobile — `apps/mobile/`

```
apps/mobile/
├── lib/
│   ├── main.dart                          ← Uygulama giriş noktası
│   │                                        - FittrackApp StatefulWidget
│   │                                        - Token okuma + /auth/me ile boot
│   │                                        - Theme state (light/dark/system, persisted)
│   │                                        - Role-based routing (coach/player/login)
│   │                                        - AuthExpired callback (token refresh fail → logout)
│   ├── api/                               ← HTTP + WebSocket istemcileri
│   │   ├── api_client.dart                ← Dio instance + auth interceptor + 401→refresh+retry
│   │   ├── api_exception.dart             ← DioException → ApiException Türkçe + ensureOk(res)
│   │   ├── auth_api.dart                  ← login + register coach/player + me + refresh + logout + forgot/reset password
│   │   ├── chat_api.dart                  ← listThreads + listMessages + sendMessage + markRead + startThread
│   │   ├── clubs_api.dart                 ← getMyClub + listFacilities + listEquipment
│   │   ├── teams_api.dart                 ← CRUD takım + roster + create/remove player + UpdateTeamInput
│   │   ├── players_api.dart               ← getMyPlayer + getPlayer + updatePlayer + UpdatePlayerInput
│   │   ├── programs_api.dart              ← generateForPlayer + listForPlayer + logSession
│   │   ├── matches_api.dart               ← listForTeam + create + update + delete (+CreateMatchInput, UpdateMatchInput)
│   │   └── health_api.dart                ← availability + injury + performance test API
│   ├── models/                            ← Dart modelleri (manuel JSON parse)
│   │   ├── auth_tokens.dart               ← AuthTokens (accessToken, refreshToken)
│   │   ├── user.dart                      ← User (id, email, role, fullName, locale, ...)
│   │   ├── club.dart                      ← Club + Facility + Equipment
│   │   ├── team.dart                      ← Team (clubId, name, category, season, active)
│   │   ├── player.dart                    ← Player + TeamPlayer
│   │   ├── exercise.dart                  ← ExerciseSummary (id, slug, nameTr, category, ...)
│   │   ├── program.dart                   ← TrainingProgram + TrainingSession + SessionExercise + SessionLog
│   │   ├── match.dart                     ← Match (opponent, date, scoreUs/Them, ...)
│   │   ├── invite.dart                    ← Invite + CreatePlayerResult
│   │   ├── health.dart                    ← PlayerAvailability + InjuryRecord + PerformanceTest
│   │   └── chat.dart                      ← ChatThread + ChatThreadSummary + ChatMessage
│   ├── screens/                           ← 22 UI ekranı
│   │   ├── login_screen.dart              ← E-posta/şifre + "Şifremi unuttum" + register linkleri
│   │   ├── register_screen.dart           ← Antrenör kayıt (email + şifre + ad + opsiyonel kulüp)
│   │   ├── player_register_screen.dart    ← Oyuncu kayıt (büyük monospace davet kodu + form)
│   │   ├── forgot_password_screen.dart    ← 2-step: email gir → token+yeni şifre (dev modda token auto-fill)
│   │   ├── home_screen.dart               ← Antrenör Home: SliverAppBar gradient hero + Mesajlar (unread badge) + Kulübüm + mini grid
│   │   ├── player_home_screen.dart        ← Oyuncu Home: forma no'lu hero + 4 ActionCard
│   │   ├── settings_screen.dart           ← Profil + tema seçici (3 mod) + about + güvenli logout
│   │   ├── club_screen.dart               ← Kulüp + tesis + ekipman + takımlar (uzun-bas → Düzenle/Sil menü)
│   │   ├── team_create_screen.dart        ← Takım form (existing param ile edit moduna sokulur)
│   │   ├── team_detail_screen.dart        ← Roster + AppBar Maçlar + bottom sheet 8 aksiyon
│   │   ├── player_create_screen.dart      ← 11 alanlı oyuncu form + davet kod modal'ı
│   │   ├── player_edit_screen.dart        ← Antrenör için oyuncu profil edit (PATCH)
│   │   ├── player_self_edit_screen.dart   ← Oyuncu için kendi profil edit (kısıtlı alanlar)
│   │   ├── player_stats_screen.dart       ← RPE bar chart + kategori dağılımı + availability
│   │   ├── matches_screen.dart            ← Fikstür + skor güncelleme modal + sil
│   │   ├── injuries_screen.dart           ← Sakatlık liste + create + resolve
│   │   ├── perf_tests_screen.dart         ← 17 test türü + delta + history
│   │   ├── availability_screen.dart       ← Bildirim formu (7 durum) + 30 gün geçmiş
│   │   ├── program_view_screen.dart       ← Haftalık takvim (expandable) + "Bu haftaya üret" FAB
│   │   ├── session_detail_screen.dart     ← Kategori-renkli gradient header + egzersiz listesi + RPE form
│   │   ├── chat_threads_screen.dart       ← Thread liste + unread badge + göreceli zaman
│   │   └── chat_room_screen.dart          ← WebSocket real-time mesaj balonları + auto-reconnect
│   ├── storage/
│   │   └── token_storage.dart             ← flutter_secure_storage wrapper (token + tema modu)
│   └── util/
│       ├── labels.dart                    ← 14 enum sözlüğü Türkçe + tarih helper (dayShort, dayLong, formatDate)
│       └── exercise_visuals.dart          ← Kategori → ikon + renk eşlemesi + intensity rengi
├── android/                               ← Android proje (build.gradle, manifest, MainActivity)
│   └── app/src/main/AndroidManifest.xml   ← INTERNET izni + usesCleartextTraffic (dev)
├── ios/                                   ← iOS scaffolding (Runner.xcodeproj, Info.plist)
├── test/
│   └── widget_test.dart                   ← Boot → login screen smoke test
├── pubspec.yaml                           ← deps: dio + flutter_secure_storage + flutter_localizations + web_socket_channel
└── README.md                              ← Mobil developer onboarding
```

**Önemli mobile dosya açıklamaları:**

- **`lib/main.dart`** — Uygulamanın beyni. `FittrackApp` StatefulWidget içinde:
  - `_user` (giriş yapan), `_themeMode` (tema), `_booting` (yükleniyor) state'i
  - `_bootstrap()` ile token oku → `/auth/me` ile user fetch → role'e göre route
  - `apiClient.onAuthExpired = () => setState(() => _user = null)` — refresh fail olursa otomatik logout
  - MaterialApp'a `themeMode + theme + darkTheme + locale + delegates` props

- **`lib/api/api_client.dart`** — Tüm HTTP iletişiminin temeli. `Dio` instance + 2 interceptor:
  1. `onRequest`: Token storage'dan oku → `Authorization: Bearer ...` header ekle
  2. `onResponse`: 401 yakalanırsa (refresh/login/register dışında) → ayrı `_refreshDio` ile `/auth/refresh` çağır → yeni token ile orijinal isteği retry. Refresh fail → `onAuthExpired` callback.

- **`lib/api/auth_api.dart`** — `AuthApi` class — login/register coach+player/me/refresh/logout/forgotPassword/resetPassword fonksiyonları + `AuthException` (Türkçe mesaj).

- **`lib/screens/chat_room_screen.dart`** — En sofistike ekran:
  - `WebSocketChannel.connect('ws://10.0.2.2:3000/ws/chat?threadId=X&token=Y')`
  - `_socketSub.listen(_onWsMessage)` → JSON parse → state'e push
  - Bağlantı koparsa `_scheduleReconnect()` (5s sonra tekrar dene)
  - AppBar altında "Bağlantı yok" banner (renk kırmızı)
  - Mesaj balonları: kendisi sağ-yeşil, diğeri sol-gri
  - Klavye gönder + auto-scroll-to-bottom

- **`lib/screens/program_view_screen.dart`** — Engine ürünü görüntüleme:
  - `FutureBuilder<List<TrainingProgram>>` ile program listesi
  - Her program kartı expandable → 7 günlük seans listesi
  - "Bu haftaya üret" FAB (sadece coach için — `canGenerate=true`)
  - Off günü = "Dinlenme" badge
  - RPE kayıtlı seans = yeşil ✓ ikonu

- **`lib/util/exercise_visuals.dart`** — 12 antrenman kategorisi için ikon + renk:
  ```dart
  'endurance': CategoryVisual(Icons.directions_run, Color(0xFF1976D2)),    // mavi
  'strength': CategoryVisual(Icons.fitness_center, Color(0xFFD32F2F)),     // kırmızı
  'recovery': CategoryVisual(Icons.spa, Color(0xFF558B2F)),                // yeşil
  // ...
  ```
  Backend GIF eklenmediği sürece bu fallback. `intensityColor(1-5)` → 1=yeşil, 5=kırmızı.

### Shared — `packages/shared/`

```
packages/shared/
└── src/
    ├── index.ts                           ← Re-export point
    └── schemas/
        ├── enums.schema.ts                ← TÜM enum'lar (Prisma ile 1-1 senkron)
        ├── user.schema.ts                 ← UserSchema + Login/Register inputs + AuthTokensSchema
        ├── club.schema.ts                 ← Club + Coach + Team + Facility + Equipment + Invite
        ├── player.schema.ts               ← Player + Availability + Injury
        ├── exercise.schema.ts             ← Exercise + SelectedExercise (engine output)
        ├── program.schema.ts              ← TrainingProgram + Session + Exercise + Log
        ├── match.schema.ts                ← Match + scores
        ├── performance.schema.ts          ← PerformanceTest + types
        └── chat.schema.ts                 ← ChatThread + ChatMessage + ChatThreadSummary
```

**Önemli:** Bu package backend'den `import { Schema } from '@fittrack/shared'` ile kullanılıyor. **Mobile (Dart) doğrudan kullanmıyor** ama Dart modelleri bu şemalarla uyumlu yazıldı (manuel referans).

---

## 7. Veri modeli

### 18 Prisma tablosu (özet)

```
User                  ← Hesap (email, passwordHash, role, fullName, locale)
RefreshToken          ← Long-lived token saklama
Coach                 ← User + clubId + licenseLevel + isClubAdmin
Player                ← clubId + birthDate + position + heightCm + weightKg + jerseyNumber + ...
Club                  ← name + city + league + foundedYear
Team                  ← clubId + name + category (U13..senior) + season
TeamPlayer            ← Team-Player M:N (joinedAt, leftAt)
Facility              ← Kulüp tesisi (type, name)
Equipment             ← Kulüp ekipmanı (item, quantity)
Invite                ← Davet kodu (code, expiresAt, acceptedBy, playerId)
Exercise              ← Egzersiz havuzu (~190 kayıt)
TrainingProgram       ← Haftalık program (playerId|teamId, weekStartDate, microcycleType, generationInputs)
TrainingSession       ← Bir günün seansı (programId, date, type, category, duration, intensity)
SessionExercise       ← Seans-egzersiz M:N (sets, reps, durationSec, distanceMeters, restSec, intensity)
SessionLog            ← Oyuncu RPE girişi (rpe, fatigue, mood, sleepHours, notes)
TrainingAttendance    ← Antrenmana katılım (status: present/absent/late/excused)
Match                 ← Maç (opponent, date, isHome, scoreUs, scoreThem)
PlayerAvailability    ← Günlük durum (date, status, note)
InjuryRecord          ← Sakatlık (type, severity, bodyPart, startedAt, resolvedAt)
PerformanceTest       ← Test sonucu (type, value, unit, testedAt)
ChatThread            ← Coach-Player mesajlaşma kanalı
ChatMessage           ← Mesaj (threadId, senderId, body, sentAt)
```

Tam şema: `apps/api/prisma/schema.prisma`

---

## 8. Backend endpoint dökümü

### Auth (`/auth/*`)
```
POST  /auth/register/coach     {email, password, fullName, clubName?}    → {user, tokens}
POST  /auth/register/player    {inviteCode, email, password, fullName}   → {user, tokens}
POST  /auth/login              {email, password}                         → {user, tokens}
POST  /auth/login/code         {code}                                    → {user, tokens}  (kalıcı PIN)
POST  /auth/refresh            {refreshToken}                            → {accessToken, refreshToken}
POST  /auth/logout             {refreshToken}                            → 204
POST  /auth/forgot-password    {email}                                   → {message, devToken?}
POST  /auth/reset-password     {token, newPassword}                      → 204
GET   /auth/me                 (Bearer)                                   → User
GET   /auth/me/player          (Bearer)                                   → {playerId, player}
```

### Clubs (`/clubs/*`)
```
POST   /clubs                                  (coach)               → Club
GET    /clubs/me                               (coach)               → Club | null
PATCH  /clubs/:clubId                          (coach + admin)       → Club
GET    /clubs/:clubId/facilities                                     → Facility[]
POST   /clubs/:clubId/facilities                                     → Facility
DELETE /clubs/:clubId/facilities/:facilityId                         → 204
GET    /clubs/:clubId/equipment                                      → Equipment[]
POST   /clubs/:clubId/equipment                                      → Equipment
DELETE /clubs/:clubId/equipment/:equipmentId                         → 204
```

### Teams (`/teams/*`)
```
GET    /teams?includeInactive=                 (coach)               → Team[]
POST   /teams                                  (coach)               → Team
GET    /teams/:teamId                          (coach)               → Team
PATCH  /teams/:teamId                          (coach)               → Team
DELETE /teams/:teamId                          (coach + admin)       → 204
GET    /teams/:teamId/players                  (coach)               → roster
POST   /teams/:teamId/players                  (coach)               → {player, teamPlayer, invite}
POST   /teams/:teamId/players/:playerId        (coach)               → TeamPlayer
DELETE /teams/:teamId/players/:playerId        (coach)               → 204
```

### Players (`/players/*`)
```
GET    /players/:playerId                      (coach + own)         → Player
PATCH  /players/:playerId                      (coach only)          → Player
GET/POST   /players/:playerId/availability                           → Availability
GET/POST   /players/:playerId/injuries
PATCH      /players/:playerId/injuries/:injuryId                     → resolve
GET/POST   /players/:playerId/performance-tests
GET    /players/:playerId/programs?weekStartDate=&from=&to=          → Program[]
POST   /players/:playerId/programs/generate    (coach only)          → Program
```

### Sessions (`/sessions/*`)
```
GET    /sessions/:sessionId/attendance         (auth)                → Attendance[]
POST   /sessions/:sessionId/attendance         (coach bulk)          → result
GET    /sessions/:sessionId/logs                                     → Log[]
POST   /sessions/:sessionId/log                (player only)         → Log
```

### Matches
```
GET    /teams/:teamId/matches                  (coach)               → Match[]
POST   /teams/:teamId/matches                  (coach)               → Match
PATCH  /matches/:matchId                       (coach)               → Match
DELETE /matches/:matchId                       (coach)               → 204
```

### Chat (`/chat/*` + WS)
```
GET    /chat/threads                           (auth)                → ChatThreadSummary[]
POST   /chat/threads                           (coach)               → ChatThread
GET    /chat/threads/:threadId/messages?before=&limit=               → ChatMessage[]
POST   /chat/threads/:threadId/messages                              → ChatMessage
POST   /chat/threads/:threadId/read                                  → 204
WS     /ws/chat?threadId=&token=                                     → real-time msg push
```

### Health
```
GET    /health                                                       → {status, uptimeSeconds, timestamp}
```

**Toplam: 38 REST endpoint + 1 WebSocket route**

---

## 9. Mobil ekranlar

### 22 ekran tek tek

**1. LoginScreen (`login_screen.dart`)**
- E-posta + şifre form
- "Şifremi unuttum" linki (sağa yaslı, küçük)
- "Antrenör olarak kayıt ol" + "Davet kodum var (oyuncu)" alt linkleri
- Form validation: email regex + şifre boş değil
- Submit → `authApi.login()` → token storage'a yaz → Home'a route

**2. RegisterScreen (`register_screen.dart`)**
- Antrenör kaydı: ad, e-posta, şifre (min 8), opsiyonel kulüp adı
- Kulüp adı dolu ise backend hesap + kulüp birlikte oluşturur

**3. PlayerRegisterScreen (`player_register_screen.dart`)**
- Davet kodu input — büyük monospace font, otomatik uppercase, max 16 char
- Ad + e-posta + şifre
- Submit → `authApi.registerPlayer(code, email, password, name)` → otomatik login

**4. ForgotPasswordScreen (`forgot_password_screen.dart`)** — 2 adımlı
- Adım 1: E-posta gir → "Sıfırlama tokeni gönder" → backend dev'de token döner, otomatik adım 2'ye doldurur (mavi info banner: "Geliştirme modu")
- Adım 2: Token + yeni şifre → "Şifreyi sıfırla" → 204 → snackbar + login'e dön
- Production'da adım 1 sonrası token email ile gönderilir, kullanıcı manuel girer

**5. HomeScreen — Antrenör (`home_screen.dart`)**
- SliverAppBar 200px collapsible hero (gradient + dekoratif daireler + avatar + "Hoş geldin")
- AppBar'da ⚙ Settings butonu
- "Antrenör paneli" başlığı + 2 büyük ActionCard:
  - 🛡️ Kulübüm (yeşil gradient ikon)
  - 💬 Mesajlar (mavi gradient + **kırmızı unread badge** sağ üst)
- "Hızlı erişim" 4'lü mini grid:
  - Programlar / Maçlar / Sakatlıklar / Performans (her biri kategori-renkli)
- Lifecycle: app resume olunca chat threads çekilir, unread badge güncellenir

**6. PlayerHomeScreen (`player_home_screen.dart`)**
- Hero'da büyük forma numarası dairesi (beyaz daire, içinde "10")
- AppBar'da ✏ profile-edit + ⚙ Settings butonları
- 4 ActionCard:
  - 📅 Bu haftaki programım
  - 🏃 Hazırbulunuşluk
  - 📊 İstatistiklerim
  - 💬 Mesajlar
- Pull-to-refresh ile MyPlayerInfo yeniden çekilir

**7. SettingsScreen (`settings_screen.dart`)**
- Profil kartı (büyük avatar + ad + email + rol chip)
- Görünüm bölümü: 3 selectable card (Sistem / Açık / Koyu) — selected olana yeşil ✓ ikonu
- Hakkında: app sürüm + API endpoint
- Çıkış kartı (kırmızı errorContainer rengi, onay dialog)

**8. ClubScreen (`club_screen.dart`)**
- Üstte kulüp kartı (logo placeholder + ad + lig + şehir + kuruluş yılı)
- 3 bölüm: Takımlar / Tesisler / Ekipman (her biri sayı badge'li başlık)
- Boş state: "Henüz takım eklenmemiş. Sağ alttaki + Takım ile oluştur"
- "+ Takım" FAB
- Takım uzun-bas → bottom sheet menü: Düzenle / Sil
- Pull-to-refresh

**9. TeamCreateScreen (`team_create_screen.dart`)** — create + edit
- 3 alanlı form: ad + kategori dropdown (U13/U14/.../A Takımı) + sezon (YYYY-YYYY format validation)
- Default sezon Temmuz başlangıçlı
- `existing` param verilirse "Düzenle" başlığı + pre-filled

**10. TeamDetailScreen (`team_detail_screen.dart`)**
- Üstte takım meta kartı (ad + kategori + sezon + Pasif rozeti)
- Kadro listesi (forma no'ya göre sıralı, jersey-no avatar'lı)
- AppBar'da ⚽ ikonu → MatchesScreen
- "+ Oyuncu" FAB
- Oyuncuya tıkla → bottom sheet (8 aksiyon):
  - 📅 Programlar / 📊 İstatistikler / 🩹 Sakatlıklar / ⏱ Performans / 🏃 Hazırbulunuşluk / 💬 Mesaj gönder / ✏ Profili düzenle
- Oyuncuya uzun-bas → kadrodan çıkar onayı

**11. PlayerCreateScreen (`player_create_screen.dart`)**
- 11 alanlı form: ad / doğum (Türkçe date picker) / mevki (4 grup) / detay mevki (kademeli — mevkiye göre değişir) / tercih ayak / boy (cm 120-230) / kilo (kg 30-150) / forma no (1-99) / statü / e-posta opsiyonel
- Submit → CreatePlayerResult döner (player + invite kodu)
- Modal açılır: yeşil ✓ + oyuncu adı + **büyük monospace davet kodu** + 📋 kopyala + son kullanma tarihi

**12. PlayerEditScreen (`player_edit_screen.dart`)**
- Antrenör için: doğum/mevki/detay mevki/ayak/boy/kilo/forma/statü güncelleme
- Ad + e-posta + teamId değiştirilemez (yeniden çıkar/ekle gerekir)

**13. PlayerSelfEditScreen (`player_self_edit_screen.dart`)**
- Oyuncu kendi: boy/kilo/forma/ayak (sadece bunlar)
- Read-only kısım (ad/mevki/statü/doğum) info banner'la: "Antrenörünle iletişime geç"

**14. PlayerStatsScreen (`player_stats_screen.dart`)**
- 4 özet kartı: Toplam antrenman / Toplam dakika / Ort. RPE / Geri bildirim oranı (X/Y)
- **RPE Trend** — son 20 girişi gradient bar chart (intensity-renkli, custom paint, no fl_chart dep)
- Antrenman dağılımı — kategori bazlı progress bar (renkli + ikon + sayı)
- Hazırbulunuşluk dağılımı (son 30 gün) — renkli chip'ler

**15. MatchesScreen (`matches_screen.dart`)**
- Maç kartları: rakip + tarih + ev/dep + lig + skor (varsa, G/B/M renkli rozet)
- "+ Maç" FAB → bottom sheet form (rakip + tarih + saat + Ev/Dep segmented + lig + not)
- Maça tıkla → skor güncelleme modal
- Uzun-bas → sil onayı

**16. InjuriesScreen (`injuries_screen.dart`)**
- Sakatlık kartları (tür + bölge + şiddet renkli + tarihler)
- Aktif sakatlık → "Kapat" butonu, iyileşmiş → "İyileşti" chip
- "+ Yeni" FAB → form (tür + şiddet + bölge + başlangıç + tahmini dönüş + açıklama)
- "Kapat" → resolveInjury

**17. PerfTestsScreen (`perf_tests_screen.dart`)**
- 17 test türü için gruplandırılmış kartlar
- Her kart: en güncel değer (büyük) + delta (önceki değere göre, ▲/▼ + renk) + son 5 geçmiş satır
- "+ Test" FAB → modal (test türü dropdown 17 seçenek + birim auto-fill + değer + tarih + not)

**18. AvailabilityScreen (`availability_screen.dart`)**
- Renk-kodlu kartlar (Hazır=yeşil, Şüpheli=turuncu, Sakat=kırmızı, ...)
- "+ Bildir" FAB (sadece player edit) → form (tarih + 7 durum dropdown + opsiyonel not)
- Coach modunda read-only

**19. ProgramViewScreen (`program_view_screen.dart`)**
- Haftalık program listesi (en yeni üstte)
- Her hafta kartı expandable: 7 günlük seans satırları
- Gün satırı: gün adı (Pzt/Sal/...) + tarih + kategori + tip + dakika + şiddet
- Off günü → "Dinlenme" badge (gri)
- RPE log'u olan seans → yeşil ✓ ikonu, sağda
- Coach için "Bu haftaya üret" extended FAB → engine tetikler → yeni program eklenir

**20. SessionDetailScreen (`session_detail_screen.dart`)**
- Üstte kategori-renkli gradient banner (kategori + tarih)
- 3 metric kutu: süre / şiddet (1-5 renkli) / tip
- Egzersiz listesi:
  - Her satır: 64x64 gradient ikon kutu (kategoriye özel renk + ikon, GIF varsa Image.network) + index badge
  - Egzersiz adı + açıklama (2 satır truncated) + metric chip'leri (set×reps, dakika, mesafe, dinlenme, şiddet)
- Player için en altta RPE form: 1-10 ChoiceChip + 1-5 yorgunluk + 1-5 mood + opsiyonel not
- Coach için: oyuncu RPE girmişse read-only kart

**21. ChatThreadsScreen (`chat_threads_screen.dart`)**
- ListTile per thread: avatar (initial harf) + karşı tarafın adı + rol chip + son mesaj preview + sağda göreceli zaman ("5dk", "1s", "2g") veya unread badge (kırmızı circular)
- Boş state: "Henüz mesaj yok" + role'e özel ipucu
- Pull-to-refresh

**22. ChatRoomScreen (`chat_room_screen.dart`)** — En sofistike
- AppBar: karşı tarafın adı
- Mesaj balonları:
  - Kendisi: sağa yaslı, primary renkli arka plan, bottom-right radius küçük
  - Diğeri: sola yaslı, surfaceContainerHighest, bottom-left radius küçük
  - Her balonda: body + saat (HH:MM)
- Auto-scroll-to-bottom yeni mesajda
- Klavye + send butonu
- **WebSocket bağlantısı** — `ws://10.0.2.2:3000/ws/chat?threadId=&token=`
- Bağlantı koparsa AppBar altında **kırmızı banner** "Bağlantı yok — yeniden deneniyor…" + 5s sonra otomatik reconnect

---

## 10. Emulator'de çalıştırma el rehberi

> Sıfırdan başlayan biri için adım adım. Tahmini süre: ilk seferde 30-45 dakika.

### Önkoşul kontrolü

Aşağıdakilerin **hepsi** kurulu olmalı. Tek tek doğrula:

```cmd
node --version              REM v20+ olmalı
pnpm --version              REM 10+ olmalı
flutter --version           REM 3.41+ olmalı
"C:\Program Files\PostgreSQL\17\bin\psql" --version  REM 17.x olmalı
```

Eksik olanlar için kurulum:
- **Node.js 20+:** https://nodejs.org → LTS
- **pnpm:** `npm install -g pnpm`
- **Flutter:** https://docs.flutter.dev/get-started/install/windows
- **PostgreSQL 17:** https://www.postgresql.org/download/windows/
- **Android Studio + SDK + AVD:** https://developer.android.com/studio

### Adım 1 — Repo'yu hazırla

```cmd
cd C:\Users\umutc\OneDrive\Desktop\Fitness_beslenme_app
pnpm install                                REM tüm workspace bağımlılıkları
copy apps\api\.env.example apps\api\.env    REM env şablonu
```

`apps\api\.env` dosyasını aç, şu değerleri doldur:
```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/fittrack?schema=public"
JWT_SECRET="rastgele-64-char-uzun-bir-string-buraya"
JWT_REFRESH_SECRET="farkli-bir-rastgele-64-char-string"
NODE_ENV="development"
PORT=3000
LOG_LEVEL="info"
CORS_ORIGINS="*"
```

> 💡 Rastgele secret üretmek için: `node -e "console.log(require('crypto').randomBytes(48).toString('base64'))"`

### Adım 2 — PostgreSQL'i başlat

```powershell
"C:\Program Files\PostgreSQL\17\bin\pg_ctl.exe" -D "$env:USERPROFILE\dev\pgdata" start
```

İlk seferde DB cluster initialize gerekirse:
```powershell
"C:\Program Files\PostgreSQL\17\bin\initdb.exe" -D "$env:USERPROFILE\dev\pgdata" -U postgres
"C:\Program Files\PostgreSQL\17\bin\createdb.exe" -U postgres fittrack
```

### Adım 3 — Prisma schema + seed

```cmd
cd C:\Users\umutc\OneDrive\Desktop\Fitness_beslenme_app
pnpm --filter @fittrack/api db:generate    REM Prisma client üret
pnpm --filter @fittrack/api db:push         REM şema → DB
pnpm --filter @fittrack/api db:seed         REM ~190 egzersiz yükle
```

Doğrulama:
```cmd
pnpm --filter @fittrack/api db:studio      REM http://localhost:5555 açılır
```
Studio'da `Exercise` tablosunu kontrol et — ~190 satır olmalı.

### Adım 4 — Backend API'yi başlat

```cmd
pnpm dev:api
```

Beklenen çıktı (renkli):
```
[12:00:00.000] INFO (12345): Server listening at http://127.0.0.1:3000
```

Yeni bir terminal aç, doğrula:
```cmd
curl http://localhost:3000/health
REM {"status":"ok","uptimeSeconds":N,"timestamp":"..."}
```

### Adım 5 — Test hesaplarını oluştur

Antrenör hesabı:
```cmd
curl -X POST http://localhost:3000/auth/register/coach ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"test@fittrack.app\",\"password\":\"Test1234\",\"fullName\":\"Test Antrenor\",\"clubName\":\"Test Kulup\"}"
```

(Yanıttan `accessToken`'i kopyala, takım + oyuncu için kullanacağız.)

```cmd
SET TOKEN=<yapıştır-buraya>
curl -X POST http://localhost:3000/teams ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json" ^
  -d "{\"name\":\"A Takimi\",\"category\":\"senior\",\"season\":\"2025-2026\"}"
```

(Yanıttan `id`'yi kopyala = TEAM_ID)

Oyuncu profili + davet kodu:
```cmd
SET TEAM=<team-id>
curl -X POST http://localhost:3000/teams/%TEAM%/players ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json" ^
  -d "{\"fullName\":\"Test Oyuncu\",\"birthDate\":\"2008-03-15T00:00:00.000Z\",\"position\":\"midfielder\",\"detailedPosition\":\"CM\",\"preferredFoot\":\"right\",\"heightCm\":178,\"weightKg\":72,\"jerseyNumber\":10,\"employmentStatus\":\"amateur\"}"
```

(Yanıttan `invite.code`'u kopyala)

Oyuncu hesabı:
```cmd
SET CODE=<davet-kodu>
curl -X POST http://localhost:3000/auth/register/player ^
  -H "Content-Type: application/json" ^
  -d "{\"inviteCode\":\"%CODE%\",\"email\":\"oyuncu@fittrack.app\",\"password\":\"Oyuncu1234\",\"fullName\":\"Test Oyuncu\"}"
```

### Adım 6 — Android Studio + AVD başlat

**a) Tek tıkla (önerilen):**
```cmd
cd C:\Users\umutc\OneDrive\Desktop\Fitness_beslenme_app
studio.bat
```

`studio.bat` otomatik:
1. Android Studio'yu açar
2. İlk AVD'yi (örn. `Medium_Phone`) arka planda boot eder
3. `adb shell getprop sys.boot_completed` ile bekler (max 180s)
4. Yeni cmd penceresinde `flutter run apps/mobile` başlatır

**b) Manuel:**
```cmd
REM 1. Android Studio aç
"C:\Program Files\Android\Android Studio\bin\studio64.exe"

REM 2. AVD Manager'dan bir AVD oluştur (yoksa) — Pixel 6 + API 34 önerilir
REM 3. AVD'yi başlat (Studio'dan veya komutla):
"C:\Users\umutc\AppData\Local\Android\Sdk\emulator\emulator.exe" -avd Medium_Phone

REM 4. Emulator boot olunca (yeşil ev ikonu + saat göründüğünde):
cd apps\mobile
flutter run
```

### Adım 7 — Build'in tamamlanmasını bekle

İlk build için ~3-10 dakika (Gradle dependency download, Kotlin compile, Dart compile). Sonraki build'ler 30-60 saniye.

Çıktıda göreceğin önemli satırlar:
```
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk
Installing build/app/outputs/flutter-apk/app-debug.apk...
Syncing files to device sdk gphone16k x86 64...
Flutter run key commands.
r Hot reload.
R Hot restart.
q Quit
A Dart VM Service on sdk gphone16k x86 64 is available at: http://...
```

Son satırı görünce app emulator'de açılmıştır.

### Adım 8 — Test girişi

Emulator'de açılan fittrack uygulamasında:

1. **Login ekranı** açılır — fittrack başlık + form
2. E-posta: `test@fittrack.app` / Şifre: `Test1234` → "Giriş yap"
3. **Antrenör Home** açılır — yeşil hero header

### Sorun giderme (sık karşılaşılanlar)

**❌ "No connected devices"**
→ Emulator açık mı? `adb devices` ile kontrol et. Boş ise emulator boot et.

**❌ "Sunucuya bağlanılamadı (10.0.2.2:3000)"**
→ API çalışıyor mu? `curl http://localhost:3000/health` host'ta dene. Çalışıyor ama emulator bağlanamıyorsa: emulator'ün host'a `10.0.2.2` ile eriştiğini biliyor musun? (Bilinen değer)

**❌ "INFO Critical: Failed to load opengl32sw"**
→ Sadece warning, ignore. Emulator yine de açılır.

**❌ adb "device offline"**
→ Emulator'de "Allow USB debugging" popup'ı var. Allow'a bas. Sonrasında: `adb kill-server && adb start-server`.

**❌ "Build failed: ... Gradle"**
→ Internet bağlantısı kontrol et (Gradle ilk build'de dependency indiriyor). Antivirüs Gradle wrapper'ı engelliyor olabilir.

**❌ "Connection refused" WebSocket**
→ API restart edildi mi? `tsx watch` ile auto-reload normalde çalışır ama bazen takılır. `pnpm dev:api` yeniden çalıştır.

**❌ Hot reload çalışmıyor**
→ flutter run cmd penceresinde `r` (küçük r) tuşuna bas. `R` (büyük) hot restart yapar (state reset).

**❌ "Davet kodu geçersiz"**
→ Backend'de invite süresi doldu (varsayılan 14 gün). Yeni kod üret: koç olarak login → bir takıma yeni oyuncu ekle.

---

## 11. Demo senaryosu

> Sunum sırasında ekrandan ekrana akacak 15-20 dakikalık akış. Her adım için **ne yapacağın + ne göstereceğin + ne diyeceğin**.

### Açılış (1 dk) — "Vizyon"

Ekrana: SUNUM.md'nin ilk paragrafı.

> "Bu uygulama, alt lig ve akademi futbol antrenörlerinin pratik problemlerini çözmek için tasarlandı. Tek başına çalışan koç, sınırlı bütçe, manuel veri girişi gerçekliği... Premier League değil, lokal kulüp."

### Bölüm A — Antrenör Akışı (8 dk)

**1. Login + Modern UI (1 dk)**
- `studio.bat` ile uygulama açılır
- Login ekranı: `test@fittrack.app` / `Test1234` → Giriş yap
- Antrenör Home açılır
- "Settings'e gidiyorum, dark mode toggle..." → ⚙ → Koyu seç → "Anında değişiyor, kalıcı (kapatıp açtığında hatırlanır)"

**2. Kulüp + Takım (1 dk)**
- "Kulübüm" tile → ClubScreen
- "Test Kulup" kartını göster: "Backend kulüp meta'sını getiriyor"
- "+ Takım" FAB → form: ad="U17 A", kategori=U17, sezon=otomatik
- "Takımı oluştur" → snackbar + listede görünür
- "Bu varsayılan sezon, Temmuz başlangıçlı"

**3. Oyuncu Oluştur + Davet Kodu (2 dk)**
- Yeni takıma tıkla → boş kadro
- "+ Oyuncu" FAB → 11 alanlı form
- "Doğum tarihi alanına basın..." → **Türkçe ay isimleri** (Ocak/Şubat...) — "flutter_localizations ile"
- Form doldur (örnek: Mehmet Demir, 17 yaş, CM, sağ ayak, 178/72, forma 9)
- Submit → **yeşil ✓ modal** açılır → davet kodu büyük + monospace
- "📋 kopyala" → "Bu kodu WhatsApp'tan oyuncuya gönderiyor antrenör. Oyuncu bu kodla kayıt oluyor — şifre paylaşmaya gerek yok"

**4. Engine ile Program Üretme (2 dk)**
- Oyuncuya tıkla → bottom sheet 8 aksiyon → "Programlar"
- ProgramView boş → "Bu haftaya üret" extended FAB
- Tıkla → loading spinner → "Engine 7 günlük plan üretiyor"
- 1-2 saniye sonra haftalık kart belirir
- Aç → 7 gün listesi:
  - Pzt: Güç (mor) — 60 dk şiddet 4
  - Salı: Sürat & çeviklik (turuncu) — 45 dk şiddet 4
  - Çar: Toparlanma (yeşil) — 30 dk şiddet 1 (off)
  - vs.
- "Engine kural tabanlı — neden 'Salı=sürat' diye sorulduğunda explain edilebilir. Match week'te MD-3=hacim, MD-2=şiddet, MD-1=hafif, vs."
- Bir güne tıkla → SessionDetail
- Üstte gradient banner kategori-renkli, 3 metric kutu, altında egzersiz listesi
- Her egzersiz: kategori-ikon kutusu + numaralı badge + chip'ler (3×10, 60sn dinlenme, ...)

**5. Mesajlaşma — Gerçek Zamanlı (2 dk)**
- Oyuncudan geri çık → kadro → oyuncu bottom sheet → "Mesaj gönder"
- ChatRoom açılır → boş
- "Yarın 18:00 antrenman var, hazır mısın?" yaz → gönder → balon sağda yeşil
- "Bu mesaj WebSocket ile push edilir, polling değil. Şimdi oyuncu hesabına geçince anında görecek"

### Bölüm B — Oyuncu Akışı (5 dk)

**6. Logout + Oyuncu Login (30 sn)**
- Settings'ten logout → Login
- `oyuncu@fittrack.app` / `Oyuncu1234` → Giriş yap
- PlayerHome açılır — **forma 10 dairesi** + ad + mevki

**7. Mesajı Gör + Cevap Yaz (1 dk)**
- "Mesajlar" tile → thread listesi → antrenör thread'i (kırmızı badge ile unread)
- Aç → balonlar görünür (antrenör balonu sol-gri)
- "Hazırım koç" yaz → gönder
- "Şimdi tekrar antrenör hesabına dönecek olursak — anında görecek"

**8. Programa Bak + RPE Gir (2 dk)**
- Geri → "Bu haftaki programım" → ProgramView
- Coach hesabıyla aynı programı görüyor (read-only — "Bu haftaya üret" FAB yok)
- Bir günü aç → seans → SessionDetail
- En altta **RPE form** → 1-10 ChoiceChip 8 efor, 1-5 yorgunluk 3, 1-5 mood 4, not opsiyonel
- "Kaydet" → snackbar + form "Güncelle" moduna geçer

**9. Hazırbulunuşluk + Self-Edit (1 dk)**
- Geri → "Hazırbulunuşluk" → "+ Bildir" → bugün "Hazır" → kaydet
- Geri → AppBar ✏ → Profilimi düzenle → boy=180 yap → kaydet

**10. İstatistikler (30 sn)**
- "İstatistiklerim" → 4 özet kartı (toplam antrenman, dakika, ort RPE, geri bildirim)
- RPE bar chart: tek girişin (8) yeşil-turuncu gradient bar
- Antrenman dağılımı: kategori bar'ları
- Hazırbulunuşluk: "Hazır × 1" yeşil chip

### Bölüm C — Kapanış (3 dk)

**11. Antrenöre Dön — Real-time Doğrulama (1 dk)**
- Logout → antrenör login
- Home'da Mesajlar tile'ında **kırmızı badge "1"** (oyuncunun "Hazırım koç" mesajı için)
- "Mesajlar" → thread → cevabı gör

**12. Oyuncunun RPE'sini Gör (1 dk)**
- Geri → Test Oyuncu → "Programlar" → o seansa gir
- En altta "Oyuncu geri bildirimi" kartı RPE 8 + yorgunluk 3 + mood 4 görünür
- "Antrenör artık planı kalibre edebilir — Salı çok yüklendi mi diye"

**13. Şifremi Unuttum (1 dk)**
- Logout → Login → "Şifremi unuttum"
- E-posta gir → "Sıfırlama tokeni gönder" → mavi info banner + token otomatik dolar
- Yeni şifre gir → "Şifreyi sıfırla" → snackbar + login'e dön
- "Production'da bu token email ile gönderilir, dev modunda response'da geliyor"

### Anahtar mesajlar (sunum boyunca tekrarla)

- "Engine kural tabanlı — şeffaf"
- "Backend Fastify + Prisma + Postgres"
- "Mobile Flutter, tek codebase Android + iOS"
- "Real-time chat WebSocket"
- "Token refresh otomatik — kullanıcı manuel relogin yapmaz"
- "Dark mode + Türkçe + modern UI"
- "Hedef kullanıcı = alt lig koçu, bütçesiz, tek başına"

---

## 12. Test hesapları

```
Antrenör:
  E-posta : test@fittrack.app
  Şifre   : Test1234
  Kulüp   : Test Kulup
  Takım   : "00"

Oyuncu:
  E-posta : oyuncu@fittrack.app
  Şifre   : Oyuncu1234
  Profil  : Test Oyuncu, 17 yaş, CM, sağ ayak, 178cm/72kg, forma 10
  Bonus   : Bu hafta için 6 seanslık match_week programı üretildi
```

DB reset edilirse `Adım 5`'i tekrar çalıştır.

---

## 13. SSS

**S: Backend ve mobile aynı bilgisayarda olmak zorunda mı?**
C: Geliştirme için evet — emulator host'a `10.0.2.2:3000` ile bağlanır. Production'da backend ayrı sunucuda, mobile'ın `lib/api/api_client.dart` içindeki `apiBaseUrl` değişir.

**S: Gerçek Android telefona kurulabilir mi?**
C: Evet. `flutter build apk --release` ile APK üret, telefona yükle. Ama API base URL'i değiştirmek lazım — `10.0.2.2` çalışmaz, gerçek IP veya domain gerek.

**S: iOS'ta çalışır mı?**
C: Scaffolding hazır (`apps/mobile/ios/`). macOS + Xcode + Apple Developer hesabı ile `flutter build ios` ile derlenir. Windows'ta build edilemez (Apple sınırlaması).

**S: Engine algoritmasını nasıl değiştirebilirim?**
C: `apps/api/src/services/program-engine/` altındaki dosyalar:
- `plan-week.ts`: Hangi gün hangi kategori
- `select-exercises.ts`: Egzersiz havuzundan filtreleme kriterleri
- `index.ts`: Akış orchestrator
Değişiklikten sonra `ENGINE_VERSION` bump et ve `program-engine/README.md`'de notla.

**S: Yeni bir egzersiz kategorisi nasıl eklenir?**
C: 3 yer:
1. `packages/shared/src/schemas/enums.schema.ts` — `TrainingCategorySchema` enum'una ekle
2. `apps/api/prisma/schema.prisma` — Prisma enum'una ekle, migration üret
3. `apps/mobile/lib/util/labels.dart` + `exercise_visuals.dart` — Türkçe label + ikon/renk

**S: Push notification yok mu?**
C: Henüz yok. Firebase Cloud Messaging entegrasyonu gerekiyor (mobile + backend tarafı).

**S: Egzersiz GIF'leri yok, neden?**
C: Backend seed'de URL field var ama boş. Açıklama: `apps/mobile/README.md` → "Egzersiz görselleri" bölümü. ExerciseDB API ile populate edilebilir.

**S: WebSocket multi-user nasıl çalışıyor?**
C: `chat-hub.ts` her thread için subscriber set tutuyor. Coach + Player aynı thread'e subscribe ise birinin mesajı diğerine push edilir. Multi-instance backend deploy için Redis pub/sub gerekir (kod yorumu var).

**S: Real production deployment için neler yapılmalı?**
C: 7 madde, hepsi `README.md` "Bilinen sınırlamalar" tablosunda:
1. API base URL env config
2. HTTPS + cleartext kapatma
3. Token refresh süreleri ayarla
4. Egzersiz görselleri populate
5. Email service (forgot password için)
6. Push notification (Firebase)
7. WebSocket için Redis (multi-instance)

---

## 14. Bilinen sınırlamalar

| # | Sorun | Etkilenen dosya | Çözüm |
|---|-------|-----------------|-------|
| 1 | API base URL hardcoded `10.0.2.2:3000` | `apps/mobile/lib/api/api_client.dart` | Build flavor / env config |
| 2 | `usesCleartextTraffic="true"` | `android/app/src/main/AndroidManifest.xml` | HTTPS + bayrak kaldır |
| 3 | Egzersiz görselleri yok | `apps/api/prisma/seed/exercises.ts` | ExerciseDB API entegre |
| 4 | Şifremi unuttum email yok | `apps/api/src/services/password-reset.service.ts` | Resend/SendGrid + dev token kaldır |
| 5 | Push notification yok | — | Firebase Cloud Messaging |
| 6 | Avatar upload yok | — | Backend `/users/:id/avatar` + S3/Cloudinary |
| 7 | iOS gerçek build | — | macOS + Xcode + Apple Developer |
| 8 | Multi-instance chat | `apps/api/src/services/chat-hub.ts` | Redis pub/sub |
| 9 | Multi-instance password reset | `apps/api/src/services/password-reset.service.ts` | Redis veya DB tablosu |
| 10 | Performance test attendance UI | — | Bireysel programda anlamsız; team programları gelince UI eklenir |
| 11 | Token süresi kısa (dev) | `apps/api/.env` | Production'da uzat |

---

## Sonuç

> Bu sunum dosyası, fittrack uygulamasının tüm yönlerini kapsar: vizyon, tasarım kararları, teknoloji yığını, mimari, dosya dosya açıklama, endpoint listesi, ekran-bazlı tur, sıfırdan kurulum + emulator çalıştırma rehberi, demo senaryosu, SSS, sınırlamalar.
>
> Tek başına okunduğunda projeyi sıfırdan ayağa kaldırma + sunma için yeterli olmalıdır.
>
> **İletişim:** Geliştirme detayı için [`README.md`](./README.md) ve [`apps/mobile/README.md`](./apps/mobile/README.md). Engine kalibrasyonu için [`apps/api/src/services/program-engine/README.md`](./apps/api/src/services/program-engine/README.md). Agent çalışma kuralları için [`CONTEXT.md`](./CONTEXT.md).
