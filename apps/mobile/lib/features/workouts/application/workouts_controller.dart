import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/workout_repository.dart';
import '../domain/workout.dart';

/// Loads the workout history (first page). Screens call `ref.invalidate` after
/// mutations (start/finish/delete) to refresh.
final workoutHistoryProvider = FutureProvider<WorkoutListPage>((ref) {
  return ref.watch(workoutRepositoryProvider).list();
});

/// Loads a single workout with sets.
final workoutDetailProvider =
    FutureProvider.family<Workout, String>((ref, id) {
  return ref.watch(workoutRepositoryProvider).get(id);
});
