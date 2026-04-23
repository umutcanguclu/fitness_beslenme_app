import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_error.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/fittrack_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../workouts/application/workouts_controller.dart';
import '../../workouts/data/workout_repository.dart';
import '../../workouts/domain/workout.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final history = ref.watch(workoutHistoryProvider);
    final userName = authState is AuthAuthenticated ? authState.user.name : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName,
            style: textTheme.titleLarge?.copyWith(color: colors.primary)),
        actions: [
          IconButton(
            tooltip: strings.localeToggleLabel,
            icon: const Icon(Icons.translate),
            onPressed: () => ref.read(localeControllerProvider.notifier).toggle(),
          ),
          IconButton(
            tooltip: strings.authSignOut,
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(workoutHistoryProvider),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${strings.dashboardWelcome}${userName.isEmpty ? '' : ', $userName'}',
                  style: textTheme.headlineMedium?.copyWith(color: colors.textPrimary),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  strings.workoutHistoryTitle,
                  style: textTheme.titleMedium?.copyWith(color: colors.textPrimary),
                ),
              ),
              const SizedBox(height: 8),
              history.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error is ApiError ? error.message : '$error',
                    style: TextStyle(color: colors.danger),
                  ),
                ),
                data: (page) {
                  if (page.items.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border.all(color: colors.border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        strings.workoutHistoryEmpty,
                        style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                      ),
                    );
                  }
                  return Column(
                    children: page.items
                        .map((workout) => _WorkoutHistoryTile(workout: workout))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startWorkout(context, ref),
        icon: const Icon(Icons.play_arrow),
        label: Text(strings.workoutStartAction),
      ),
    );
  }

  Future<void> _startWorkout(BuildContext context, WidgetRef ref) async {
    try {
      final workout = await ref.read(workoutRepositoryProvider).start();
      ref.invalidate(workoutHistoryProvider);
      if (context.mounted) {
        context.go('${AppRoute.workoutActiveBase}/${workout.id}');
      }
    } on ApiError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }
}

class _WorkoutHistoryTile extends StatelessWidget {
  const _WorkoutHistoryTile({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final dateFmt = DateFormat.yMMMd().add_Hm();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name ?? strings.workoutUntitled,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFmt.format(workout.startedAt.toLocal()),
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: workout.isFinished
                      ? colors.success.withValues(alpha: 0.12)
                      : colors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  workout.isFinished
                      ? strings.workoutFinished
                      : strings.workoutInProgress,
                  style: TextStyle(
                    color: workout.isFinished ? colors.success : colors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    final base = workout.isFinished ? AppRoute.workoutDetailBase : AppRoute.workoutActiveBase;
    context.go('$base/${workout.id}');
  }
}
