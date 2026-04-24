import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

/// Dev-mode: always auto-login as the bundled test user so the sign-in
/// screen never blocks testing. Flip `_kDevAutoLogin` off to restore the
/// normal flow.
const bool _kDevAutoLogin = true;
const String _kDevEmail = 'test@fittrack.dev';
const String _kDevPassword = 'Test1234!';

/// Owns the client-side authentication state.
///
/// On startup it probes secure storage for an access token and, if found,
/// calls `/auth/me` to hydrate the user. Login/register/logout mutate state.
class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final storage = ref.read(secureStorageProvider);
    final repo = ref.read(authRepositoryProvider);

    Future<AuthState> devAutoLogin(String reason) async {
      try {
        final response =
            await repo.login(email: _kDevEmail, password: _kDevPassword);
        await repo.persistTokens(response.tokens);
        return AuthAuthenticated(response.user);
      } on ApiError {
        return const AuthUnauthenticated();
      }
    }

    final token = await storage.read(SecureStorageKeys.accessToken);
    if (token == null || token.isEmpty) {
      if (_kDevAutoLogin) return devAutoLogin('no-token');
      return const AuthUnauthenticated();
    }
    try {
      final user = await repo.fetchMe();
      return AuthAuthenticated(user);
    } on ApiError {
      await storage.clear();
      if (_kDevAutoLogin) return devAutoLogin('stale-token');
      return const AuthUnauthenticated();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.login(email: email, password: password);
      await repo.persistTokens(response.tokens);
      return AuthAuthenticated(response.user);
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    String? locale,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.register(
        email: email,
        password: password,
        name: name,
        locale: locale,
      );
      await repo.persistTokens(response.tokens);
      return AuthAuthenticated(response.user);
    });
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(AuthUnauthenticated());
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);
