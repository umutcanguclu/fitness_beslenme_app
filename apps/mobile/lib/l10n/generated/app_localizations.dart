import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'FitTrack'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Train. Track. Transcend.'**
  String get appTagline;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @tabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// No description provided for @tabWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get tabWorkouts;

  /// No description provided for @tabExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get tabExercises;

  /// No description provided for @tabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get tabProgress;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @dashboardWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get dashboardWelcome;

  /// No description provided for @dashboardThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get dashboardThisWeek;

  /// No description provided for @dashboardNoData.
  ///
  /// In en, this message translates to:
  /// **'No workouts logged yet. Start your first session.'**
  String get dashboardNoData;

  /// No description provided for @localeToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get localeToggleLabel;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInTitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back. Let\'s pick up where you left off.'**
  String get authSignInSubtitle;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUpTitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your training today.'**
  String get authSignUpSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authNameLabel;

  /// No description provided for @authSignInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInAction;

  /// No description provided for @authSignUpAction.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUpAction;

  /// No description provided for @authNoAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'No account yet?'**
  String get authNoAccountPrompt;

  /// No description provided for @authHaveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccountPrompt;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get authErrorPasswordTooShort;

  /// No description provided for @authErrorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get authErrorNameRequired;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get authErrorEmailTaken;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @workoutStartAction.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get workoutStartAction;

  /// No description provided for @workoutHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get workoutHistoryTitle;

  /// No description provided for @workoutHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No past workouts yet. Tap below to start your first.'**
  String get workoutHistoryEmpty;

  /// No description provided for @workoutActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Active workout'**
  String get workoutActiveTitle;

  /// No description provided for @workoutUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled workout'**
  String get workoutUntitled;

  /// No description provided for @workoutInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get workoutInProgress;

  /// No description provided for @workoutFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish workout'**
  String get workoutFinish;

  /// No description provided for @workoutFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get workoutFinished;

  /// No description provided for @workoutAddSet.
  ///
  /// In en, this message translates to:
  /// **'Add set'**
  String get workoutAddSet;

  /// No description provided for @workoutNoSets.
  ///
  /// In en, this message translates to:
  /// **'No sets logged yet.'**
  String get workoutNoSets;

  /// No description provided for @workoutExerciseLabel.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get workoutExerciseLabel;

  /// No description provided for @workoutWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get workoutWeightLabel;

  /// No description provided for @workoutRepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get workoutRepsLabel;

  /// No description provided for @workoutTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time (s)'**
  String get workoutTimeLabel;

  /// No description provided for @workoutDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance (m)'**
  String get workoutDistanceLabel;

  /// No description provided for @workoutRpeLabel.
  ///
  /// In en, this message translates to:
  /// **'RPE'**
  String get workoutRpeLabel;

  /// No description provided for @workoutPickExercise.
  ///
  /// In en, this message translates to:
  /// **'Pick an exercise'**
  String get workoutPickExercise;

  /// No description provided for @workoutSearchExercise.
  ///
  /// In en, this message translates to:
  /// **'Search exercises'**
  String get workoutSearchExercise;

  /// No description provided for @workoutErrorSetIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Record at least weight/reps, time, or distance.'**
  String get workoutErrorSetIncomplete;

  /// No description provided for @workoutDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this workout?'**
  String get workoutDeleteConfirm;

  /// No description provided for @workoutDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get workoutDeleteConfirmBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
