import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_error.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/fittrack_colors.dart';
import '../data/nutrition_repository.dart';
import '../domain/nutrition.dart';

class NutritionWizardScreen extends ConsumerStatefulWidget {
  const NutritionWizardScreen({super.key});

  @override
  ConsumerState<NutritionWizardScreen> createState() =>
      _NutritionWizardScreenState();
}

class _NutritionWizardScreenState
    extends ConsumerState<NutritionWizardScreen> {
  static const _stepCount = 4;
  final PageController _page = PageController();
  int _step = 0;

  String _gender = 'male';
  int _age = 28;
  double _heightCm = 175;
  double _weightKg = 75;
  String _activityLevel = 'moderate';
  String _goal = 'maintain';
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
    setState(() => _submitting = true);
    try {
      final input = NutritionGenerateInput(
        age: _age,
        gender: _gender,
        heightCm: _heightCm,
        weightKg: _weightKg,
        activityLevel: _activityLevel,
        goal: _goal,
      );
      await ref.read(nutritionRepositoryProvider).generate(input);
      ref.invalidate(activeNutritionPlanProvider);
      if (mounted) context.go(AppRoute.nutritionDashboard);
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
            _Header(step: _step, total: _stepCount, onBack: _back, colors: colors),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _StepGender(gender: _gender, onSelect: (v) => setState(() => _gender = v)),
                  _StepBody(
                    age: _age,
                    heightCm: _heightCm,
                    weightKg: _weightKg,
                    onAge: (v) => setState(() => _age = v),
                    onHeight: (v) => setState(() => _heightCm = v),
                    onWeight: (v) => setState(() => _weightKg = v),
                  ),
                  _StepActivity(
                    level: _activityLevel,
                    onSelect: (v) => setState(() => _activityLevel = v),
                  ),
                  _StepGoal(goal: _goal, onSelect: (v) => setState(() => _goal = v)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FilledButton(
                onPressed: _submitting ? null : _next,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: colors.primary,
                  foregroundColor: colors.primaryForeground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _submitting
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: colors.primaryForeground),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isLast ? Icons.restaurant_menu : Icons.arrow_forward,
                              size: 20),
                          const SizedBox(width: 10),
                          Text(
                            isLast ? 'Planı Oluştur' : 'Devam',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.primaryForeground,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
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
              Text('${step + 1} / $total',
                  style: TextStyle(
                      color: colors.textMuted, fontWeight: FontWeight.w600)),
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

class _Frame extends StatelessWidget {
  const _Frame({required this.title, required this.subtitle, required this.child});
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
                  color: colors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: colors.textMuted)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
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
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: 0.10) : colors.surface,
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
                    child: Icon(icon,
                        color: selected ? colors.primary : colors.textPrimary),
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
                            style: TextStyle(color: colors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(
                    selected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: selected ? colors.primary : colors.textDim,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepGender extends StatelessWidget {
  const _StepGender({required this.gender, required this.onSelect});
  final String gender;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'Cinsiyet',
      subtitle: 'BMR hesabı için gerekli.',
      child: Column(
        children: [
          _Option(title: 'Erkek', subtitle: 'Mifflin-St Jeor +5', icon: Icons.male, selected: gender == 'male', onTap: () => onSelect('male')),
          _Option(title: 'Kadın', subtitle: 'Mifflin-St Jeor −161', icon: Icons.female, selected: gender == 'female', onTap: () => onSelect('female')),
          _Option(title: 'Belirtmek istemiyorum', subtitle: 'Ortalama değer kullan', icon: Icons.person, selected: gender == 'prefer_not_to_say', onTap: () => onSelect('prefer_not_to_say')),
        ],
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.onAge,
    required this.onHeight,
    required this.onWeight,
  });

  final int age;
  final double heightCm;
  final double weightKg;
  final void Function(int) onAge;
  final void Function(double) onHeight;
  final void Function(double) onWeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    return _Frame(
      title: 'Vücut ölçüleri',
      subtitle: 'Yaş, boy ve kilonu seç.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NumberCard(label: 'Yaş', value: '$age', colors: colors, slider: Slider(
            value: age.toDouble(), min: 14, max: 90, divisions: 76,
            label: '$age', onChanged: (v) => onAge(v.round()),
          )),
          const SizedBox(height: 12),
          _NumberCard(label: 'Boy', value: '${heightCm.round()} cm', colors: colors, slider: Slider(
            value: heightCm, min: 120, max: 220, divisions: 100,
            label: '${heightCm.round()} cm', onChanged: onHeight,
          )),
          const SizedBox(height: 12),
          _NumberCard(label: 'Kilo', value: '${weightKg.round()} kg', colors: colors, slider: Slider(
            value: weightKg, min: 35, max: 200, divisions: 165,
            label: '${weightKg.round()} kg', onChanged: onWeight,
          )),
        ],
      ),
    );
  }
}

class _NumberCard extends StatelessWidget {
  const _NumberCard({required this.label, required this.value, required this.slider, required this.colors});
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
                  fontSize: 28,
                  fontWeight: FontWeight.w800)),
          slider,
        ],
      ),
    );
  }
}

class _StepActivity extends StatelessWidget {
  const _StepActivity({required this.level, required this.onSelect});
  final String level;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return _Frame(
      title: 'Aktivite seviyesi',
      subtitle: 'Haftalık fiziksel aktivite yoğunluğun.',
      child: Column(
        children: [
          _Option(title: 'Sedanter', subtitle: 'Masa başı, çok az hareket', icon: Icons.chair, selected: level == 'sedentary', onTap: () => onSelect('sedentary')),
          _Option(title: 'Hafif', subtitle: '1–3 gün / hafta hafif egzersiz', icon: Icons.directions_walk, selected: level == 'light', onTap: () => onSelect('light')),
          _Option(title: 'Orta', subtitle: '3–5 gün / hafta düzenli egzersiz', icon: Icons.directions_bike, selected: level == 'moderate', onTap: () => onSelect('moderate')),
          _Option(title: 'Aktif', subtitle: '6–7 gün / hafta ağır egzersiz', icon: Icons.directions_run, selected: level == 'active', onTap: () => onSelect('active')),
          _Option(title: 'Çok Aktif', subtitle: 'Günde iki seans ya da ağır iş', icon: Icons.local_fire_department, selected: level == 'very_active', onTap: () => onSelect('very_active')),
        ],
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
    return _Frame(
      title: 'Beslenme hedefin',
      subtitle: 'Kalori hedefini ve makro dağılımını şekillendirir.',
      child: Column(
        children: [
          _Option(title: 'Yağ Yakma', subtitle: 'TDEE − 500 kcal · Yüksek protein', icon: Icons.local_fire_department_outlined, selected: goal == 'lose_fat', onTap: () => onSelect('lose_fat')),
          _Option(title: 'Koruma', subtitle: 'TDEE seviyesi', icon: Icons.balance, selected: goal == 'maintain', onTap: () => onSelect('maintain')),
          _Option(title: 'Kas Kazanma', subtitle: 'TDEE + 300 kcal · Hafif bulk', icon: Icons.fitness_center, selected: goal == 'gain_muscle', onTap: () => onSelect('gain_muscle')),
          _Option(title: 'Genel Beslenme', subtitle: 'Dengeli, TDEE seviyesi', icon: Icons.favorite_outline, selected: goal == 'general_fitness', onTap: () => onSelect('general_fitness')),
        ],
      ),
    );
  }
}
