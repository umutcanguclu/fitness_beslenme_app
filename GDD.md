# FitTrack — Game/Product Design Document

> ⚠️ **ESKİ — futbol pivotundan ÖNCE yazıldı (referans amaçlı duruyor).**
> Bu doküman genel fitness uygulamasının (workout/PR/GPS/beslenme) vizyonu. Proje şu an **alt lig + akademi futbol antrenörleri için "antrenör + oyuncu" platformu**na pivot etti. Güncel vizyon ve kurallar için: [CONTEXT.md](./CONTEXT.md) + [README.md](./README.md). Buradaki kapsam, veri modeli, frontend dependency listesi (Riverpod/dio/freezed/fl_chart vb.) yeni futbol odağı için **bağlayıcı değildir** — `apps/mobile/` Flutter iskeleti kurulurken yeniden değerlendirilecek.

> **Proje türü:** Kişisel / Portfolio projesi
> **Sahip:** GarroshCan (Temreon Studio)
> **Durum:** Planlama → MVP geliştirme
> **Son güncelleme:** Ocak 2026 (eski vizyon)

---

## 1. Vizyon

FitTrack, bir fitness tutkunu için tasarlanmış, **kapsamlı ama sade** bir mobil antrenman takip uygulamasıdır. Hem ağırlık antrenmanı, hem kardiyo, hem de beslenme verilerini tek çatı altında birleştirir; bunu yaparken kullanıcıyı formlarla boğmak yerine **hızlı giriş, anlamlı grafik, otomatik öngörü** üçlüsüne odaklanır.

Bu proje bir portfolio göstergesi olarak tasarlanmıştır: production-grade mimari, TypeScript stack, clean architecture, Google Cloud deployment ve profesyonel UI ile bir full-stack mobil uygulama geliştirme yetkinliğini kanıtlar.

## 2. Hedef Kitle

Birincil: **Kendim** (geliştirici + kullanıcı)
İkincil: CV/portfolio için değerlendiren teknik mülakat sahipleri, işverenler
Persona: Haftada 3-5 gün antrenman yapan, ölçülebilir ilerleme isteyen, Türkçe/İngilizce arayüz tercihli kullanıcı

## 3. Ana Değer Önerileri

1. **Hızlı workout kaydı**: 3 tıkla sete başla, zamanlayıcı otomatik
2. **Otomatik PR tespiti**: Rekor kırdığın anda bildirim
3. **Görsel ilerleme**: Haftalık/aylık grafikler, volume trend
4. **Template sistemi**: Favori rutinlerini kaydet, tek tıkla başlat
5. **Offline-first**: İnternet olmadan da çalışır, sonradan sync
6. **Çok dilli**: Türkçe + İngilizce (i18n ile genişleyebilir)

## 4. Kapsam (Scope)

### MVP — Faz 1 (Hafta 1-2)
- [ ] Auth: register, login, JWT, refresh token
- [ ] Profil: kilo, boy, yaş, hedef
- [ ] Egzersiz kütüphanesi (wger.de kaynaklı ~500 egzersiz, TR+EN)
- [ ] Workout oluşturma ve başlatma
- [ ] Set kaydı (weight + reps VEYA time VEYA distance)
- [ ] Workout geçmişi
- [ ] Temel dashboard (son 7 gün)

### Faz 2 — Değer katmanı (Hafta 3)
- [ ] PR otomatik hesaplama ve bildirim
- [ ] Workout template'leri
- [ ] Rest timer (antrenman içi)
- [ ] Haftalık/aylık istatistik grafikleri
- [ ] Volume / intensity tracking

### Faz 3 — Kardiyo (Hafta 4, opsiyonel)
- [ ] GPS ile koşu/yürüyüş
- [ ] Mesafe, tempo, kalori
- [ ] Harita üzerinde rota
- [ ] Kardiyo geçmişi

### Faz 4 — Beslenme (sonraya)
- [ ] Yemek logla
- [ ] Makro hesaplama (P/C/F)
- [ ] Günlük kalori hedefi
- [ ] Barkod tarama (stretch goal)

