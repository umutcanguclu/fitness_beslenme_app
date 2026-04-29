// Auto-matcher tek-token "drill" / "cone" / "sprint" üzerinden yanlış
// pozitifler üretti. Onları manuel temizliyoruz.

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const BAD_MATCH_SLUGS = [
  // Sprint kelimesi sebebiyle yanlış eşleşenler
  'sa-sprint-30m',
  'sa-hill-sprint',
  'sprint-uphill',
  'sprint-resisted-sled',
  'sprint-reactive-start',
  'sprint-10m-acceleration',
  'sprint-20m-flying',
  // Drill / cone tek-kelime
  'decel-180-turn',
  'agility-t-drill',
  'agility-hexagon',
  'agility-arrowhead',
  'agility-pro-agility',
  'reactive-mirror-drill',
  'reactive-color-cone',
  'reactive-ball-drop',
  'tc-dribbling-cones',
  'tech-shoot-cone-finish',
  'tech-shoot-cross-finish',
  'tech-cross-cutback',
  // Çok genel eşleşmeler
  'recovery-walking-stretches',
  'recovery-mobility-spiderman-lunge',
  'recovery-breathing-box',
  'recovery-breathing-diaphragmatic',
  'recovery-mobility-thoracic-rotation',
  'recovery-mobility-90-90-hip',
  'recovery-mobility-ankle-rocker',
  'recovery-mobility-glute-bridge-march',
  'recovery-foam-roll-it-band',
  'recovery-foam-roll-back',
  'recovery-pnf-hamstring-partner',
  'recovery-static-piriformis',
  'recovery-mobility-cat-cow',
  'cd-breathing-down-regulation',
  // Yanlış eşleşen güç hareketleri
  'stb-nordic-hamstring',
  'stb-copenhagen-adductor',
  'plyo-broad-jump',
  'plyo-bounding',
  'pl-broad-jump',
  // Plyometrik ankle/single-leg yanlışları
  'balance-ankle-hops',
  'balance-single-leg-romanian-reach',
  'balance-bosu-squat',
  // Diğer
  'injury-prevention-knee-vmo',
  'core-suitcase-carry',
  'core-mcgill-curlup',
  'strength-medball-rotational-throw',
  'strength-rdl-single-leg',
  'strength-bulgarian-split-squat',
  'strength-copenhagen-adductor',
];

const result = await prisma.exercise.updateMany({
  where: { slug: { in: BAD_MATCH_SLUGS } },
  data: { thumbnailUrl: null, imageUrls: [] },
});
console.log(`Temizlendi: ${result.count} egzersizin yanlış görseli kaldırıldı`);

const stats = await prisma.exercise.groupBy({
  by: ['category'],
  _count: { _all: true },
  where: { imageUrls: { isEmpty: false } },
});
console.log('\nKategoriye göre görselli egzersiz sayısı:');
for (const s of stats) console.log(`  ${s.category.padEnd(20)} ${s._count._all}`);

const total = await prisma.exercise.count();
const withImages = await prisma.exercise.count({ where: { imageUrls: { isEmpty: false } } });
console.log(`\nToplam: ${withImages}/${total} egzersizde görsel var`);

await prisma.$disconnect();
