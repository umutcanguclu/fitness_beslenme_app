import { PrismaClient } from '@prisma/client';
import { FOOTBALL_EXERCISES } from './seed/exercises.js';

const prisma = new PrismaClient();

async function seedExercises() {
  let created = 0;
  let updated = 0;
  for (const ex of FOOTBALL_EXERCISES) {
    const result = await prisma.exercise.upsert({
      where: { slug: ex.slug },
      create: ex,
      update: ex,
    });
    // upsert dönüş değeri create/update ayırt etmiyor, yaklaşık sayıyoruz
    // bir önceki var mı diye ek sorgu yapmak istemiyoruz — toplam yeterli
    created += result ? 1 : 0;
  }
  console.log(`✓ ${created} egzersiz upsert edildi`);
  void updated;
}

async function main() {
  console.log('🌱 Seed başlıyor...');
  await seedExercises();
  console.log('✓ Seed tamamlandı');
}

main()
  .catch((e) => {
    console.error('❌ Seed hatası:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
