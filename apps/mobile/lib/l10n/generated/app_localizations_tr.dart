// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'FitTrack';

  @override
  String get appTagline => 'Çalış. Takip et. Aş.';

  @override
  String get actionSave => 'Kaydet';

  @override
  String get actionCancel => 'İptal';

  @override
  String get actionDelete => 'Sil';

  @override
  String get actionEdit => 'Düzenle';

  @override
  String get actionDone => 'Bitti';

  @override
  String get actionRetry => 'Tekrar dene';

  @override
  String get actionBack => 'Geri';

  @override
  String get commonLoading => 'Yükleniyor…';

  @override
  String get tabDashboard => 'Panel';

  @override
  String get tabWorkouts => 'Antrenmanlar';

  @override
  String get tabExercises => 'Egzersizler';

  @override
  String get tabProgress => 'İlerleme';

  @override
  String get tabProfile => 'Profil';

  @override
  String get dashboardWelcome => 'Tekrar hoş geldin';

  @override
  String get dashboardThisWeek => 'Bu hafta';

  @override
  String get dashboardNoData =>
      'Henüz kaydedilmiş antrenman yok. İlk seansına başla.';

  @override
  String get localeToggleLabel => 'Dil';
}
