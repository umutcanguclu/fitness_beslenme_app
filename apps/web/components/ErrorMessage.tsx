import type { ApiError } from '@/lib/api.js';

const TR_MESSAGES: Record<string, string> = {
  UNAUTHORIZED: 'E-posta veya şifre hatalı.',
  CONFLICT: 'Bu kayıt zaten mevcut.',
  NOT_FOUND: 'Aranan kayıt bulunamadı.',
  VALIDATION_ERROR: 'Girilen bilgiler geçersiz.',
  FORBIDDEN: 'Bu işlem için yetkiniz yok.',
  INTERNAL_ERROR: 'Sunucu hatası — birazdan tekrar deneyin.',
};

export function ErrorMessage({ error }: { error: ApiError | string | null }) {
  if (!error) return null;
  if (typeof error === 'string') {
    return <div className="card border-danger/40 text-danger text-sm">{error}</div>;
  }
  const msg = TR_MESSAGES[error.code] ?? error.message;
  return (
    <div className="card border-danger/40 text-danger text-sm">
      {msg}
      {error.code === 'VALIDATION_ERROR' && error.details ? (
        <pre className="mt-2 text-xs overflow-auto">{JSON.stringify(error.details, null, 2)}</pre>
      ) : null}
    </div>
  );
}
