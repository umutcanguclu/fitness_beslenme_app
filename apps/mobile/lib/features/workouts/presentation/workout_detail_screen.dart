import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_error.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/fittrack_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/workouts_controller.dart';
import '../data/workout_repository.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final detail = ref.watch(workoutDetailProvider(workoutId));
    final dateFmt = DateFormat.yMMMd().add_Hm();

    return Scaffold(
      appBar: AppBar(
        title: detail.when(
          loading: () => Text(strings.commonLoading),
          error: (error, stack) => Text(strings.authErrorGeneric),
          data: (w) => Text(w.name ?? strings.workoutUntitled),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: strings.actionDelete,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            error is ApiError ? error.message : '$error',
            style: TextStyle(color: colors.danger),
          ),
        ),
        data: (workout) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                dateFmt.format(workout.startedAt.toLocal()),
                style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
              ),
              if (workout.notes != null && workout.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    workout.notes!,
                    style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('${strings.tabWorkouts} · ${workout.sets.length}',
                  style: textTheme.titleMedium?.copyWith(color: colors.textPrimary)),
              const SizedBox(height: 8),
              if (workout.sets.isEmpty)
                Text(strings.workoutNoSets,
                    style: textTheme.bodyMedium?.copyWith(color: colors.textMuted))
              else
                ...workout.sets.map((set) {
                  final parts = <String>[];
                  if (set.weightKg != null && set.reps != null) {
                    parts.add('${set.weightKg}kg × ${set.reps}');
                  } else if (set.reps != null) {
                    parts.add('${set.reps} reps');
                  }
                  if (set.timeSeconds != null) parts.add('${set.timeSeconds}s');
                  if (set.distanceMeters != null) parts.add('${set.distanceMeters}m');
                  if (set.rpe != null) parts.add('RPE ${set.rpe}');
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colors.accent.withValues(alpha: 0.15),
                      child: Text('${set.order + 1}',
                          style: TextStyle(color: colors.accent)),
                    ),
                    title: Text(parts.join(' · ')),
                    subtitle: Text(set.exerciseId,
                        style: TextStyle(color: colors.textDim, fontSize: 11)),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.workoutDeleteConfirm),
        content: Text(strings.workoutDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(workoutRepositoryProvider).delete(workoutId);
      ref.invalidate(workoutHistoryProvider);
      if (context.mounted) context.go(AppRoute.home);
    } on ApiError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}
