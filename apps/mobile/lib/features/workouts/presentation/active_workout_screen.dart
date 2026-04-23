import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_error.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/fittrack_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../exercises/domain/exercise.dart';
import '../../exercises/presentation/exercise_picker.dart';
import '../application/workouts_controller.dart';
import '../data/workout_repository.dart';
import '../domain/workout.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Exercise? _selectedExercise;
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _timeController = TextEditingController();
  final _distanceController = TextEditingController();
  bool _submittingSet = false;
  bool _finishing = false;
  String? _setError;

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _timeController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _pickExercise() async {
    final selected = await showExercisePicker(context);
    if (selected != null) setState(() => _selectedExercise = selected);
  }

  Future<void> _addSet() async {
    final strings = AppLocalizations.of(context);
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final reps = int.tryParse(_repsController.text);
    final time = int.tryParse(_timeController.text);
    final distance = int.tryParse(_distanceController.text);
    final exercise = _selectedExercise;

    if (exercise == null) {
      setState(() => _setError = strings.workoutPickExercise);
      return;
    }
    final hasWeightReps = weight != null || reps != null;
    if (!hasWeightReps && time == null && distance == null) {
      setState(() => _setError = strings.workoutErrorSetIncomplete);
      return;
    }

    setState(() {
      _setError = null;
      _submittingSet = true;
    });

    try {
      await ref.read(workoutRepositoryProvider).addSet(
            workoutId: widget.workoutId,
            exerciseId: exercise.id,
            weightKg: weight,
            reps: reps,
            timeSeconds: time,
            distanceMeters: distance,
          );
      _weightController.clear();
      _repsController.clear();
      _timeController.clear();
      _distanceController.clear();
      ref.invalidate(workoutDetailProvider(widget.workoutId));
    } on ApiError catch (error) {
      setState(() => _setError = error.message);
    } finally {
      if (mounted) setState(() => _submittingSet = false);
    }
  }

  Future<void> _finish() async {
    setState(() => _finishing = true);
    try {
      await ref.read(workoutRepositoryProvider).finish(widget.workoutId);
      ref.invalidate(workoutHistoryProvider);
      if (mounted) context.go(AppRoute.home);
    } on ApiError catch (error) {
      setState(() => _setError = error.message);
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final locale = ref.watch(localeControllerProvider).languageCode;
    final detail = ref.watch(workoutDetailProvider(widget.workoutId));

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.workoutActiveTitle),
        actions: [
          TextButton(
            onPressed: _finishing ? null : _finish,
            child: _finishing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(strings.workoutFinish),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (workout) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSetForm(strings, colors, locale),
                const SizedBox(height: 24),
                Text(
                  '${strings.tabWorkouts} · ${workout.sets.length}',
                  style: textTheme.titleMedium?.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: 8),
                if (workout.sets.isEmpty)
                  Text(strings.workoutNoSets,
                      style: textTheme.bodyMedium?.copyWith(color: colors.textMuted))
                else
                  ...workout.sets.map((set) => _SetTile(set: set)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSetForm(AppLocalizations strings, FitTrackColors colors, String locale) {
    final selected = _selectedExercise;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _submittingSet ? null : _pickExercise,
            icon: const Icon(Icons.fitness_center),
            label: Text(
              selected == null ? strings.workoutPickExercise : selected.nameFor(locale),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: strings.workoutWeightLabel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: strings.workoutRepsLabel),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _timeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: strings.workoutTimeLabel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _distanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: strings.workoutDistanceLabel),
              ),
            ),
          ]),
          if (_setError != null) ...[
            const SizedBox(height: 12),
            Text(_setError!, style: TextStyle(color: colors.danger)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submittingSet ? null : _addSet,
            icon: _submittingSet
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(strings.workoutAddSet),
          ),
        ],
      ),
    );
  }
}

class _SetTile extends StatelessWidget {
  const _SetTile({required this.set});

  final WorkoutSet set;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final parts = <String>[];
    if (set.weightKg != null && set.reps != null) {
      parts.add('${set.weightKg}kg × ${set.reps}');
    } else if (set.reps != null) {
      parts.add('${set.reps} reps');
    }
    if (set.timeSeconds != null) parts.add('${set.timeSeconds}s');
    if (set.distanceMeters != null) parts.add('${set.distanceMeters}m');
    if (set.rpe != null) parts.add('RPE ${set.rpe}');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colors.accent.withValues(alpha: 0.15),
            child: Text(
              '${set.order + 1}',
              style: TextStyle(color: colors.accent, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              parts.join(' · '),
              style: TextStyle(color: colors.textPrimary),
            ),
          ),
          Text(
            set.exerciseId,
            style: TextStyle(color: colors.textDim, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
