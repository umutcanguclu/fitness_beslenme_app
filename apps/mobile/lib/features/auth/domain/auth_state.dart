/// Lightweight user snapshot kept in client state.
/// Full server-side schema lives in `packages/shared` (TS/Zod).
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.locale,
  });

  final String id;
  final String email;
  final String name;
  final String locale;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        locale: (json['locale'] as String?) ?? 'en',
      );
}

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AuthUser user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
