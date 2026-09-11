import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockdo/providers/clock_provider.dart';
import 'package:clockdo/models/time_block.dart';
import 'package:clockdo/models/todo_item.dart';
import 'package:clockdo/models/task_category.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kanban Mode & Provider Tests', () {
    late ClockProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = ClockProvider();
    });

    test('Default viewMode is AppViewMode.clock', () {
      expect(provider.viewMode, AppViewMode.clock);
    });

    test('setViewMode and toggleViewMode update view mode and notify listeners', () {
      int notifyCount = 0;
      provider.addListener(() {
        notifyCount++;
      });

      provider.setViewMode(AppViewMode.kanban);
      expect(provider.viewMode, AppViewMode.kanban);
      expect(notifyCount, 1);

      provider.toggleViewMode();
      expect(provider.viewMode, AppViewMode.clock);
      expect(notifyCount, 2);

      provider.toggleViewMode();
      expect(provider.viewMode, AppViewMode.kanban);
      expect(notifyCount, 3);
    });

    test('setBlockStatus moves block to new status and awards gamification on complete', () {
      final block = TimeBlock.create(
        title: 'Kanban Feature Task',
        startHour: 10.0,
        endHour: 11.0,
        category: TaskCategory.work,
        status: TaskStatus.pending,
      );
      provider.addBlock(block);

      expect(provider.allBlocks.first.status, TaskStatus.pending);
      final initialTicks = provider.gamification.ticks;

      // Move to inProgress
      provider.setBlockStatus(block.id, TaskStatus.inProgress);
      expect(provider.allBlocks.first.status, TaskStatus.inProgress);

      // Move to completed (triggers gamification)
      provider.setBlockStatus(block.id, TaskStatus.completed);
      expect(provider.allBlocks.first.status, TaskStatus.completed);
      expect(provider.gamification.ticks, greaterThan(initialTicks));
      expect(provider.gamification.totalCompletedTasks, 1);
    });

    test('convertTodoToScheduledBlock converts a backlog todo into a scheduled time block', () {
      final todo = TodoItem.create(
        title: 'Plan Sprint',
        description: 'Organizar columnas Kanban',
        category: TaskCategory.work,
      );
      provider.addTodo(todo);

      expect(provider.todoItems.length, 1);
      expect(provider.allBlocks.isEmpty, true);

      // Convert to inProgress time block
      provider.convertTodoToScheduledBlock(
        todoId: todo.id,
        initialStatus: TaskStatus.inProgress,
        startHour: 14.0,
        endHour: 15.0,
      );

      // Todo should be removed from backlog
      expect(provider.todoItems.isEmpty, true);
      // New time block should exist with inProgress status
      expect(provider.allBlocks.length, 1);
      final createdBlock = provider.allBlocks.first;
      expect(createdBlock.title, 'Plan Sprint');
      expect(createdBlock.description, 'Organizar columnas Kanban');
      expect(createdBlock.status, TaskStatus.inProgress);
      expect(createdBlock.startHour, 14.0);
      expect(createdBlock.endHour, 15.0);
    });

    test('moveBlockToBacklog unassigns time block and returns it to backlog todo', () {
      final block = TimeBlock.create(
        title: 'Reunión cancelada',
        startHour: 9.0,
        endHour: 10.0,
        category: TaskCategory.work,
      );
      provider.addBlock(block);

      expect(provider.allBlocks.length, 1);
      expect(provider.todoItems.isEmpty, true);

      provider.moveBlockToBacklog(block.id);

      expect(provider.allBlocks.isEmpty, true);
      expect(provider.todoItems.length, 1);
      expect(provider.todoItems.first.title, 'Reunión cancelada');
    });
  });
}
