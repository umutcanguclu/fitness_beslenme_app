// Free-exercise-db (yuhonas/free-exercise-db, public domain) ile bizim
// Exercise tablomuzu eşleştirir, eşleşenlerin imageUrls + thumbnailUrl
// alanlarını günceller. Football-spesifik drill'ler (FIFA 11+, rondo,
// SSG vb.) genelde eşleşmez — bunlara UI category-icon fallback gösterir.

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const FED_URL = 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json';
const IMG_BASE = 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises';

function normalize(s) {
  return s
    .toLowerCase()
    .replace(/[ıİ]/g, 'i')
    .replace(/[şŞ]/g, 's')
    .replace(/[ğĞ]/g, 'g')
    .replace(/[üÜ]/g, 'u')
    .replace(/[öÖ]/g, 'o')
    .replace(/[çÇ]/g, 'c')
    .replace(/\([^)]*\)/g, ' ')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim()
    .split(/\s+/)
    .filter(Boolean);
}

function similarity(aTokens, bTokens) {
  if (aTokens.length === 0 || bTokens.length === 0) return 0;
  const setB = new Set(bTokens);
  let hits = 0;
  for (const t of aTokens) if (setB.has(t)) hits += 1;
  // Jaccard-ish ama kısa kelimelere ağırlık veriyoruz (her ikisinde geçen)
  const union = new Set([...aTokens, ...bTokens]).size;
  return hits / Math.max(aTokens.length, union * 0.5);
}

async function main() {
  console.log('Free-exercise-db indiriliyor...');
  const res = await fetch(FED_URL);
  if (!res.ok) throw new Error(`Fetch fail: ${res.status}`);
  const fed = await res.json();
  console.log(`  ${fed.length} egzersiz yüklendi`);

  const fedNorm = fed.map((e) => ({
    raw: e,
    nameTokens: normalize(e.name),
  }));

  const ours = await prisma.exercise.findMany({
    select: { id: true, slug: true, nameEn: true, nameTr: true, category: true },
  });
  console.log(`  DB: ${ours.length} egzersizimiz var\n`);

  let matched = 0;
  let updated = 0;
  let skippedFootball = 0;

  for (const our of ours) {
    // Apaçık futbol-spesifik prefix'lere bakmadan geç (eşleşme şansı yok)
    if (
      our.slug.startsWith('fifa11p-') ||
      our.slug.startsWith('ssg-') ||
      our.slug.startsWith('rondo-') ||
      our.slug.startsWith('tech-rondo-') ||
      our.slug.startsWith('tech-set-piece') ||
      our.slug.startsWith('sp-') ||
      our.slug.startsWith('tc-rondo') ||
      our.slug.startsWith('gk-') ||
      our.slug.startsWith('ta-') ||
      our.slug.startsWith('tech-passing-overload') ||
      our.slug.startsWith('tech-positional')
    ) {
      skippedFootball += 1;
      continue;
    }

    const ourTokens = normalize(our.nameEn);
    if (ourTokens.length === 0) continue;

    let best = null;
    let bestScore = 0;
    for (const f of fedNorm) {
      const score = similarity(ourTokens, f.nameTokens);
      if (score > bestScore) {
        bestScore = score;
        best = f.raw;
      }
    }

    // Düşük güvenli eşleşmeleri at
    if (!best || bestScore < 0.5) continue;
    // Kısa kelimelerde 1-token rastlantıları çıkar
    if (ourTokens.length === 1 && bestScore < 0.7) continue;

    matched += 1;
    const folder = best.id || best.name?.replace(/ /g, '_');
    const images = (best.images || []).map((i) =>
      i.startsWith('http') ? i : `${IMG_BASE}/${folder}/${i.split('/').pop()}`,
    );
    if (images.length === 0) continue;

    await prisma.exercise.update({
      where: { id: our.id },
      data: { thumbnailUrl: images[0], imageUrls: images },
    });
    updated += 1;
    console.log(`  ✓ ${our.nameEn.padEnd(36)} → ${best.name} (${images.length} kare, skor ${bestScore.toFixed(2)})`);
  }

  console.log(`\n=== Özet ===`);
  console.log(`Toplam egzersiz: ${ours.length}`);
  console.log(`Football-spesifik (atlandı): ${skippedFootball}`);
  console.log(`Eşleşme bulundu: ${matched}`);
  console.log(`Güncellendi: ${updated}`);
  console.log(`Görseli olmayan: ${ours.length - updated}`);

  await prisma.$disconnect();
}

main().catch(async (err) => {
  console.error('FATAL:', err);
  await prisma.$disconnect();
  process.exit(1);
});
