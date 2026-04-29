'use client';

import { useEffect } from 'react';

// Production'da /sw.js'i kayıt eder. Development'ta atlar — Next dev mode'da
// SW asset cache'i hot-reload'u kafa karıştırır.
export function ServiceWorkerRegistrar() {
  useEffect(() => {
    if (process.env.NODE_ENV !== 'production') return;
    if (typeof navigator === 'undefined' || !('serviceWorker' in navigator)) return;
    navigator.serviceWorker.register('/sw.js').catch(() => {
      // Registry hatasıyla uygulama bozulmasın.
    });
  }, []);
  return null;
}
