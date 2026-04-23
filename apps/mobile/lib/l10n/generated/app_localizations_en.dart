// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FitTrack';

  @override
  String get appTagline => 'Train. Track. Transcend.';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDone => 'Done';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionBack => 'Back';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabWorkouts => 'Workouts';

  @override
  String get tabExercises => 'Exercises';

  @override
  String get tabProgress => 'Progress';

  @override
  String get tabProfile => 'Profile';

  @override
  String get dashboardWelcome => 'Welcome back';

  @override
  String get dashboardThisWeek => 'This week';

  @override
  String get dashboardNoData =>
      'No workouts logged yet. Start your first session.';

  @override
  String get localeToggleLabel => 'Language';
}
