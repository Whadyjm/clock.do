import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_localizations_es.dart';
import 'app_localizations_en.dart';

/// Clase abstracta base que define todas las cadenas localizadas para Clock.Do.
abstract class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizationsEs();
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('es'),
    Locale('en'),
  ];

  // ── General y Navegación ──
  String get appTitle;
  String get today;
  String get cancel;
  String get save;
  String get edit;
  String get delete;
  String get accept;
  String get close;
  String get success;
  String get error;

  // ── Estados de Tarea ──
  String get statusPending;
  String get statusInProgress;
  String get statusCompleted;

  // ── Header y Barra Superior ──
  String get cloudSyncTooltip;
  String accountTooltip(String email);
  String pendingTodosTooltip(int count);
  String remindersActiveTooltip(int minutes);
  String get remindersAtStartTooltip;
  String get remindersDisabledTooltip;
  String themeTooltip(String modeName);
  String get monthlyCalendarTooltip;
  String get languageTooltip;
  String get settingsTooltip;

  // ── Ajustes / Settings ──
  String get settingsTitle;
  String get settingsSubtitle;
  String get viewOnboardingOption;

  // ── Onboarding ──
  String get onboardingSkip;
  String get onboardingNext;
  String get onboardingGetStarted;
  String get onboardingStep1Badge;
  String get onboardingStep1Title;
  String get onboardingStep1Desc;
  String get onboardingStep2Badge;
  String get onboardingStep2Title;
  String get onboardingStep2Desc;
  String get onboardingStep3Badge;
  String get onboardingStep3Title;
  String get onboardingStep3Desc;
  String get onboardingStep4Badge;
  String get onboardingStep4Title;
  String get onboardingStep4Desc;

  // ── Selector de Idioma ──
  String get languageTitle;
  String get languageSubtitle;
  String get languageSpanish;
  String get languageSpanishDesc;
  String get languageEnglish;
  String get languageEnglishDesc;
  String get languageSystem;
  String get languageSystemDesc;

  // ── Selector de Tema ──
  String get themeTitle;
  String get lightMode;
  String get lightModeDesc;
  String get darkMode;
  String get darkModeDesc;
  String get systemMode;
  String get systemModeDesc;

  // ── Tira Semanal y Fechas ──
  String get dayToday;
  String get noTasksDay;
  String get noTasksDaySubtitle;

  // ── Reloj Radial ──
  String get magnifierMode;
  String get hourFormat12;
  String get hourFormat24;

  // ── Categorías Predeterminadas ──
  String get categoryWork;
  String get categoryPersonal;
  String get categoryHealth;
  String get categoryStudy;
  String get categoryLeisure;
  String get categoryOther;

  // ── Diálogo de Categorías ──
  String get newCategoryTitle;
  String get editCategoryTitle;
  String get categoryNameLabel;
  String get categoryNameHint;
  String get categoryNameRequired;
  String get categoryColorLabel;
  String get categoryIconLabel;
  String get createCategoryButton;
  String get saveCategoryButton;
  String get deleteCategoryConfirm;

  // ── Formulario de Tarea (Bloque de Tiempo) ──
  String get newTaskTitle;
  String get editTaskTitle;
  String get taskTitleLabel;
  String get taskTitleHint;
  String get taskTitleRequired;
  String get taskDescLabel;
  String get taskDescHint;
  String get startTimeLabel;
  String get endTimeLabel;
  String get durationLabel;
  String get categoryLabel;
  String get newCategoryOption;
  String get reminderLabel;
  String get reminderCustomTime;
  String get reminderDisabled;
  String get reminderGlobalDefault;
  String get deleteTaskConfirmTitle;
  String get deleteTaskConfirmMessage;
  String get invalidTimeRangeError;
  String get taskOverlapWarning;

  // ── Notificaciones y Recordatorios ──
  String get notificationsSettingsTitle;
  String get notificationsMasterToggle;
  String get notificationsMasterToggleDesc;
  String get defaultAdvanceTime;
  String get advanceAtEventTime;
  String advanceMinutesBefore(int minutes);
  String get testNotificationButton;
  String get testNotificationSent;

  // ── Lista ToDo (Backlog) ──
  String get todoListTitle;
  String get todoListSubtitle;
  String get newTodoHint;
  String get addTodoButton;
  String get pendingTab;
  String get completedTab;
  String get scheduleTask;
  String get emptyTodoList;
  String get emptyCompletedList;
  String get clearCompletedTodos;
  String get clearCompletedConfirm;

  // ── Autenticación y Nube Supabase ──
  String get authTitle;
  String get authSubtitle;
  String get emailLabel;
  String get emailHint;
  String get passwordLabel;
  String get passwordHint;
  String get signInButton;
  String get signUpButton;
  String get signOutButton;
  String get syncNowButton;
  String get syncingStatus;
  String get syncedStatus;
  String get authSuccessMessage;
  String get invalidCredentialsError;

  // ── Gamificación & Maestría del Tiempo ──
  String get gamificationTitle;
  String get gamificationSubtitle;
  String get ticksLabel;
  String get currentStreakLabel;
  String get bestStreakLabel;
  String get daysUnit;
  String get dayUnit;
  String get streakFreezeLabel;
  String get streakFreezeDesc;
  String get levelLabel;
  String get levelProgressLabel;
  String get nextLevelLabel;
  String get maxLevelReached;
  String get achievementsSectionTitle;
  String unlockedBadgeCount(int unlocked, int total);
  String get statsSectionTitle;
  String get tasksCompletedStat;
  String get focusMinutesStat;
  String get goldenDialTodayTitle;
  String get goldenDialTodayActive;
  String goldenDialTodayProgress(int completed, int total, int percent);
  String get streakFreezeUsedToast;
  String levelUpCelebration(String levelName);
  String badgeUnlockedCelebration(String badgeName);
  String badgeUnlockedAt(String dateStr);
  String get badgeLocked;
  String get claimReward;
  String get awesomeButton;

  // Niveles
  String get level1Title;
  String get level2Title;
  String get level3Title;
  String get level4Title;
  String get level5Title;
  String get level6Title;

  // Logros
  String get badgeFirstStepTitle;
  String get badgeFirstStepDesc;
  String get badgeEarlyBirdTitle;
  String get badgeEarlyBirdDesc;
  String get badgeNightOwlTitle;
  String get badgeNightOwlDesc;
  String get badgeTaskMaster10Title;
  String get badgeTaskMaster10Desc;
  String get badgeTaskMaster50Title;
  String get badgeTaskMaster50Desc;
  String get badgeStreak3Title;
  String get badgeStreak3Desc;
  String get badgeStreak7Title;
  String get badgeStreak7Desc;
  String get badgeGoldenDialTitle;
  String get badgeGoldenDialDesc;
  String get badgeCleanSlateTitle;
  String get badgeCleanSlateDesc;
  String get badgeBalancedLifeTitle;
  String get badgeBalancedLifeDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['es', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return SynchronousFuture<AppLocalizations>(AppLocalizationsEn());
      case 'es':
      default:
        return SynchronousFuture<AppLocalizations>(AppLocalizationsEs());
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
