# FitTrack — Kurulum Rehberi

> Bu doküman, **fittrack** projesini sıfırdan ayağa kaldırmak için kurmanız gereken tüm programları, neden kurulduklarını, nereden indirileceklerini ve doğrulama komutlarını içerir. Sıralı ilerleyin; her adımdan sonra doğrulama komutunu çalıştırın.
>
> **Tahmini toplam süre:** İlk kurulum için 1–1.5 saat (indirme hızına bağlı). Adım adım kurulum yaklaşık 30 dakika işlem süresi alır, geri kalanı indirme ve build süreleridir.

---

## İçindekiler

1. [Genel bakış — neyi neden kuruyoruz](#1-genel-bakış)
2. [Kurulum sırası özet tablosu](#2-kurulum-sırası-özet-tablosu)
3. [Node.js 20+ kurulumu](#3-nodejs-20-kurulumu)
4. [pnpm 10+ kurulumu](#4-pnpm-10-kurulumu)
5. [PostgreSQL 17 kurulumu](#5-postgresql-17-kurulumu)
6. [Flutter 3.41+ kurulumu](#6-flutter-341-kurulumu)
7. [Android Studio + SDK + AVD kurulumu](#7-android-studio--sdk--avd-kurulumu)
8. [Git kurulumu (opsiyonel ama önerilen)](#8-git-kurulumu)
9. [Kod editörü (VS Code önerilir)](#9-kod-editörü-önerilen-vs-code)
10. [Toplu doğrulama — her şey doğru kuruldu mu?](#10-toplu-doğrulama)
11. [Sık karşılaşılan kurulum sorunları](#11-sık-karşılaşılan-kurulum-sorunları)
12. [Sonraki adım — projeyi ayağa kaldırma](#12-sonraki-adım)

---

## 1. Genel bakış

FitTrack iki ayrı uygulamadan oluşur:

- **Backend (apps/api):** Node.js + TypeScript + Fastify + Prisma + PostgreSQL üzerinde çalışan bir REST + WebSocket API
- **Mobile (apps/mobile):** Flutter ile yazılmış Android (ve iOS scaffolding'i hazır) uygulaması

Bu iki katman için **6 ana program + 2 opsiyonel program** kurmanız gerekiyor. Aşağıda her birinin **ne işe yaradığını ve neden gerektiğini** açıklıyorum.

| # | Program | Ne için kullanılıyor |
|---|---------|---------------------|
| 1 | **Node.js 20+** | Backend'i çalıştıran JavaScript runtime'ı. TypeScript kodu Node üzerinde çalışır. |
| 2 | **pnpm 10+** | Paket yöneticisi. Projedeki tüm bağımlılıkları yükler. npm yerine pnpm kullanılmasının nedeni: monorepo (workspace) desteği daha güçlü, disk kullanımı daha az. |
| 3 | **PostgreSQL 17** | İlişkisel veritabanı. Kulüp, takım, oyuncu, program, egzersiz verileri burada saklanır. |
| 4 | **Flutter 3.41+** | Mobil uygulamanın geliştirildiği framework. Dart dili dahil gelir. |
| 5 | **Android Studio + SDK** | Android emülatörü (AVD) ve uygulamayı build etmek için gerekli SDK'lar. |
| 6 | **AVD (Android Virtual Device)** | Telefonu simüle eden sanal cihaz. Uygulamayı burada test edeceğiz. |
| 7 | **Git** (opsiyonel) | Versiyon kontrol. Kod tabanını klonlamak için. |
| 8 | **VS Code veya benzeri** (opsiyonel) | Kod editörü. Android Studio ağır geldiğinde günlük geliştirme için. |

---

## 2. Kurulum sırası özet tablosu

Bu sırayla ilerleyin; her birinin doğrulama komutuyla doğru kurulduğundan emin olun.

| Sıra | Program | Sürüm | İndirme | Doğrulama komutu |
|-----|---------|-------|---------|------------------|
| 1 | Node.js | 20 LTS+ | https://nodejs.org | `node --version` |
| 2 | pnpm | 10+ | `npm install -g pnpm` | `pnpm --version` |
| 3 | PostgreSQL | 17 | https://www.postgresql.org/download/windows/ | `psql --version` |
| 4 | Git | latest | https://git-scm.com/download/win | `git --version` |
| 5 | Flutter SDK | 3.41+ | https://docs.flutter.dev/get-started/install/windows | `flutter --version` |
| 6 | Android Studio | latest | https://developer.android.com/studio | (GUI ile açılır) |
| 7 | Android SDK + AVD | API 34+ | Android Studio içinden | `adb --version` |
| 8 | VS Code (opsiyonel) | latest | https://code.visualstudio.com | `code --version` |

---

## 3. Node.js 20+ kurulumu

**Niye gerekiyor:** Backend API Node.js üzerinde çalışıyor. TypeScript dosyaları `tsx` ile Node'a derleniyor.

### İndirme ve kurulum

1. https://nodejs.org adresine git.
2. **LTS** (Long Term Support) sürümünü indir — şu anda **v20.x** veya **v22.x** olmalı. (En az v20 lazım.)
3. İndirilen `.msi` dosyasını çalıştır → **Next**, **Next**, **Install**.
4. Kurulum sırasında **"Add to PATH"** seçeneği işaretli olsun (varsayılan).
5. Opsiyonel: "Tools for Native Modules" sayfasında onay kutusunu işaretlemen gerekmez — bizim projemizde native build yok.

### Doğrulama

Yeni bir **Komut İstemi** (cmd) veya **PowerShell** penceresi aç (mevcut açık olanlar PATH'i göremez):

```cmd
node --version
```

Çıktı şuna benzer olmalı:
```
v20.18.0
```

Ayrıca `npm` de otomatik gelir:
```cmd
npm --version
```

> ⚠️ Çıktı `v18.x` veya altı ise: eski sürümü kaldır, yeniden kur. v20'nin altı **yetersiz**.

---

## 4. pnpm 10+ kurulumu

**Niye gerekiyor:** Proje pnpm workspace (monorepo) yapısında. `apps/api`, `apps/mobile`, `packages/shared` aynı `pnpm install` ile yönetiliyor. npm ile çalışmaz.

### Kurulum

Node.js kurulduktan sonra **tek komut yeterli:**

```cmd
npm install -g pnpm
```

### Doğrulama

```cmd
pnpm --version
```

Çıktı `10.x.x` veya üstü olmalı (örn. `10.13.1`).

> 💡 İlk seferde global path uyarısı çıkarsa: PowerShell'i kapat, yeniden aç.

---

## 5. PostgreSQL 17 kurulumu

**Niye gerekiyor:** Projenin veri katmanı. Prisma ORM bu DB üzerinde çalışıyor. Mongo, MySQL veya SQLite **uyumsuz** — Prisma şeması Postgres'e özgü özellikler kullanıyor (örn. `jsonb`).

### İndirme

1. https://www.postgresql.org/download/windows/ adresine git.
2. **"Download the installer"** linkine tıkla → EDB Installer'a yönlendirir.
3. **PostgreSQL 17.x — Windows x86-64** sürümünü indir (~300 MB).

### Kurulum

İndirilen `.exe`'yi çalıştır:

1. **Installation Directory:** Varsayılan `C:\Program Files\PostgreSQL\17` — değiştirme.
2. **Select Components:** Hepsi işaretli kalsın:
   - PostgreSQL Server ✅
   - pgAdmin 4 ✅ (görsel DB yönetimi için)
   - Stack Builder ✅
   - Command Line Tools ✅
3. **Data Directory:** Varsayılan `C:\Program Files\PostgreSQL\17\data` — değiştirme.
4. **Password:** `postgres` kullanıcısı için bir şifre belirle. **NOT AL** — `.env` dosyasında kullanacaksın. Örnek: `postgres` (basit, dev için).
5. **Port:** `5432` — değiştirme.
6. **Locale:** `Default locale` — değiştirme.
7. **Pre-Installation Summary** → **Next** → **Install** (~5 dakika).
8. Kurulum bitince **"Launch Stack Builder"** kutusunun işaretini KALDIR → **Finish**.

### PATH ekleme (önemli)

PostgreSQL komutları PATH'te olmazsa `psql` direkt çalışmaz. **Sistem Ortam Değişkenleri**'ne ekle:

1. Windows arama → **"environment variables"** → **"Edit the system environment variables"**
2. **Environment Variables...** → **Path** → **Edit** → **New**
3. Şunu ekle: `C:\Program Files\PostgreSQL\17\bin`
4. **OK** → **OK** → **OK**.
5. Tüm cmd/PowerShell pencerelerini kapat, yeniden aç.

### Doğrulama

```cmd
psql --version
```

Çıktı: `psql (PostgreSQL) 17.x`

Bağlantı testi (şifre soracak — kurulumda belirlediğin):
```cmd
psql -U postgres -h localhost
```

`postgres=#` prompt'u açılırsa başarılı. `\q` ile çık.

### `fittrack` veritabanını oluştur

Projenin kullanacağı boş DB'yi oluştur:

```cmd
"C:\Program Files\PostgreSQL\17\bin\createdb.exe" -U postgres fittrack
```

Şifre sorar — kurulumdaki şifre.

Tablolar Prisma `db:push` ile sonradan otomatik gelecek; şimdilik boş DB yeterli.

---

## 6. Flutter 3.41+ kurulumu

**Niye gerekiyor:** Mobil uygulama Flutter ile yazıldı. Dart dili Flutter SDK'sıyla beraber gelir.

### İndirme

1. https://docs.flutter.dev/get-started/install/windows adresine git.
2. **"Get the Flutter SDK"** bölümünden **"flutter_windows_3.x.x-stable.zip"** dosyasını indir (~1 GB).

### Kurulum

1. İndirilen zip'i şuraya çıkar: `C:\src\flutter` (yol kısa olsun; `Program Files` veya boşluklu dizinlere koyma — Flutter sorun çıkarır).

   > ⚠️ `C:\Program Files\flutter` **YANLIŞ**. Boşluk Flutter'ı kırar. `C:\src\flutter` veya `C:\flutter` kullan.

2. PATH'e ekle:
   - Windows arama → **"environment variables"** → **"Edit the system environment variables"**
   - **Environment Variables...** → **Path** → **Edit** → **New**
   - Şunu ekle: `C:\src\flutter\bin`
   - **OK** → **OK** → **OK**
3. Tüm cmd pencerelerini kapat, yeniden aç.

### Doğrulama

```cmd
flutter --version
```

Çıktı:
```
Flutter 3.41.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision ...
Engine • revision ...
Tools • Dart 3.11.0
```

### `flutter doctor` ile sağlık kontrolü

```cmd
flutter doctor
```

İlk çalıştırmada şuna benzer çıktı verir (henüz tüm araçlar kurulmadığı için bazı satırlar **❌ x** olacak — normal):

```
[✓] Flutter (Channel stable, 3.41.0, on Microsoft Windows ...)
[✓] Windows Version
[✗] Android toolchain - develop for Android devices
    ✗ Unable to locate Android SDK.
[✗] Android Studio (not installed)
[!] VS Code (not installed)
```

Android Studio'yu (Adım 7) kurunca bunlar yeşillenecek.

### Lisansları kabul et (Android Studio kurulduktan sonra)

```cmd
flutter doctor --android-licenses
```

Tüm sorulara `y` cevabı ver.

---

## 7. Android Studio + SDK + AVD kurulumu

**Niye gerekiyor:** Mobil uygulamayı emülatörde çalıştırmak için. Aynı zamanda Android SDK, build araçları ve emülatör motorunu paketler.

### İndirme

1. https://developer.android.com/studio adresine git.
2. **"Download Android Studio"** → en yeni stabil sürümü indir (~1 GB).

### Kurulum

1. İndirilen `.exe`'yi çalıştır → **Next**, **Next**.
2. **Choose Components:** **Android Studio** ve **Android Virtual Device** seçili olsun.
3. **Configuration Settings** ekranında kurulum yolu varsayılan kalabilir (`C:\Program Files\Android\Android Studio`).
4. **Install** → kurulum tamamlanınca **Finish**.

### İlk açılış sihirbazı

Android Studio'yu ilk kez açtığında:

1. **Import Settings** → "Do not import" → **OK**
2. **Welcome wizard:**
   - **Standard** kurulum tipini seç (Custom değil).
   - **License Agreement:** her birini seçip Accept'le → **Finish**.
   - Bileşenler indirilir (~2-3 GB, Android SDK + emulator + platform-tools). Bu uzun sürer.

### AVD (Android Virtual Device) oluştur

1. Android Studio açık → **More Actions** veya **Configure** menüsünden → **Virtual Device Manager** (veya Welcome ekranında **AVD Manager**).
2. **Create Device** veya **+** butonuna bas.
3. **Hardware:** `Pixel 6` veya `Medium Phone` seç → **Next**.
4. **System Image:** **API 34** (veya 35) **— x86_64** seç. İlk seferde **Download** linkine basıp imajı indir (~1 GB).
5. **AVD Name:** Örn. `Medium_Phone` (boşluk yerine alt çizgi).
6. **Finish**.

### PATH ekleme — `adb` ve `emulator` için

Android SDK'nın bin klasörlerini PATH'e ekle:

1. Windows arama → **"environment variables"** → **"Edit the system environment variables"**
2. **Environment Variables...** → **Path** → **Edit** → **New**
3. Şu iki yolu ekle (kullanıcı adına dikkat — kendi kullanıcı adınla değiştir):
   ```
   C:\Users\<KULLANICI_ADIN>\AppData\Local\Android\Sdk\platform-tools
   C:\Users\<KULLANICI_ADIN>\AppData\Local\Android\Sdk\emulator
   ```
4. **OK** → tüm cmd pencerelerini yeniden aç.

> 💡 Kullanıcı adını bulmak için: cmd'de `echo %USERPROFILE%`.

### Doğrulama

```cmd
adb --version
flutter doctor
```

`flutter doctor` çıktısı şimdi şöyle olmalı:

```
[✓] Flutter (Channel stable, 3.41.0)
[✓] Windows Version
[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
[✓] Android Studio (version 2024.x)
```

Hâlâ `[!]` veya `[✗]` varsa: `flutter doctor --android-licenses` çalıştır, hepsine `y` de.

### AVD'yi test et

```cmd
emulator -list-avds
```

Oluşturduğun AVD adı görünmeli (örn. `Medium_Phone`).

Başlat:
```cmd
emulator -avd Medium_Phone
```

Emülatör penceresi açılmalı (ilk açılış ~2 dakika sürer).

---

## 8. Git kurulumu

**Niye gerekiyor:** Kod tabanını klonlamak için. Eğer kod zaten lokalindeyse atla.

### İndirme + kurulum

1. https://git-scm.com/download/win adresine git → otomatik indirir.
2. `.exe`'yi çalıştır → **Next** ile varsayılan ayarlarla ilerle. **"Git from the command line and also from 3rd-party software"** seçili olsun.

### Doğrulama

```cmd
git --version
```

Çıktı: `git version 2.x.x`

---

## 9. Kod editörü — önerilen VS Code

**Niye opsiyonel:** Android Studio her şeyi yapabilir, ama TypeScript/Node tarafı için VS Code çok daha hafif ve hızlı.

### Kurulum

1. https://code.visualstudio.com → **Download for Windows** → kurulum.
2. Kurulum sırasında **"Add 'Open with Code' action to Windows Explorer file context menu"** seçeneğini işaretle (sağ tıkla → Open with Code kısayolu için).

### Önerilen eklentiler

VS Code açıldığında sol alttaki extension ikonuna basıp şunları yükle:

| Eklenti | Niye |
|---------|------|
| **Dart** | Dart syntax + intellisense |
| **Flutter** | `Run` butonu + hot reload |
| **Prisma** | `schema.prisma` syntax + format |
| **ESLint** | TypeScript lint |
| **Prettier - Code formatter** | Otomatik kod formatlama |
| **GitLens** | Git geçmişi inline gösterme |

---

## 10. Toplu doğrulama

**Tüm araçların doğru kurulup kurulmadığını tek seferde kontrol et.** Yeni bir cmd penceresi aç:

```cmd
node --version
pnpm --version
psql --version
flutter --version
adb --version
git --version
```

Beklenen çıktı (sürümler güncel olabilir):

```
v20.18.0
10.13.1
psql (PostgreSQL) 17.x
Flutter 3.41.0 • channel stable
Android Debug Bridge version 1.0.41
git version 2.47.0
```

Flutter sağlık kontrolü:
```cmd
flutter doctor
```

Tüm satırlar **[✓]** olmalı (VS Code satırı `[!]` olabilir, sorun değil — opsiyonel).

PostgreSQL servisi çalışıyor mu:
```cmd
sc query postgresql-x64-17
```

`STATE: 4 RUNNING` görmen lazım. Görmezsen başlat:
```cmd
net start postgresql-x64-17
```

Emülatör listesi:
```cmd
emulator -list-avds
```

En az 1 AVD görmeli.

---

## 11. Sık karşılaşılan kurulum sorunları

### ❌ `pnpm` komutu bulunamadı

**Sebep:** Node.js global path PATH'te değil.

**Çözüm:** Yeni cmd aç. Hâlâ olmazsa:
```cmd
npm config get prefix
```
Çıkan yolu (örn. `C:\Users\<ad>\AppData\Roaming\npm`) PATH'e ekle.

---

### ❌ `flutter doctor` Android lisansları için şikayet ediyor

```cmd
flutter doctor --android-licenses
```
Tüm sorulara `y` de.

---

### ❌ `psql` komutu bulunamadı

**Sebep:** PostgreSQL bin klasörü PATH'te değil.

**Çözüm:** `C:\Program Files\PostgreSQL\17\bin` PATH'e ekle, cmd'yi yeniden aç.

---

### ❌ Emülatör boot olmuyor / siyah ekran

**Sebep:** Genelde HAXM (Intel) veya Hyper-V (AMD) eksik/çakışıyor.

**Çözüm:**
- Intel CPU: BIOS'ta **VT-x / Virtualization Technology** açık olmalı. Windows'ta **Windows Hypervisor Platform** özelliği açık olmalı (Windows Features → işaretle).
- AMD CPU: BIOS'ta **SVM Mode** açık olmalı.
- Android Studio → SDK Manager → SDK Tools → **Android Emulator Hypervisor Driver** yüklü mü kontrol et.

---

### ❌ Postgres bağlantı reddediyor: "password authentication failed"

**Sebep:** Kurulumdaki şifreyi unuttun veya yanlış giriyorsun.

**Çözüm:** Şifre sıfırlama:
1. `C:\Program Files\PostgreSQL\17\data\pg_hba.conf` dosyasını yönetici olarak aç.
2. `host all all 127.0.0.1/32 scram-sha-256` satırını `host all all 127.0.0.1/32 trust` olarak değiştir.
3. Servisi yeniden başlat:
   ```cmd
   net stop postgresql-x64-17
   net start postgresql-x64-17
   ```
4. Şifresiz bağlan: `psql -U postgres`
5. Yeni şifre ata: `ALTER USER postgres WITH PASSWORD 'yenisifre';`
6. `pg_hba.conf` satırını `scram-sha-256`'ya geri çevir, servisi tekrar başlat.

---

### ❌ Flutter "Unable to find Android SDK"

**Sebep:** `ANDROID_HOME` env değişkeni yok.

**Çözüm:** Sistem ortam değişkenlerine yeni **System Variable** ekle:
- **Name:** `ANDROID_HOME`
- **Value:** `C:\Users\<KULLANICI_ADIN>\AppData\Local\Android\Sdk`

cmd'yi yeniden aç, `flutter doctor` tekrar dene.

---

### ❌ `npm install -g pnpm` permission denied

**Sebep:** Yönetici izni gerekli.

**Çözüm:** cmd'yi **Yönetici olarak çalıştır** → komutu tekrar dene.

---

## 12. Sonraki adım

Tüm araçlar kurulduktan ve `flutter doctor` tamamen yeşillendikten sonra:

1. Proje klasörüne git:
   ```cmd
   cd <proje-yolu>
   ```

2. Bağımlılıkları yükle:
   ```cmd
   pnpm install
   ```

3. `.env` dosyasını oluştur:
   ```cmd
   copy apps\api\.env.example apps\api\.env
   ```

   İçine şunu yaz (kurulumdaki Postgres şifrenle):
   ```env
   DATABASE_URL="postgresql://postgres:<SIFREN>@localhost:5432/fittrack?schema=public"
   JWT_SECRET="rastgele-64-char-uzun-string"
   JWT_REFRESH_SECRET="farkli-rastgele-64-char-string"
   NODE_ENV="development"
   PORT=3000
   LOG_LEVEL="info"
   CORS_ORIGINS="*"
   ```

   > 💡 Rastgele secret üret: `node -e "console.log(require('crypto').randomBytes(48).toString('base64'))"`

4. Veritabanı şemasını yükle + seed:
   ```cmd
   pnpm --filter @fittrack/api db:generate
   pnpm --filter @fittrack/api db:push
   pnpm --filter @fittrack/api db:seed
   ```

5. API'yi başlat:
   ```cmd
   pnpm dev:api
   ```

6. Yeni cmd penceresinde emülatörü ve uygulamayı başlat:
   ```cmd
   studio.bat
   ```
   (veya manuel: `emulator -avd Medium_Phone` → ayrı cmd'de `cd apps\mobile && flutter run`)

Detaylı kurulum komutları, test hesapları ve demo akışı için projedeki **`README.md`** ve **`SUNUM.md`** dosyalarına bakın.

---

## Hızlı referans — tüm kurulum komutları

Tek yerde kopyalanabilir özet:

```cmd
REM 1) Node.js → https://nodejs.org/ (manuel kurulum)

REM 2) pnpm
npm install -g pnpm

REM 3) PostgreSQL 17 → https://www.postgresql.org/download/windows/ (manuel kurulum)
REM    PATH'e ekle: C:\Program Files\PostgreSQL\17\bin
"C:\Program Files\PostgreSQL\17\bin\createdb.exe" -U postgres fittrack

REM 4) Flutter → https://docs.flutter.dev/get-started/install/windows
REM    C:\src\flutter dizinine zip aç, PATH'e C:\src\flutter\bin ekle

REM 5) Android Studio → https://developer.android.com/studio
REM    Standard kurulum, AVD oluştur
REM    PATH'e ekle:
REM      C:\Users\<ad>\AppData\Local\Android\Sdk\platform-tools
REM      C:\Users\<ad>\AppData\Local\Android\Sdk\emulator

REM 6) Lisansları kabul et
flutter doctor --android-licenses

REM 7) Git → https://git-scm.com/download/win

REM 8) Son kontrol
flutter doctor
```

---

**Hazırlandığı kaynaklar:** projenin kök dizinindeki `README.md` ve `SUNUM.md` dosyaları (özellikle README "Kurulum" bölümü ve SUNUM "10. Emulator'de çalıştırma el rehberi" bölümü).
