'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { logout, type SessionUser } from '@/lib/session';

const COACH_LINKS = [
  { href: '/dashboard', label: 'Özet' },
  { href: '/teams', label: 'Takımlar' },
  { href: '/chat', label: 'Mesajlar' },
];

const PLAYER_LINKS = [
  { href: '/my-program', label: 'Programım' },
  { href: '/chat', label: 'Mesajlar' },
];

export function Nav({ user }: { user: SessionUser }) {
  const router = useRouter();
  const pathname = usePathname();
  const links = user.role === 'coach' ? COACH_LINKS : PLAYER_LINKS;

  async function onLogout() {
    await logout();
    router.replace('/login');
  }

  return (
    <header className="sticky top-0 z-10 bg-bg/90 backdrop-blur border-b border-border">
      <div className="max-w-3xl mx-auto px-4 py-3 flex items-center gap-4">
        <Link href={user.role === 'coach' ? '/dashboard' : '/my-program'} className="text-accent font-bold text-lg shrink-0">
          fittrack
        </Link>
        <nav className="flex gap-1 flex-1 overflow-x-auto">
          {links.map((link) => {
            const isActive = pathname === link.href || pathname.startsWith(link.href + '/');
            return (
              <Link
                key={link.href}
                href={link.href}
                className={`px-3 py-1.5 rounded text-sm whitespace-nowrap ${
                  isActive ? 'bg-accent/10 text-accent' : 'text-text-muted hover:text-text'
                }`}
              >
                {link.label}
              </Link>
            );
          })}
        </nav>
        <button onClick={onLogout} className="btn-ghost px-3 py-1.5 text-sm shrink-0">
          Çıkış
        </button>
      </div>
    </header>
  );
}
