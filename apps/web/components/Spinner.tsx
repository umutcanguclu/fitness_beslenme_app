export function Spinner({ size = 24 }: { size?: number }) {
  return (
    <div
      className="inline-block animate-spin rounded-full border-2 border-border border-t-accent"
      style={{ width: size, height: size }}
      aria-label="Yükleniyor"
    />
  );
}

export function FullPageSpinner() {
  return (
    <div className="min-h-dvh flex items-center justify-center">
      <Spinner size={32} />
    </div>
  );
}
