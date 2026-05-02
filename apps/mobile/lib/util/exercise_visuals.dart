import 'package:flutter/material.dart';

// Maps a training/exercise category to an icon + accent color.
// Used as a placeholder visual when backend doesn't provide an image/gif.

class CategoryVisual {
  final IconData icon;
  final Color color;
  const CategoryVisual(this.icon, this.color);
}

const _visuals = <String, CategoryVisual>{
  'endurance': CategoryVisual(Icons.directions_run, Color(0xFF1976D2)),
  'sprint_agility': CategoryVisual(Icons.flash_on, Color(0xFFFF9800)),
  'strength': CategoryVisual(Icons.fitness_center, Color(0xFFD32F2F)),
  'plyometric': CategoryVisual(Icons.bolt, Color(0xFFE91E63)),
  'technical': CategoryVisual(Icons.sports_soccer, Color(0xFF388E3C)),
  'tactical': CategoryVisual(Icons.lightbulb, Color(0xFF7B1FA2)),
  'goalkeeper_specific': CategoryVisual(Icons.sports_handball, Color(0xFF00838F)),
  'recovery': CategoryVisual(Icons.spa, Color(0xFF558B2F)),
  'warmup': CategoryVisual(Icons.local_fire_department, Color(0xFFEF6C00)),
  'cooldown': CategoryVisual(Icons.ac_unit, Color(0xFF0277BD)),
  'small_sided_game': CategoryVisual(Icons.sports, Color(0xFF2E7D32)),
  'set_piece': CategoryVisual(Icons.flag, Color(0xFF6A1B9A)),
};

CategoryVisual visualForCategory(String code) =>
    _visuals[code] ?? const CategoryVisual(Icons.sports_soccer, Color(0xFF607D8B));

Color intensityColor(int intensity) {
  switch (intensity) {
    case 1:
      return const Color(0xFF2E7D32);
    case 2:
      return const Color(0xFF7CB342);
    case 3:
      return const Color(0xFFFFB300);
    case 4:
      return const Color(0xFFEF6C00);
    case 5:
      return const Color(0xFFD32F2F);
  }
  return const Color(0xFF9E9E9E);
}
