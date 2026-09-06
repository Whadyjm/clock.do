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
}
