import PlayerDetailClient from './page-client';

export function generateStaticParams() {
  return [{ playerId: '__shell__' }];
}

export default function Page() {
  return <PlayerDetailClient />;
}
