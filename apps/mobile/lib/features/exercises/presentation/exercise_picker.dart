import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/locale_controller.dart';
import '../../../core/theme/fittrack_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/exercise.dart';

/// Opens a bottom sheet with a searchable list of exercises from the
/// asset catalog. Returns the selected [Exercise] or `null` on dismiss.
Future<Exercise?> showExercisePicker(BuildContext context) {
  return showModalBottomSheet<Exercise>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _ExercisePickerSheet(),
  );
}

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  const _ExercisePickerSheet();

  @override
  ConsumerState<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final catalog = ref.watch(exerciseCatalogProvider);
    final locale = ref.watch(localeControllerProvider).languageCode;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: strings.workoutSearchExercise,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                ),
              ),
              Expanded(
                child: catalog.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('$error')),
                  data: (exercises) {
                    final filtered = _query.isEmpty
                        ? exercises
                        : exercises.where((e) {
                            final name = e.nameFor(locale).toLowerCase();
                            final muscles = e.muscleGroup.join(' ').toLowerCase();
                            return name.contains(_query) || muscles.contains(_query);
                          }).toList();
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          strings.dashboardNoData,
                          style: TextStyle(color: colors.textMuted),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: colors.border, height: 1),
                      itemBuilder: (context, index) {
                        final exercise = filtered[index];
                        return ListTile(
                          title: Text(exercise.nameFor(locale)),
                          subtitle: Text(
                            exercise.muscleGroup.join(' · '),
                            style: TextStyle(color: colors.textMuted),
                          ),
                          onTap: () => Navigator.of(context).pop(exercise),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
