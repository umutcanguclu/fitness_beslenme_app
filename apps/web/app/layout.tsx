import type { Metadata, Viewport } from 'next';
import './globals.css';
import { ServiceWorkerRegistrar } from '@/components/ServiceWorkerRegistrar';

export const metadata: Metadata = {
  title: 'fittrack',
  description: 'Futbol antrenör/oyuncu platformu — alt lig + akademi',
  manifest: '/manifest.webmanifest',
  icons: {
    icon: [{ url: '/icon.svg', type: 'image/svg+xml' }],
    apple: [{ url: '/icon.svg' }],
  },
  appleWebApp: {
    capable: true,
    title: 'fittrack',
    statusBarStyle: 'black-translucent',
  },
};

export const viewport: Viewport = {
  themeColor: '#0a0a0a',
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  viewportFit: 'cover',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  // suppressHydrationWarning: Dark Reader / Grammarly gibi tarayıcı uzantıları
  // <html> ve <body>'ye attribute enjekte eder, SSR ile uyuşmaz. Üretimde sorun
  // değil ama dev console'da uyarı verir; Next.js'in resmi önerisi bu flag.
  return (
    <html lang="tr" className="dark" suppressHydrationWarning>
      <body suppressHydrationWarning>
        {children}
        <ServiceWorkerRegistrar />
      </body>
    </html>
  );
}
