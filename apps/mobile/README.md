# fittrack mobile

> Flutter Android uygulaması — `app.fittrack`. Antrenör + oyuncu rolleri, koyu mod, Türkçe arayüz.

Daha geniş genel bakış: [root README](../../README.md).

## Hızlı başlangıç

```cmd
flutter pub get
flutter run                  REM debug, hot reload
flutter analyze              REM 0 hata, 0 warning
flutter test                 REM widget smoke test
```

API çalışır olmalı: `pnpm dev:api` (root). Emulator'den host'a `http://10.0.2.2:3000`.

## Stack

- **Flutter 3.41 / Dart 3.11**
- Material 3, light + **dark mode** (sistem + manuel toggle, persisted)
- Türkçe locale + Türkçe date picker (`flutter_localizations`)
- HTTP: `dio` 5.x, auth interceptor + 401 → otomatik token refresh
- Storage: `flutter_secure_storage` 10.x (Android Keystore'da token + tema)
- State: yok — `StatefulWidget` + callback (basit yetti)

## Klasör yapısı

```
lib/
├── main.dart                      # FittrackApp + theme state + role-based routing
├── api/
│   ├── api_client.dart            # Dio instance + auth interceptor + 401→refresh+retry
│   ├── api_exception.dart         # DioException → ApiException (Türkçe mesaj)
│   ├── auth_api.dart              # login/register coach+player/me/refresh/logout
│   ├── chat_api.dart              # threads/messages/send/read/start
│   ├── clubs_api.dart             # getMyClub/listFacilities/listEquipment
│   ├── health_api.dart            # availability + injuries + performance tests
│   ├── matches_api.dart           # CRUD + skor güncelleme
│   ├── players_api.dart           # getMyPlayer/getPlayer/updatePlayer
│   ├── programs_api.dart          # generate/list/logSession
│   └── teams_api.dart             # CRUD + roster + create/remove player
├── models/                        # 11 model — manuel JSON parse, freezed yok
│   ├── auth_tokens.dart, user.dart
│   ├── club.dart                  # Club + Facility + Equipment
│   ├── team.dart, player.dart, exercise.dart
│   ├── program.dart               # TrainingProgram + Session + Exercise + Log
│   ├── match.dart, invite.dart
│   ├── health.dart                # Availability + Injury + PerformanceTest
│   └── chat.dart                  # ChatThreadSummary + ChatThread + ChatMessage
├── screens/                       # 20 ekran
│   ├── login_screen.dart, register_screen.dart, player_register_screen.dart
│   ├── home_screen.dart           # antrenör hero + ActionCard'lar + mini grid
│   ├── player_home_screen.dart    # oyuncu hero + 4 ActionCard
│   ├── settings_screen.dart       # tema seçici + profil + logout
│   ├── club_screen.dart           # kulüp + takımlar + tesisler + ekipman
│   ├── team_create_screen.dart    # create + edit (existing param)
│   ├── team_detail_screen.dart    # roster + AppBar Maçlar + bottom sheet 8 aksiyon
│   ├── player_create_screen.dart  # 11 alanlı form + invite kod modal
│   ├── player_edit_screen.dart    # PATCH-friendly subset
│   ├── matches_screen.dart        # fikstür + skor modal
│   ├── injuries_screen.dart       # sakatlık liste + create + resolve
│   ├── perf_tests_screen.dart     # 17 test + delta + history
│   ├── availability_screen.dart   # bildirim + 30 gün liste
│   ├── program_view_screen.dart   # haftalık takvim + generate FAB
│   ├── session_detail_screen.dart # egzersiz listesi + RPE form / log kartı
│   ├── player_stats_screen.dart   # RPE chart + kategori bar + availability dağılım
│   ├── chat_threads_screen.dart   # thread liste + unread badge
│   └── chat_room_screen.dart      # mesaj balonları + 5s polling + send
├── storage/
│   └── token_storage.dart         # tokens + tema modu persistence
└── util/
    ├── labels.dart                # 14 enum sözlüğü Türkçe + tarih helper
    └── exercise_visuals.dart      # kategori → ikon + renk + intensity color
```

## Davranış desenleri

### Routing

`main.dart` rol-bazlı:
- `_user == null` → `LoginScreen`
- `_user.isPlayer` → `PlayerHomeScreen`
- `_user.isCoach` → `HomeScreen` (antrenör)

Boot sırasında token varsa `/auth/me` çağrılır → User alınır → home'a düşer. 401 olursa token silinir → login.

### Tema

`TokenStorage.readThemeMode()` / `writeThemeMode()` — `light` / `dark` / `system`. Default `system`. `MaterialApp.themeMode` bu state'e bağlı.

Custom theme (`_buildTheme(brightness)` in main.dart):
- Material 3 + `ColorScheme.fromSeed(0xFF1B5E20)` (futbol yeşili)
- Dark scaffold `0xFF0E1411`, kart `0xFF1A2620`, AppBar `0xFF14201A`
- Card 16dp radius + ince border, FilledButton 12dp, TextField 12dp + 2px focus border, FAB 16dp

### Token refresh

`ApiClient` interceptor `onResponse`:
- 401 yakalanır + path `/auth/*` değilse
- Ayrı `_refreshDio` ile `/auth/refresh` çağrılır (recursion önlemek için)
- Yeni token saklanır, orijinal isteğin `Authorization` header'ı güncellenir, retry edilir
- Refresh fail → tokens temizlenir + `onAuthExpired` callback → main.dart logout state'e döner

### Hata zinciri

```
DioException
  → toApiException(e)
  → throw ApiException(message Türkçe, statusCode)
  → ekran try/catch yakalar
  → SnackBar veya inline error card
```

`ensureOk(res)` 4xx yakalar (validateStatus<500 olduğu için response handler'a düşer).

### State pattern (per ekran)

Her ekran 4 state:
1. **Loading** — `CircularProgressIndicator`
2. **Error** — error card + "Tekrar dene" butonu
3. **Empty** — büyük ikon + açıklayıcı metin + (opsiyonel) FAB hatırlatıcısı
4. **Data** — RefreshIndicator + içerik

Pattern referansı: `club_screen.dart`.

### Modal pattern

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (_) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: _MyForm(...),
  ),
);
```

`viewInsets.bottom` klavye için. Drag handle, başlık, sonra form.

### Setstate gotcha

Arrow body Future döndürürse Flutter assert atar:

```dart
// ❌ HATALI
void _load() => setState(() => _future = _fetch());

