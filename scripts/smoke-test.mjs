// One-shot end-to-end smoke test against http://localhost:3000.
// Yazılan endpoint'lerin canlı boot'ta çalıştığını doğrular.

const BASE = 'http://localhost:3000';

async function jfetch(path, opts = {}) {
  const res = await fetch(BASE + path, {
    headers: {
      'Content-Type': 'application/json',
      ...(opts.token ? { Authorization: `Bearer ${opts.token}` } : {}),
      ...(opts.headers ?? {}),
    },
    ...opts,
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  });
  let body;
  try { body = await res.json(); } catch { body = null; }
  return { status: res.status, body };
}

function ok(label, status, expected = 200) {
  const pass = status === expected;
  console.log(`${pass ? '✓' : '✗'} [${status}] ${label}${pass ? '' : ` (expected ${expected})`}`);
  return pass;
}

async function run() {
  const stamp = Date.now();
  const email = `smoke-${stamp}@test.local`;
  const password = 'gizli-1234';

  // 1. health
  const health = await jfetch('/health');
  ok('GET /health', health.status, 200);

  // 2. register coach + club
  const reg = await jfetch('/auth/register/coach', {
    method: 'POST',
    body: { email, password, fullName: 'Smoke Hoca', clubName: 'Smoke Kulüp' },
  });
  if (!ok('POST /auth/register/coach', reg.status, 201)) {
    console.log('   →', reg.body);
    return;
  }
  const token = reg.body.tokens.accessToken;

  // 3. /clubs/me
  const club = await jfetch('/clubs/me', { token });
  if (!ok('GET /clubs/me', club.status, 200)) return;
  const clubId = club.body.id;
  console.log(`   clubId=${clubId} name="${club.body.name}"`);

  // 4. add facility + equipment
  const facility = await jfetch(`/clubs/${clubId}/facilities`, {
    method: 'POST',
    token,
    body: { type: 'natural_grass', name: 'Ana Saha' },
  });
  ok('POST /clubs/:id/facilities', facility.status, 201);

  const equipment = await jfetch(`/clubs/${clubId}/equipment`, {
    method: 'POST',
    token,
    body: { item: 'cones', quantity: 30 },
  });
  ok('POST /clubs/:id/equipment', equipment.status, 201);

  // 5. team
  const team = await jfetch('/teams', {
    method: 'POST',
    token,
    body: { name: 'A Takım', category: 'senior', season: '2026-2027' },
  });
  if (!ok('POST /teams', team.status, 201)) {
    console.log('   →', team.body);
    return;
  }
  const teamId = team.body.id;

  // 6. player profile + invite
  const player = await jfetch(`/teams/${teamId}/players`, {
    method: 'POST',
    token,
    body: {
      fullName: 'Ali Veli',
      birthDate: '2000-01-15',
      position: 'midfielder',
      preferredFoot: 'right',
      heightCm: 178,
      weightKg: 72,
      employmentStatus: 'amateur',
    },
  });
  if (!ok('POST /teams/:id/players', player.status, 201)) {
    console.log('   →', player.body);
    return;
  }
  const playerId = player.body.player.id;
  console.log(`   playerId=${playerId} inviteCode=${player.body.invite.code}`);

  // 7. set availability (kendi ya da koç olarak)
  const avail = await jfetch(`/players/${playerId}/availability`, {
    method: 'POST',
    token,
    body: { date: '2026-04-28', status: 'ready' },
  });
  ok('POST /players/:id/availability', avail.status, 201);

  // 8. generate program
  const gen = await jfetch(`/players/${playerId}/programs/generate`, {
    method: 'POST',
    token,
    body: { weekStartDate: '2026-04-27', microcycleType: 'match_week' },
  });
  if (!ok('POST /players/:id/programs/generate', gen.status, 201)) {
    console.log('   →', gen.body);
    return;
  }
  const sessions = gen.body.sessions ?? [];
  console.log(`   sessions=${sessions.length}`);
  for (const s of sessions) {
    console.log(`   - ${new Date(s.date).toISOString().slice(0, 10)}: ${s.category} (${s.exercises.length} egz, ${s.durationMinutes} dk, şid ${s.intensity})`);
  }

  // 9. list programs
  const list = await jfetch(`/players/${playerId}/programs?weekStartDate=2026-04-27`, { token });
  ok('GET /players/:id/programs', list.status, 200);
  console.log(`   listLen=${list.body.length}`);

  // 10. injury create + list
  const injury = await jfetch(`/players/${playerId}/injuries`, {
    method: 'POST',
    token,
    body: {
      type: 'muscle',
      severity: 'minor',
      bodyPart: 'sol hamstring',
      startedAt: '2026-04-25',
    },
  });
  ok('POST /players/:id/injuries', injury.status, 201);

  const injList = await jfetch(`/players/${playerId}/injuries`, { token });
  ok('GET /players/:id/injuries', injList.status, 200);
  console.log(`   activeInjuries=${injList.body.length}`);

  // 11. match create + list
  const match = await jfetch(`/teams/${teamId}/matches`, {
    method: 'POST',
    token,
    body: { opponent: 'Rakip FC', date: '2026-05-03T15:00:00Z', isHome: true, competition: 'Lig' },
  });
  ok('POST /teams/:id/matches', match.status, 201);

  // 12. performance test
  const perf = await jfetch(`/players/${playerId}/performance-tests`, {
    method: 'POST',
    token,
    body: { type: 'sprint_30m', value: 4.05, unit: 's' },
  });
  ok('POST /players/:id/performance-tests', perf.status, 201);

  console.log('\nDONE');
}

run().catch((err) => {
  console.error('FATAL', err);
  process.exit(1);
});
