import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_error.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/fittrack_colors.dart';
import '../data/nutrition_repository.dart';
import '../domain/nutrition.dart';

class NutritionDashboardScreen extends ConsumerWidget {
  const NutritionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activeNutritionPlanProvider);
    final foodsAsync = ref.watch(foodCatalogProvider);
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error is ApiError ? error.message : '$error',
              style: TextStyle(color: colors.danger)),
        ),
        data: (plan) {
          if (plan == null) {
            return const Center(child: Text('Aktif beslenme planı yok.'));
          }
          return foodsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Yemekler yüklenemedi.')),
            data: (foods) => _Body(plan: plan, foods: foods, colors: colors, textTheme: textTheme),
          );
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.plan,
    required this.foods,
    required this.colors,
    required this.textTheme,
  });

  final NutritionPlan plan;
  final Map<String, FoodMeta> foods;
  final FitTrackColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: colors.background,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => context.go(AppRoute.home),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: colors.textPrimary),
              tooltip: 'Yeni plan',
              onPressed: () => context.go(AppRoute.nutritionWizard),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.danger),
              tooltip: 'Planı sil',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(20, 72, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.accent.withValues(alpha: 0.28),
                    colors.primary.withValues(alpha: 0.10),
                    colors.background,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('BESLENME PLANI',
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        )),
                  ),
                  const SizedBox(height: 8),
                  Text(plan.name,
                      style: textTheme.headlineSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _KcalDial(
                        target: plan.targetKcal,
                        bmr: plan.bmr,
                        tdee: plan.tdee,
                        colors: colors,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MacroRow(
                              label: 'Protein',
                              value: plan.proteinG,
                              unit: 'g',
                              color: colors.primary,
                            ),
                            const SizedBox(height: 8),
                            _MacroRow(
                              label: 'Karbonhidrat',
                              value: plan.carbsG,
                              unit: 'g',
                              color: colors.accent,
                            ),
                            const SizedBox(height: 8),
                            _MacroRow(
                              label: 'Yağ',
                              value: plan.fatG,
                              unit: 'g',
                              color: colors.warning,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, idx) => _MealCard(
                meal: plan.meals[idx],
                foods: foods,
                colors: colors,
                textTheme: textTheme,
              ),
              childCount: plan.meals.length,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Planı sil?'),
        content: const Text('Bu beslenme planı silinecek.'),
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
      await ref.read(nutritionRepositoryProvider).delete(plan.id);
      ref.invalidate(activeNutritionPlanProvider);
      if (context.mounted) context.go(AppRoute.home);
    } on ApiError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _KcalDial extends StatelessWidget {
  const _KcalDial({
    required this.target,
    required this.bmr,
    required this.tdee,
    required this.colors,
  });

  final int target;
  final int bmr;
  final int tdee;
  final FitTrackColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.accent, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$target',
              style: TextStyle(
                  color: colors.accent,
                  fontSize: 28,
                  fontWeight: FontWeight.w800)),
          Text('kcal / gün',
              style: TextStyle(color: colors.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text('TDEE $tdee',
              style: TextStyle(color: colors.textDim, fontSize: 10)),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final int value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(color: colors.textMuted, fontSize: 12))),
        Text('$value$unit',
            style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    required this.foods,
    required this.colors,
    required this.textTheme,
  });

  final Meal meal;
  final Map<String, FoodMeta> foods;
  final FitTrackColors colors;
  final TextTheme textTheme;

  IconData get _icon => switch (meal.key) {
        'breakfast' => Icons.wb_sunny_outlined,
        'snack1' => Icons.coffee_outlined,
        'lunch' => Icons.restaurant,
        'snack2' => Icons.local_cafe_outlined,
        'dinner' => Icons.nightlight_round,
        _ => Icons.restaurant_menu,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_icon, color: colors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.name,
                          style: textTheme.titleMedium?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${meal.kcal} kcal',
                          style: TextStyle(
                              color: colors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                ),
                _Pill(text: 'P ${meal.proteinG.round()}', color: colors.primary),
                const SizedBox(width: 4),
                _Pill(text: 'K ${meal.carbsG.round()}', color: colors.accent),
                const SizedBox(width: 4),
                _Pill(text: 'Y ${meal.fatG.round()}', color: colors.warning),
              ],
            ),
          ),
          Divider(color: colors.border, height: 1),
          ...meal.items.map((it) {
            final food = foods[it.foodId];
            final name = food?.nameTr ?? it.foodId;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('${it.grams} g · ${it.kcal} kcal',
                            style: TextStyle(
                                color: colors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(
                    'P${it.proteinG.toStringAsFixed(0)} · K${it.carbsG.toStringAsFixed(0)} · Y${it.fatG.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: colors.textDim,
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
