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
  static const _stepCount = 5;

  final PageController _page = PageController();
  int _step = 0;

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

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _stepCount - 1) {
      _page.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step == 0) {
      context.go(AppRoute.home);
      return;
    }
    _page.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _submit() async {
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final isLast = _step == _stepCount - 1;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _WizardHeader(
              step: _step,
              total: _stepCount,
              onBack: _back,
              colors: colors,
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _StepGoal(goal: _goal, onSelect: (v) => setState(() => _goal = v)),
                  _StepLevel(level: _level, onSelect: (v) => setState(() => _level = v)),
                  _StepEquipment(
                      equipment: _equipment,
                      onSelect: (v) => setState(() => _equipment = v)),
                  _StepTime(
                    days: _daysPerWeek,
                    minutes: _sessionMinutes,
                    onDays: (v) => setState(() => _daysPerWeek = v),
                    onMinutes: (v) => setState(() => _sessionMinutes = v),
                  ),
                  _StepMuscles(
                    selected: _muscles,
                    onToggle: (m, add) => setState(() {
                      if (add) {
                        _muscles.add(m);
                      } else if (_muscles.length > 1) {
                        _muscles.remove(m);
                      }
                    }),
                  ),
                ],
              ),
            ),
            _WizardFooter(
              isLast: isLast,
              submitting: _submitting,
              onNext: _next,
              colors: colors,
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({
    required this.step,
    required this.total,
    required this.onBack,
    required this.colors,
  });

  final int step;
  final int total;
  final VoidCallback onBack;
  final FitTrackColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back, color: colors.textPrimary),
              ),
              const Spacer(),
              Text(
                '${step + 1} / $total',
                style: TextStyle(color: colors.textMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (step + 1) / total,
                minHeight: 6,
                backgroundColor: colors.surface,
                valueColor: AlwaysStoppedAnimation(colors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardFooter extends StatelessWidget {
  const _WizardFooter({
    required this.isLast,
    required this.submitting,
    required this.onNext,
    required this.colors,
    required this.textTheme,
  });

  final bool isLast;
  final bool submitting;
  final VoidCallback onNext;
  final FitTrackColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: FilledButton(
        onPressed: submitting ? null : onNext,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: colors.primary,
          foregroundColor: colors.primaryForeground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: submitting
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: colors.primaryForeground),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isLast ? Icons.auto_awesome : Icons.arrow_forward,
                      size: 20),
                  const SizedBox(width: 10),
                  Text(
                    isLast ? 'Programı Oluştur' : 'Devam',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.primaryForeground,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------- step widgets ----------

class _StepFrame extends StatelessWidget {
  const _StepFrame({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: ListView(
        children: [
          Text(title,
              style: textTheme.headlineSmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: colors.textMuted, fontSize: 14)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: 0.10)
              : colors.surface,
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.primary.withValues(alpha: 0.18)
                          : colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: selected ? colors.primary : colors.textPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            )),
                        const SizedBox(height: 3),
                        Text(subtitle,
                            style:
                                TextStyle(color: colors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, color: colors.primary, size: 22)
                  else
                    Icon(Icons.radio_button_unchecked,
                        color: colors.textDim, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepGoal extends StatelessWidget {
  const _StepGoal({required this.goal, required this.onSelect});
  final String goal;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Hedefin ne?',
      subtitle: 'Programı buna göre şekillendireceğim.',
      child: Column(
        children: [
          _OptionCard(
            title: 'Yağ Yakma',
            subtitle: 'Yüksek tempo, kısa dinlenme',
            icon: Icons.local_fire_department_outlined,
            selected: goal == 'lose_fat',
            onTap: () => onSelect('lose_fat'),
          ),
          _OptionCard(
            title: 'Kas Kazanma',
            subtitle: 'Hacim odaklı, uzun dinlenme',
            icon: Icons.fitness_center,
            selected: goal == 'gain_muscle',
            onTap: () => onSelect('gain_muscle'),
          ),
          _OptionCard(
            title: 'Koruma',
            subtitle: 'Formu koru, dengeyi sağla',
            icon: Icons.balance,
            selected: goal == 'maintain',
            onTap: () => onSelect('maintain'),
          ),
          _OptionCard(
            title: 'Genel Fitness',
            subtitle: 'Dengeli, her şeyden biraz',
            icon: Icons.favorite_outline,
            selected: goal == 'general_fitness',
            onTap: () => onSelect('general_fitness'),
          ),
        ],
      ),
    );
  }
}

class _StepLevel extends StatelessWidget {
  const _StepLevel({required this.level, required this.onSelect});
  final String level;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Deneyim seviyen?',
      subtitle: 'Doğru zorluğa ayarlayacağım.',
      child: Column(
        children: [
          _OptionCard(
            title: 'Başlangıç',
            subtitle: 'Yeni başlıyorum veya 6 aydan az',
            icon: Icons.eco_outlined,
            selected: level == 'beginner',
            onTap: () => onSelect('beginner'),
          ),
          _OptionCard(
            title: 'Orta',
            subtitle: '6 ay – 2 yıl tutarlı antrenman',
            icon: Icons.trending_up,
            selected: level == 'intermediate',
            onTap: () => onSelect('intermediate'),
          ),
          _OptionCard(
            title: 'İleri',
            subtitle: '2+ yıl ciddi antrenman',
            icon: Icons.emoji_events_outlined,
            selected: level == 'advanced',
            onTap: () => onSelect('advanced'),
          ),
        ],
      ),
    );
  }
}

class _StepEquipment extends StatelessWidget {
  const _StepEquipment({required this.equipment, required this.onSelect});
  final String equipment;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return _StepFrame(
      title: 'Elindeki ekipman?',
      subtitle: 'Sadece erişebildiğin ekipmanı kullanacağım.',
      child: Column(
        children: [
          _OptionCard(
            title: 'Sadece Vücut Ağırlığı',
            subtitle: 'Evde, hiçbir ekipman yok',
            icon: Icons.self_improvement,
            selected: equipment == 'bodyweight_only',
            onTap: () => onSelect('bodyweight_only'),
          ),
          _OptionCard(
            title: 'Dumbbell / Kettlebell',
            subtitle: 'Evde birkaç ağırlık var',
            icon: Icons.sports_gymnastics,
            selected: equipment == 'dumbbell_only',
            onTap: () => onSelect('dumbbell_only'),
          ),
          _OptionCard(
            title: 'Tam Donanımlı Salon',
            subtitle: 'Barbell, makineler, kablolar',
            icon: Icons.business,
            selected: equipment == 'full_gym',
            onTap: () => onSelect('full_gym'),
          ),
        ],
      ),
    );
  }
}

class _StepTime extends StatelessWidget {
  const _StepTime({
    required this.days,
    required this.minutes,
    required this.onDays,
    required this.onMinutes,
  });
  final int days;
  final int minutes;
  final void Function(int) onDays;
  final void Function(int) onMinutes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    return _StepFrame(
      title: 'Ne kadar vaktin var?',
      subtitle: 'Haftalık sıklık ve seans süresi.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BigNumberCard(
            label: 'Haftada',
            value: '$days gün',
            colors: colors,
            slider: Slider(
              value: days.toDouble(),
              min: 2,
              max: 6,
              divisions: 4,
              label: '$days gün',
              onChanged: (v) => onDays(v.round()),
            ),
          ),
          const SizedBox(height: 12),
          _BigNumberCard(
            label: 'Seans',
            value: '$minutes dk',
            colors: colors,
            slider: Slider(
              value: minutes.toDouble(),
              min: 30,
              max: 120,
              divisions: 9,
              label: '$minutes dk',
              onChanged: (v) => onMinutes(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigNumberCard extends StatelessWidget {
  const _BigNumberCard({
    required this.label,
    required this.value,
    required this.slider,
    required this.colors,
  });

  final String label;
  final String value;
  final Widget slider;
  final FitTrackColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.textMuted, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: colors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800)),
          slider,
        ],
      ),
    );
  }
}

class _StepMuscles extends StatelessWidget {
  const _StepMuscles({required this.selected, required this.onToggle});

  final Set<String> selected;
  final void Function(String, bool) onToggle;

  static const _options = <MapEntry<String, ({String label, IconData icon})>>[
    MapEntry('chest', (label: 'Göğüs', icon: Icons.accessibility_new)),
    MapEntry('back', (label: 'Sırt', icon: Icons.arrow_upward)),
    MapEntry('shoulders', (label: 'Omuz', icon: Icons.waves)),
    MapEntry('biceps', (label: 'Biceps', icon: Icons.fitness_center)),
    MapEntry('triceps', (label: 'Triceps', icon: Icons.sports_martial_arts)),
    MapEntry('forearms', (label: 'Ön Kol', icon: Icons.pan_tool_outlined)),
    MapEntry('core', (label: 'Core', icon: Icons.adjust)),
    MapEntry('quads', (label: 'Ön Bacak', icon: Icons.directions_walk)),
    MapEntry('hamstrings', (label: 'Arka Bacak', icon: Icons.directions_run)),
    MapEntry('glutes', (label: 'Kalça', icon: Icons.airline_seat_recline_normal)),
    MapEntry('calves', (label: 'Baldır', icon: Icons.hiking)),
    MapEntry('cardio', (label: 'Kardiyo', icon: Icons.favorite)),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    return _StepFrame(
      title: 'Hangi bölgeler?',
      subtitle: 'Çalıştırmak istediklerini seç.',
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
        physics: const NeverScrollableScrollPhysics(),
        children: _options.map((e) {
          final isSel = selected.contains(e.key);
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onToggle(e.key, !isSel),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                color: isSel
                    ? colors.primary.withValues(alpha: 0.12)
                    : colors.surface,
                border: Border.all(
                  color: isSel ? colors.primary : colors.border,
                  width: isSel ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(e.value.icon,
                      color: isSel ? colors.primary : colors.textPrimary,
                      size: 28),
                  const SizedBox(height: 8),
                  Text(
                    e.value.label,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
