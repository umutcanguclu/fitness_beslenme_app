import Link from 'next/link';

export function AuthShell({
  title,
  subtitle,
  children,
  footer,
}: {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
}) {
  return (
    <main className="min-h-dvh flex flex-col">
      <div className="px-6 pt-6">
        <Link href="/" className="text-accent font-bold text-lg">
          fittrack
        </Link>
      </div>
      <div className="flex-1 flex items-center justify-center px-6 py-10">
        <div className="w-full max-w-md">
          <h1 className="text-2xl font-semibold mb-1">{title}</h1>
          {subtitle && <p className="text-text-muted mb-6">{subtitle}</p>}
          {children}
          {footer && <div className="mt-6 text-center text-sm text-text-muted">{footer}</div>}
        </div>
      </div>
    </main>
  );
}
