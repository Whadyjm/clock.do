import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockdo/models/time_block.dart';
import 'package:clockdo/models/todo_item.dart';
import 'package:clockdo/models/task_category.dart';
import 'package:clockdo/models/task_priority.dart';
import 'package:clockdo/models/sync_action.dart';
import 'package:clockdo/services/local_database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late LocalDatabaseService localDb;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_clockdo_test_');

    localDb = LocalDatabaseService();
    localDb.resetForTesting();
    await localDb.init(tempDir.path);
    await localDb.clearUserData(preserveExternalCalendar: false);
    await localDb.clearSyncQueue();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LocalDatabaseService - TimeBlock CRUD', () {
    test('saveTimeBlock and getTimeBlocks stores and retrieves blocks correctly', () async {
      final block = TimeBlock.create(
        title: 'Bloque de Estudio',
        description: 'Notas de física cuántica',
        date: DateTime(2026, 9, 13),
        startHour: 10.0,
        endHour: 11.5,
        category: TaskCategory.learning,
        priority: TaskPriority.high,
      );

      await localDb.saveTimeBlock(block);

      final blocks = localDb.getTimeBlocks();
      expect(blocks.length, 1);
      expect(blocks.first.id, block.id);
      expect(blocks.first.title, 'Bloque de Estudio');
      expect(blocks.first.description, 'Notas de física cuántica');
      expect(blocks.first.startHour, 10.0);
      expect(blocks.first.endHour, 11.5);
      expect(blocks.first.category, TaskCategory.learning);
      expect(blocks.first.priority, TaskPriority.high);
    });

    test('deleteTimeBlock removes the block by id', () async {
      final block1 = TimeBlock.create(
        title: 'Bloque 1',
        date: DateTime(2026, 9, 13),
        startHour: 8.0,
        endHour: 9.0,
      );
      final block2 = TimeBlock.create(
        title: 'Bloque 2',
        date: DateTime(2026, 9, 13),
        startHour: 14.0,
        endHour: 15.0,
      );

      await localDb.saveTimeBlocks([block1, block2]);
      expect(localDb.getTimeBlocks().length, 2);

      await localDb.deleteTimeBlock(block1.id);
      final remaining = localDb.getTimeBlocks();
      expect(remaining.length, 1);
      expect(remaining.first.id, block2.id);
    });
  });

  group('LocalDatabaseService - TodoItem & Notes CRUD', () {
    test('saveTodo and getTodos preserves title, description/notes and state', () async {
      final todo = TodoItem.create(
        title: 'Revisar servidor Supabase',
        description: 'Verificar índices en Postgres y RLS en time_blocks',
        category: TaskCategory.work,
        priority: TaskPriority.urgent,
      );

      await localDb.saveTodo(todo);

      final todos = localDb.getTodos();
      expect(todos.length, 1);
      expect(todos.first.id, todo.id);
      expect(todos.first.title, 'Revisar servidor Supabase');
      expect(todos.first.description,
          'Verificar índices en Postgres y RLS en time_blocks');
      expect(todos.first.isCompleted, isFalse);
    });

    test('deleteTodo removes todo by id', () async {
      final todo = TodoItem.create(title: 'Tarea a borrar');
      await localDb.saveTodo(todo);
      expect(localDb.getTodos().length, 1);

      await localDb.deleteTodo(todo.id);
      expect(localDb.getTodos(), isEmpty);
    });
  });

  group('LocalDatabaseService - Offline Sync Queue', () {
    test('enqueueSyncAction adds actions and deduplicates by targetId', () async {
      expect(localDb.hasPendingSync, isFalse);
      expect(localDb.pendingSyncCount, 0);

      // 1. Encolar inserción
      final action1 = SyncAction.create(
        targetId: 'block-123',
        entityType: SyncEntityType.timeBlock,
        operation: SyncOperationType.upsert,
        payload: {'title': 'Bloque v1'},
      );
      await localDb.enqueueSyncAction(action1);

      expect(localDb.hasPendingSync, isTrue);
      expect(localDb.pendingSyncCount, 1);

      // 2. Encolar actualización del mismo bloque -> debe deduplicar
      final action2 = SyncAction.create(
        targetId: 'block-123',
        entityType: SyncEntityType.timeBlock,
        operation: SyncOperationType.upsert,
        payload: {'title': 'Bloque v2'},
      );
      await localDb.enqueueSyncAction(action2);

      expect(localDb.pendingSyncCount, 1);
      final pending = localDb.getPendingSyncActions();
      expect(pending.first.payload?['title'], 'Bloque v2');

      // 3. Eliminar acción procesada
      await localDb.removeSyncAction(pending.first.id);
      expect(localDb.hasPendingSync, isFalse);
      expect(localDb.pendingSyncCount, 0);
    });
  });

  group('LocalDatabaseService - Migration from SharedPreferences', () {
    test('migrateFromSharedPreferencesIfEmpty imports existing tasks to Hive', () async {
      SharedPreferences.setMockInitialValues({
        'clockdo_tasks': [
          '{"id":"sp-1","title":"Tarea SP","date":"2026-09-13T00:00:00.000","startHour":9.0,"endHour":10.0,"category":1,"status":0,"priority":0,"ringIndex":0,"notificationEnabled":true,"isExternalCalendar":false}',
        ],
        'clockdo_todos': [
          '{"id":"todo-sp-1","title":"Todo SP","description":"Nota previa","category":0,"priority":0,"isCompleted":false,"createdAt":"2026-09-13T10:00:00.000"}',
        ],
      });

      final prefs = await SharedPreferences.getInstance();
      await localDb.migrateFromSharedPreferencesIfEmpty(prefs);

      final blocks = localDb.getTimeBlocks();
      expect(blocks.length, 1);
      expect(blocks.first.id, 'sp-1');
      expect(blocks.first.title, 'Tarea SP');

      final todos = localDb.getTodos();
      expect(todos.length, 1);
      expect(todos.first.id, 'todo-sp-1');
      expect(todos.first.description, 'Nota previa');
    });
  });
}
