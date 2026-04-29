import TeamDetailClient from './page-client';

// Statik export: build sırasında bilinen UUID yok, placeholder ile shell üretiyoruz.
// Gerçek navigasyon client-side router üzerinden yapılır (Capacitor app yapısı).
export function generateStaticParams() {
  return [{ teamId: '__shell__' }];
}

export default function Page() {
  return <TeamDetailClient />;
}
