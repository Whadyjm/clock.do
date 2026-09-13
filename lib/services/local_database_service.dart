import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_block.dart';
import '../models/todo_item.dart';
import '../models/task_category.dart';
import '../models/gamification_data.dart';
import '../models/sync_action.dart';

/// Servicio de Base de Datos Local de alto rendimiento con Hive.
/// Garantiza la persistencia inmediata de bloques, tareas ToDo, notas,
/// categorías y estado de gamificación, además de gestionar la cola de sincronización offline.
class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static const String _kBlocksBox = 'clockdo_time_blocks_box';
  static const String _kTodosBox = 'clockdo_todos_box';
  static const String _kCategoriesBox = 'clockdo_categories_box';
  static const String _kGamificationBox = 'clockdo_gamification_box';
  static const String _kSyncQueueBox = 'clockdo_sync_queue_box';

  late Box<String> _blocksBox;
  late Box<String> _todosBox;
  late Box<String> _categoriesBox;
  late Box<String> _gamificationBox;
  late Box<String> _syncQueueBox;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Inicializa Hive y abre todas las boxes necesarias.
  /// En entorno de tests, permite pasar un [customPath] para inicializar sin plugins nativos de path_provider.
  Future<void> init([String? customPath]) async {
    if (_initialized) return;

    try {
      if (customPath != null) {
        Hive.init(customPath);
      } else {
        await Hive.initFlutter();
      }
      _blocksBox = await Hive.openBox<String>(_kBlocksBox);
      _todosBox = await Hive.openBox<String>(_kTodosBox);
      _categoriesBox = await Hive.openBox<String>(_kCategoriesBox);
      _gamificationBox = await Hive.openBox<String>(_kGamificationBox);
      _syncQueueBox = await Hive.openBox<String>(_kSyncQueueBox);

      _initialized = true;
      debugPrint('[LocalDatabaseService] Hive inicializado correctamente.');
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error al inicializar Hive: $e');
    }
  }

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
  }

  // ──────────────────────────────────────────────
  // Migración transparente desde SharedPreferences
  // ──────────────────────────────────────────────

  /// Si las boxes de Hive están vacías tras una actualización, importa automáticamente
  /// las tareas y datos preexistentes en SharedPreferences para garantizar que el usuario no pierda nada.
  Future<void> migrateFromSharedPreferencesIfEmpty(SharedPreferences prefs) async {
    if (!_initialized) return;

    // 1. Migrar Categorías
    if (_categoriesBox.isEmpty && prefs.containsKey('clockdo_custom_categories')) {
      final list = prefs.getStringList('clockdo_custom_categories') ?? [];
      for (final raw in list) {
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          final id = json['id'] as String;
          await _categoriesBox.put(id, raw);
        } catch (_) {}
      }
      debugPrint('[LocalDatabaseService] Migradas ${_categoriesBox.length} categorías desde SharedPreferences.');
    }

    // 2. Migrar Bloques de Tiempo
    if (_blocksBox.isEmpty && prefs.containsKey('clockdo_tasks')) {
      final list = prefs.getStringList('clockdo_tasks') ?? [];
      for (final raw in list) {
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          final id = json['id'] as String;
          await _blocksBox.put(id, raw);
        } catch (_) {}
      }
      debugPrint('[LocalDatabaseService] Migrados ${_blocksBox.length} bloques desde SharedPreferences.');
    }

    // 3. Migrar Tareas ToDo / Notas
    if (_todosBox.isEmpty && prefs.containsKey('clockdo_todos')) {
      final list = prefs.getStringList('clockdo_todos') ?? [];
      for (final raw in list) {
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          final id = json['id'] as String;
          await _todosBox.put(id, raw);
        } catch (_) {}
      }
      debugPrint('[LocalDatabaseService] Migrados ${_todosBox.length} todos desde SharedPreferences.');
    }

    // 4. Migrar Gamificación
    if (_gamificationBox.isEmpty && prefs.containsKey('clockdo_gamification')) {
      final raw = prefs.getString('clockdo_gamification');
      if (raw != null && raw.isNotEmpty) {
        await _gamificationBox.put('current', raw);
        debugPrint('[LocalDatabaseService] Gamificación migrada desde SharedPreferences.');
      }
    }
  }

  // ──────────────────────────────────────────────
  // Bloques de Tiempo (TimeBlocks)
  // ──────────────────────────────────────────────

  /// Guarda o actualiza un bloque de tiempo localmente
  Future<void> saveTimeBlock(TimeBlock block) async {
    if (!_initialized || !_blocksBox.isOpen) return;
    await _blocksBox.put(block.id, jsonEncode(block.toJson()));
  }

  /// Guarda una lista de bloques en lote y elimina las claves que ya no existan
  Future<void> saveTimeBlocks(List<TimeBlock> blocks) async {
    if (!_initialized || !_blocksBox.isOpen) return;
    final validIds = blocks.map((b) => b.id).toSet();
    final keysToRemove =
        _blocksBox.keys.where((k) => !validIds.contains(k)).toList();
    if (keysToRemove.isNotEmpty) {
      await _blocksBox.deleteAll(keysToRemove);
    }
    if (!_blocksBox.isOpen) return;
    final entries = <String, String>{};
    for (final b in blocks) {
      entries[b.id] = jsonEncode(b.toJson());
    }
    if (entries.isNotEmpty) {
      await _blocksBox.putAll(entries);
    }
  }

  /// Obtiene todos los bloques de tiempo guardados
  List<TimeBlock> getTimeBlocks({List<TaskCategory> customCategories = const []}) {
    if (!_initialized || !_blocksBox.isOpen) return [];
    final list = <TimeBlock>[];
    for (final raw in _blocksBox.values) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        list.add(TimeBlock.fromJson(json, customCategories: customCategories));
      } catch (e) {
        debugPrint('[LocalDatabaseService] Error parseando bloque: $e');
      }
    }
    return list;
  }

  /// Elimina un bloque de tiempo por ID
  Future<void> deleteTimeBlock(String id) async {
    if (!_initialized || !_blocksBox.isOpen) return;
    await _blocksBox.delete(id);
  }

  /// Elimina todos los bloques que coincidan con la condición
  Future<void> deleteTimeBlocksWhere(bool Function(TimeBlock) predicate,
      {List<TaskCategory> customCategories = const []}) async {
    if (!_initialized || !_blocksBox.isOpen) return;
    final keysToDelete = <String>[];
    for (final key in _blocksBox.keys) {
      final raw = _blocksBox.get(key);
      if (raw != null) {
        try {
          final block = TimeBlock.fromJson(jsonDecode(raw), customCategories: customCategories);
          if (predicate(block)) {
            keysToDelete.add(key as String);
          }
        } catch (_) {}
      }
    }
    if (_blocksBox.isOpen && keysToDelete.isNotEmpty) {
      await _blocksBox.deleteAll(keysToDelete);
    }
  }

  // ──────────────────────────────────────────────
  // Tareas ToDo y Notas (Todos)
  // ──────────────────────────────────────────────

  /// Guarda o actualiza una tarea ToDo / Nota localmente
  Future<void> saveTodo(TodoItem item) async {
    if (!_initialized || !_todosBox.isOpen) return;
    await _todosBox.put(item.id, jsonEncode(item.toJson()));
  }

  /// Guarda una lista de tareas ToDo en lote y elimina las claves que ya no existan
  Future<void> saveTodos(List<TodoItem> items) async {
    if (!_initialized || !_todosBox.isOpen) return;
    final validIds = items.map((t) => t.id).toSet();
    final keysToRemove =
        _todosBox.keys.where((k) => !validIds.contains(k)).toList();
    if (keysToRemove.isNotEmpty) {
      await _todosBox.deleteAll(keysToRemove);
    }
    if (!_todosBox.isOpen) return;
    final entries = <String, String>{};
    for (final t in items) {
      entries[t.id] = jsonEncode(t.toJson());
    }
    if (entries.isNotEmpty) {
      await _todosBox.putAll(entries);
    }
  }

  /// Obtiene todas las tareas ToDo guardadas
  List<TodoItem> getTodos({List<TaskCategory> customCategories = const []}) {
    if (!_initialized || !_todosBox.isOpen) return [];
    final list = <TodoItem>[];
    for (final raw in _todosBox.values) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        list.add(TodoItem.fromJson(json, customCategories: customCategories));
      } catch (e) {
        debugPrint('[LocalDatabaseService] Error parseando todo: $e');
      }
    }
    return list;
  }

  /// Elimina una tarea ToDo por ID
  Future<void> deleteTodo(String id) async {
    if (!_initialized || !_todosBox.isOpen) return;
    await _todosBox.delete(id);
  }

  // ──────────────────────────────────────────────
  // Categorías Personalizadas
  // ──────────────────────────────────────────────

  /// Guarda o actualiza una categoría personalizada
  Future<void> saveCategory(TaskCategory category) async {
    if (!_initialized || !_categoriesBox.isOpen) return;
    await _categoriesBox.put(category.id, jsonEncode(category.toJson()));
  }

  /// Guarda una lista de categorías en lote y elimina las claves que ya no existan
  Future<void> saveCategories(List<TaskCategory> categories) async {
    if (!_initialized || !_categoriesBox.isOpen) return;
    final validIds = categories.map((c) => c.id).toSet();
    final keysToRemove =
        _categoriesBox.keys.where((k) => !validIds.contains(k)).toList();
    if (keysToRemove.isNotEmpty) {
      await _categoriesBox.deleteAll(keysToRemove);
    }
    if (!_categoriesBox.isOpen) return;
    final entries = <String, String>{};
    for (final c in categories) {
      entries[c.id] = jsonEncode(c.toJson());
    }
    if (entries.isNotEmpty) {
      await _categoriesBox.putAll(entries);
    }
  }

  /// Obtiene todas las categorías personalizadas
  List<TaskCategory> getCategories() {
    if (!_initialized || !_categoriesBox.isOpen) return [];
    final list = <TaskCategory>[];
    for (final raw in _categoriesBox.values) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        list.add(TaskCategory.fromJson(json));
      } catch (e) {
        debugPrint('[LocalDatabaseService] Error parseando categoría: $e');
      }
    }
    return list;
  }

  /// Elimina una categoría personalizada por ID
  Future<void> deleteCategory(String id) async {
    if (!_initialized || !_categoriesBox.isOpen) return;
    await _categoriesBox.delete(id);
  }

  // ──────────────────────────────────────────────
  // Gamificación y Maestría
  // ──────────────────────────────────────────────

  /// Guarda los datos de gamificación
  Future<void> saveGamification(GamificationData data) async {
    if (!_initialized || !_gamificationBox.isOpen) return;
    await _gamificationBox.put('current', jsonEncode(data.toJson()));
  }

  /// Obtiene los datos de gamificación guardados
  GamificationData? getGamification() {
    if (!_initialized || !_gamificationBox.isOpen) return null;
    final raw = _gamificationBox.get('current');
    if (raw == null) return null;
    try {
      return GamificationData.fromJson(jsonDecode(raw));
    } catch (e) {
      debugPrint('[LocalDatabaseService] Error parseando gamificación: $e');
      return null;
    }
  }

  // ──────────────────────────────────────────────
  // Cola de Sincronización Offline (sync_queue)
  // ──────────────────────────────────────────────

  /// Encola una acción de sincronización (upsert o delete) cuando se está offline o falla la red.
  /// Deduplica inteligentemente: si ya hay una acción previa sobre el mismo targetId, la actualiza.
  Future<void> enqueueSyncAction(SyncAction action) async {
    if (!_initialized || !_syncQueueBox.isOpen) return;

    // Buscar si ya existe una acción pendiente para este targetId
    String? existingKey;
    for (final key in _syncQueueBox.keys) {
      final raw = _syncQueueBox.get(key);
      if (raw != null) {
        try {
          final existing = SyncAction.fromJson(jsonDecode(raw));
          if (existing.targetId == action.targetId && existing.entityType == action.entityType) {
            existingKey = key as String;
            break;
          }
        } catch (_) {}
      }
    }

    if (existingKey != null && _syncQueueBox.isOpen) {
      await _syncQueueBox.delete(existingKey);
    }

    if (_syncQueueBox.isOpen) {
      await _syncQueueBox.put(action.id, jsonEncode(action.toJson()));
      debugPrint('[LocalDatabaseService] Acción encolada: $action (Pendientes: ${_syncQueueBox.length})');
    }
  }

  /// Devuelve todas las acciones pendientes en la cola ordenadas cronológicamente
  List<SyncAction> getPendingSyncActions() {
    if (!_initialized || !_syncQueueBox.isOpen) return [];
    final list = <SyncAction>[];
    for (final raw in _syncQueueBox.values) {
      try {
        list.add(SyncAction.fromJson(jsonDecode(raw)));
      } catch (e) {
        debugPrint('[LocalDatabaseService] Error parseando acción de cola: $e');
      }
    }
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  /// Elimina una acción procesada de la cola
  Future<void> removeSyncAction(String actionId) async {
    if (!_initialized || !_syncQueueBox.isOpen) return;
    await _syncQueueBox.delete(actionId);
  }

  /// Limpia la cola de sincronización por completo
  Future<void> clearSyncQueue() async {
    if (!_initialized || !_syncQueueBox.isOpen) return;
    await _syncQueueBox.clear();
  }

  /// Cantidad de operaciones pendientes de sincronizar
  int get pendingSyncCount => (_initialized && _syncQueueBox.isOpen) ? _syncQueueBox.length : 0;

  /// Indica si hay operaciones pendientes de sincronización
  bool get hasPendingSync => pendingSyncCount > 0;

  // ──────────────────────────────────────────────
  // Limpieza de datos por cierre de sesión
  // ──────────────────────────────────────────────

  /// Limpia las tablas del usuario activo al cerrar sesión
  Future<void> clearUserData({bool preserveExternalCalendar = true}) async {
    if (!_initialized) return;

    if (preserveExternalCalendar) {
      // Eliminar solo bloques que no sean del calendario nativo
      await deleteTimeBlocksWhere((b) => !b.isExternalCalendar);
    } else {
      if (_blocksBox.isOpen) await _blocksBox.clear();
    }

    if (_todosBox.isOpen) await _todosBox.clear();
    if (_categoriesBox.isOpen) await _categoriesBox.clear();
    if (_gamificationBox.isOpen) await _gamificationBox.clear();
    if (_syncQueueBox.isOpen) await _syncQueueBox.clear();
    debugPrint('[LocalDatabaseService] Datos de usuario limpiados.');
  }
}
