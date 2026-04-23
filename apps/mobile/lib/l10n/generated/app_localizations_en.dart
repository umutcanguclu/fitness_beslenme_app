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

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authSignInSubtitle =>
      'Welcome back. Let\'s pick up where you left off.';

  @override
  String get authSignUpTitle => 'Create account';

  @override
  String get authSignUpSubtitle => 'Start tracking your training today.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authNameLabel => 'Name';

  @override
  String get authSignInAction => 'Sign in';

  @override
  String get authSignUpAction => 'Create account';

  @override
  String get authNoAccountPrompt => 'No account yet?';

  @override
  String get authHaveAccountPrompt => 'Already have an account?';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authErrorInvalidEmail => 'Enter a valid email address.';

  @override
  String get authErrorPasswordTooShort =>
      'Password must be at least 8 characters.';

  @override
  String get authErrorNameRequired => 'Enter your name.';

  @override
  String get authErrorInvalidCredentials => 'Invalid email or password.';

  @override
  String get authErrorEmailTaken => 'This email is already registered.';

  @override
  String get authErrorNetwork => 'Network error. Please try again.';

  @override
  String get authErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get workoutStartAction => 'Start workout';

  @override
  String get workoutHistoryTitle => 'History';

  @override
  String get workoutHistoryEmpty =>
      'No past workouts yet. Tap below to start your first.';

  @override
  String get workoutActiveTitle => 'Active workout';

  @override
  String get workoutUntitled => 'Untitled workout';

  @override
  String get workoutInProgress => 'In progress';

  @override
  String get workoutFinish => 'Finish workout';

  @override
  String get workoutFinished => 'Finished';

  @override
  String get workoutAddSet => 'Add set';

  @override
  String get workoutNoSets => 'No sets logged yet.';

  @override
  String get workoutExerciseLabel => 'Exercise';

  @override
  String get workoutWeightLabel => 'Weight (kg)';

  @override
  String get workoutRepsLabel => 'Reps';

  @override
  String get workoutTimeLabel => 'Time (s)';

  @override
  String get workoutDistanceLabel => 'Distance (m)';

  @override
  String get workoutRpeLabel => 'RPE';

  @override
  String get workoutPickExercise => 'Pick an exercise';

  @override
  String get workoutSearchExercise => 'Search exercises';

  @override
  String get workoutErrorSetIncomplete =>
      'Record at least weight/reps, time, or distance.';

  @override
  String get workoutDeleteConfirm => 'Delete this workout?';

  @override
  String get workoutDeleteConfirmBody => 'This cannot be undone.';
}
