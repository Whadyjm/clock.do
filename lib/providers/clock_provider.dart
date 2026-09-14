import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_block.dart';
import '../models/task_category.dart';
import '../models/todo_item.dart';
import '../models/gamification_data.dart';
import '../models/sync_action.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../services/device_calendar_service.dart';
import '../services/local_database_service.dart';
import '../services/connectivity_service.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/pomodoro_state.dart';

const _kStorageKey = 'clockdo_tasks';
const _kTodoStorageKey = 'clockdo_todos';
const _kThemeStorageKey = 'clockdo_theme_mode';
const _kReminderMinutesKey = 'clockdo_reminder_minutes';
const _kNotifEnabledKey = 'clockdo_notif_enabled';
const _kCategoriesStorageKey = 'clockdo_custom_categories';
const _kLocaleStorageKey = 'clockdo_locale';
const _kGamificationStorageKey = 'clockdo_gamification';
const _kDeviceCalSyncEnabledKey = 'clockdo_device_cal_sync_enabled';
const _kSelectedDeviceCalIdsKey = 'clockdo_selected_device_cal_ids';
const _kLastUserIdKey = 'clockdo_last_user_id';
const _kViewModeStorageKey = 'clockdo_view_mode';
const _kPomodoroSettingsKey = 'clockdo_pomodoro_settings';
const _kPomodoroStateKey = 'clockdo_pomodoro_state';

/// Modos de visualización principal de la aplicación.
enum AppViewMode {
  clock,
  kanban,
  pomodoro;

  String getLocalizedName(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case AppViewMode.clock:
        return l10n.clockView;
      case AppViewMode.kanban:
        return l10n.kanbanView;
      case AppViewMode.pomodoro:
        return l10n.pomodoroView;
    }
  }
}

/// Estado global de la aplicación ClockDo con soporte de recordatorios globales, temas, calendario, tareas ToDo y sincronización Supabase.
class ClockProvider extends ChangeNotifier {
  final List<TimeBlock> _blocks = [];
  final List<TodoItem> _todoItems = [];
  final List<TaskCategory> _customCategories = [];
  bool _is24h = false;
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale; // null = seguir sistema
  DateTime _now = DateTime.now();
  DateTime _selectedDate = normalizeDate(DateTime.now());
  AppViewMode _viewMode = AppViewMode.clock;
  Timer? _clockTimer;
  StreamSubscription? _authSub;
  String? _lastUserId;

  AppViewMode get viewMode => _viewMode;

  // ──────────────────────────────────────────────
  // Base de Datos Local y Conectividad (Offline-First)
  // ──────────────────────────────────────────────
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final ConnectivityService _connectivity = ConnectivityService();
  StreamSubscription<bool>? _connectivitySub;

  bool get isOnline => _connectivity.isOnline;
  int get pendingSyncCount => _localDb.pendingSyncCount;
  bool get hasPendingSync => _localDb.hasPendingSync;

  // ──────────────────────────────────────────────
  // Configuración de Supabase / Cloud Sync
  // ──────────────────────────────────────────────
  final SupabaseService _supabase = SupabaseService();
  bool _isCloudSyncing = false;

  bool get isCloudSyncing => _isCloudSyncing;
  bool get isUserLoggedIn => _supabase.isAuthenticated;
  String? get lastUserId => _lastUserId;
  String? get userEmail => _supabase.currentUser?.email;

  // ──────────────────────────────────────────────
  // Configuración de Calendarios del Dispositivo
  // ──────────────────────────────────────────────
  final DeviceCalendarService _deviceCalService = DeviceCalendarService();
  bool _deviceCalendarSyncEnabled = false;
  List<String> _selectedDeviceCalendarIds = [];
  List<Calendar> _availableDeviceCalendars = [];
  bool _isDeviceCalendarSyncing = false;
  bool _calendarPermissionDenied = false;
  bool _calendarPermissionPermanentlyDenied = false;

  bool get deviceCalendarSyncEnabled => _deviceCalendarSyncEnabled;
  List<String> get selectedDeviceCalendarIds => List.unmodifiable(_selectedDeviceCalendarIds);
  List<Calendar> get availableDeviceCalendars => List.unmodifiable(_availableDeviceCalendars);
  bool get isDeviceCalendarSyncing => _isDeviceCalendarSyncing;
  bool get calendarPermissionDenied => _calendarPermissionDenied;
  bool get calendarPermissionPermanentlyDenied => _calendarPermissionPermanentlyDenied;

  // ──────────────────────────────────────────────
  // Configuración Global de Notificaciones
  // ──────────────────────────────────────────────
  int _reminderMinutesBefore = 5; // Por defecto: 5 minutos antes
  bool _notificationsEnabled = true;
  final NotificationService _notifService = NotificationService();

  // ──────────────────────────────────────────────
  // Getters Bloques de Tiempo
  // ──────────────────────────────────────────────

  /// Todos los bloques de tiempo guardados.
  List<TimeBlock> get allBlocks => List.unmodifiable(_blocks);

  /// Bloques correspondientes al día seleccionado con anillos calculados.
  List<TimeBlock> get selectedDateBlocks {
    final dayBlocks = _blocks.where((b) => b.occursOnDate(_selectedDate)).map((b) {
      if (b.isRecurring && !b.isOnDay(_selectedDate)) {
        return b.copyWith(date: _selectedDate);
      }
      return b;
    }).toList();
    _calculateRingsForList(dayBlocks);
    return dayBlocks;
  }

  /// Bloques del día (legacy getter para compatibilidad).
  List<TimeBlock> get blocks => selectedDateBlocks;

  // ──────────────────────────────────────────────
  // Getters Tareas ToDo (Backlog)
  // ──────────────────────────────────────────────

  /// Todas las tareas ToDo guardadas.
  List<TodoItem> get todoItems => List.unmodifiable(_todoItems);

  /// Cantidad de tareas ToDo pendientes (sin completar).
  int get pendingTodoCount => _todoItems.where((t) => !t.isCompleted).length;

  /// Lista de tareas ToDo pendientes.
  List<TodoItem> get pendingTodos =>
      _todoItems.where((t) => !t.isCompleted).toList();

  /// Lista de tareas ToDo completadas.
  List<TodoItem> get completedTodos =>
      _todoItems.where((t) => t.isCompleted).toList();

  bool get is24h => _is24h;

  ThemeMode get themeMode => _themeMode;

  Locale? get locale => _locale;

  String get currentLanguageCode => _locale?.languageCode ?? 'system';

  DateTime get now => _now;

  DateTime get selectedDate => _selectedDate;

  int get reminderMinutesBefore => _reminderMinutesBefore;

  bool get notificationsEnabled => _notificationsEnabled;

  /// Categorías personalizadas creadas por el usuario.
  List<TaskCategory> get customCategories => List.unmodifiable(_customCategories);

  /// Todas las categorías disponibles (fijas del sistema + personalizadas).
  List<TaskCategory> get allCategories =>
      [...TaskCategory.defaultCategories, ..._customCategories];

  bool get isViewingToday {
    final today = normalizeDate(_now);
    return _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;
  }

  /// Hora actual como decimal (ej: 9:30 → 9.5).
  double get currentHourDecimal =>
      _now.hour + _now.minute / 60.0 + _now.second / 3600.0;

  /// Hora actual normalizada al rango de la vista (12h → mod 12).
  double get currentHourView =>
      _is24h ? currentHourDecimal : currentHourDecimal % 12;

  // ──────────────────────────────────────────────
  // Gamificación y Maestría Temporal
  // ──────────────────────────────────────────────
  GamificationData _gamification = const GamificationData();
  GamificationData get gamification => _gamification;

  Achievement? _latestUnlockedAchievement;
  Achievement? get latestUnlockedAchievement => _latestUnlockedAchievement;
  void clearLatestAchievement() {
    _latestUnlockedAchievement = null;
  }

  WatchmakerLevel? _latestLevelUp;
  WatchmakerLevel? get latestLevelUp => _latestLevelUp;
  void clearLatestLevelUp() {
    _latestLevelUp = null;
  }

  String? _gamificationToast;
  String? get gamificationToast => _gamificationToast;
  void clearGamificationToast() {
    _gamificationToast = null;
  }

  /// Indica si el día seleccionado ha alcanzado el estado de Día Dorado (Golden Dial):
  /// Al menos 2 tareas planificadas y 80% o más completadas.
  bool get isGoldenDialAchieved {
    final dayBlocks = selectedDateBlocks;
    if (dayBlocks.length < 2) return false;
    final completed = dayBlocks.where((b) => b.status == TaskStatus.completed).length;
    return (completed / dayBlocks.length) >= 0.8;
  }

  /// Proporción de cumplimiento (0.0 a 1.0) para el día seleccionado
  double get dailyCompletionRatio {
    final dayBlocks = selectedDateBlocks;
    if (dayBlocks.isEmpty) return 0.0;
    final completed = dayBlocks.where((b) => b.status == TaskStatus.completed).length;
    return (completed / dayBlocks.length).clamp(0.0, 1.0);
  }

  int get dailyCompletedCount =>
      selectedDateBlocks.where((b) => b.status == TaskStatus.completed).length;

  int get dailyTotalCount => selectedDateBlocks.length;

  // ──────────────────────────────────────────────
  // Inicialización
  // ──────────────────────────────────────────────

  ClockProvider() {
    _startClock();
    _initAndLoad();
  }

  /// Inicializa notificaciones, carga datos del disco y base de datos local Hive,
  /// e inicia listeners de conectividad y Supabase.
  Future<void> _initAndLoad() async {
    await _initNotifications();
    await _loadFromStorage();
    _initConnectivityListener();
    _initSupabaseListener();
  }

