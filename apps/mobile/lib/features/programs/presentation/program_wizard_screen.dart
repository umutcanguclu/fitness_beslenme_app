import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_error.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/fittrack_colors.dart';
import '../data/program_repository.dart';
import '../domain/program.dart';

class ProgramWizardScreen extends ConsumerStatefulWidget {
  const ProgramWizardScreen({super.key});

  @override
  ConsumerState<ProgramWizardScreen> createState() => _ProgramWizardScreenState();
}

class _ProgramWizardScreenState extends ConsumerState<ProgramWizardScreen> {
  String _goal = 'gain_muscle';
  String _level = 'beginner';
  String _equipment = 'full_gym';
  int _daysPerWeek = 4;
  int _sessionMinutes = 60;
  final Set<String> _muscles = {
    'chest',
    'back',
    'shoulders',
    'biceps',
    'triceps',
    'quads',
    'hamstrings',
    'core',
  };

  bool _submitting = false;

  static const _muscleOptions = <MapEntry<String, String>>[
    MapEntry('chest', 'Göğüs'),
    MapEntry('back', 'Sırt'),
    MapEntry('shoulders', 'Omuz'),
    MapEntry('biceps', 'Biceps'),
    MapEntry('triceps', 'Triceps'),
    MapEntry('forearms', 'Ön Kol'),
    MapEntry('core', 'Core'),
    MapEntry('quads', 'Ön Bacak'),
    MapEntry('hamstrings', 'Arka Bacak'),
    MapEntry('glutes', 'Kalça'),
    MapEntry('calves', 'Baldır'),
    MapEntry('cardio', 'Kardiyo'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Oluştur'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Hedefin ne?', textTheme, colors),
            _chipGroup(
              selected: _goal,
              options: const [
                MapEntry('lose_fat', 'Yağ Yakma'),
                MapEntry('gain_muscle', 'Kas Kazanma'),
                MapEntry('maintain', 'Koruma'),
                MapEntry('general_fitness', 'Genel Fitness'),
              ],
              onSelect: (v) => setState(() => _goal = v),
            ),
            const SizedBox(height: 16),
            _section('Seviyen', textTheme, colors),
            _chipGroup(
              selected: _level,
              options: const [
                MapEntry('beginner', 'Başlangıç'),
                MapEntry('intermediate', 'Orta'),
                MapEntry('advanced', 'İleri'),
              ],
              onSelect: (v) => setState(() => _level = v),
            ),
            const SizedBox(height: 16),
            _section('Elindeki ekipman', textTheme, colors),
            _chipGroup(
              selected: _equipment,
              options: const [
                MapEntry('bodyweight_only', 'Sadece Vücut Ağırlığı'),
                MapEntry('dumbbell_only', 'Sadece Dumbbell'),
                MapEntry('full_gym', 'Tam Donanımlı Spor Salonu'),
              ],
              onSelect: (v) => setState(() => _equipment = v),
            ),
            const SizedBox(height: 16),
            _section('Haftada kaç gün? ($_daysPerWeek gün)', textTheme, colors),
            Slider(
              value: _daysPerWeek.toDouble(),
              min: 2,
              max: 6,
              divisions: 4,
              label: '$_daysPerWeek gün',
              onChanged: (v) => setState(() => _daysPerWeek = v.round()),
            ),
            const SizedBox(height: 8),
            _section('Seans süresi ($_sessionMinutes dk)', textTheme, colors),
            Slider(
              value: _sessionMinutes.toDouble(),
              min: 30,
              max: 120,
              divisions: 9,
              label: '$_sessionMinutes dk',
              onChanged: (v) => setState(() => _sessionMinutes = v.round()),
            ),
            const SizedBox(height: 16),
            _section('Çalışmak istediğin bölgeler', textTheme, colors),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _muscleOptions.map((opt) {
                final selected = _muscles.contains(opt.key);
                return FilterChip(
                  label: Text(opt.value),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _muscles.add(opt.key);
                    } else if (_muscles.length > 1) {
                      _muscles.remove(opt.key);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _submitting ? null : _generate,
              icon: _submitting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome),
              label: const Text('Programı Oluştur'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, TextTheme textTheme, FitTrackColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title,
          style: textTheme.titleMedium?.copyWith(color: colors.textPrimary)),
    );
  }

  Widget _chipGroup({
    required String selected,
    required List<MapEntry<String, String>> options,
    required void Function(String) onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        return ChoiceChip(
          label: Text(o.value),
          selected: selected == o.key,
          onSelected: (v) {
            if (v) onSelect(o.key);
          },
        );
      }).toList(),
    );
  }

  Future<void> _generate() async {
    if (_muscles.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final input = ProgramGenerateInput(
        goal: _goal,
        level: _level,
        equipment: _equipment,
        daysPerWeek: _daysPerWeek,
        sessionMinutes: _sessionMinutes,
        targetMuscles: _muscles.toList(),
      );
      final program = await ref.read(programRepositoryProvider).generate(input);
      ref.invalidate(activeProgramProvider);
      if (mounted) context.go('${AppRoute.programDetailBase}/${program.id}');
    } on ApiError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
