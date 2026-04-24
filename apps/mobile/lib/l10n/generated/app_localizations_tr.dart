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

  @override
  String get authSignInTitle => 'Giriş yap';

  @override
  String get authSignInSubtitle =>
      'Tekrar hoş geldin. Kaldığın yerden devam edelim.';

  @override
  String get authSignUpTitle => 'Hesap oluştur';

  @override
  String get authSignUpSubtitle =>
      'Antrenmanlarını bugünden takip etmeye başla.';

  @override
  String get authEmailLabel => 'E-posta';

  @override
  String get authPasswordLabel => 'Şifre';

  @override
  String get authNameLabel => 'Ad';

  @override
  String get authSignInAction => 'Giriş yap';

  @override
  String get authSignUpAction => 'Hesap oluştur';

  @override
  String get authNoAccountPrompt => 'Henüz hesabın yok mu?';

  @override
  String get authHaveAccountPrompt => 'Zaten hesabın var mı?';

  @override
  String get authSignOut => 'Çıkış yap';

  @override
  String get authErrorInvalidEmail => 'Geçerli bir e-posta adresi gir.';

  @override
  String get authErrorPasswordTooShort => 'Şifre en az 8 karakter olmalı.';

  @override
  String get authErrorNameRequired => 'Adını gir.';

  @override
  String get authErrorInvalidCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get authErrorEmailTaken => 'Bu e-posta zaten kayıtlı.';

  @override
  String get authErrorNetwork => 'Ağ hatası. Lütfen tekrar dene.';

  @override
  String get authErrorGeneric => 'Bir şeyler ters gitti. Lütfen tekrar dene.';

  @override
  String get workoutStartAction => 'Antrenman başlat';

  @override
  String get workoutHistoryTitle => 'Geçmiş';

  @override
  String get workoutHistoryEmpty => 'Henüz antrenman yok. İlk seansını başlat.';

  @override
  String get workoutActiveTitle => 'Aktif antrenman';

  @override
  String get workoutUntitled => 'İsimsiz antrenman';

  @override
  String get workoutInProgress => 'Devam ediyor';

  @override
  String get workoutFinish => 'Antrenmanı bitir';

  @override
  String get workoutFinished => 'Tamamlandı';

  @override
  String get workoutAddSet => 'Set ekle';

  @override
  String get workoutNoSets => 'Henüz set kaydı yok.';

  @override
  String get workoutExerciseLabel => 'Egzersiz';

  @override
  String get workoutWeightLabel => 'Ağırlık (kg)';

  @override
  String get workoutRepsLabel => 'Tekrar';

  @override
  String get workoutTimeLabel => 'Süre (sn)';

  @override
  String get workoutDistanceLabel => 'Mesafe (m)';

  @override
  String get workoutRpeLabel => 'RPE';

  @override
  String get workoutPickExercise => 'Egzersiz seç';

  @override
  String get workoutSearchExercise => 'Egzersiz ara';

  @override
  String get workoutErrorSetIncomplete =>
      'En az ağırlık/tekrar, süre veya mesafe gir.';

  @override
  String get workoutDeleteConfirm => 'Bu antrenmanı silmek istiyor musun?';

  @override
  String get workoutDeleteConfirmBody => 'Bu işlem geri alınamaz.';

  @override
  String get recipesTitle => 'Tarifler';

  @override
  String get recipesSearch => 'Ad, etiket veya malzeme ile ara';

  @override
  String get recipesCategoryAll => 'Tümü';

  @override
  String get recipesEmpty => 'Filtrelerle eşleşen tarif yok.';

  @override
  String get recipesNotFound => 'Tarif bulunamadı.';

  @override
  String get recipesTime => 'süre';

  @override
  String get recipesServings => 'porsiyon';

  @override
  String get recipesDifficulty => 'zorluk';

  @override
  String get recipesDifficultyEasy => 'kolay';

  @override
  String get recipesDifficultyMedium => 'orta';

  @override
  String get recipesDifficultyHard => 'zor';

  @override
  String get recipesIngredients => 'Malzemeler';

  @override
  String get recipesSteps => 'Yapılışı';

  @override
  String get recipesProtein => 'protein';

  @override
  String get recipesCarbs => 'karb.';

  @override
  String get recipesFat => 'yağ';

  @override
  String get tabRecipes => 'Tarifler';
}
