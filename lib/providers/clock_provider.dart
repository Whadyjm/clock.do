import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_block.dart';
import '../models/task_category.dart';
import '../models/todo_item.dart';
import '../models/gamification_data.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../services/device_calendar_service.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';

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

/// Modos de visualización principal de la aplicación.
enum AppViewMode {
  clock,
  kanban;

  String getLocalizedName(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case AppViewMode.clock:
        return l10n.clockView;
      case AppViewMode.kanban:
        return l10n.kanbanView;
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

  /// Inicializa notificaciones, carga datos del disco, y luego inicia el listener
  /// de Supabase en orden garantizado. Esto evita que syncWithCloud() se ejecute
  /// con _blocks y _todoItems vacíos antes de que se hayan cargado desde SharedPreferences.
  Future<void> _initAndLoad() async {
    await _initNotifications();
    await _loadFromStorage();
    // El listener de Supabase se inicia solo DESPUÉS de que los datos locales
    // ya están en memoria, garantizando que syncWithCloud() siempre verá los datos correctos.
    _initSupabaseListener();
  }

  /// Inicializa el servicio de notificaciones y solicita permisos.
  Future<void> _initNotifications() async {
    await _notifService.init();
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

  /// Programa o cancela la notificación de un bloque respetando su configuración individual y la global.
  void _scheduleBlockNotification(TimeBlock block) {
    if (!_notificationsEnabled || !block.notificationEnabled) {
      _notifService.cancelTaskReminder(block.id);
      _notifService.cancelIntervalReminders(block.id);
      return;
    }
    _notifService.scheduleTaskReminder(
      block: block,
      minutesBefore: effectiveReminderMinutes(block),
      enabled: true,
    );
    if (block.hasIntervalReminder) {
      _notifService.scheduleIntervalReminders(
        block: block,
        enabled: true,
      );
    } else {
      _notifService.cancelIntervalReminders(block.id);
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

  /// Sincroniza bloques y tareas ToDo con Supabase.
  Future<void> syncWithCloud() async {
    if (!_supabase.isAuthenticated || _isCloudSyncing) return;

    _isCloudSyncing = true;
    notifyListeners();

    try {
      // 0. Sincronizar categorías personalizadas
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

      // 1. Sincronizar bloques de tiempo
      // Subir todos los bloques locales que no pertenezcan al calendario externo
      for (final localBlock in _blocks) {
        if (!localBlock.isExternalCalendar) {
          await _supabase.upsertTimeBlock(localBlock);
        }
      }

      // Descargar bloques de la nube
      final cloudBlocks = await _supabase.fetchTimeBlocks();

      // Combinar: Mantener locales y externos (más recientes), e incorporar bloques de la nube
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

      // 2. Sincronizar tareas ToDo
      // Subir todas las tareas locales a la nube
      for (final localTodo in _todoItems) {
        await _supabase.upsertTodo(localTodo);
      }

      // Descargar tareas de la nube
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

      // 3. Sincronizar Gamificación
      final cloudGamification = await _supabase.fetchGamification();
      if (cloudGamification != null) {
        if (_gamification.ticks == 0 &&
            _gamification.totalCompletedTasks == 0 &&
            _gamification.unlockedAchievements.isEmpty) {
          _gamification = cloudGamification;
        } else {
          final mergedAchievements = Map<String, DateTime>.from(_gamification.unlockedAchievements);
          cloudGamification.unlockedAchievements.forEach((k, v) {
            if (!mergedAchievements.containsKey(k) || v.isBefore(mergedAchievements[k]!)) {
              mergedAchievements[k] = v;
            }
          });

          _gamification = _gamification.copyWith(
            ticks: _gamification.ticks > cloudGamification.ticks ? _gamification.ticks : cloudGamification.ticks,
            currentStreak: _gamification.currentStreak > cloudGamification.currentStreak ? _gamification.currentStreak : cloudGamification.currentStreak,
            bestStreak: _gamification.bestStreak > cloudGamification.bestStreak ? _gamification.bestStreak : cloudGamification.bestStreak,
            streakFreezeCount: _gamification.streakFreezeCount > cloudGamification.streakFreezeCount ? _gamification.streakFreezeCount : cloudGamification.streakFreezeCount,
            totalCompletedTasks: _gamification.totalCompletedTasks > cloudGamification.totalCompletedTasks ? _gamification.totalCompletedTasks : cloudGamification.totalCompletedTasks,
            totalFocusMinutes: _gamification.totalFocusMinutes > cloudGamification.totalFocusMinutes ? _gamification.totalFocusMinutes : cloudGamification.totalFocusMinutes,
            unlockedAchievements: mergedAchievements,
            lastActiveDate: _gamification.lastActiveDate ?? cloudGamification.lastActiveDate,
          );
        }
      }
      await _saveGamificationToStorage();
      await _supabase.upsertGamification(_gamification);
    } catch (e) {
      debugPrint('[ClockProvider] Error al sincronizar con la nube: $e');
    } finally {
      _isCloudSyncing = false;
      notifyListeners();
    }
  }

  /// Cierra sesión en Supabase y limpia todas las tareas y datos del usuario de la UI y del almacenamiento local.
  Future<void> signOut() async {
    // 1. Intentar sincronizar datos pendientes con la nube antes de salir
    if (_supabase.isAuthenticated) {
      try {
        await syncWithCloud();
      } catch (e) {
        debugPrint('[ClockProvider] Error al sincronizar antes de cerrar sesión: $e');
      }
    }

    // 2. Cerrar sesión en el cliente de Supabase
    await _supabase.signOut();

    // 3. Limpiar los datos del usuario de memoria y de SharedPreferences
    await clearUserData();
  }

  /// Limpia las tareas, bloques, notas ToDo, categorías personalizadas y datos de gamificación
  /// asociados al usuario que cerró sesión, manteniendo intactos los calendarios nativos del dispositivo
  /// y las preferencias de la app (tema, idioma).
  Future<void> clearUserData() async {
    _lastUserId = null;
    await _saveLastUserIdToStorage();

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
  // CRUD de bloques
  // ──────────────────────────────────────────────

  void addBlock(TimeBlock block) {
    _blocks.add(block);
    _recalculateAllRings();
    _saveToStorage();
    _supabase.upsertTimeBlock(block);
    _scheduleBlockNotification(block);
    notifyListeners();
  }

  void updateBlock(TimeBlock updated) {
    final idx = _blocks.indexWhere((b) => b.id == updated.id);
    if (idx != -1) {
      _blocks[idx] = updated;
      _recalculateAllRings();
      _saveToStorage();
      _supabase.upsertTimeBlock(updated);
      _scheduleBlockNotification(updated);
      notifyListeners();
    }
  }

  void deleteBlock(String id) {
    _blocks.removeWhere((b) => b.id == id);
    _recalculateAllRings();
    _saveToStorage();
    _supabase.deleteTimeBlock(id);
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
    _supabase.upsertTimeBlock(updated);

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
    _supabase.upsertTimeBlock(updated);

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
    _supabase.deleteTodo(todoId);

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
    _supabase.deleteTimeBlock(blockId);
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
    _supabase.upsertTodo(todo);
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // CRUD de Tareas ToDo (Backlog)
  // ──────────────────────────────────────────────

  void addTodo(TodoItem item) {
    _todoItems.insert(0, item); // Las más recientes arriba
    _saveTodosToStorage();
    _supabase.upsertTodo(item);
    notifyListeners();
  }

  void updateTodo(TodoItem updated) {
    final idx = _todoItems.indexWhere((t) => t.id == updated.id);
    if (idx != -1) {
      _todoItems[idx] = updated;
      _saveTodosToStorage();
      _supabase.upsertTodo(updated);
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
    _supabase.upsertTodo(updated);
    if (nextCompleted) {
      _onTodoCompleted(updated);
    }
    notifyListeners();
  }

  void deleteTodo(String id) {
    _todoItems.removeWhere((t) => t.id == id);
    _saveTodosToStorage();
    _supabase.deleteTodo(id);
    notifyListeners();
  }

  void clearCompletedTodos() {
    final completed = _todoItems.where((t) => t.isCompleted).toList();
    _todoItems.removeWhere((t) => t.isCompleted);
    _saveTodosToStorage();
    for (final item in completed) {
      _supabase.deleteTodo(item.id);
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
      _supabase.upsertTodo(updatedTodo);
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
  // Modo de Vista (Reloj / Kanban)
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
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _customCategories.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_kCategoriesStorageKey, jsonList);
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _blocks.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList(_kStorageKey, jsonList);
  }

  Future<void> _saveTodosToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _todoItems.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_kTodoStorageKey, jsonList);
  }

  Future<void> _saveGamificationToStorage() async {
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
    _supabase.upsertCategory(category);
    notifyListeners();
  }

  void updateCustomCategory(TaskCategory updated) {
    final idx = _customCategories.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _customCategories[idx] = updated;
      _saveCategoriesToStorage();
      _supabase.upsertCategory(updated);
      notifyListeners();
    }
  }

  void deleteCustomCategory(String categoryId) {
    _customCategories.removeWhere((c) => c.id == categoryId);
    for (var i = 0; i < _blocks.length; i++) {
      if (_blocks[i].category.id == categoryId) {
        _blocks[i] = _blocks[i].copyWith(category: TaskCategory.none);
        _supabase.upsertTimeBlock(_blocks[i]);
      }
    }
    for (var i = 0; i < _todoItems.length; i++) {
      if (_todoItems[i].category.id == categoryId) {
        _todoItems[i] = _todoItems[i].copyWith(category: TaskCategory.none);
        _supabase.upsertTodo(_todoItems[i]);
      }
    }
    _saveToStorage();
    _saveTodosToStorage();
    _saveCategoriesToStorage();
    _supabase.deleteCategory(categoryId);
    notifyListeners();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // Cargar último ID de usuario autenticado
    if (prefs.containsKey(_kLastUserIdKey)) {
      _lastUserId = prefs.getString(_kLastUserIdKey);
    }

    // Cargar Modo de Vista (Reloj / Kanban)
    if (prefs.containsKey(_kViewModeStorageKey)) {
      final savedMode = prefs.getString(_kViewModeStorageKey);
      if (savedMode == AppViewMode.kanban.name) {
        _viewMode = AppViewMode.kanban;
      } else {
        _viewMode = AppViewMode.clock;
      }
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

    // Cargar Categorías Personalizadas primero (para que estén disponibles al deserializar bloques y todos)
    final catJsonList = prefs.getStringList(_kCategoriesStorageKey) ?? [];
    _customCategories.clear();
    for (final json in catJsonList) {
      try {
        _customCategories.add(TaskCategory.fromJson(jsonDecode(json)));
      } catch (_) {
        // Ignorar categorías corruptas
      }
    }

    // Cargar Tareas del Reloj
    final jsonList = prefs.getStringList(_kStorageKey) ?? [];
    _blocks.clear();
    for (final json in jsonList) {
      try {
        _blocks.add(TimeBlock.fromJson(jsonDecode(json), customCategories: _customCategories));
      } catch (_) {
        // Ignorar bloques corruptos
      }
    }
    _recalculateAllRings();
    _rescheduleAllNotifications();

    // Cargar Tareas ToDo (Backlog)
    final todoJsonList = prefs.getStringList(_kTodoStorageKey) ?? [];
    _todoItems.clear();
    for (final json in todoJsonList) {
      try {
        _todoItems.add(TodoItem.fromJson(jsonDecode(json), customCategories: _customCategories));
      } catch (_) {
        // Ignorar items corruptos
      }
    }

    // Cargar Gamificación y Maestría
    if (prefs.containsKey(_kGamificationStorageKey)) {
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
      _supabase.upsertGamification(_gamification);
    } else if (diffDays > 1) {
      // Racha rota por inactividad
      _gamification = _gamification.copyWith(currentStreak: 0);
      _saveGamificationToStorage();
      _supabase.upsertGamification(_gamification);
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
      _supabase.upsertGamification(_gamification);
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
    _supabase.upsertGamification(_gamification);
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
    _supabase.upsertGamification(_gamification);
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
    _authSub?.cancel();
    super.dispose();
  }
}
