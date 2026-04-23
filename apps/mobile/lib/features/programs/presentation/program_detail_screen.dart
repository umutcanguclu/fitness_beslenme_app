import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_error.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/fittrack_colors.dart';
import '../../exercises/domain/exercise.dart';
import '../data/program_repository.dart';
import '../domain/program.dart';

class ProgramDetailScreen extends ConsumerWidget {
  const ProgramDetailScreen({super.key, required this.programId});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programAsync = ref.watch(activeProgramProvider);
    final catalogAsync = ref.watch(exerciseCatalogProvider);
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: programAsync.maybeWhen(
          data: (p) => Text(p?.name ?? 'Program'),
          orElse: () => const Text('Program'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Programı sil',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: programAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error is ApiError ? error.message : '$error',
              style: TextStyle(color: colors.danger)),
        ),
        data: (program) {
          if (program == null) {
            return const Center(child: Text('Aktif program yok.'));
          }
          return catalogAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (exercises) {
              final map = {for (final e in exercises) e.id: e};
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProgramHeader(program: program),
                  const SizedBox(height: 16),
                  ...program.days.map((day) => _DaySection(
                        day: day,
                        exerciseMap: map,
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Programı sil?'),
        content: const Text('Bu program silinecek.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(programRepositoryProvider).delete(programId);
      ref.invalidate(activeProgramProvider);
      if (context.mounted) context.go(AppRoute.home);
    } on ApiError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _ProgramHeader extends StatelessWidget {
  const _ProgramHeader({required this.program});
  final Program program;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(program.name,
              style: textTheme.titleLarge?.copyWith(color: colors.textPrimary)),
          const SizedBox(height: 6),
          Text(
            '${program.daysPerWeek} gün/hafta · ${program.sessionMinutes} dk',
            style: TextStyle(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.day, required this.exerciseMap});

  final ProgramDay day;
  final Map<String, Exercise> exerciseMap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Gün ${day.dayIndex + 1} · ${day.name}',
              style: textTheme.titleMedium?.copyWith(color: colors.primary),
            ),
          ),
          ...day.exercises.map((pe) {
            final ex = exerciseMap[pe.exerciseId];
            return _ExerciseRow(programExercise: pe, exercise: ex);
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.programExercise, required this.exercise});

  final ProgramExercise programExercise;
  final Exercise? exercise;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final ex = exercise;
    return InkWell(
      onTap: ex == null ? null : () => _showDetail(context, ex),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            _Thumb(url: ex?.primaryImage),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex?.nameEn ?? programExercise.exerciseId,
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _setsLabel(programExercise),
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textMuted),
          ],
        ),
      ),
    );
  }

  static String _setsLabel(ProgramExercise pe) {
    final rest = 'Dinlenme ${pe.restSeconds}s';
    if (pe.targetReps != null) return '${pe.targetSets} × ${pe.targetReps} · $rest';
    if (pe.targetTimeSeconds != null) return '${pe.targetSets} × ${pe.targetTimeSeconds}s · $rest';
    return '${pe.targetSets} set · $rest';
  }

  void _showDetail(BuildContext context, Exercise ex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExerciseSheet(exercise: ex),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: url == null
          ? Icon(Icons.fitness_center, color: colors.textMuted)
          : Image.network(url!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.fitness_center, color: colors.textMuted)),
    );
  }
}

class _ExerciseSheet extends StatefulWidget {
  const _ExerciseSheet({required this.exercise});
  final Exercise exercise;

  @override
  State<_ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends State<_ExerciseSheet> {
  int _frame = 0;
  late final ExerciseAnimator _animator;

  @override
  void initState() {
    super.initState();
    if (widget.exercise.images.length > 1) {
      _animator = ExerciseAnimator(() {
        if (mounted) setState(() => _frame = 1 - _frame);
      });
      _animator.start();
    } else {
      _animator = ExerciseAnimator(() {});
    }
  }

  @override
  void dispose() {
    _animator.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final images = widget.exercise.images;
    final currentUrl = images.isEmpty ? null : images[_frame.clamp(0, images.length - 1)];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.exercise.nameEn,
                  style: textTheme.titleLarge?.copyWith(color: colors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                '${widget.exercise.muscleGroup.join(" · ")} · ${widget.exercise.equipment.join(" · ")}',
                style: TextStyle(color: colors.textMuted),
              ),
              const SizedBox(height: 16),
              if (currentUrl != null)
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      currentUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.broken_image, size: 48, color: colors.textMuted),
                      loadingBuilder: (context, child, progress) => progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (widget.exercise.instructionsEn != null)
                Text(
                  widget.exercise.instructionsEn!,
                  style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Alternates between frames every 700ms for a crude 2-frame animation.
class ExerciseAnimator {
  ExerciseAnimator(this.tick);
  final void Function() tick;
  bool _running = false;

  void start() {
    _running = true;
    _loop();
  }

  void stop() {
    _running = false;
  }

  Future<void> _loop() async {
    while (_running) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!_running) break;
      tick();
    }
  }
}
