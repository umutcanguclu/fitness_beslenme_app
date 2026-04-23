/// Compile-time configuration resolved via `--dart-define` or
/// `--dart-define-from-file=.env`.
///
/// Build/run example:
///   flutter run --dart-define=API_URL=http://10.0.2.2:3000
///
/// For `.env` usage create `apps/mobile/.env` and run:
///   flutter run --dart-define-from-file=.env
class Env {
  const Env._();

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isProduction => appEnv == 'production';
  static bool get isDevelopment => appEnv == 'development';
}