### Dışarıda tutulanlar (MVP için)
- Sosyal özellikler (arkadaş ekleme, paylaşım)
- Antrenör/müşteri modu
- Apple Health / Google Fit entegrasyonu
- Abonelik / premium özellikler
- Ses komutu ile set kaydı

## 5. Teknik Mimari

### Frontend (Mobile)
- Flutter 3.41+ · Dart 3.11+
- Material 3 tema + özel `ThemeExtension` (koyu tema, lime accent)
- Riverpod 2 (state + DI)
- go_router (navigasyon + deep link)
- dio (HTTP + auth interceptor)
- freezed + json_serializable (immutable modeller + JSON)
- flutter_localizations + intl + ARB (çok dil)
- flutter_secure_storage (token) + shared_preferences (ayarlar)
- fl_chart (grafikler)

### Backend (API)
- Node.js (v20+) + Fastify + TypeScript
- Prisma ORM + PostgreSQL
- JWT auth (access + refresh)
- Zod (validation, frontend ile paylaşımlı)
- Pino (logging)
- PM2 (deploy, Google Cloud e2-micro)

### Paylaşımlı
- pnpm workspaces (backend + paketler)
- `packages/shared` — Zod şemaları, TS tipleri (backend tarafı için kaynak)
- `packages/exercise-db` — statik egzersiz JSON'u (mobile tarafta asset olarak kopyalanır)
- Mobile tarafında Dart model eşdeğerleri `freezed` ile elle tutulur (tek cross-language maliyeti)

### Deployment
- Backend: Google Cloud Compute Engine e2-micro + PM2 + nginx
- DB: PostgreSQL (aynı instance'da başlangıç, büyürse managed)
- Mobil: `flutter build apk` / `flutter build appbundle` (Android), `flutter build ipa` (iOS, macOS üzerinde Xcode ile)

## 6. Veri Modeli (taslak)

```
User        { id, email, passwordHash, name, locale, createdAt }
Profile     { userId, height, weight, age, gender, goal, unit }
Exercise    { id, nameEn, nameTr, muscleGroup, equipment, type, mediaUrl }
Template    { id, userId, name, exerciseList[] }
Workout     { id, userId, startedAt, finishedAt, templateId?, notes }
Set         { id, workoutId, exerciseId, order, weight?, reps?, time?, distance?, rpe? }
PR          { id, userId, exerciseId, metric, value, achievedAt }
CardioSession { id, userId, type, distance, duration, route[], startedAt }
```

## 7. UI/UX Yönü

**Tema:** Koyu tema birincil (dark-first), light tema sonradan. Accent renk kullanıcı seçimli (default: electric lime / cyberpunk teal — Temreon Studio estetiğine yakın).

**Font:** Inter (gövde) + Barlow Condensed (başlık) — modern, okunaklı, cyberpunk estetiğinin "daha olgun" versiyonu. Flutter tarafında `google_fonts` paketiyle yüklenir.

**Temel ekranlar:**
1. Dashboard (bugün + son 7 gün özet)
2. Workout (aktif + yeni başlat + geçmiş)
3. Exercises (kütüphane arama/filtre)
4. Progress (grafikler, PR'lar)
5. Profile (ayarlar, dil, birim sistemi)

## 8. Başarı Kriterleri

- [ ] Production'a deploy edilmiş, benim aktif kullandığım bir uygulama
- [ ] 50+ gerçek workout kaydı
- [ ] App Store / Play Store TestFlight / Internal Track'te yayında
- [ ] GitHub'da temiz README + screenshots ile showcase repo
- [ ] CV'de "Full-stack mobile fitness app" olarak yer alabilir

## 9. Riskler

- **Scope creep**: "Hepsi bir arada" isteği. Karşı önlem: Faz'lara sıkı sıkıya sadık kal, Faz 1 bitmeden Faz 2'ye geçme.
- **Mobil deployment karmaşıklığı**: iOS build için macOS + Xcode gerekiyor. Karşı önlem: Android'i öncelikle, iOS build'i macOS erişimi olduğunda ele al.
- **Backend + mobil paralel geliştirme yükü**: Tek kişi. Karşı önlem: Backend önce bitsin, mock data ile mobil geliştir.
