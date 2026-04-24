import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../data/workout_repository.dart';
import '../domain/workout.dart';

/// Blocks until the auth controller has finished auto-login so we don't fire
/// API calls with a missing Bearer token on cold start.
Future<void> _awaitAuth(Ref ref) async {
  final auth = await ref.watch(authControllerProvider.future);
  if (auth is! AuthAuthenticated) {
    throw StateError('Not authenticated');
  }
}

/// Loads the workout history (first page). Screens call `ref.invalidate` after
/// mutations (start/finish/delete) to refresh.
final workoutHistoryProvider = FutureProvider<WorkoutListPage>((ref) async {
  await _awaitAuth(ref);
  return ref.watch(workoutRepositoryProvider).list();
});

/// Loads a single workout with sets.
final workoutDetailProvider =
    FutureProvider.family<Workout, String>((ref, id) async {
  await _awaitAuth(ref);
  return ref.watch(workoutRepositoryProvider).get(id);
});
