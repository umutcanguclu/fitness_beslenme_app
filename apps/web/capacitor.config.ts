import type { CapacitorConfig } from '@capacitor/cli';

// Capacitor — native shell yapılandırması.
// webDir: Next.js statik export çıktısı (`next build` sonrası `out/` klasörü).
// appId: Android paket adı + iOS bundle id; namespace olarak ters domain.
// server: prod build'de tanımlı değil; native app file:// üzerinden out/'u yükler.
//   Geliştirme için server.url = "http://192.168.x.x:3001" set'leyip live reload alabilirsin.
const config: CapacitorConfig = {
  appId: 'app.fittrack.coach',
  appName: 'fittrack',
  webDir: 'out',
  android: {
    // Android cleartext (http) izinli — local API'ye geliştirmede ulaşılabilsin.
    // Production'da HTTPS olan API kullan.
    allowMixedContent: true,
  },
  // GELİŞTİRME: Capacitor app, Next.js dev server'a doğrudan bağlanır.
  // Tam SPA routing + canlı reload. Production için bunu kaldır + statik export'u kullan.
  // 10.0.2.2 = Android emülatörünün host loopback köprüsü. Fiziksel telefon için LAN IP kullan.
  server: {
    url: 'http://10.0.2.2:3001',
    cleartext: true,
  },
};

export default config;
