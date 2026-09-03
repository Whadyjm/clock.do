import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_block.dart';
import '../models/task_category.dart';
import '../models/todo_item.dart';
import '../services/notification_service.dart';

const _kStorageKey = 'clockdo_tasks';
const _kTodoStorageKey = 'clockdo_todos';
const _kThemeStorageKey = 'clockdo_theme_mode';
const _kReminderMinutesKey = 'clockdo_reminder_minutes';
const _kNotifEnabledKey = 'clockdo_notif_enabled';

/// Estado global de la aplicación ClockDo con soporte de recordatorios globales, temas, calendario y tareas ToDo.
class ClockProvider extends ChangeNotifier {
  final List<TimeBlock> _blocks = [];
  final List<TodoItem> _todoItems = [];
  bool _is24h = false;
  ThemeMode _themeMode = ThemeMode.system;
  DateTime _now = DateTime.now();
  DateTime _selectedDate = normalizeDate(DateTime.now());
  Timer? _clockTimer;

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
    final dayBlocks = _blocks.where((b) => b.isOnDay(_selectedDate)).toList();
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

  DateTime get now => _now;

  DateTime get selectedDate => _selectedDate;

  int get reminderMinutesBefore => _reminderMinutesBefore;

  bool get notificationsEnabled => _notificationsEnabled;

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
  // Inicialización
  // ──────────────────────────────────────────────

  ClockProvider() {
    _startClock();
    _initAndLoad();
  }

  /// Inicializa notificaciones y luego carga datos en orden garantizado.
  Future<void> _initAndLoad() async {
    await _initNotifications();
    await _loadFromStorage();
  }

  /// Inicializa el servicio de notificaciones y solicita permisos.
  Future<void> _initNotifications() async {
    await _notifService.init();
    // Solicitar permisos de forma no-bloqueante (el usuario puede rechazar)
    _notifService.requestPermissions().then((granted) {
      debugPrint('[ClockProvider] Notification permission granted: $granted');
    });
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

  void _rescheduleAllNotifications() {
    if (!_notificationsEnabled) return;
    for (final block in _blocks) {
      _notifService.scheduleTaskReminder(
        block: block,
        minutesBefore: _reminderMinutesBefore,
        enabled: _notificationsEnabled,
      );
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
  // Navegación de Calendario
  // ──────────────────────────────────────────────

  void selectDate(DateTime date) {
    _selectedDate = normalizeDate(date);
    notifyListeners();
  }

  void jumpToToday() {
    _selectedDate = normalizeDate(DateTime.now());
    notifyListeners();
  }

  void nextDay() {
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    notifyListeners();
  }

  void previousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
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
  // CRUD de bloques
  // ──────────────────────────────────────────────

  void addBlock(TimeBlock block) {
    _blocks.add(block);
    _recalculateAllRings();
    _saveToStorage();
    _notifService.scheduleTaskReminder(
      block: block,
      minutesBefore: _reminderMinutesBefore,
      enabled: _notificationsEnabled,
    );
    notifyListeners();
  }

  void updateBlock(TimeBlock updated) {
    final idx = _blocks.indexWhere((b) => b.id == updated.id);
    if (idx != -1) {
      _blocks[idx] = updated;
      _recalculateAllRings();
      _saveToStorage();
      _notifService.scheduleTaskReminder(
        block: updated,
        minutesBefore: _reminderMinutesBefore,
        enabled: _notificationsEnabled,
      );
      notifyListeners();
    }
  }

  void deleteBlock(String id) {
    _blocks.removeWhere((b) => b.id == id);
    _recalculateAllRings();
    _saveToStorage();
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

    if (nextStatus == TaskStatus.completed) {
      _notifService.cancelTaskReminder(id);
    } else {
      _notifService.scheduleTaskReminder(
        block: updated,
        minutesBefore: _reminderMinutesBefore,
        enabled: _notificationsEnabled,
      );
    }
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // CRUD de Tareas ToDo (Backlog)
  // ──────────────────────────────────────────────

  void addTodo(TodoItem item) {
    _todoItems.insert(0, item); // Las más recientes arriba
    _saveTodosToStorage();
    notifyListeners();
  }

  void updateTodo(TodoItem updated) {
    final idx = _todoItems.indexWhere((t) => t.id == updated.id);
    if (idx != -1) {
      _todoItems[idx] = updated;
      _saveTodosToStorage();
      notifyListeners();
    }
  }

  void toggleTodo(String id) {
    final idx = _todoItems.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final item = _todoItems[idx];
    final nextCompleted = !item.isCompleted;
    _todoItems[idx] = item.copyWith(
      isCompleted: nextCompleted,
      completedAt: nextCompleted ? DateTime.now() : null,
      clearCompletedAt: !nextCompleted,
    );
    _saveTodosToStorage();
    notifyListeners();
  }

  void deleteTodo(String id) {
    _todoItems.removeWhere((t) => t.id == id);
    _saveTodosToStorage();
    notifyListeners();
  }

  void clearCompletedTodos() {
    _todoItems.removeWhere((t) => t.isCompleted);
    _saveTodosToStorage();
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
      _todoItems[idx] = todo.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      _saveTodosToStorage();
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

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

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

    // Cargar Tareas del Reloj
    final jsonList = prefs.getStringList(_kStorageKey) ?? [];
    _blocks.clear();
    for (final json in jsonList) {
      try {
        _blocks.add(TimeBlock.fromJson(jsonDecode(json)));
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
        _todoItems.add(TodoItem.fromJson(jsonDecode(json)));
      } catch (_) {
        // Ignorar items corruptos
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }
}
