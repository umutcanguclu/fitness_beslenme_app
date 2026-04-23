import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

/// Owns the client-side authentication state.
///
/// On startup it probes secure storage for an access token and, if found,
/// calls `/auth/me` to hydrate the user. Login/register/logout mutate state.
class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(SecureStorageKeys.accessToken);
    if (token == null || token.isEmpty) {
      return const AuthUnauthenticated();
    }
    try {
      final user = await ref.read(authRepositoryProvider).fetchMe();
      return AuthAuthenticated(user);
    } on ApiError {
      await storage.clear();
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
