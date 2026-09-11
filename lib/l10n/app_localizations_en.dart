import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// English implementation of AppLocalizations.
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn() : super(const Locale('en'));

  @override
  String get appTitle => 'Clock.Do';
  @override
  String get today => 'Today';
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get edit => 'Edit';
  @override
  String get delete => 'Delete';
  @override
  String get accept => 'Accept';
  @override
  String get close => 'Close';
  @override
  String get success => 'Success';
  @override
  String get error => 'Error';

  @override
  String get statusPending => 'Pending';
  @override
  String get statusInProgress => 'In progress';
  @override
  String get statusCompleted => 'Completed';

  @override
  String get cloudSyncTooltip => 'Sign In / Cloud';
  @override
  String accountTooltip(String email) => 'Account: $email';
  @override
  String pendingTodosTooltip(int count) => count == 1
      ? '1 pending task'
      : '$count pending tasks';
  @override
  String remindersActiveTooltip(int minutes) =>
      'Reminders: ${minutes == 0 ? "At start time" : "${minutes}m before"}';
  @override
  String get remindersAtStartTooltip => 'Reminders: At start time';
  @override
  String get remindersDisabledTooltip => 'Reminders disabled';
  @override
  String themeTooltip(String modeName) => 'Theme: $modeName';
  @override
  String get monthlyCalendarTooltip => 'Monthly Calendar';
  @override
  String get languageTooltip => 'Change Language';
  @override
  String get settingsTooltip => 'Settings';

  @override
  String get settingsTitle => 'Settings';
  @override
  String get settingsSubtitle => 'Customize theme, language & reminders';

  @override
  String get languageTitle => 'App Language';
  @override
  String get languageSubtitle => 'Choose your preferred language';
  @override
  String get languageSpanish => 'Español';
  @override
  String get languageSpanishDesc => 'Spanish (Castilian)';
  @override
  String get languageEnglish => 'English';
  @override
  String get languageEnglishDesc => 'English (US)';
  @override
  String get languageSystem => 'Follow System';
  @override
  String get languageSystemDesc => 'Match your device language automatically';

  @override
  String get themeTitle => 'App Theme';
  @override
  String get lightMode => 'Light Mode';
  @override
  String get lightModeDesc => 'Bright layout and pastel tones';
  @override
  String get darkMode => 'Dark Mode';
  @override
  String get darkModeDesc => 'Deep surfaces and vivid contrasts';
  @override
  String get systemMode => 'Follow System';
  @override
  String get systemModeDesc => 'Automatically adjusts to your device';

  @override
  String get dayToday => 'Today';
  @override
  String get noTasksDay => 'No time blocks';
  @override
  String get noTasksDaySubtitle => 'Tap the clock or press + to plan your day';

  @override
  String get magnifierMode => 'Magnifier Mode';
  @override
  String get hourFormat12 => '12H';
  @override
  String get hourFormat24 => '24H';

  @override
  String get categoryWork => 'Work';
  @override
  String get categoryPersonal => 'Personal';
  @override
  String get categoryHealth => 'Health';
  @override
  String get categoryStudy => 'Study';
  @override
  String get categoryLeisure => 'Leisure';
  @override
  String get categoryOther => 'Other';

  @override
  String get newCategoryTitle => 'New Category';
  @override
  String get editCategoryTitle => 'Edit Category';
  @override
  String get categoryNameLabel => 'Category name';
  @override
  String get categoryNameHint => 'E.g., Gym, Projects...';
  @override
  String get categoryNameRequired => 'Please enter a category name';
  @override
  String get categoryColorLabel => 'Distinctive color';
  @override
  String get categoryIconLabel => 'Representative icon';
  @override
  String get createCategoryButton => 'Create Category';
  @override
  String get saveCategoryButton => 'Save Changes';
  @override
  String get deleteCategoryConfirm => 'Do you want to delete this category? Associated tasks will be moved to Other.';

  @override
  String get newTaskTitle => 'New Time Block';
  @override
  String get editTaskTitle => 'Edit Time Block';
  @override
  String get taskTitleLabel => 'Block title';
  @override
  String get taskTitleHint => 'What are you working on?';
  @override
  String get taskTitleRequired => 'Please enter a title for the task';
  @override
  String get taskDescLabel => 'Notes or description (optional)';
  @override
  String get taskDescHint => 'Add details, links or subtasks...';
  @override
  String get startTimeLabel => 'Start Time';
  @override
  String get endTimeLabel => 'End Time';
  @override
  String get durationLabel => 'Duration';
  @override
  String get taskTypeLabel => 'Task Type';
  @override
  String get timeRangeOption => 'Time range';
  @override
  String get pointTaskOption => 'Point-in-time (no end)';
  @override
  String get pointTaskTimeLabel => 'Task Time';
  @override
  String get pointTaskBadge => 'Point Task';
  @override
  String get pointTaskHint => 'Marks a specific moment of the day without end time';
  @override
  String get categoryLabel => 'Category';
  @override
  String get newCategoryOption => '+ New Category';
  @override
  String get reminderLabel => 'Reminder Notification';
  @override
  String get reminderCustomTime => 'Custom';
  @override
  String get reminderDisabled => 'No notification';
  @override
  String get reminderGlobalDefault => 'Global default';
  @override
  String get deleteTaskConfirmTitle => 'Delete block?';
  @override
  String get deleteTaskConfirmMessage => 'This action cannot be undone.';
  @override
  String get invalidTimeRangeError => 'End time must be after start time';
  @override
  String get taskOverlapWarning => 'This block overlaps with another schedule';

  @override
  String get notificationsSettingsTitle => 'Notifications & Reminders';
  @override
  String get notificationsMasterToggle => 'Enable notifications';
  @override
  String get notificationsMasterToggleDesc => 'Receive sound and visual alerts before your planned tasks start.';
  @override
  String get defaultAdvanceTime => 'Default advance time';
  @override
  String get advanceAtEventTime => 'At event start';
  @override
  String advanceMinutesBefore(int minutes) => '$minutes min before';
  @override
  String get testNotificationButton => 'Send Test Notification';
  @override
  String get testNotificationSent => 'Test notification sent';

  @override
  String get todoListTitle => 'Pending Tasks (ToDo)';
  @override
  String get todoListSubtitle => 'Task backlog ready to be scheduled on your clock';
  @override
  String get newTodoHint => 'Write a new task...';
  @override
  String get addTodoButton => 'Add';
  @override
  String get pendingTab => 'Pending';
  @override
  String get completedTab => 'Completed';
  @override
  String get scheduleTask => 'Schedule on Clock';
  @override
  String get emptyTodoList => 'No pending tasks!';
  @override
  String get emptyCompletedList => 'No completed tasks yet';
  @override
  String get clearCompletedTodos => 'Clear completed';
  @override
  String get clearCompletedConfirm => 'Do you want to delete all completed tasks?';

  @override
  String get authTitle => 'Cloud Synchronization';
  @override
  String get authSubtitle => 'Connect your account to backup your tasks and access from any device.';
  @override
  String get emailLabel => 'Email address';
  @override
  String get emailHint => 'example@mail.com';
  @override
  String get passwordLabel => 'Password';
  @override
  String get passwordHint => 'At least 6 characters';
  @override
  String get signInButton => 'Sign In';
  @override
  String get signUpButton => 'Create Account';
  @override
  String get signOutButton => 'Sign Out';
  @override
  String get syncNowButton => 'Sync Now';
  @override
  String get syncingStatus => 'Syncing...';
  @override
  String get syncedStatus => 'Data synchronized';
  @override
  String get authSuccessMessage => 'Signed in successfully';
  @override
  String get invalidCredentialsError => 'Authentication error: check your credentials';
  @override
  String get forgotPasswordTitle => 'Reset Password';
  @override
  String get forgotPasswordSubtitle => 'Enter your email address to receive an OTP code and instructions to reset your password.';
  @override
  String get sendRecoveryEmailButton => 'Send Recovery Code';
  @override
  String get resetPasswordTitle => 'Set New Password';
  @override
  String get resetPasswordSubtitle => 'Enter the 8-digit OTP code sent to your email and set your new password.';
  @override
  String get otpCodeLabel => 'OTP Code (8 digits)';
  @override
  String get otpCodeHint => 'e.g. 12345678';
  @override
  String get newPasswordLabel => 'New Password';
  @override
  String get newPasswordHint => 'At least 6 characters';
  @override
  String get confirmNewPasswordLabel => 'Confirm New Password';
  @override
  String get passwordsDoNotMatch => 'Passwords do not match';
  @override
  String get resetPasswordButton => 'Reset Password';
  @override
  String get passwordResetSuccess => 'Password updated successfully!';
  @override
  String get changePasswordButton => 'Change Password';
  @override
  String get changePasswordTitle => 'Update Password';
  @override
  String get alreadyHaveOtp => 'Already have a code? Enter it here';
  @override
  String get backToSignIn => 'Back to Sign In';
  @override
  String get resendOtp => "Didn't receive the code? Resend";
  @override
  String get recoveryEmailSent => 'Code sent to your email. Please check your inbox.';

  @override
  String get viewOnboardingOption => 'View Welcome Guide';
  @override
  String get onboardingSkip => 'Skip';
  @override
  String get onboardingNext => 'Next';
  @override
  String get onboardingGetStarted => 'Get Started! 🚀';

  @override
  String get onboardingStep1Badge => '⏱️ RADIAL INNOVATION';
  @override
  String get onboardingStep1Title => 'Your Time in a New Dimension';
  @override
  String get onboardingStep1Desc => 'Say goodbye to boring linear lists. Visualize and master your entire day on a gorgeous interactive circular clock.';

  @override
  String get onboardingStep2Badge => '🎯 TOTAL FOCUS';
  @override
  String get onboardingStep2Title => 'Plan Instantly with a Touch';
  @override
  String get onboardingStep2Desc => 'Drag on the dial to schedule tasks or keep pending items in the backlog ready to be placed on your clock.';

  @override
  String get onboardingStep3Badge => '🔔 SYNCED & SECURE';
  @override
  String get onboardingStep3Title => 'Absolute Punctuality & Cloud Backup';
  @override
  String get onboardingStep3Desc => 'Smart reminders with custom advance alerts and seamless cloud backup so you never miss a beat.';

  @override
  String get onboardingStep4Badge => '✨ ALL SET';
  @override
  String get onboardingStep4Title => 'Welcome to Clock.Do';
  @override
  String get onboardingStep4Desc => 'Your day organized, your goals reached, and your time under total control. Let\'s get started!';

  // ── Gamification & Time Mastery (EN) ──
  @override
  String get gamificationTitle => 'Time Mastery';
  @override
  String get gamificationSubtitle => 'Your progress, streaks & productivity achievements';
  @override
  String get ticksLabel => 'Ticks';
  @override
  String get currentStreakLabel => 'Current Streak';
  @override
  String get bestStreakLabel => 'Best Streak';
  @override
  String get daysUnit => 'days';
  @override
  String get dayUnit => 'day';
  @override
  String get streakFreezeLabel => 'Streak Freezes';
  @override
  String get streakFreezeDesc => 'Automatically protect your streak if you take a rest day';
  @override
  String get levelLabel => 'Level';
  @override
  String get levelProgressLabel => 'Level Progress';
  @override
  String get nextLevelLabel => 'Next Level';
  @override
  String get maxLevelReached => 'Maximum Mastery Level Reached!';
  @override
  String get achievementsSectionTitle => 'Achievement Badges';
  @override
  String unlockedBadgeCount(int unlocked, int total) => '$unlocked of $total unlocked';
  @override
  String get statsSectionTitle => 'Global Statistics';
  @override
  String get tasksCompletedStat => 'Blocks Completed';
  @override
  String get focusMinutesStat => 'Focus Minutes';
  @override
  String get goldenDialTodayTitle => 'Golden Dial';
  @override
  String get goldenDialTodayActive => 'Golden Dial achieved today! 🎉';
  @override
  String goldenDialTodayProgress(int completed, int total, int percent) => '$completed of $total blocks ($percent%)';
  @override
  String get streakFreezeUsedToast => '🛡️ Streak Freeze used! Your streak was protected.';
  @override
  String levelUpCelebration(String levelName) => 'Level Up! You are now $levelName';
  @override
  String badgeUnlockedCelebration(String badgeName) => 'New badge unlocked: $badgeName!';
  @override
  String badgeUnlockedAt(String dateStr) => 'Unlocked on $dateStr';
  @override
  String get badgeLocked => 'Locked';
  @override
  String get claimReward => 'Claim!';
  @override
  String get awesomeButton => 'Awesome!';

  // Levels
  @override
  String get level1Title => 'Apprentice Watchmaker';
  @override
  String get level2Title => 'Gear Craftsman';
  @override
  String get level3Title => 'Quartz Tuner';
  @override
  String get level4Title => 'Pendulum Guardian';
  @override
  String get level5Title => 'Chrononaut';
  @override
  String get level6Title => 'Grand Time Master';

  // Badges
  @override
  String get badgeFirstStepTitle => 'First Step';
  @override
  String get badgeFirstStepDesc => 'Complete your first time block on the clock';
  @override
  String get badgeEarlyBirdTitle => 'Early Bird';
  @override
  String get badgeEarlyBirdDesc => 'Complete a block before 8:00 AM';
  @override
  String get badgeNightOwlTitle => 'Night Owl';
  @override
  String get badgeNightOwlDesc => 'Complete a block after 9:00 PM';
  @override
  String get badgeTaskMaster10Title => 'Steady Focus';
  @override
  String get badgeTaskMaster10Desc => 'Complete 10 time blocks on the clock';
  @override
  String get badgeTaskMaster50Title => 'Routine Master';
  @override
  String get badgeTaskMaster50Desc => 'Complete 50 time blocks';
  @override
  String get badgeStreak3Title => 'Initial Spark';
  @override
  String get badgeStreak3Desc => 'Maintain a 3-day streak';
  @override
  String get badgeStreak7Title => 'Steel Habit';
  @override
  String get badgeStreak7Desc => 'Reach a 7-day streak';
  @override
  String get badgeGoldenDialTitle => 'Golden Dial';
  @override
  String get badgeGoldenDialDesc => 'Complete 80% or more of your day\'s tasks (min. 3 blocks)';
  @override
  String get badgeCleanSlateTitle => 'Clean Slate';
  @override
  String get badgeCleanSlateDesc => 'Complete 5 pending tasks from the ToDo Backlog';
  @override
  String get badgeBalancedLifeTitle => 'Balanced Life';
  @override
  String get badgeBalancedLifeDesc => 'Complete blocks from at least 3 different categories in a day';

  // ── Device Calendars ──
  @override
  String get deviceCalendarSettingsTitle => 'Device Calendars';
  @override
  String get deviceCalendarSettingsSubtitle => 'Sync events from Google, iCloud, and Outlook';
  @override
  String get deviceCalendarSyncToggle => 'Sync device events';
  @override
  String get deviceCalendarSyncDesc => 'Automatically display your external events on Clock.Do\'s radial dial.';
  @override
  String get deviceCalendarPermissionsRequired => 'Calendar access permissions are required to sync your events.';
  @override
  String get deviceCalendarGrantPermission => 'Grant Permissions';
  @override
  String get deviceCalendarNoCalendarsFound => 'No calendars found on this device.';
  @override
  String get deviceCalendarSelectCalendars => 'Select calendars to include';
  @override
  String get deviceCalendarSyncNow => 'Sync Now';
  @override
  String deviceCalendarSyncedCount(int count) => count == 1 ? '1 event synced' : '$count events synced';
  @override
  String get deviceCalendarBadge => 'Calendar';
  @override
  String get deviceCalendarStatusEnabled => 'Sync enabled';
  @override
  String get deviceCalendarStatusDisabled => 'Disabled';
  @override
  String deviceCalendarLinkedCount(int count) => count == 1 ? '1 calendar linked' : '$count calendars linked';
  @override
  String get deviceCalendarPermissionRequired => 'Calendar Permission Required';
  @override
  String get deviceCalendarPermissionHint => 'Clock.Do needs access to your calendars to display your events. Tap the button to grant access.';
  @override
  String get deviceCalendarPermissionPermanentlyDenied => 'Calendar Access Blocked';
  @override
  String get deviceCalendarOpenSettingsHint => 'You have permanently denied calendar access. Go to System Settings › Privacy › Calendars to enable it.';
  @override
  String get deviceCalendarOpenSettings => 'Open Settings';
  @override
  String get deviceCalendarGoToSettings => 'Go to System Settings › Apps › Clock.Do › Permissions › Calendar';
}

