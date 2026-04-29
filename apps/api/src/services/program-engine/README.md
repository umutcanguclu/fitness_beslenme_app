# Program Engine (rule_engine_v1)

Kural tabanlı haftalık futbol antrenman programı üretici. Şu an **iskelet implementasyon** — temel akış çalışır, ama kural setleri henüz alt lig pratiğine göre kalibre edilmedi.

## Akış

```
generateProgram(input)
  → loadPlayerSnapshot()      [yaş, mevki, kilo, sakatlık, availability]
  → loadClubResources()        [equipment + facility → availableLocations]
  → loadMatchContext()         [bu hafta maç var mı, MD-X için]
  → planWeek()                 [7 günlük (kategori + şiddet + süre) plan]
       her gün her kategori için:
       → selectExercisesForCategory()  [filtre: ekipman + lokasyon + yaş + mevki]
       → toSelectedExercise()           [defaults + şiddet ayarı]
  → GeneratedProgram döner
```

## Şu an çalışan

- Match week periyodizasyonu: MD-3 yüksek hacim, MD-2 yüksek şiddet, MD-1 hafif teknik, MD off, MD+1 recovery
- Generic week (maç yoksa) 6 günlük dağılım + 1 off
- Availability adjustment: `injured/ill/away/suspended` → off, `doubtful` → düşük yük, `limited` → orta yük
- Aktif sakatlık → `plyometric` ve `sprint_agility` çıkar
- Egzersiz filtresi: kategori + yaş aralığı + mevki + ekipman AND + lokasyon
- Aynı egzersiz hafta içinde tekrar etmez (`usedExerciseIds`)

## TODO (kalibre edilmesi gerekenler)

- [x] **Mevki bazlı özel dağılım**: kaleci için takım çalışması yerine `goalkeeper_specific` (small_sided_game/tactical/technical → goalkeeper_specific substitusyonu)
- [x] **Yaş bazlı şiddet eğrisi**: <14 yaş şiddet max 3 + süre max 70 dk; 14-15 yaş şiddet max 4 + süre max 80 dk
- [x] **Akıllı sıralama**: `CATEGORY_PRIORITY` ile warmup ilk, recovery yakın, cooldown son
- [x] **Preseason ve recovery_week template'leri**: `pickDayBase` microcycleType'a göre uygun şablonu seçer
- [x] **Position-aware exercise ranking**: selector mevki-spesifik egzersizleri (positionsTargeted'da oyuncunun mevkisi olanları) önce sıralar
- [ ] `position_group` session tipi (defansa özel duran top — takım programı geldiğinde)
- [ ] Egzersiz çeşitliliği skoru (önceki haftaları kontrol et, primaryMuscle çakışmasını azalt)
- [ ] Microcycle bütünlüğü: haftalık toplam hacim hedefi (örn. 280 dk, MD'ye göre dağıt)
- [ ] `team` programı (sadece bireysel değil, takım antrenmanı)
- [ ] Engine snapshot'ı vs. ürün state diff'i (programı yeniden ürettiğinde değişimi göster)

## Çıktıyı DB'ye yazmak

`program-writer.ts` `GeneratedProgram`'ı alıp:

1. Aynı `playerId+weekStartDate` için var olan `TrainingProgram`'ı **siler** (cascade ile sessions/exercises/attendance/logs).
2. Yeni `TrainingProgram` oluşturur (`generationInputs` JSON snapshot içinde, audit için).
3. Her `GeneratedSession` için `TrainingSession` + sıralı `SessionExercise` nested-create eder.
4. Tek transaction içinde — kısmi yazıma izin yok.

İki kullanım:

```ts
// Engine + DB tek seferde
const written = await generateAndWriteProgram({ playerId, weekStartDate }, db);

// Veya iki adım (örn. preview)
const generated = await generateProgram(input, db);
// ... preview / değişiklik ...
const written = await writeProgram(generated, { playerId }, db);
```

**Replace stratejisi notu:** hafta içinde program yeniden üretilirse o haftanın attendance/RPE kayıtları kaybolur. UI katmanında "X kayıt silinecek" uyarısı planlanıyor.

## Versiyonlama

`ENGINE_VERSION = 'rule_engine_v1'`. Kural değişikliklerinde versiyon bumplanır; eski programlar audit için generationInputs ile birlikte saklanır. Sonradan v2'ye geçince koç eski programı yeniden üretebilir.
