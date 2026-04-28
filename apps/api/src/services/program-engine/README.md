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

- [ ] Mevki bazlı **özel** dağılım (kalecinin programı çoğunlukla `goalkeeper_specific` olmalı; santrafora şut ağırlıklı)
- [ ] `position_group` session tipi (defansa özel duran top, vs.)
- [ ] Yaş bazlı şiddet eğrisi (U13'te yüksek hacim ÇOK riskli — limit koy)
- [ ] Egzersiz çeşitliliği skoru (önceki haftaları kontrol et, primaryMuscle çakışmasını azalt)
- [ ] Akıllı sıralama: warmup ilk, cooldown son, ana iş bloğu ortada
- [ ] Microcycle bütünlüğü: haftalık toplam hacim hedefi (örn. 280 dk, MD'ye göre dağıt)
- [ ] `preseason` ve `recovery_week` template'leri
- [ ] `team` programı (sadece bireysel değil, takım antrenmanı)
- [ ] Engine snapshot'ı vs. ürün state diff'i (programı yeniden ürettiğinde değişimi göster)

## Çıktıyı DB'ye yazmak

Engine sadece `GeneratedProgram` döner. `program-writer.ts` (henüz yazılmadı) bunu alıp:

1. `TrainingProgram` row'u oluşturur (`generationInputs` JSON snapshot'ı içinde)
2. Her `GeneratedSession` için `TrainingSession` + `SessionExercise` insert eder
3. Aynı playerId+weekStartDate için varsa eski programı archive eder/değiştirir

## Versiyonlama

`ENGINE_VERSION = 'rule_engine_v1'`. Kural değişikliklerinde versiyon bumplanır; eski programlar audit için generationInputs ile birlikte saklanır. Sonradan v2'ye geçince koç eski programı yeniden üretebilir.