  /// Escucha cambios de conectividad para sincronizar automáticamente al recuperar conexión
  void _initConnectivityListener() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((isOnline) {
      notifyListeners();
      if (isOnline && _supabase.isAuthenticated) {
        debugPrint('[ClockProvider] Conexión a internet restablecida. Sincronizando con Supabase...');
        syncWithCloud();
      }
    });
  }

  /// Inicializa el servicio de notificaciones y solicita permisos.
  Future<void> _initNotifications() async {
    await _notifService.init();
    _notifService.onPomodoroNotificationTapped = () {
      setViewMode(AppViewMode.pomodoro);
    };
    // Solicitar permisos de forma no-bloqueante (el usuario puede rechazar)
    _notifService.requestPermissions().then((granted) {
      debugPrint('[ClockProvider] Notification permission granted: $granted');
    });
  }

  /// Escucha cambios de sesión en Supabase y sincroniza o limpia datos
  void _initSupabaseListener() {
    final currentSupabaseUserId = _supabase.currentUser?.id;
    if (currentSupabaseUserId != null) {
      _lastUserId = currentSupabaseUserId;
      _saveLastUserIdToStorage();
    }

    _authSub = _supabase.authStateChanges?.listen((data) async {
      final currentUserId = data.session?.user.id;
      if (data.session != null && currentUserId != null) {
        // Si el usuario cambió (ej. inició sesión otro usuario sin pasar por signOut previo)
        if (_lastUserId != null && _lastUserId != currentUserId) {
          await clearUserData();
        }
        _lastUserId = currentUserId;
        await _saveLastUserIdToStorage();
        await syncWithCloud();
      } else if (data.event == AuthChangeEvent.signedOut || (_lastUserId != null && currentUserId == null)) {
        // El usuario activo cerró sesión
        await clearUserData();
      } else {
        notifyListeners();
      }
    });

    // Si ya está autenticado al iniciar la app, sincronizar
    if (_supabase.isAuthenticated) {
      syncWithCloud();
    }
  }


  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = DateTime.now();
      notifyListeners();
    });
  }

  // ──────────────────────────────────────────────
  // Configuración de Recordatorios Globales
  // ──────────────────────────────────────────────

  void setReminderMinutes(int minutes) {
    _reminderMinutesBefore = minutes;
    _saveNotificationSettingsToStorage();
    _rescheduleAllNotifications();
    notifyListeners();
  }

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    _saveNotificationSettingsToStorage();
    if (enabled) {
      _notifService.requestPermissions();
      _rescheduleAllNotifications();
    } else {
      _notifService.cancelAll();
    }
    notifyListeners();
  }

  void sendTestNotification() {
    _notifService.showTestNotification(minutesBefore: _reminderMinutesBefore);
  }

  /// Devuelve los minutos de anticipación efectivos para un bloque.
  int effectiveReminderMinutes(TimeBlock block) =>
      block.reminderMinutes ?? _reminderMinutesBefore;

  /// Indica si la notificación está efectivamente activa para el bloque.
  bool isBlockNotificationActive(TimeBlock block) =>
      _notificationsEnabled && block.notificationEnabled;

  /// Obtiene la versión del bloque situada en su próxima ocurrencia activa si es recurrente.
  TimeBlock _resolveNextOccurrenceBlock(TimeBlock block) {
    if (!block.isRecurring) return block;

    final now = DateTime.now();
    final today = normalizeDate(now);
    final hour = block.startHour.floor() % 24;
    final minute = ((block.startHour - block.startHour.floor()) * 60).round();

    // Comprobar si ocurre hoy y su hora aún no ha pasado
    if (block.occursOnDate(today)) {
      final todayStart = DateTime(today.year, today.month, today.day, hour, minute);
      if (todayStart.isAfter(now)) {
        return block.copyWith(date: today);
      }
    }

    // Buscar la próxima fecha que coincida con la regla de recurrencia en los siguientes 30 días
    for (int i = 1; i <= 30; i++) {
      final candidateDate = today.add(Duration(days: i));
      if (block.occursOnDate(candidateDate)) {
        return block.copyWith(date: candidateDate);
      }
    }

    return block;
  }

  /// Programa o cancela la notificación de un bloque respetando su configuración individual y la global.
  void _scheduleBlockNotification(TimeBlock block) {
    if (!_notificationsEnabled || !block.notificationEnabled) {
      _notifService.cancelTaskReminder(block.id);
      _notifService.cancelIntervalReminders(block.id);
      return;
    }

    final targetBlock = _resolveNextOccurrenceBlock(block);

    _notifService.scheduleTaskReminder(
      block: targetBlock,
      minutesBefore: effectiveReminderMinutes(targetBlock),
      enabled: true,
    );
    if (targetBlock.hasIntervalReminder) {
      _notifService.scheduleIntervalReminders(
        block: targetBlock,
        enabled: true,
      );
    } else {
      _notifService.cancelIntervalReminders(targetBlock.id);
    }
  }

  void _rescheduleAllNotifications() {
    if (!_notificationsEnabled) {
      _notifService.cancelAll();
      return;
    }
    for (final block in _blocks) {
      _scheduleBlockNotification(block);
    }
  }

  // ──────────────────────────────────────────────
  // Gestión de Temas (Claro / Oscuro / Sistema)
  // ──────────────────────────────────────────────

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemeToStorage();
    notifyListeners();
  }

  void cycleThemeMode() {
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
        break;
    }
    _saveThemeToStorage();
    notifyListeners();
  }

  String get themeModeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  IconData get themeModeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  // ──────────────────────────────────────────────
  // Gestión de Idioma (Español / Inglés / Sistema)
  // ──────────────────────────────────────────────

  void setLocale(Locale? newLocale) {
    _locale = newLocale;
    _saveLocaleToStorage();
    notifyListeners();
  }

  Future<void> _saveLocaleToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_locale == null) {
      await prefs.remove(_kLocaleStorageKey);
    } else {
      await prefs.setString(_kLocaleStorageKey, _locale!.languageCode);
    }
  }

  // ──────────────────────────────────────────────
  // Navegación de Calendario
  // ──────────────────────────────────────────────

  void selectDate(DateTime date) {
    _selectedDate = normalizeDate(date);
    if (_deviceCalendarSyncEnabled) {
      syncDeviceCalendarEvents(date: _selectedDate);
    }
    notifyListeners();
  }

  void jumpToToday() {
    _selectedDate = normalizeDate(DateTime.now());
    if (_deviceCalendarSyncEnabled) {
      syncDeviceCalendarEvents(date: _selectedDate);
    }
    notifyListeners();
  }

  void nextDay() {
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    if (_deviceCalendarSyncEnabled) {
      syncDeviceCalendarEvents(date: _selectedDate);
    }
    notifyListeners();
  }

  void previousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    if (_deviceCalendarSyncEnabled) {
      syncDeviceCalendarEvents(date: _selectedDate);
    }
    notifyListeners();
  }

  List<TimeBlock> blocksForDate(DateTime date) {
    final target = normalizeDate(date);
    return _blocks.where((b) => b.isOnDay(target)).toList();
  }

  List<TaskCategory> categoriesForDate(DateTime date) {
    final dayBlocks = blocksForDate(date);
    final unique = <TaskCategory>{};
    for (final b in dayBlocks) {
      unique.add(b.category);
    }
    return unique.toList();
  }

  bool hasTasksOnDate(DateTime date) {
    final target = normalizeDate(date);
    return _blocks.any((b) => b.isOnDay(target));
  }

  // ──────────────────────────────────────────────
  // Sincronización con Supabase (Nube)
  // ──────────────────────────────────────────────

  // ──────────────────────────────────────────────
  // Sincronización con Supabase (Nube) & Cola Offline
  // ──────────────────────────────────────────────

  /// Sincroniza bloques, tareas ToDo, notas y categorías con Supabase.
  /// 1. Drena la cola de sincronización offline (_localDb.syncQueue).
  /// 2. Descarga cambios remotos y fusiona con la base de datos local Hive.
  Future<void> syncWithCloud() async {
    if (!_supabase.isAuthenticated || _isCloudSyncing) return;

    // Verificar si realmente existe una conexión a internet funcional
    final isOnline = await _connectivity.checkGoodConnection();
    if (!isOnline) {
      debugPrint('[ClockProvider] syncWithCloud omitido: sin conexión a internet.');
      return;
    }

    _isCloudSyncing = true;
    notifyListeners();

    try {
      // ── Paso 1: Drenar cola de sincronización offline (sync_queue) ──
      final pendingActions = _localDb.getPendingSyncActions();
      if (pendingActions.isNotEmpty) {
        debugPrint('[ClockProvider] Drenando ${pendingActions.length} acciones pendientes de sync_queue...');

        // Ejecutar primero las eliminaciones para evitar que la descarga posterior las resucite
        final deletes = pendingActions
            .where((a) => a.operation == SyncOperationType.delete)
            .toList();
        for (final action in deletes) {
          bool success = false;
          switch (action.entityType) {
            case SyncEntityType.timeBlock:
              success = await _supabase.deleteTimeBlock(action.targetId);
              break;
            case SyncEntityType.todo:
              success = await _supabase.deleteTodo(action.targetId);
              break;
            case SyncEntityType.category:
              success = await _supabase.deleteCategory(action.targetId);
              break;
            case SyncEntityType.gamification:
              success = true;
              break;
          }
          if (success) {
            await _localDb.removeSyncAction(action.id);
          }
        }

        // Luego ejecutar inserciones y actualizaciones (upserts)
        final upserts = pendingActions
            .where((a) => a.operation == SyncOperationType.upsert)
            .toList();
        for (final action in upserts) {
          bool success = false;
          if (action.payload == null) {
            await _localDb.removeSyncAction(action.id);
            continue;
          }
          switch (action.entityType) {
            case SyncEntityType.timeBlock:
              success = await _supabase.upsertTimeBlockMap(action.payload!);
              break;
            case SyncEntityType.todo:
              success = await _supabase.upsertTodoMap(action.payload!);
              break;
            case SyncEntityType.category:
              success = await _supabase.upsertCategoryMap(action.payload!);
              break;
            case SyncEntityType.gamification:
              try {
                success = await _supabase.upsertGamification(
                  GamificationData.fromJson(action.payload!),
                );
              } catch (_) {
                success = false;
              }
              break;
          }
          if (success) {
            await _localDb.removeSyncAction(action.id);
          }
        }
      }

      // ── Paso 2: Sincronizar Categorías Personalizadas ──
      final cloudCategories = await _supabase.fetchCategories();
      final catMap = <String, TaskCategory>{};
      for (final c in cloudCategories) {
        catMap[c.id] = c;
      }
      for (final c in _customCategories) {
        catMap[c.id] = c;
      }
      for (final localCat in _customCategories) {
        await _supabase.upsertCategory(localCat);
      }
      _customCategories.clear();
      _customCategories.addAll(catMap.values);
      await _saveCategoriesToStorage();

      // ── Paso 3: Sincronizar Bloques de Tiempo ──
      // Subir bloques locales creados por el usuario
      for (final localBlock in _blocks) {
        if (!localBlock.isExternalCalendar) {
          await _supabase.upsertTimeBlock(localBlock);
        }
      }

      // Descargar bloques de la nube
      final cloudBlocks = await _supabase.fetchTimeBlocks();
      final blockMap = <String, TimeBlock>{};
      for (final b in cloudBlocks) {
        blockMap[b.id] = b;
      }
      for (final b in _blocks) {
        blockMap[b.id] = b;
      }

      _blocks.clear();
      _blocks.addAll(blockMap.values);
      _recalculateAllRings();
      await _saveToStorage();
      _rescheduleAllNotifications();

      // ── Paso 4: Sincronizar Tareas ToDo y Notas ──
      for (final localTodo in _todoItems) {
        await _supabase.upsertTodo(localTodo);
      }

      final cloudTodos = await _supabase.fetchTodos();
      final todoMap = <String, TodoItem>{};
      for (final t in cloudTodos) {
        todoMap[t.id] = t;
      }
      for (final t in _todoItems) {
        todoMap[t.id] = t;
      }

      _todoItems.clear();
      _todoItems.addAll(todoMap.values);
      _todoItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveTodosToStorage();

      // ── Paso 5: Sincronizar Gamificación y Logros ──
      final cloudGamification = await _supabase.fetchGamification();
      if (cloudGamification != null) {
        if (_gamification.ticks == 0 &&
            _gamification.totalCompletedTasks == 0 &&
            _gamification.unlockedAchievements.isEmpty) {
          _gamification = cloudGamification;
        } else {
          final mergedAchievements =
              Map<String, DateTime>.from(_gamification.unlockedAchievements);
          cloudGamification.unlockedAchievements.forEach((k, v) {
            if (!mergedAchievements.containsKey(k) ||
                v.isBefore(mergedAchievements[k]!)) {
              mergedAchievements[k] = v;
            }
          });

          _gamification = _gamification.copyWith(
            ticks: _gamification.ticks > cloudGamification.ticks
                ? _gamification.ticks
                : cloudGamification.ticks,
            currentStreak: _gamification.currentStreak > cloudGamification.currentStreak
                ? _gamification.currentStreak
                : cloudGamification.currentStreak,
            bestStreak: _gamification.bestStreak > cloudGamification.bestStreak
                ? _gamification.bestStreak
                : cloudGamification.bestStreak,
            streakFreezeCount: _gamification.streakFreezeCount >
                    cloudGamification.streakFreezeCount
                ? _gamification.streakFreezeCount
                : cloudGamification.streakFreezeCount,
            totalCompletedTasks: _gamification.totalCompletedTasks >
                    cloudGamification.totalCompletedTasks
                ? _gamification.totalCompletedTasks
                : cloudGamification.totalCompletedTasks,
            totalFocusMinutes: _gamification.totalFocusMinutes >
                    cloudGamification.totalFocusMinutes
                ? _gamification.totalFocusMinutes
                : cloudGamification.totalFocusMinutes,
            unlockedAchievements: mergedAchievements,
            lastActiveDate:
                _gamification.lastActiveDate ?? cloudGamification.lastActiveDate,
          );
        }
      }
      await _saveGamificationToStorage();
      await _supabase.upsertGamification(_gamification);

      debugPrint('[ClockProvider] Sincronización con la nube completada exitosamente.');
    } catch (e) {
      debugPrint('[ClockProvider] Error al sincronizar con la nube: $e');
    } finally {
      _isCloudSyncing = false;
      notifyListeners();
    }
  }

  /// Cierra sesión en Supabase y limpia todas las tareas y datos del usuario de la UI,
  /// de la base de datos Hive y de SharedPreferences.
  Future<void> signOut() async {
    if (_supabase.isAuthenticated) {
      try {
        await syncWithCloud();
      } catch (e) {
        debugPrint('[ClockProvider] Error al sincronizar antes de cerrar sesión: $e');
      }
    }

    await _supabase.signOut();
    await clearUserData();
  }

  /// Limpia las tareas, bloques, notas ToDo, categorías personalizadas y datos de gamificación
  /// asociados al usuario que cerró sesión, manteniendo intactos los calendarios nativos del dispositivo
  /// y las preferencias de la app (tema, idioma).
  Future<void> clearUserData() async {
    _lastUserId = null;
    await _saveLastUserIdToStorage();

    // Limpiar base de datos local Hive
    await _localDb.clearUserData(preserveExternalCalendar: true);

    // Eliminar bloques creados por el usuario (conservar eventos de calendario del dispositivo)
    _blocks.removeWhere((b) => !b.isExternalCalendar);
    _recalculateAllRings();
    await _saveToStorage();

    // Limpiar ToDos
    _todoItems.clear();
    await _saveTodosToStorage();

    // Limpiar categorías personalizadas
    _customCategories.clear();
    await _saveCategoriesToStorage();

    // Reiniciar gamificación al estado base
    _gamification = const GamificationData();
    await _saveGamificationToStorage();

    // Cancelar todas las notificaciones programadas y reprogramar solo si queda algún evento del dispositivo
    await _notifService.cancelAll();
    _rescheduleAllNotifications();

    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Encolado y Sincronización Remota (Offline-First)
  // ──────────────────────────────────────────────

  Future<void> _pushTimeBlockRemote(TimeBlock block) async {
    if (block.isExternalCalendar) return;
    if (_connectivity.isOnline && _supabase.isAuthenticated) {
      final success = await _supabase.upsertTimeBlock(block);
      if (!success) {
        await _localDb.enqueueSyncAction(SyncAction.create(
          targetId: block.id,
          entityType: SyncEntityType.timeBlock,
          operation: SyncOperationType.upsert,
          payload: block.toJson(),
        ));
        notifyListeners();
      }
    } else {
      if (_supabase.isAuthenticated) {
        await _localDb.enqueueSyncAction(SyncAction.create(
          targetId: block.id,
          entityType: SyncEntityType.timeBlock,
          operation: SyncOperationType.upsert,
          payload: block.toJson(),
        ));
        notifyListeners();
      }
    }
  }

  Future<void> _deleteTimeBlockRemote(String id) async {
    if (_connectivity.isOnline && _supabase.isAuthenticated) {
      final success = await _supabase.deleteTimeBlock(id);
      if (!success) {
        await _localDb.enqueueSyncAction(SyncAction.create(
          targetId: id,
          entityType: SyncEntityType.timeBlock,
          operation: SyncOperationType.delete,
        ));
        notifyListeners();
      }
    } else {
      if (_supabase.isAuthenticated) {
        await _localDb.enqueueSyncAction(SyncAction.create(
          targetId: id,
          entityType: SyncEntityType.timeBlock,
          operation: SyncOperationType.delete,
        ));
        notifyListeners();
      }
    }
  }

  Future<void> _pushTodoRemote(TodoItem item) async {
    if (_connectivity.isOnline && _supabase.isAuthenticated) {
      final success = await _supabase.upsertTodo(item);
      if (!success) {
        await _localDb.enqueueSyncAction(SyncAction.create(
          targetId: item.id,
          entityType: SyncEntityType.todo,
          operation: SyncOperationType.upsert,
          payload: item.toJson(),
        ));
        notifyListeners();
      }
    } else {
      if (_supabase.isAuthenticated) {
        await _localDb.enqueueSyncAction(SyncAction.create(
          targetId: item.id,
          entityType: SyncEntityType.todo,
          operation: SyncOperationType.upsert,
          payload: item.toJson(),
        ));
        notifyListeners();
      }
    }
  }

  Future<void> _deleteTodoRemote(String id) async {
    if (_connectivity.isOnline && _supabase.isAuthenticated) {
      final success = await _supabase.deleteTodo(id);
      if (!success) {
        await _localDb.enqueueSyncAction(SyncAction.create(
          targetId: id,
          entityType: SyncEntityType.todo,
          operation: SyncOperationType.delete,
        ));
        notifyListeners();
      }
    } else {
      if (_supabase.isAuthenticated) {
        await _localDb.enqueueSyncAction(SyncAction.create(
          targetId: id,
          entityType: SyncEntityType.todo,
          operation: SyncOperationType.delete,
        ));
        notifyListeners();
      }
    }
  }

  Future<void> _pushCategoryRemote(TaskCategory category) async {
    if (category.isDefault) return;
    if (_connectivity.isOnline && _supabase.isAuthenticated) {
      final success = await _supabase.upsertCategory(category);
      if (!success) {
        await _localDb.enqueueSyncAction(SyncAction.create(
          targetId: category.id,
          entityType: SyncEntityType.category,
          operation: SyncOperationType.upsert,
          payload: category.toJson(),
        ));
        notifyListeners();
      }
    } else {
      if (_supabase.isAuthenticated) {
        await _localDb.enqueueSyncAction(SyncAction.create(
          targetId: category.id,
          entityType: SyncEntityType.category,
          operation: SyncOperationType.upsert,
          payload: category.toJson(),
        ));
        notifyListeners();
      }
    }
  }

  Future<void> _deleteCategoryRemote(String id) async {
    if (_connectivity.isOnline && _supabase.isAuthenticated) {
      final success = await _supabase.deleteCategory(id);
      if (!success) {
        await _localDb.enqueueSyncAction(SyncAction.create(
          targetId: id,
          entityType: SyncEntityType.category,
          operation: SyncOperationType.delete,
        ));
        notifyListeners();
      }
    } else {
      if (_supabase.isAuthenticated) {
        await _localDb.enqueueSyncAction(SyncAction.create(
          targetId: id,
          entityType: SyncEntityType.category,
          operation: SyncOperationType.delete,
        ));
        notifyListeners();
      }
    }
  }

  Future<void> _pushGamificationRemote() async {
    if (_connectivity.isOnline && _supabase.isAuthenticated) {
      final success = await _supabase.upsertGamification(_gamification);
      if (!success) {
        await _localDb.enqueueSyncAction(SyncAction.create(
          targetId: 'gamification',
          entityType: SyncEntityType.gamification,
          operation: SyncOperationType.upsert,
          payload: _gamification.toJson(),
        ));
        notifyListeners();
      }
    } else {
      if (_supabase.isAuthenticated) {
        await _localDb.enqueueSyncAction(SyncAction.create(
          targetId: 'gamification',
          entityType: SyncEntityType.gamification,
          operation: SyncOperationType.upsert,
          payload: _gamification.toJson(),
        ));
        notifyListeners();
      }
    }
  }

  // ──────────────────────────────────────────────
  // CRUD de bloques
  // ──────────────────────────────────────────────

  void addBlock(TimeBlock block) {
    _blocks.add(block);
    _recalculateAllRings();
    _saveToStorage();
    _pushTimeBlockRemote(block);
    _scheduleBlockNotification(block);
    notifyListeners();
  }

  void updateBlock(TimeBlock updated) {
    final idx = _blocks.indexWhere((b) => b.id == updated.id);
    if (idx != -1) {
      _blocks[idx] = updated;
      _recalculateAllRings();
      _saveToStorage();
      _pushTimeBlockRemote(updated);
      _scheduleBlockNotification(updated);
      notifyListeners();
    }
  }

  void deleteBlock(String id) {
    _blocks.removeWhere((b) => b.id == id);
    _recalculateAllRings();
    _saveToStorage();
    _deleteTimeBlockRemote(id);
    _notifService.cancelTaskReminder(id);
    notifyListeners();
  }

  void toggleStatus(String id) {
    final idx = _blocks.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    final block = _blocks[idx];
    final nextStatus = TaskStatus.values[
        (block.status.index + 1) % TaskStatus.values.length];
    final updated = block.copyWith(status: nextStatus);
    _blocks[idx] = updated;
    _saveToStorage();
    _pushTimeBlockRemote(updated);

    if (nextStatus == TaskStatus.completed) {
      _notifService.cancelTaskReminder(id);
      _onTaskCompleted(updated);
    } else {
      _scheduleBlockNotification(updated);
    }
    notifyListeners();
  }

  /// Establece el estado de una tarea directamente (útil para mover entre columnas Kanban).
  void setBlockStatus(String id, TaskStatus newStatus) {
    final idx = _blocks.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    final block = _blocks[idx];
    if (block.status == newStatus) return;

    final updated = block.copyWith(status: newStatus);
    _blocks[idx] = updated;
    _saveToStorage();
    _pushTimeBlockRemote(updated);

    if (newStatus == TaskStatus.completed) {
      _notifService.cancelTaskReminder(id);
      _onTaskCompleted(updated);
    } else {
      _scheduleBlockNotification(updated);
    }
    notifyListeners();
  }

  /// Convierte un ítem ToDo en un TimeBlock con un estado inicial específico (ej. al soltarlo en una columna Kanban).
  void convertTodoToScheduledBlock({
    required String todoId,
    required TaskStatus initialStatus,
    DateTime? date,
    double? startHour,
    double? endHour,
  }) {
    final idx = _todoItems.indexWhere((t) => t.id == todoId);
    if (idx == -1) return;
    final todo = _todoItems.removeAt(idx);
    _saveTodosToStorage();
    _deleteTodoRemote(todoId);

    final targetDate = date ?? _selectedDate;
    final double defaultStart = startHour ?? (_now.hour + (_now.minute / 60.0)).clamp(0.0, 23.5);
    final double? defaultEnd = endHour ?? (defaultStart <= 22.5 ? defaultStart + 1.0 : null);

    final block = TimeBlock(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      date: targetDate,
      startHour: defaultStart,
      endHour: defaultEnd,
      category: todo.category,
      status: initialStatus,
    );
    addBlock(block);
  }

  /// Desasigna un bloque de tiempo de la agenda y lo devuelve al Backlog de ToDos.
  void moveBlockToBacklog(String blockId) {
    final idx = _blocks.indexWhere((b) => b.id == blockId);
    if (idx == -1) return;
    final block = _blocks.removeAt(idx);
    _recalculateAllRings();
    _saveToStorage();
    _deleteTimeBlockRemote(blockId);
    _notifService.cancelTaskReminder(blockId);

    final todo = TodoItem(
      id: block.id,
      title: block.title,
      description: block.description,
      category: block.category,
      isCompleted: block.status == TaskStatus.completed,
      createdAt: DateTime.now(),
    );
    _todoItems.insert(0, todo);
    _saveTodosToStorage();
    _pushTodoRemote(todo);
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // CRUD de Tareas ToDo (Backlog)
  // ──────────────────────────────────────────────

  void addTodo(TodoItem item) {
    _todoItems.insert(0, item); // Las más recientes arriba
    _saveTodosToStorage();
    _pushTodoRemote(item);
    notifyListeners();
  }

  void updateTodo(TodoItem updated) {
    final idx = _todoItems.indexWhere((t) => t.id == updated.id);
    if (idx != -1) {
      _todoItems[idx] = updated;
      _saveTodosToStorage();
      _pushTodoRemote(updated);
      notifyListeners();
    }
  }

  void toggleTodo(String id) {
    final idx = _todoItems.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final item = _todoItems[idx];
    final nextCompleted = !item.isCompleted;
    final updated = item.copyWith(
      isCompleted: nextCompleted,
      completedAt: nextCompleted ? DateTime.now() : null,
      clearCompletedAt: !nextCompleted,
    );
    _todoItems[idx] = updated;
    _saveTodosToStorage();
    _pushTodoRemote(updated);
    if (nextCompleted) {
      _onTodoCompleted(updated);
    }
    notifyListeners();
  }

  void deleteTodo(String id) {
    _todoItems.removeWhere((t) => t.id == id);
    _saveTodosToStorage();
    _deleteTodoRemote(id);
    notifyListeners();
  }

  void clearCompletedTodos() {
    final completed = _todoItems.where((t) => t.isCompleted).toList();
    _todoItems.removeWhere((t) => t.isCompleted);
    _saveTodosToStorage();
    for (final item in completed) {
      _deleteTodoRemote(item.id);
    }
    notifyListeners();
  }

  /// Convierte o agenda una tarea ToDo como bloque de tiempo en el reloj radial.
  void scheduleTodoAsBlock({
    required String todoId,
    required DateTime date,
    required double startHour,
    required double endHour,
    bool markTodoCompleted = false,
  }) {
    final idx = _todoItems.indexWhere((t) => t.id == todoId);
    if (idx == -1) return;
    final todo = _todoItems[idx];

    final block = TimeBlock.create(
      title: todo.title,
      description: todo.description,
      date: date,
      startHour: startHour,
      endHour: endHour,
      category: todo.category,
    );
    addBlock(block);

    if (markTodoCompleted) {
      final updatedTodo = todo.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      _todoItems[idx] = updatedTodo;
      _saveTodosToStorage();
      _pushTodoRemote(updatedTodo);
    }
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Lógica de anillos concéntricos por día
  // ──────────────────────────────────────────────

  void _recalculateAllRings() {
    final map = <DateTime, List<TimeBlock>>{};
    for (final b in _blocks) {
      map.putIfAbsent(b.date, () => []).add(b);
    }
    for (final list in map.values) {
      _calculateRingsForList(list);
    }
  }

  static void _calculateRingsForList(List<TimeBlock> dayBlocks) {
    dayBlocks.sort((a, b) => a.startHour.compareTo(b.startHour));
    final rings = <int, List<TimeBlock>>{};

    for (var i = 0; i < dayBlocks.length; i++) {
      final block = dayBlocks[i];
      int assignedRing = 0;
      while (true) {
        final ringBlocks = rings[assignedRing] ?? [];
        final hasOverlap = ringBlocks.any((b) => b.overlapsWith(block));
        if (!hasOverlap) break;
        assignedRing++;
      }
      rings.putIfAbsent(assignedRing, () => []).add(block);
      dayBlocks[i] = block.copyWith(ringIndex: assignedRing);
    }
  }

  // ──────────────────────────────────────────────
  // Modo 12h / 24h
  // ──────────────────────────────────────────────

  void toggleClockMode() {
    _is24h = !_is24h;
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Modo de Vista (Reloj / Kanban / Pomodoro)
  // ──────────────────────────────────────────────

  void setViewMode(AppViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    _saveViewModeToStorage();
    notifyListeners();
  }

  void toggleViewMode() {
    _viewMode = _viewMode == AppViewMode.clock
        ? AppViewMode.kanban
        : AppViewMode.clock;
    _saveViewModeToStorage();
    notifyListeners();
  }

  Future<void> _saveViewModeToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kViewModeStorageKey, _viewMode.name);
  }

  // ──────────────────────────────────────────────
  // Motor y Estado de Pomodoro (Modo Enfoque)
  // ──────────────────────────────────────────────
  PomodoroSettings _pomodoroSettings = const PomodoroSettings();
  PomodoroSessionState _pomodoroState = const PomodoroSessionState();
  Timer? _pomodoroTimer;
  DateTime? _pomodoroLastTick;

  PomodoroSettings get pomodoroSettings => _pomodoroSettings;
  PomodoroSessionState get pomodoroState => _pomodoroState;
  bool get isPomodoroRunning => _pomodoroState.status == PomodoroStatus.running;
  bool get hasActivePomodoroSession => _pomodoroState.status != PomodoroStatus.idle;

  int _secondsForPhase(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.focus:
        return _pomodoroSettings.focusDurationMinutes * 60;
      case PomodoroPhase.shortBreak:
        return _pomodoroSettings.shortBreakDurationMinutes * 60;
      case PomodoroPhase.longBreak:
        return _pomodoroSettings.longBreakDurationMinutes * 60;
    }
  }

  void _schedulePomodoroNotification() {
    if (!_pomodoroSettings.enableNotifications) return;
    if (_pomodoroState.remainingSeconds <= 0) return;

    final scheduledDate = DateTime.now().add(Duration(seconds: _pomodoroState.remainingSeconds));
    final phase = _pomodoroState.phase;
    final taskTitle = _pomodoroState.activeTask?.title;

    final String title;
    final String body;

    if (phase.isFocus) {
      final taskPart = (taskTitle != null && taskTitle.trim().isNotEmpty) ? ': "$taskTitle"' : '';
      title = '🎉 ¡Sesión de enfoque completada$taskPart!';
      body = 'Completaste tu lapso de concentración. Tómate un merecido descanso.';
    } else if (phase == PomodoroPhase.shortBreak) {
      title = '⚡ ¡Descanso corto finalizado!';
      body = 'Tu descanso ha terminado. ¿Listo para el siguiente bloque de concentración?';
    } else {
      title = '🌿 ¡Descanso largo finalizado!';
      body = 'Ciclo completo terminado. ¡Momento de volver con energía!';
    }

    _notifService.schedulePomodoroCompletion(
      scheduledDate: scheduledDate,
      title: title,
      body: body,
      sound: _pomodoroSettings.soundEnabled,
    );
  }

  void _cancelPomodoroNotification() {
    _notifService.cancelPomodoroNotification();
  }

  void startPomodoro() {
    if (_pomodoroState.status == PomodoroStatus.running) return;

    int remaining = _pomodoroState.remainingSeconds;
    int total = _pomodoroState.totalSeconds;

    if (_pomodoroState.status == PomodoroStatus.idle || remaining <= 0) {
      total = _secondsForPhase(_pomodoroState.phase);
      remaining = total;
    }

    _pomodoroState = _pomodoroState.copyWith(
      status: PomodoroStatus.running,
      remainingSeconds: remaining,
      totalSeconds: total,
    );

    _pomodoroLastTick = DateTime.now();
    _pomodoroTimer?.cancel();
    _pomodoroTimer = Timer.periodic(const Duration(milliseconds: 500), _onPomodoroTick);
    _schedulePomodoroNotification();
    _savePomodoroStateToStorage();
    notifyListeners();
  }

  void pausePomodoro() {
    if (_pomodoroState.status != PomodoroStatus.running) return;
    _pomodoroTimer?.cancel();
    _pomodoroTimer = null;
    _cancelPomodoroNotification();
    _pomodoroState = _pomodoroState.copyWith(status: PomodoroStatus.paused);
    _savePomodoroStateToStorage();
    notifyListeners();
  }

  void resumePomodoro() {
    startPomodoro();
  }

  void resetPomodoro() {
    _pomodoroTimer?.cancel();
    _pomodoroTimer = null;
    _cancelPomodoroNotification();
    final phaseSecs = _secondsForPhase(_pomodoroState.phase);
    _pomodoroState = _pomodoroState.copyWith(
      status: PomodoroStatus.idle,
      remainingSeconds: phaseSecs,
      totalSeconds: phaseSecs,
    );
    _savePomodoroStateToStorage();
    notifyListeners();
  }

  void setPomodoroPhase(PomodoroPhase phase) {
    if (_pomodoroState.phase == phase) return;
    _pomodoroTimer?.cancel();
    _pomodoroTimer = null;
    _cancelPomodoroNotification();
    final phaseSecs = _secondsForPhase(phase);
    _pomodoroState = _pomodoroState.copyWith(
      phase: phase,
      status: PomodoroStatus.idle,
      remainingSeconds: phaseSecs,
      totalSeconds: phaseSecs,
    );
    _savePomodoroStateToStorage();
    notifyListeners();
  }

  void skipPomodoroPhase() {
    _pomodoroTimer?.cancel();
    _pomodoroTimer = null;
    _cancelPomodoroNotification();

    PomodoroPhase nextPhase;
    int nextCycles = _pomodoroState.completedCycles;

    if (_pomodoroState.phase.isFocus) {
      if (nextCycles + 1 >= _pomodoroSettings.longBreakInterval) {
        nextPhase = PomodoroPhase.longBreak;
        nextCycles = 0;
      } else {
        nextPhase = PomodoroPhase.shortBreak;
        nextCycles = nextCycles + 1;
      }
    } else {
      nextPhase = PomodoroPhase.focus;
    }

    final totalSecs = _secondsForPhase(nextPhase);
    _pomodoroState = _pomodoroState.copyWith(
      phase: nextPhase,
      status: PomodoroStatus.idle,
      remainingSeconds: totalSecs,
      totalSeconds: totalSecs,
      completedCycles: nextCycles,
    );
    _savePomodoroStateToStorage();
    notifyListeners();
  }

  void adjustPomodoroTime(int deltaMinutes) {
    final deltaSeconds = deltaMinutes * 60;
    final newRemaining = (_pomodoroState.remainingSeconds + deltaSeconds).clamp(60, 180 * 60);
    final newTotal = _pomodoroState.totalSeconds < newRemaining ? newRemaining : _pomodoroState.totalSeconds;

    _pomodoroState = _pomodoroState.copyWith(
      remainingSeconds: newRemaining,
      totalSeconds: newTotal,
    );
    if (_pomodoroState.status == PomodoroStatus.running) {
      _schedulePomodoroNotification();
    }
    _savePomodoroStateToStorage();
    notifyListeners();
  }

  void setPomodoroActiveTask({
    required String id,
    required String title,
    required TaskCategory category,
    bool isTodo = false,
  }) {
    _pomodoroState = _pomodoroState.copyWith(
      activeTask: PomodoroActiveTask(
        id: id,
        title: title,
        category: category,
        isTodo: isTodo,
      ),
    );
    _savePomodoroStateToStorage();
    notifyListeners();
  }

  void clearPomodoroActiveTask() {
    _pomodoroState = _pomodoroState.copyWith(clearActiveTask: true);
    _savePomodoroStateToStorage();
    notifyListeners();
  }

  void completePomodoroTask() {
    if (_pomodoroState.activeTask == null) return;
    final task = _pomodoroState.activeTask!;
    if (task.isTodo) {
      toggleTodo(task.id);
    } else {
      setBlockStatus(task.id, TaskStatus.completed);
    }
  }

  void updatePomodoroSettings(PomodoroSettings newSettings) {
    _pomodoroSettings = newSettings;
    _savePomodoroSettingsToStorage();

    if (_pomodoroState.status == PomodoroStatus.idle) {
      final newSecs = _secondsForPhase(_pomodoroState.phase);
      _pomodoroState = _pomodoroState.copyWith(
        remainingSeconds: newSecs,
        totalSeconds: newSecs,
      );
      _savePomodoroStateToStorage();
    }
    notifyListeners();
  }

  void _onPomodoroTick(Timer timer) {
    if (_pomodoroState.status != PomodoroStatus.running) return;

    final now = DateTime.now();
    final elapsedSecs = _pomodoroLastTick != null
        ? now.difference(_pomodoroLastTick!).inSeconds
        : 1;

    if (elapsedSecs < 1) return;
    _pomodoroLastTick = now;

    final newRemaining = _pomodoroState.remainingSeconds - elapsedSecs;

    if (newRemaining <= 0) {
      _onPomodoroPhaseCompleted();
    } else {
      _pomodoroState = _pomodoroState.copyWith(remainingSeconds: newRemaining);
      notifyListeners();
    }
  }

  void _onPomodoroPhaseCompleted() {
    _pomodoroTimer?.cancel();
    _pomodoroTimer = null;
    _cancelPomodoroNotification();

    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    final completedPhase = _pomodoroState.phase;
    final taskTitle = _pomodoroState.activeTask?.title;

    if (completedPhase.isFocus) {
      const ticksEarned = 15;
      final focusMinutes = _pomodoroSettings.focusDurationMinutes;
      final newCompletedSessions = _pomodoroState.totalPomodorosToday + 1;
      final newFocusMinutesToday = _pomodoroState.totalFocusMinutesToday + focusMinutes;

      // Actualizar Gamification
      final oldLevel = _gamification.currentLevel;
      final newTicks = _gamification.ticks + ticksEarned;
      final newTotalMinutes = _gamification.totalFocusMinutes + focusMinutes;
      final newTotalPomodoros = _gamification.totalPomodoroSessions + 1;

      final updatedCategoryMinutes = Map<String, int>.from(_gamification.categoryFocusMinutes);
      if (_pomodoroState.activeTask != null) {
        final catId = _pomodoroState.activeTask!.category.id;
        updatedCategoryMinutes[catId] = (updatedCategoryMinutes[catId] ?? 0) + focusMinutes;
      }

      _gamification = _gamification.copyWith(
        ticks: newTicks,
        totalFocusMinutes: newTotalMinutes,
        totalPomodoroSessions: newTotalPomodoros,
        categoryFocusMinutes: updatedCategoryMinutes,
      );

      final newLevel = _gamification.currentLevel;
      if (newLevel.level > oldLevel.level) {
        _latestLevelUp = newLevel;
      }

      _saveGamificationToStorage();
      _pushGamificationRemote();

      // Disparar Notificación si está habilitada
      if (_pomodoroSettings.enableNotifications) {
        final taskPart = (taskTitle != null && taskTitle.trim().isNotEmpty) ? ': "$taskTitle"' : '';
        _notifService.showPomodoroCompletionNotification(
          title: '🎉 ¡Sesión de enfoque completada$taskPart!',
          body: 'Completaste $focusMinutes min de concentración. Tómate un merecido descanso (+15 Ticks).',
          sound: _pomodoroSettings.soundEnabled,
        );
      }

      // Siguiente fase: descanso corto o descanso largo
      final nextCycle = _pomodoroState.completedCycles + 1;
      PomodoroPhase nextPhase;
      int nextCycles;

      if (nextCycle >= _pomodoroSettings.longBreakInterval) {
        nextPhase = PomodoroPhase.longBreak;
        nextCycles = 0;
      } else {
        nextPhase = PomodoroPhase.shortBreak;
        nextCycles = nextCycle;
      }

      final nextSecs = _secondsForPhase(nextPhase);
      _pomodoroState = _pomodoroState.copyWith(
        phase: nextPhase,
        status: PomodoroStatus.idle,
        remainingSeconds: nextSecs,
        totalSeconds: nextSecs,
        completedCycles: nextCycles,
        totalPomodorosToday: newCompletedSessions,
        totalFocusMinutesToday: newFocusMinutesToday,
      );

      _evaluateAchievements();

      if (_pomodoroSettings.autoStartBreaks) {
        startPomodoro();
      } else {
        _savePomodoroStateToStorage();
        notifyListeners();
      }
    } else {
      // Fin de descanso
      if (_pomodoroSettings.enableNotifications) {
        final isShort = completedPhase == PomodoroPhase.shortBreak;
        _notifService.showPomodoroCompletionNotification(
          title: isShort ? '⚡ ¡Descanso corto finalizado!' : '🌿 ¡Descanso largo finalizado!',
          body: isShort
              ? '¿Listo para tu siguiente bloque de concentración?'
              : 'Ciclo completo terminado. Es hora de comenzar un nuevo bloque de enfoque.',
          sound: _pomodoroSettings.soundEnabled,
        );
      }

      const nextPhase = PomodoroPhase.focus;
      final nextSecs = _secondsForPhase(nextPhase);

      _pomodoroState = _pomodoroState.copyWith(
        phase: nextPhase,
        status: PomodoroStatus.idle,
        remainingSeconds: nextSecs,
        totalSeconds: nextSecs,
      );

      if (_pomodoroSettings.autoStartPomodoros) {
        startPomodoro();
      } else {
        _savePomodoroStateToStorage();
        notifyListeners();
      }
    }
  }

  Future<void> _savePomodoroSettingsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPomodoroSettingsKey, jsonEncode(_pomodoroSettings.toJson()));
  }

  Future<void> _savePomodoroStateToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPomodoroStateKey, jsonEncode(_pomodoroState.toJson()));
  }

  // ──────────────────────────────────────────────
  // Persistencia
  // ──────────────────────────────────────────────

  Future<void> _saveNotificationSettingsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReminderMinutesKey, _reminderMinutesBefore);
    await prefs.setBool(_kNotifEnabledKey, _notificationsEnabled);
  }

  Future<void> _saveThemeToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeStorageKey, _themeMode.name);
  }

  Future<void> _saveCategoriesToStorage() async {
    await _localDb.saveCategories(_customCategories);
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _customCategories.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_kCategoriesStorageKey, jsonList);
  }

  Future<void> _saveToStorage() async {
    await _localDb.saveTimeBlocks(_blocks);
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _blocks.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList(_kStorageKey, jsonList);
  }

  Future<void> _saveTodosToStorage() async {
    await _localDb.saveTodos(_todoItems);
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _todoItems.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_kTodoStorageKey, jsonList);
  }

  Future<void> _saveGamificationToStorage() async {
    await _localDb.saveGamification(_gamification);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGamificationStorageKey, jsonEncode(_gamification.toJson()));
  }

  Future<void> _saveDeviceCalendarSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDeviceCalSyncEnabledKey, _deviceCalendarSyncEnabled);
    await prefs.setStringList(_kSelectedDeviceCalIdsKey, _selectedDeviceCalendarIds);
  }

  Future<void> _saveLastUserIdToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastUserId == null) {
      await prefs.remove(_kLastUserIdKey);
    } else {
      await prefs.setString(_kLastUserIdKey, _lastUserId!);
    }
  }

  // ──────────────────────────────────────────────
  // Sincronización de Calendarios del Dispositivo
  // ──────────────────────────────────────────────

  /// Carga la lista de calendarios disponibles desde el dispositivo.
  /// Actualiza [calendarPermissionDenied] y [calendarPermissionPermanentlyDenied]
  /// para que la UI pueda dar feedback preciso al usuario.
  Future<List<Calendar>> loadDeviceCalendars() async {
    final result = await _deviceCalService.getCalendars();

    _calendarPermissionDenied = result.permissionDenied;
    _calendarPermissionPermanentlyDenied = result.permissionPermanentlyDenied;
    _availableDeviceCalendars = result.calendars;

    // Si no hay ninguno seleccionado previamente y se encuentran calendarios, seleccionar todos por defecto
    if (_selectedDeviceCalendarIds.isEmpty && _availableDeviceCalendars.isNotEmpty) {
      _selectedDeviceCalendarIds = _availableDeviceCalendars
          .where((c) => c.id != null)
          .map((c) => c.id!)
          .toList();
      await _saveDeviceCalendarSettings();
    }
    notifyListeners();
    return _availableDeviceCalendars;
  }

  /// Activa o desactiva la sincronización con los calendarios del dispositivo.
  Future<void> setDeviceCalendarSyncEnabled(bool enabled) async {
    _deviceCalendarSyncEnabled = enabled;
    await _saveDeviceCalendarSettings();
    if (enabled) {
      await loadDeviceCalendars();
      await syncDeviceCalendarEvents(date: _selectedDate);
    }
    notifyListeners();
  }

  /// Alterna la selección de un calendario por su ID.
  Future<void> toggleDeviceCalendarSelection(String calendarId) async {
    if (_selectedDeviceCalendarIds.contains(calendarId)) {
      _selectedDeviceCalendarIds.remove(calendarId);
    } else {
      _selectedDeviceCalendarIds.add(calendarId);
    }
    await _saveDeviceCalendarSettings();
    if (_deviceCalendarSyncEnabled) {
      await syncDeviceCalendarEvents(date: _selectedDate);
    }
    notifyListeners();
  }

  /// Sincroniza eventos de los calendarios del dispositivo para un rango de fechas (-7 días a +30 días).
  Future<int> syncDeviceCalendarEvents({DateTime? date}) async {
    if (_isDeviceCalendarSyncing) return 0;
    final centerDate = normalizeDate(date ?? _selectedDate);

    // Si la lista de calendarios está vacía, intentar cargarlos
    if (_availableDeviceCalendars.isEmpty) {
      await loadDeviceCalendars();
    }
    if (_selectedDeviceCalendarIds.isEmpty) {
      debugPrint('[ClockProvider] No hay calendarios de dispositivo seleccionados.');
      return 0;
    }

    _isDeviceCalendarSyncing = true;
    notifyListeners();

    try {
      final rangeStart = centerDate.subtract(const Duration(days: 7));
      final rangeEnd = centerDate.add(const Duration(days: 30));

      final namesMap = <String, String>{};
      for (final cal in _availableDeviceCalendars) {
        if (cal.id != null) {
          namesMap[cal.id!] = cal.name ?? 'Calendario';
        }
      }

      final externalBlocks = await _deviceCalService.fetchEventsForRange(
        startDate: rangeStart,
        endDate: rangeEnd,
        calendarIds: _selectedDeviceCalendarIds,
        calendarNames: namesMap,
      );

      debugPrint('[ClockProvider] Sincronizados ${externalBlocks.length} eventos externos.');

      // Eliminar bloques externos previos dentro del rango sincronizado para evitar duplicados o reflejar eliminaciones
      _blocks.removeWhere((b) =>
          b.isExternalCalendar &&
          !b.date.isBefore(rangeStart) &&
          !b.date.isAfter(rangeEnd));

      // Agregar los nuevos bloques sincronizados
      for (final block in externalBlocks) {
        _blocks.add(block);
        _scheduleBlockNotification(block);
      }

      _recalculateAllRings();
      await _saveToStorage();
      return externalBlocks.length;
    } catch (e) {
      debugPrint('[ClockProvider] Error sincronizando eventos de dispositivo: $e');
      return 0;
    } finally {
      _isDeviceCalendarSyncing = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────
  // CRUD de Categorías Personalizadas
  // ──────────────────────────────────────────────

  void addCustomCategory(TaskCategory category) {
    if (_customCategories.any((c) => c.id == category.id)) return;
    _customCategories.add(category);
    _saveCategoriesToStorage();
    _pushCategoryRemote(category);
    notifyListeners();
  }

  void updateCustomCategory(TaskCategory updated) {
    final idx = _customCategories.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _customCategories[idx] = updated;
      _saveCategoriesToStorage();
      _pushCategoryRemote(updated);
      notifyListeners();
    }
  }

  void deleteCustomCategory(String categoryId) {
    _customCategories.removeWhere((c) => c.id == categoryId);
    for (var i = 0; i < _blocks.length; i++) {
      if (_blocks[i].category.id == categoryId) {
        _blocks[i] = _blocks[i].copyWith(category: TaskCategory.none);
        _pushTimeBlockRemote(_blocks[i]);
      }
    }
    for (var i = 0; i < _todoItems.length; i++) {
      if (_todoItems[i].category.id == categoryId) {
        _todoItems[i] = _todoItems[i].copyWith(category: TaskCategory.none);
        _pushTodoRemote(_todoItems[i]);
      }
    }
    _saveToStorage();
    _saveTodosToStorage();
    _saveCategoriesToStorage();
    _deleteCategoryRemote(categoryId);
    notifyListeners();
  }

  Future<void> _loadFromStorage() async {
    // Asegurar que Hive y el detector de conectividad estén listos
    if (!_localDb.isInitialized) {
      await _localDb.init();
    }
    await _connectivity.init();

    final prefs = await SharedPreferences.getInstance();

    // Migración automática y transparente desde SharedPreferences si Hive está vacío
    await _localDb.migrateFromSharedPreferencesIfEmpty(prefs);

    // Cargar último ID de usuario autenticado
    if (prefs.containsKey(_kLastUserIdKey)) {
      _lastUserId = prefs.getString(_kLastUserIdKey);
    }

    // Cargar Modo de Vista (Reloj / Kanban / Pomodoro)
    if (prefs.containsKey(_kViewModeStorageKey)) {
      final savedMode = prefs.getString(_kViewModeStorageKey);
      if (savedMode == AppViewMode.kanban.name) {
        _viewMode = AppViewMode.kanban;
      } else if (savedMode == AppViewMode.pomodoro.name) {
        _viewMode = AppViewMode.pomodoro;
      } else {
        _viewMode = AppViewMode.clock;
      }
    }

    // Cargar Configuración y Estado de Pomodoro
    if (prefs.containsKey(_kPomodoroSettingsKey)) {
      try {
        final raw = prefs.getString(_kPomodoroSettingsKey);
        if (raw != null) {
          _pomodoroSettings = PomodoroSettings.fromJson(jsonDecode(raw));
        }
      } catch (e) {
        debugPrint('[ClockProvider] Error loading Pomodoro settings: $e');
      }
    }
    if (prefs.containsKey(_kPomodoroStateKey)) {
      try {
        final raw = prefs.getString(_kPomodoroStateKey);
        if (raw != null) {
          final loaded = PomodoroSessionState.fromJson(jsonDecode(raw));
          _pomodoroState = loaded.copyWith(
            status: loaded.status.isRunning ? PomodoroStatus.paused : loaded.status,
          );
        }
      } catch (e) {
        debugPrint('[ClockProvider] Error loading Pomodoro state: $e');
      }
    } else {
      _pomodoroState = PomodoroSessionState(
        phase: PomodoroPhase.focus,
        status: PomodoroStatus.idle,
        remainingSeconds: _pomodoroSettings.focusDurationMinutes * 60,
        totalSeconds: _pomodoroSettings.focusDurationMinutes * 60,
      );
    }

    // Cargar Recordatorios Globales
    if (prefs.containsKey(_kReminderMinutesKey)) {
      _reminderMinutesBefore = prefs.getInt(_kReminderMinutesKey) ?? 5;
    }
    if (prefs.containsKey(_kNotifEnabledKey)) {
      _notificationsEnabled = prefs.getBool(_kNotifEnabledKey) ?? true;
    }

    // Cargar Tema
    final savedTheme = prefs.getString(_kThemeStorageKey);
    if (savedTheme != null) {
      if (savedTheme == ThemeMode.light.name) {
        _themeMode = ThemeMode.light;
      } else if (savedTheme == ThemeMode.dark.name) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    }

    // Cargar Idioma
    if (prefs.containsKey(_kLocaleStorageKey)) {
      final langCode = prefs.getString(_kLocaleStorageKey);
      if (langCode != null && langCode.isNotEmpty) {
        _locale = Locale(langCode);
      }
    }

    // 1. Cargar Categorías Personalizadas desde Hive (o fallback a SharedPreferences)
    _customCategories.clear();
    final localCategories = _localDb.getCategories();
    if (localCategories.isNotEmpty) {
      _customCategories.addAll(localCategories);
    } else {
      final catJsonList = prefs.getStringList(_kCategoriesStorageKey) ?? [];
      for (final json in catJsonList) {
        try {
          _customCategories.add(TaskCategory.fromJson(jsonDecode(json)));
        } catch (_) {}
      }
    }

    // 2. Cargar Tareas del Reloj desde Hive (o fallback a SharedPreferences)
    _blocks.clear();
    final localBlocks = _localDb.getTimeBlocks(customCategories: _customCategories);
    if (localBlocks.isNotEmpty) {
      _blocks.addAll(localBlocks);
    } else {
      final jsonList = prefs.getStringList(_kStorageKey) ?? [];
      for (final json in jsonList) {
        try {
          _blocks.add(TimeBlock.fromJson(jsonDecode(json), customCategories: _customCategories));
        } catch (_) {}
      }
    }
    _recalculateAllRings();
    _rescheduleAllNotifications();

    // 3. Cargar Tareas ToDo (Backlog y Notas) desde Hive (o fallback a SharedPreferences)
    _todoItems.clear();
    final localTodos = _localDb.getTodos(customCategories: _customCategories);
    if (localTodos.isNotEmpty) {
      _todoItems.addAll(localTodos);
    } else {
      final todoJsonList = prefs.getStringList(_kTodoStorageKey) ?? [];
      for (final json in todoJsonList) {
        try {
          _todoItems.add(TodoItem.fromJson(jsonDecode(json), customCategories: _customCategories));
        } catch (_) {}
      }
    }

    // 4. Cargar Gamificación y Maestría desde Hive (o fallback a SharedPreferences)
    final localGamification = _localDb.getGamification();
    if (localGamification != null) {
      _gamification = localGamification;
      _evaluateStreakGrace();
    } else if (prefs.containsKey(_kGamificationStorageKey)) {
      try {
        final raw = prefs.getString(_kGamificationStorageKey);
        if (raw != null) {
          _gamification = GamificationData.fromJson(jsonDecode(raw));
          _evaluateStreakGrace();
        }
      } catch (e) {
        debugPrint('[ClockProvider] Error al cargar gamificación: $e');
      }
    }

    // Calcular estadísticas por categoría retroactivamente si aún no existen
    _backfillCategoryStatsFromExistingData();

    // Cargar Configuración de Calendarios del Dispositivo
    if (prefs.containsKey(_kDeviceCalSyncEnabledKey)) {
      _deviceCalendarSyncEnabled = prefs.getBool(_kDeviceCalSyncEnabledKey) ?? false;
    }
    if (prefs.containsKey(_kSelectedDeviceCalIdsKey)) {
      _selectedDeviceCalendarIds = prefs.getStringList(_kSelectedDeviceCalIdsKey) ?? [];
    }
    if (_deviceCalendarSyncEnabled) {
      loadDeviceCalendars().then((_) {
        syncDeviceCalendarEvents(date: _selectedDate);
      });
    }

    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Motor de Gamificación y Maestría
  // ──────────────────────────────────────────────

  /// Evalúa si el usuario mantuvo la racha, la perdió o salvó un día usando Streak Freeze.
  void _evaluateStreakGrace() {
    if (_gamification.lastActiveDate == null || _gamification.currentStreak == 0) return;
    final today = normalizeDate(_now);
    final last = normalizeDate(_gamification.lastActiveDate!);
    final diffDays = today.difference(last).inDays;

    if (diffDays == 0 || diffDays == 1) {
      // Racha activa y en orden
      return;
    }

    if (diffDays == 2 && _gamification.streakFreezeCount > 0) {
      // Se saltó exactamente ayer, pero contaba con un escudo de racha
      _gamification = _gamification.copyWith(
        streakFreezeCount: _gamification.streakFreezeCount - 1,
        lastActiveDate: today.subtract(const Duration(days: 1)),
      );
      _gamificationToast = 'freeze_used';
      _saveGamificationToStorage();
      _pushGamificationRemote();
    } else if (diffDays > 1) {
      // Racha rota por inactividad
      _gamification = _gamification.copyWith(currentStreak: 0);
      _saveGamificationToStorage();
      _pushGamificationRemote();
    }
  }

  /// Calcula retroactivamente las estadísticas por categoría a partir de bloques y notas existentes.
  void _backfillCategoryStatsFromExistingData() {
    if (_gamification.categoryCompletedTasks.isNotEmpty) return;

    final catTasks = <String, int>{};
    final catMins = <String, int>{};

    for (final b in _blocks) {
      if (b.status == TaskStatus.completed) {
        final catId = b.category.id;
        catTasks[catId] = (catTasks[catId] ?? 0) + 1;
        final mins = (b.durationHours.abs() * 60).round().clamp(1, 1440);
        catMins[catId] = (catMins[catId] ?? 0) + mins;
      }
    }

    for (final t in _todoItems) {
      if (t.isCompleted) {
        final catId = t.category.id;
        catTasks[catId] = (catTasks[catId] ?? 0) + 1;
      }
    }

    if (catTasks.isNotEmpty || catMins.isNotEmpty) {
      _gamification = _gamification.copyWith(
        categoryCompletedTasks: catTasks,
        categoryFocusMinutes: catMins,
      );
      _evaluateAchievements();
      _saveGamificationToStorage();
      _pushGamificationRemote();
    }
  }

  /// Procesa la finalización de un bloque de tiempo (Ticks, Racha, Nivel, Logros y Categorías).
  void _onTaskCompleted(TimeBlock block) {
    final today = normalizeDate(_now);
    int ticksEarned = 25; // Base por bloque completado

    // Bono Madrugador (+10 ticks si se completa antes de las 8:00 AM)
    if (_now.hour < 8) {
      ticksEarned += 10;
    }

    // Duración de enfoque estimada
    final durationMinutes = (block.durationHours.abs() * 60).round().clamp(1, 1440);

    // Actualización de Racha
    int newStreak = _gamification.currentStreak;
    int newBestStreak = _gamification.bestStreak;
    DateTime? last = _gamification.lastActiveDate != null
        ? normalizeDate(_gamification.lastActiveDate!)
        : null;

    if (last == null) {
      newStreak = 1;
    } else {
      final diffDays = today.difference(last).inDays;
      if (diffDays == 0) {
        // Mismo día: racha ya contada para hoy
      } else if (diffDays == 1) {
        // Día consecutivo directo
        newStreak += 1;
      } else if (diffDays == 2 && _gamification.streakFreezeCount > 0) {
        // Día rescatado con Streak Freeze
        newStreak += 1;
        _gamification = _gamification.copyWith(
          streakFreezeCount: _gamification.streakFreezeCount - 1,
        );
        _gamificationToast = 'freeze_used';
      } else {
        // Racha reiniciada
        newStreak = 1;
      }
    }

    if (newStreak > newBestStreak) {
      newBestStreak = newStreak;
    }

    final oldLevel = _gamification.currentLevel;
    final newTicks = _gamification.ticks + ticksEarned;
    final newTotalTasks = _gamification.totalCompletedTasks + 1;
    final newTotalMinutes = _gamification.totalFocusMinutes + durationMinutes;

    // Actualización de estadísticas por categoría
    final catId = block.category.id;
    final updatedCategoryTasks = Map<String, int>.from(_gamification.categoryCompletedTasks);
    updatedCategoryTasks[catId] = (updatedCategoryTasks[catId] ?? 0) + 1;

    final updatedCategoryMinutes = Map<String, int>.from(_gamification.categoryFocusMinutes);
    updatedCategoryMinutes[catId] = (updatedCategoryMinutes[catId] ?? 0) + durationMinutes;

    _gamification = _gamification.copyWith(
      ticks: newTicks,
      currentStreak: newStreak,
      bestStreak: newBestStreak,
      lastActiveDate: today,
      totalCompletedTasks: newTotalTasks,
      totalFocusMinutes: newTotalMinutes,
      categoryCompletedTasks: updatedCategoryTasks,
      categoryFocusMinutes: updatedCategoryMinutes,
    );

    // Verificar si subió de nivel
    final newLevel = _gamification.currentLevel;
    if (newLevel.level > oldLevel.level) {
      _latestLevelUp = newLevel;
    }

    // Evaluar catálogo de logros generales y de categorías
    _evaluateAchievements(triggerBlock: block);

    _saveGamificationToStorage();
    _pushGamificationRemote();
  }

  /// Procesa la finalización de una tarea ToDo del backlog (+15 Ticks).
  void _onTodoCompleted(TodoItem item) {
    final oldLevel = _gamification.currentLevel;
    final newTicks = _gamification.ticks + 15;

    // Actualización de estadísticas por categoría para el ToDo
    final catId = item.category.id;
    final updatedCategoryTasks = Map<String, int>.from(_gamification.categoryCompletedTasks);
    updatedCategoryTasks[catId] = (updatedCategoryTasks[catId] ?? 0) + 1;

    _gamification = _gamification.copyWith(
      ticks: newTicks,
      categoryCompletedTasks: updatedCategoryTasks,
    );

    final newLevel = _gamification.currentLevel;
    if (newLevel.level > oldLevel.level) {
      _latestLevelUp = newLevel;
    }

    // Logro Mesa Limpia: 5 tareas ToDo completadas
    final completedTodosCount = _todoItems.where((t) => t.isCompleted).length;
    if (completedTodosCount >= 5) {
      _unlockAchievement('clean_slate');
    }

    // Evaluar logros de categoría
    _evaluateCategoryAchievements();

    _saveGamificationToStorage();
    _pushGamificationRemote();
  }

  /// Desbloquea un logro específico si aún no ha sido obtenido.
  void _unlockAchievement(String achievementId) {
    if (_gamification.unlockedAchievements.containsKey(achievementId)) return;
    final ach = Achievement.catalog.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => Achievement.catalog.first,
    );
    final updatedMap = Map<String, DateTime>.from(_gamification.unlockedAchievements);
    final nowUtc = DateTime.now().toUtc();
    updatedMap[achievementId] = nowUtc;

    final oldLevel = _gamification.currentLevel;
    final newTicks = _gamification.ticks + ach.pointsReward;

    _gamification = _gamification.copyWith(
      ticks: newTicks,
      unlockedAchievements: updatedMap,
    );

    final newLevel = _gamification.currentLevel;
    if (newLevel.level > oldLevel.level) {
      _latestLevelUp = newLevel;
    }

    _latestUnlockedAchievement = ach.copyWith(unlockedAt: nowUtc);
  }

  /// Evalúa las condiciones para cada uno de los logros disponibles.
  void _evaluateAchievements({TimeBlock? triggerBlock}) {
    // 1. Primer Paso
    if (_gamification.totalCompletedTasks >= 1) {
      _unlockAchievement('first_step');
    }

    // 2. Madrugador (< 8:00 AM)
    if (_now.hour < 8) {
      _unlockAchievement('early_bird');
    }

    // 3. Búho Nocturno (>= 21:00 / 9:00 PM)
    if (_now.hour >= 21) {
      _unlockAchievement('night_owl');
    }

    // 4. Enfoque Constante (10 bloques)
    if (_gamification.totalCompletedTasks >= 10) {
      _unlockAchievement('task_master_10');
    }

    // 5. Maestro de la Rutina (50 bloques)
    if (_gamification.totalCompletedTasks >= 50) {
      _unlockAchievement('task_master_50');
    }

    // 6. Racha de 3 días
    if (_gamification.currentStreak >= 3) {
      _unlockAchievement('streak_3');
    }

    // 7. Racha de 7 días
    if (_gamification.currentStreak >= 7) {
      _unlockAchievement('streak_7');
    }

    // 8. Día Dorado (Golden Dial: 80%+ de tareas del día con al menos 3 bloques)
    final dayBlocks = selectedDateBlocks;
    if (dayBlocks.length >= 3) {
      final completed = dayBlocks.where((b) => b.status == TaskStatus.completed).length;
      if ((completed / dayBlocks.length) >= 0.8) {
        _unlockAchievement('golden_dial');
      }
    }

    // 9. Vida Equilibrada: bloques completados de al menos 3 categorías distintas hoy
    final todayBlocks = blocksForDate(normalizeDate(_now));
    final completedCats = todayBlocks
        .where((b) => b.status == TaskStatus.completed)
        .map((b) => b.category.id)
        .toSet();
    if (completedCats.length >= 3) {
      _unlockAchievement('balanced_life');
    }

    // 10. Recompensas por Categoría y Sinergia
    _evaluateCategoryAchievements();

    // 11. Logros de Pomodoro
    if (_gamification.totalPomodoroSessions >= 1) {
      _unlockAchievement('pomodoro_first');
    }
    if (_pomodoroState.totalPomodorosToday >= 4) {
      _unlockAchievement('pomodoro_master_4');
    }
    if (_gamification.totalPomodoroSessions >= 10) {
      _unlockAchievement('pomodoro_zen_10');
    }
  }

  /// Evalúa logros específicos basados en tareas completadas por categoría y sinergia
  void _evaluateCategoryAchievements() {
    for (final ach in Achievement.catalog) {
      if (ach.categoryId != null && ach.targetCount != null) {
        final count = _gamification.getCompletedCountForCategory(ach.categoryId!);
        if (count >= ach.targetCount!) {
          _unlockAchievement(ach.id);
        }
      }
    }

    // Sinergia Multicategoría (Polímata Integral: al menos 10 tareas en 4 categorías distintas)
    int categoriesWith10OrMore = 0;
    _gamification.categoryCompletedTasks.forEach((_, count) {
      if (count >= 10) {
        categoriesWith10OrMore++;
      }
    });
    if (categoriesWith10OrMore >= 4) {
      _unlockAchievement('category_polymath');
    }
  }

  bool _isDisposed = false;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _clockTimer?.cancel();
    _pomodoroTimer?.cancel();
    _authSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }
}
