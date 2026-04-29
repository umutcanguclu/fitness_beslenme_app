import ChatThreadClient from './page-client';

export function generateStaticParams() {
  return [{ threadId: '__shell__' }];
}

export default function Page() {
  return <ChatThreadClient />;
}
