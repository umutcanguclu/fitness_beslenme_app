import type { Metadata, Viewport } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'fittrack',
  description: 'Futbol antrenör/oyuncu platformu — alt lig + akademi',
  manifest: '/manifest.webmanifest',
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
  return (
    <html lang="tr" className="dark">
      <body>{children}</body>
    </html>
  );
}
