/**
 * Placeholder for pulling Turkish recipes from an open dataset.
 *
 * Known candidates we still need to evaluate:
 *   - HuggingFace:  `mertbozkurt/Turkish_recipes` (needs license check)
 *   - Kaggle:       various Turkish recipes CSVs (license per-dataset)
 *   - TheMealDB:    public JSON API, only ~25 Turkish entries
 *
 * Scraping sites like yemek.com / nefis-yemek-tarifleri is a ToS violation
 * and intentionally not implemented here.
 *
 * Run with: pnpm --filter @fittrack/recipe-db sync
 */
console.log(
  'recipe-db sync: no open dataset wired up yet — see scripts/fetch-open.ts header.',
);
