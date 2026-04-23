import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/preferences.dart';

const supportedLocales = <Locale>[
  Locale('en'),
  Locale('tr'),
];

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final prefsAsync = ref.watch(sharedPreferencesProvider);
    final prefs = prefsAsync.valueOrNull;
    final stored = prefs?.getString(PreferenceKeys.locale);
    if (stored != null && _isSupported(stored)) {
      return Locale(stored);
    }
    return _deviceLocale();
  }

  Future<void> set(Locale locale) async {
    if (!_isSupportedLocale(locale)) return;
    state = locale;
    final SharedPreferences prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(PreferenceKeys.locale, locale.languageCode);
  }

  Future<void> toggle() async {
    final next = state.languageCode == 'tr' ? const Locale('en') : const Locale('tr');
    await set(next);
  }

  static Locale _deviceLocale() {
    final device = PlatformDispatcher.instance.locale;
    return _isSupportedLocale(device) ? Locale(device.languageCode) : const Locale('en');
  }

  static bool _isSupportedLocale(Locale locale) =>
      _isSupported(locale.languageCode);

  static bool _isSupported(String code) =>
      supportedLocales.any((l) => l.languageCode == code);
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);
