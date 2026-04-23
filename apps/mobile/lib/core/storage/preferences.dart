import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceKeys {
  const PreferenceKeys._();
  static const locale = 'settings.locale';
  static const themeMode = 'settings.themeMode';
}

/// Prefer reading through this provider so mock overrides in tests remain easy.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});
