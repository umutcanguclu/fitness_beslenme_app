// Vitest setup file — runs before test modules load.
// Eğer DATABASE_URL_TEST ortam değişkeni set'liyse, DATABASE_URL'i onunla
// override eder. Bu sayede entegrasyon testleri gerçek bir test DB'sine
// bağlanır; yoksa env.ts'in stub URL'i ile in-memory unit testleri çalışır.
if (process.env.DATABASE_URL_TEST) {
  process.env.DATABASE_URL = process.env.DATABASE_URL_TEST;
  process.env.NODE_ENV = 'test';
}
