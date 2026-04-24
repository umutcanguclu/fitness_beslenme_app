import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_error.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/fittrack_colors.dart';
import '../../exercises/domain/exercise.dart';
import '../data/program_repository.dart';
import '../domain/program.dart';

class ProgramDetailScreen extends ConsumerStatefulWidget {
  const ProgramDetailScreen({super.key, required this.programId});
  final String programId;

  @override
  ConsumerState<ProgramDetailScreen> createState() =>
      _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen> {
  int _selectedDay = 0;

  @override
  Widget build(BuildContext context) {
    final programAsync = ref.watch(activeProgramProvider);
    final catalogAsync = ref.watch(exerciseCatalogProvider);
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
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
              final dayIndex =
                  _selectedDay.clamp(0, program.days.length - 1).toInt();
              final currentDay = program.days[dayIndex];
              return CustomScrollView(
                slivers: [
                  _Hero(
                    program: program,
                    onDelete: () => _confirmDelete(context, ref),
                    colors: colors,
                    textTheme: textTheme,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                    sliver: SliverToBoxAdapter(
                      child: _DaySelector(
                        days: program.days,
                        selectedIndex: dayIndex,
                        onSelect: (i) => setState(() => _selectedDay = i),
                        colors: colors,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final pe = currentDay.exercises[index];
                          final ex = map[pe.exerciseId];
                          return _ExerciseRow(
                            programExercise: pe,
                            exercise: ex,
                            index: index,
                          );
                        },
                        childCount: currentDay.exercises.length,
                      ),
                    ),
                  ),
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
      await ref.read(programRepositoryProvider).delete(widget.programId);
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

class _Hero extends StatelessWidget {
  const _Hero({
    required this.program,
    required this.onDelete,
    required this.colors,
    required this.textTheme,
  });

  final Program program;
  final VoidCallback onDelete;
  final FitTrackColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: colors.background,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colors.textPrimary),
        onPressed: () => context.go(AppRoute.home),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: colors.textPrimary),
          tooltip: 'Yeniden oluştur',
          onPressed: () => context.go(AppRoute.programWizard),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: colors.danger),
          tooltip: 'Programı sil',
          onPressed: onDelete,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary.withValues(alpha: 0.28),
                colors.accent.withValues(alpha: 0.12),
                colors.background,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'AKTİF PROGRAM',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                program.name,
                style: textTheme.headlineSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatBadge(
                    icon: Icons.calendar_today,
                    value: '${program.daysPerWeek}',
                    label: 'gün/hafta',
                    colors: colors,
                  ),
                  const SizedBox(width: 10),
                  _StatBadge(
                    icon: Icons.timer_outlined,
                    value: '${program.sessionMinutes}',
                    label: 'dk/seans',
                    colors: colors,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String value;
  final String label;
  final FitTrackColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.8),
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.textMuted),
          const SizedBox(width: 6),
          Text(value,
              style: TextStyle(
                  color: colors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(color: colors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.days,
    required this.selectedIndex,
    required this.onSelect,
    required this.colors,
  });

  final List<ProgramDay> days;
  final int selectedIndex;
  final void Function(int) onSelect;
  final FitTrackColors colors;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        children: List.generate(days.length, (i) {
          final isSel = i == selectedIndex;
          final d = days[i];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? colors.primary : colors.surface,
                  border: Border.all(
                    color: isSel ? colors.primary : colors.border,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GÜN ${d.dayIndex + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isSel
                            ? colors.primaryForeground.withValues(alpha: 0.75)
                            : colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSel
                            ? colors.primaryForeground
                            : colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.programExercise,
    required this.exercise,
    required this.index,
  });

  final ProgramExercise programExercise;
  final Exercise? exercise;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final ex = exercise;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: ex == null
              ? null
              : () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _ExerciseSheet(exercise: ex),
                  ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _Thumb(url: ex?.primaryImage, size: 72),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ex?.nameEn ?? programExercise.exerciseId,
                              style: textTheme.titleSmall?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Chip(
                            text:
                                '${programExercise.targetSets} × ${programExercise.targetReps ?? "${programExercise.targetTimeSeconds ?? 0}s"}',
                            bg: colors.primary.withValues(alpha: 0.15),
                            fg: colors.primary,
                          ),
                          _Chip(
                            text: '${programExercise.restSeconds}s din.',
                            bg: colors.surfaceAlt,
                            fg: colors.textMuted,
                          ),
                          if (ex != null)
                            _Chip(
                              text: ex.muscleGroup.first,
                              bg: colors.accent.withValues(alpha: 0.14),
                              fg: colors.accent,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.textDim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, this.size = 56});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: url == null
          ? Icon(Icons.fitness_center, color: colors.textMuted, size: size * 0.35)
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.broken_image,
                  color: colors.textMuted, size: size * 0.35),
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : Center(
                      child: SizedBox(
                        width: size * 0.25,
                        height: size * 0.25,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: colors.textMuted),
                      ),
                    ),
            ),
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
  late final _ExerciseAnimator _animator;

  @override
  void initState() {
    super.initState();
    if (widget.exercise.images.length > 1) {
      _animator = _ExerciseAnimator(() {
        if (mounted) setState(() => _frame = 1 - _frame);
      });
      _animator.start();
    } else {
      _animator = _ExerciseAnimator(() {});
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
    final currentUrl =
        images.isEmpty ? null : images[_frame.clamp(0, images.length - 1)];
    final instructionSteps = (widget.exercise.instructionsEn ?? '')
        .split(RegExp(r'\n{2,}|\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    if (currentUrl != null)
                      AspectRatio(
                        aspectRatio: 1,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: ClipRRect(
                            key: ValueKey(currentUrl),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              color: colors.surface,
                              child: Image.network(
                                currentUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: colors.textMuted),
                                loadingBuilder: (context, child, progress) =>
                                    progress == null
                                        ? child
                                        : const Center(
                                            child: CircularProgressIndicator()),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      widget.exercise.nameEn,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...widget.exercise.muscleGroup.map((m) => _Chip(
                              text: m,
                              bg: colors.primary.withValues(alpha: 0.16),
                              fg: colors.primary,
                            )),
                        ...widget.exercise.equipment.map((e) => _Chip(
                              text: e,
                              bg: colors.accent.withValues(alpha: 0.14),
                              fg: colors.accent,
                            )),
                        if (widget.exercise.level != null)
                          _Chip(
                            text: widget.exercise.level!,
                            bg: colors.surfaceAlt,
                            fg: colors.textPrimary,
                          ),
                      ],
                    ),
                    if (instructionSteps.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Nasıl Yapılır',
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...instructionSteps.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${entry.key + 1}',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textPrimary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExerciseAnimator {
  _ExerciseAnimator(this.tick);
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
