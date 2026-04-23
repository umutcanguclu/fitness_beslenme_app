import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../domain/auth_state.dart';

/// Owns the client-side authentication state. On startup it probes the
/// secure storage to decide whether the user is already logged in.
///
/// Real login/register/refresh flows will be wired up in Faz 1.
class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(SecureStorageKeys.accessToken);
    if (token == null || token.isEmpty) {
      return const AuthUnauthenticated();
    }
    // Token present but we have no cached user; let Faz 1 fetch /auth/me.
    return const AuthUnauthenticated();
  }

  Future<void> signOut() async {
    final storage = ref.read(secureStorageProvider);
    await storage.clear();
    state = const AsyncData(AuthUnauthenticated());
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);