// ✅ DOĞRU
void _load() {
  setState(() {
    _future = _fetch();
  });
}
```

## Egzersiz görselleri

Backend `ExerciseSummary` zaten `thumbnailUrl` + `imageUrls` field'larına sahip. Şu an seed data'da boş. SessionDetail `_ExerciseRow`:

```dart
final mediaUrl = item.exercise.thumbnailUrl;
// ...
mediaUrl != null && mediaUrl.isNotEmpty
  ? Image.network(mediaUrl,
      errorBuilder: (_, __, ___) => Icon(visual.icon, ...),
      loadingBuilder: ...)
  : Icon(visual.icon, ...)  // kategori-renkli fallback
```

**Görsel eklemek için backend tarafında:**
- Seed dosyası `apps/api/prisma/seed/exercises.ts`
- ExerciseDB API: `https://static.exercisedb.dev/media/{exerciseId}.gif` (gym ağırlıklı, sınırlı uyum)
- Wikimedia Commons: futbol özelinde fewer ama CC-BY-SA güvenli kaynak
- Veya kendi CDN'inize yükleyip URL'leri seed'e işleyin

## Geliştirme

```cmd
flutter pub get                 REM dep'ler
flutter analyze                 REM 0 hata, 0 warning, ~6 info-level Dart 3 syntax önerisi
flutter test                    REM smoke test
flutter run                     REM debug build, hot reload (r=reload, R=restart, q=quit)
flutter run --release           REM release build
flutter build apk               REM debug APK
flutter build apk --release     REM release APK (signing config gerekli)
```

### Yeni ekran ekleme

1. `lib/screens/yeni_ekran.dart` oluştur
2. Pattern: `StatefulWidget` + `Future<T>` field + `_load()` + `FutureBuilder` + 4 state
3. Navigator stack'e ekle: `Navigator.push(MaterialPageRoute(builder: (_) => YeniEkran(...)))`
4. Refresh hook: `_load()` then(`(_) => _load()`) pattern'iyle stale data önle

### Yeni API endpoint ekleme

1. `lib/api/<domain>_api.dart` — try/catch DioException + `ensureOk(res)` + `toApiException(e)`
2. Model: `lib/models/<domain>.dart` — `factory fromJson(Map<String, dynamic>)`
3. main.dart'ta API instance oluştur, ilgili ekrana parametre olarak geçir

### Yeni dep ekleme

CONTEXT kuralı 12: **her dep için onay al**.

```cmd
flutter pub add <package>
```

Mevcut deps:
- `dio` — HTTP client (interceptor + token refresh)
- `flutter_secure_storage` — Android Keystore
- `flutter_localizations` — Türkçe date picker (SDK paketi, third-party değil)

## Test

Mevcut: 1 widget smoke test (boot → login screen render).

```cmd
flutter test
```

Genişletme:
- Service-level mock test (Dio adapter mock)
- Integration test (`integration_test/` klasörü)
- E2E (Flutter Driver)

## Deploy

Şu an dev only. Release build için:
1. `apps/mobile/android/app/build.gradle.kts` — release signing config
2. `apps/mobile/android/app/src/main/AndroidManifest.xml` — `usesCleartextTraffic` kaldır + HTTPS
3. `lib/api/api_client.dart` — base URL build flavor'a bağla
4. `flutter build apk --release` veya `flutter build appbundle --release`

## Bilinen sınırlamalar

- API base URL hardcoded `10.0.2.2:3000`
- Cleartext HTTP açık (dev için)
- Real-time chat = 5s polling
- Avatar upload yok
- Şifremi unuttum yok
- Push notification yok
- iOS yok (`flutter create --platforms=ios .` ile eklenebilir)

Tam liste: [root README — Bilinen sınırlamalar](../../README.md#bilinen-sınırlamalar).
