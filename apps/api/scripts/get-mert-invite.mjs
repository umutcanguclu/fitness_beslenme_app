import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const players = await prisma.player.findMany({
  where: { fullName: { contains: 'Mert', mode: 'insensitive' } },
  include: { invite: true, user: { select: { email: true } } },
});

for (const p of players) {
  console.log(`\n${p.fullName} (${p.position}, #${p.jerseyNumber ?? '—'})`);
  console.log(`  player.id: ${p.id}`);
  console.log(`  email:     ${p.user?.email ?? '(kayıt yok)'}`);
  console.log(`  invite:    ${p.invite?.code ?? '(yok)'}`);
  console.log(`  expires:   ${p.invite?.expiresAt?.toISOString().slice(0, 10) ?? '—'}`);
  console.log(`  used:      ${p.invite?.acceptedAt ? 'evet — kalıcı PIN' : 'henüz değil'}`);
}

await prisma.$disconnect();
