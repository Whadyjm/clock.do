import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockdo/models/time_block.dart';
import 'package:clockdo/models/todo_item.dart';
import 'package:clockdo/models/task_category.dart';
import 'package:clockdo/providers/clock_provider.dart';
import 'package:clockdo/services/local_database_service.dart';
import 'package:clockdo/services/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late LocalDatabaseService localDb;
  late ConnectivityService connectivity;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('hive_clockdo_provider_test_');

    localDb = LocalDatabaseService();
    localDb.resetForTesting();
    await localDb.init(tempDir.path);
    await localDb.clearUserData(preserveExternalCalendar: false);
    await localDb.clearSyncQueue();

    connectivity = ConnectivityService();
    connectivity.setOnlineForTesting(false); // Simular offline
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Offline-First Behavior in ClockProvider', () {
    test('Saving a TimeBlock offline stores it locally in Hive and in memory', () async {
      final provider = ClockProvider();
      await Future.delayed(const Duration(milliseconds: 50)); // Permitir _initAndLoad

      final block = TimeBlock.create(
        title: 'Entrenamiento de Tarde',
        description: '45 minutos de cardio y estiramiento',
        date: DateTime(2026, 9, 13),
        startHour: 17.0,
        endHour: 18.0,
        category: TaskCategory.health,
      );

      provider.addBlock(block);

      // Debe estar en memoria inmediatamente
      expect(provider.allBlocks.length, 1);
      expect(provider.allBlocks.first.title, 'Entrenamiento de Tarde');

      // Debe persistirse en la base de datos local Hive
      final localBlocks = localDb.getTimeBlocks();
      expect(localBlocks.length, 1);
      expect(localBlocks.first.id, block.id);
      expect(localBlocks.first.description, '45 minutos de cardio y estiramiento');
    });

    test('Saving a TodoItem offline with notes stores it in Hive and in memory', () async {
      final provider = ClockProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final todo = TodoItem.create(
        title: 'Preparar informe semanal',
        description: 'Detallar métricas de retención y análisis de usuarios offline',
        category: TaskCategory.work,
      );

      provider.addTodo(todo);

      // Memoria
      expect(provider.todoItems.length, 1);
      expect(provider.pendingTodoCount, 1);
      expect(provider.todoItems.first.title, 'Preparar informe semanal');

      // Base de datos local Hive
      final localTodos = localDb.getTodos();
      expect(localTodos.length, 1);
      expect(localTodos.first.id, todo.id);
      expect(localTodos.first.description,
          'Detallar métricas de retención y análisis de usuarios offline');
    });

    test('Toggling Todo status offline updates Hive and memory immediately', () async {
      final provider = ClockProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final todo = TodoItem.create(
        title: 'Comprar agua',
        category: TaskCategory.personal,
      );
      provider.addTodo(todo);
      expect(provider.todoItems.first.isCompleted, isFalse);

      provider.toggleTodo(todo.id);
      expect(provider.todoItems.first.isCompleted, isTrue);

      final localTodos = localDb.getTodos();
      expect(localTodos.first.isCompleted, isTrue);
    });

    test('Deleting a TimeBlock offline removes it from Hive and memory', () async {
      final provider = ClockProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final block = TimeBlock.create(
        title: 'Reunión cancelada',
        date: DateTime(2026, 9, 13),
        startHour: 11.0,
        endHour: 12.0,
      );
      provider.addBlock(block);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.allBlocks.length, 1);

      provider.deleteBlock(block.id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.allBlocks, isEmpty);

      final localBlocks = localDb.getTimeBlocks();
      expect(localBlocks, isEmpty);
    });

    test('Deleting a TodoItem offline removes it from Hive and memory', () async {
      final provider = ClockProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final todo = TodoItem.create(title: 'Nota temporal');
      provider.addTodo(todo);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.todoItems.length, 1);

      provider.deleteTodo(todo.id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.todoItems, isEmpty);

      final localTodos = localDb.getTodos();
      expect(localTodos, isEmpty);
    });
  });
}
