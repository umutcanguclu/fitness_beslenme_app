// Test antrenör hesabına bir takım + 4 çeşitli oyuncu ekler.
// Kullanım: API ayakta iken `node scripts/seed-test-players.mjs`

const BASE = process.env.API_URL ?? 'http://localhost:3000';
const EMAIL = 'antrenor@test.com';
const PASSWORD = '12341234';

async function jfetch(path, opts = {}) {
  const res = await fetch(BASE + path, {
    headers: {
      'Content-Type': 'application/json',
      ...(opts.token ? { Authorization: `Bearer ${opts.token}` } : {}),
    },
    method: opts.method ?? 'GET',
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  });
  let body;
  try { body = await res.json(); } catch { body = null; }
  if (!res.ok) {
    throw new Error(`${opts.method ?? 'GET'} ${path} → HTTP ${res.status}: ${JSON.stringify(body)}`);
  }
  return body;
}

const PLAYERS = [
  {
    fullName: 'Mert Kaplan',
    birthDate: '1996-08-14',
    position: 'goalkeeper',
    detailedPosition: 'GK',
    preferredFoot: 'right',
    heightCm: 191,
    weightKg: 86,
    jerseyNumber: 1,
    employmentStatus: 'semi_pro',
  },
  {
    fullName: 'Burak Demir',
    birthDate: '1999-03-22',
    position: 'defender',
    detailedPosition: 'CB',
    preferredFoot: 'right',
    heightCm: 188,
    weightKg: 82,
    jerseyNumber: 4,
    employmentStatus: 'amateur',
  },
  {
    fullName: 'Ahmet Yılmaz',
    birthDate: '2002-11-05',
    position: 'midfielder',
    detailedPosition: 'CM',
    preferredFoot: 'right',
    heightCm: 178,
    weightKg: 72,
    jerseyNumber: 8,
    employmentStatus: 'amateur',
  },
  {
    fullName: 'Can Aslan',
    birthDate: '2005-06-18',
    position: 'forward',
    detailedPosition: 'ST',
    preferredFoot: 'left',
    heightCm: 182,
    weightKg: 75,
    jerseyNumber: 9,
    employmentStatus: 'student',
  },
];

async function run() {
  console.log(`Login: ${EMAIL}`);
  const auth = await jfetch('/auth/login', {
    method: 'POST',
    body: { email: EMAIL, password: PASSWORD },
  });
  const token = auth.tokens.accessToken;
  console.log(`✓ Login ok — userId=${auth.user.id}`);

  console.log('Takımlar yükleniyor...');
  const teams = await jfetch('/teams', { token });
  let team = teams[0];
  if (!team) {
    console.log('Takım yok, "A Takım" oluşturuluyor...');
    team = await jfetch('/teams', {
      method: 'POST',
      token,
      body: { name: 'A Takım', category: 'senior', season: '2025-2026' },
    });
    console.log(`✓ Takım oluşturuldu: ${team.id}`);
  } else {
    console.log(`✓ Mevcut takım kullanılıyor: "${team.name}" (${team.id})`);
  }

  console.log(`\n${PLAYERS.length} oyuncu ekleniyor...\n`);
  const created = [];
  for (const p of PLAYERS) {
    try {
      const result = await jfetch(`/teams/${team.id}/players`, {
        method: 'POST',
        token,
        body: p,
      });
      created.push(result);
      console.log(`✓ ${p.fullName.padEnd(20)} #${p.jerseyNumber} ${p.position.padEnd(11)} → invite: ${result.invite.code}`);
    } catch (err) {
      console.error(`✗ ${p.fullName}: ${err.message}`);
    }
  }

  console.log(`\n${created.length}/${PLAYERS.length} oyuncu oluşturuldu.`);
  console.log(`\nTakım sayfası: http://localhost:3001/teams/${team.id}`);
}

run().catch((err) => {
  console.error('FATAL:', err.message);
  process.exit(1);
});
