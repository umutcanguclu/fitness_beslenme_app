import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/programs/presentation/program_detail_screen.dart';
import '../../features/programs/presentation/program_wizard_screen.dart';
import '../../features/workouts/presentation/active_workout_screen.dart';
import '../../features/workouts/presentation/workout_detail_screen.dart';

class AppRoute {
  const AppRoute._();
  static const home = '/';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const workoutActiveBase = '/workout/active';
  static const workoutDetailBase = '/workout';
  static const programWizard = '/programs/new';
  static const programDetailBase = '/programs';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoute.home,
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      if (authAsync.isLoading) return null;
      final auth = authAsync.valueOrNull;
      final isAuthed = auth is AuthAuthenticated;
      final onAuthPage = state.matchedLocation == AppRoute.signIn ||
          state.matchedLocation == AppRoute.signUp;

      if (!isAuthed && !onAuthPage) return AppRoute.signIn;
      if (isAuthed && onAuthPage) return AppRoute.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoute.signIn,
        name: 'sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoute.signUp,
        name: 'sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '${AppRoute.workoutActiveBase}/:id',
        name: 'workout-active',
        builder: (context, state) =>
            ActiveWorkoutScreen(workoutId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '${AppRoute.workoutDetailBase}/:id',
        name: 'workout-detail',
        builder: (context, state) =>
            WorkoutDetailScreen(workoutId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoute.programWizard,
        name: 'program-wizard',
        builder: (context, state) => const ProgramWizardScreen(),
      ),
      GoRoute(
        path: '${AppRoute.programDetailBase}/:id',
        name: 'program-detail',
        builder: (context, state) =>
            ProgramDetailScreen(programId: state.pathParameters['id']!),
      ),
    ],
  );
});

/// Bridges Riverpod auth state into go_router's Listenable-based refresh API.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this._ref) {
    _sub = _ref.listen<dynamic>(
      authControllerProvider,
      (previous, next) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
