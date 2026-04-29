// Minimal service worker — MVP PWA için.
// - Statik asset'leri (Next.js _next/static) cache-first servis et.
// - HTML navigation isteklerini network-first (offline fallback olmadan).
// - API isteklerini hiç cache'leme (token rotasyonu, taze veri).

const CACHE_NAME = 'fittrack-v1';
const APP_SHELL = ['/', '/login', '/dashboard', '/teams', '/my-program'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL).catch(() => {})),
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))),
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);

  // API: backend (port 3000 veya farklı host) — cache yok.
  if (url.origin !== self.location.origin) return;

  // Next.js dev HMR / data routes — cache yok.
  if (url.pathname.startsWith('/_next/data') || url.pathname.startsWith('/_next/webpack-hmr')) {
    return;
  }

  // Statik asset: cache-first
  if (url.pathname.startsWith('/_next/static') || /\.(?:svg|png|webmanifest|ico)$/.test(url.pathname)) {
    event.respondWith(
      caches.match(req).then(
        (cached) =>
          cached ??
          fetch(req).then((res) => {
            const copy = res.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(req, copy)).catch(() => {});
            return res;
          }),
      ),
    );
    return;
  }

  // Navigation (HTML): network-first, fallback cache
  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(req, copy)).catch(() => {});
          return res;
        })
        .catch(() => caches.match(req).then((c) => c ?? caches.match('/'))),
    );
  }
});
