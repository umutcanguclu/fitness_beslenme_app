import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/locale_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/fittrack_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/recipe.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final catalog = ref.watch(recipeCatalogProvider);
    final lang = ref.watch(localeControllerProvider).languageCode;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoute.recipesBase),
        ),
        title: Text(strings.recipesTitle),
      ),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (all) {
          final recipe = all.where((r) => r.id == recipeId).firstOrNull;
          if (recipe == null) {
            return Center(
              child: Text(strings.recipesNotFound,
                  style: TextStyle(color: colors.textMuted)),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                recipe.nameFor(lang),
                style: textTheme.headlineSmall
                    ?.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                recipeCategoryLabel(recipe.category, lang),
                style: textTheme.bodySmall?.copyWith(color: colors.accent),
              ),
              const SizedBox(height: 16),
              _MetaRow(recipe: recipe, strings: strings),
              const SizedBox(height: 16),
              if (recipe.nutrition != null)
                _NutritionRow(nutrition: recipe.nutrition!, strings: strings),
              const SizedBox(height: 16),
              Text(strings.recipesIngredients,
                  style: textTheme.titleMedium
                      ?.copyWith(color: colors.textPrimary)),
              const SizedBox(height: 8),
              ...recipe.ingredients.map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.fiber_manual_record,
                            size: 8, color: colors.textMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: colors.textPrimary),
                              children: [
                                TextSpan(
                                  text: i.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                TextSpan(
                                  text: '  ·  ${i.amount}',
                                  style: TextStyle(color: colors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 24),
              Text(strings.recipesSteps,
                  style: textTheme.titleMedium
                      ?.copyWith(color: colors.textPrimary)),
              const SizedBox(height: 8),
              ...recipe.steps.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              colors.primary.withValues(alpha: 0.15),
                          child: Text(
                            '${e.key + 1}',
                            style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e.value,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.recipe, required this.strings});

  final Recipe recipe;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    Widget chip(IconData icon, String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(icon, size: 18, color: colors.accent),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600)),
                Text(label,
                    style: TextStyle(color: colors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        chip(Icons.timer_outlined, '${recipe.totalMinutes} dk', strings.recipesTime),
        const SizedBox(width: 8),
        chip(Icons.people_outline, '${recipe.servings}', strings.recipesServings),
        const SizedBox(width: 8),
        chip(Icons.signal_cellular_alt,
            _difficultyLabel(recipe.difficulty, strings),
            strings.recipesDifficulty),
      ],
    );
  }
}

String _difficultyLabel(String key, AppLocalizations strings) {
  return switch (key) {
    'easy' => strings.recipesDifficultyEasy,
    'medium' => strings.recipesDifficultyMedium,
    'hard' => strings.recipesDifficultyHard,
    _ => key,
  };
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({required this.nutrition, required this.strings});

  final RecipeNutrition nutrition;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    Widget cell(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              Text(label,
                  style: TextStyle(color: colors.textMuted, fontSize: 11)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          cell('${nutrition.kcal ?? '-'}', 'kcal'),
          cell('${nutrition.proteinG?.toStringAsFixed(0) ?? '-'}g',
              strings.recipesProtein),
          cell('${nutrition.carbsG?.toStringAsFixed(0) ?? '-'}g',
              strings.recipesCarbs),
          cell('${nutrition.fatG?.toStringAsFixed(0) ?? '-'}g',
              strings.recipesFat),
        ],
      ),
    );
  }
}
