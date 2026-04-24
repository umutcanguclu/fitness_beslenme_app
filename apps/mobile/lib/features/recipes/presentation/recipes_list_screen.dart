import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/locale_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/fittrack_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/recipe.dart';

class RecipesListScreen extends ConsumerStatefulWidget {
  const RecipesListScreen({super.key});

  @override
  ConsumerState<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends ConsumerState<RecipesListScreen> {
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final catalog = ref.watch(recipeCatalogProvider);
    final lang = ref.watch(localeControllerProvider).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(strings.recipesTitle)),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (all) {
          final q = _query.trim().toLowerCase();
          final filtered = all.where((r) {
            if (_category != null && r.category != _category) return false;
            if (q.isEmpty) return true;
            final name = r.nameFor(lang).toLowerCase();
            final tags = r.tags.join(' ').toLowerCase();
            final ingredients = r.ingredients
                .map((i) => i.name.toLowerCase())
                .join(' ');
            return name.contains(q) ||
                tags.contains(q) ||
                ingredients.contains(q);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: strings.recipesSearch,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _CategoryChip(
                      label: strings.recipesCategoryAll,
                      selected: _category == null,
                      onTap: () => setState(() => _category = null),
                    ),
                    for (final entry in recipeCategoryLabels.entries)
                      _CategoryChip(
                        label: recipeCategoryLabel(entry.key, lang),
                        selected: _category == entry.key,
                        onTap: () => setState(() => _category = entry.key),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          strings.recipesEmpty,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) => _RecipeTile(
                          recipe: filtered[index],
                          language: lang,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: colors.primary.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: selected ? colors.primary : colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: selected ? colors.primary : colors.border),
        backgroundColor: colors.surface,
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.recipe, required this.language});

  final Recipe recipe;
  final String language;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.go('${AppRoute.recipesBase}/${recipe.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.nameFor(language),
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: colors.textDim),
                      const SizedBox(width: 4),
                      Text('${recipe.totalMinutes} dk',
                          style:
                              TextStyle(color: colors.textMuted, fontSize: 12)),
                      const SizedBox(width: 12),
                      Icon(Icons.restaurant_menu,
                          size: 14, color: colors.textDim),
                      const SizedBox(width: 4),
                      Text(
                        recipeCategoryLabel(recipe.category, language),
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (recipe.nutrition?.kcal != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${recipe.nutrition!.kcal} kcal',
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
