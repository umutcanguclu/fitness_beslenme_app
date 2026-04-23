import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/landing/presentation/landing_screen.dart';
import '../../features/auth/presentation/sign_in_placeholder_screen.dart';

/// Route names kept as typed constants so callers don't sprinkle raw strings.
class AppRoute {
  const AppRoute._();
  static const landing = '/';
  static const signIn = '/sign-in';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoute.landing,
    redirect: (context, state) {
      final auth = authAsync.valueOrNull;
      if (auth is AuthAuthenticated) return null;
      // MVP Faz 0: no protected routes yet; landing screen is always
      // reachable. Real auth guards arrive with Faz 1.
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.landing,
        name: 'landing',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: AppRoute.signIn,
        name: 'sign-in',
        builder: (context, state) => const SignInPlaceholderScreen(),
      ),
    ],
  );
});
