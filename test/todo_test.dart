import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockdo/models/task_category.dart';
import 'package:clockdo/models/time_block.dart';
import 'package:clockdo/models/todo_item.dart';
import 'package:clockdo/providers/clock_provider.dart';
import 'package:clockdo/widgets/radial_clock_canvas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TodoItem Model', () {
    test('create generates valid ID and defaults', () {
      final item = TodoItem.create(
        title: 'Comprar café',
        description: 'Grano molido colombiano',
        category: TaskCategory.personal,
      );

      expect(item.id.isNotEmpty, isTrue);
      expect(item.title, 'Comprar café');
      expect(item.description, 'Grano molido colombiano');
      expect(item.category, TaskCategory.personal);
      expect(item.isCompleted, isFalse);
      expect(item.completedAt, isNull);
    });

    test('toJson and fromJson preserves all fields', () {
      final item = TodoItem.create(
        title: 'Estudiar Flutter',
        description: 'Revisar CustomPaint',
        category: TaskCategory.learning,
      );

      final json = item.toJson();
      final restored = TodoItem.fromJson(json);

      expect(restored.id, item.id);
      expect(restored.title, item.title);
      expect(restored.description, item.description);
      expect(restored.category, item.category);
      expect(restored.isCompleted, item.isCompleted);
    });
  });

  group('ClockProvider ToDo Management', () {
    test('add, toggle, update, delete, and clear completed ToDos', () {
      final provider = ClockProvider();

      expect(provider.todoItems.isEmpty, isTrue);
      expect(provider.pendingTodoCount, 0);

      // Add ToDo
      final item1 = TodoItem.create(
        title: 'Tarea 1',
        category: TaskCategory.work,
      );
      final item2 = TodoItem.create(
        title: 'Tarea 2',
        category: TaskCategory.health,
      );

      provider.addTodo(item1);
      provider.addTodo(item2);

      expect(provider.todoItems.length, 2);
      expect(provider.pendingTodoCount, 2);
      expect(provider.pendingTodos.length, 2);
      expect(provider.completedTodos.isEmpty, isTrue);

      // Toggle status
      provider.toggleTodo(item1.id);
      expect(provider.pendingTodoCount, 1);
      expect(provider.completedTodos.length, 1);
      expect(provider.completedTodos.first.id, item1.id);

      // Update ToDo
      provider.updateTodo(item2.copyWith(title: 'Tarea 2 Actualizada'));
      expect(provider.pendingTodos.first.title, 'Tarea 2 Actualizada');

      // Schedule ToDo as TimeBlock
      final initialBlockCount = provider.allBlocks.length;
      provider.scheduleTodoAsBlock(
        todoId: item2.id,
        date: DateTime.now(),
        startHour: 10.0,
        endHour: 11.5,
        markTodoCompleted: true,
      );

      expect(provider.allBlocks.length, initialBlockCount + 1);
      expect(provider.pendingTodoCount, 0);
      expect(provider.completedTodos.length, 2);

      // Clear completed
      provider.clearCompletedTodos();
      expect(provider.todoItems.isEmpty, isTrue);
    });

    test('toggleStatus cycles through statuses and persists', () async {
      final provider = ClockProvider();
      final block = TimeBlock.create(
        title: 'Bloque de prueba',
        startHour: 8.0,
        endHour: 9.0,
        status: TaskStatus.pending,
      );

      provider.addBlock(block);
      expect(provider.allBlocks.first.status, TaskStatus.pending);

      // Toggle 1: pending -> inProgress
      provider.toggleStatus(block.id);
      expect(provider.allBlocks.first.status, TaskStatus.inProgress);

      // Toggle 2: inProgress -> completed
      provider.toggleStatus(block.id);
      expect(provider.allBlocks.first.status, TaskStatus.completed);

      // Toggle 3: completed -> pending
      provider.toggleStatus(block.id);
      expect(provider.allBlocks.first.status, TaskStatus.pending);
    });
  });

  group('RadialClockCanvas Magnifier (Modo Lupa)', () {
    testWidgets('toggles magnifier mode and displays magnifier button', (WidgetTester tester) async {
      final block = TimeBlock.create(
        title: 'Reunión de Diseño',
        startHour: 9.0,
        endHour: 10.5,
        category: TaskCategory.work,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: RadialClockCanvas(
                blocks: [block],
                currentHour: 9.5,
                is24h: false,
                onGestureComplete: (s, e) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Lupa'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      // Activar lupa
      await tester.tap(find.text('Lupa'));
      await tester.pump(const Duration(milliseconds: 300));

      // Debe mostrar la tarjeta de inspección de la tarea
      expect(find.text('Reunión de Diseño'), findsOneWidget);
      expect(find.text('Editar tarea'), findsOneWidget);
    });
  });
}
