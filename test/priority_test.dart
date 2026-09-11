import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clockdo/models/task_priority.dart';
import 'package:clockdo/models/time_block.dart';
import 'package:clockdo/models/todo_item.dart';
import 'package:clockdo/models/task_category.dart';

void main() {
  group('TaskPriority Unit Tests', () {
    test('TaskPriority enum has expected values and helpers', () {
      expect(TaskPriority.values.length, 5);
      expect(TaskPriority.none.hasPriority, isFalse);
      expect(TaskPriority.low.hasPriority, isTrue);
      expect(TaskPriority.medium.hasPriority, isTrue);
      expect(TaskPriority.high.hasPriority, isTrue);
      expect(TaskPriority.urgent.hasPriority, isTrue);

      expect(TaskPriority.none.isHighOrUrgent, isFalse);
      expect(TaskPriority.low.isHighOrUrgent, isFalse);
      expect(TaskPriority.medium.isHighOrUrgent, isFalse);
      expect(TaskPriority.high.isHighOrUrgent, isTrue);
      expect(TaskPriority.urgent.isHighOrUrgent, isTrue);
    });

    test('TaskPriority.fromIndex returns correct values and handles edge cases', () {
      expect(TaskPriority.fromIndex(0), TaskPriority.none);
      expect(TaskPriority.fromIndex(1), TaskPriority.low);
      expect(TaskPriority.fromIndex(2), TaskPriority.medium);
      expect(TaskPriority.fromIndex(3), TaskPriority.high);
      expect(TaskPriority.fromIndex(4), TaskPriority.urgent);
      expect(TaskPriority.fromIndex(null), TaskPriority.none);
      expect(TaskPriority.fromIndex(-1), TaskPriority.none);
      expect(TaskPriority.fromIndex(99), TaskPriority.none);
    });

    test('TaskPriority.fromName parses case-insensitively', () {
      expect(TaskPriority.fromName('high'), TaskPriority.high);
      expect(TaskPriority.fromName('URGENT'), TaskPriority.urgent);
      expect(TaskPriority.fromName('Low'), TaskPriority.low);
      expect(TaskPriority.fromName(null), TaskPriority.none);
      expect(TaskPriority.fromName('unknown'), TaskPriority.none);
    });

    test('Each TaskPriority has a valid non-null color and icon', () {
      for (final p in TaskPriority.values) {
        expect(p.color, isA<Color>());
        expect(p.icon, isA<IconData>());
        expect(p.displayName.isNotEmpty, isTrue);
      }
    });
  });

  group('TimeBlock Priority Tests', () {
    test('Defaults to TaskPriority.none when not specified', () {
      final block = TimeBlock.create(
        title: 'Prueba prioridad',
        startHour: 9.0,
        endHour: 10.0,
      );
      expect(block.priority, TaskPriority.none);
    });

    test('Can be initialized with custom priority', () {
      final block = TimeBlock.create(
        title: 'Reunión urgente',
        startHour: 14.0,
        endHour: 15.0,
        priority: TaskPriority.urgent,
      );
      expect(block.priority, TaskPriority.urgent);
    });

    test('copyWith modifies priority correctly', () {
      final block = TimeBlock.create(
        title: 'Tarea regular',
        startHour: 11.0,
        priority: TaskPriority.low,
      );
      final updated = block.copyWith(priority: TaskPriority.high);
      expect(updated.priority, TaskPriority.high);
      expect(updated.title, 'Tarea regular');
    });

    test('Serialization to/from JSON preserves priority', () {
      final block = TimeBlock.create(
        title: 'Tarea serializada',
        startHour: 16.0,
        endHour: 17.5,
        priority: TaskPriority.high,
      );
      final json = block.toJson();
      expect(json['priority'], TaskPriority.high.index);

      final restored = TimeBlock.fromJson(json);
      expect(restored.priority, TaskPriority.high);
    });

    test('Deserialization from JSON without priority defaults to none', () {
      final json = {
        'id': 'test-123',
        'title': 'Vieja tarea sin prioridad',
        'startHour': 10.0,
        'category': 0,
        'status': 0,
      };
      final block = TimeBlock.fromJson(json);
      expect(block.priority, TaskPriority.none);
    });

    test('Serialization to/from Supabase map preserves priority', () {
      final block = TimeBlock.create(
        title: 'Tarea Supabase',
        startHour: 8.0,
        endHour: 9.0,
        priority: TaskPriority.medium,
      );
      final supaMap = block.toSupabaseMap();
      expect(supaMap['priority'], TaskPriority.medium.index);

      final restored = TimeBlock.fromSupabaseMap(supaMap);
      expect(restored.priority, TaskPriority.medium);
    });
  });

  group('TodoItem Priority Tests', () {
    test('Defaults to TaskPriority.none when not specified', () {
      final todo = TodoItem.create(title: 'Comprar leche');
      expect(todo.priority, TaskPriority.none);
    });

    test('Can be initialized with custom priority', () {
      final todo = TodoItem.create(
        title: 'Pagar impuestos',
        priority: TaskPriority.urgent,
      );
      expect(todo.priority, TaskPriority.urgent);
    });

    test('copyWith modifies priority correctly', () {
      final todo = TodoItem.create(
        title: 'Limpiar garaje',
        priority: TaskPriority.low,
      );
      final updated = todo.copyWith(priority: TaskPriority.medium);
      expect(updated.priority, TaskPriority.medium);
    });

    test('Serialization to/from JSON preserves priority', () {
      final todo = TodoItem.create(
        title: 'Revisar PR',
        priority: TaskPriority.high,
      );
      final json = todo.toJson();
      expect(json['priority'], TaskPriority.high.index);

      final restored = TodoItem.fromJson(json);
      expect(restored.priority, TaskPriority.high);
    });

    test('Deserialization from JSON without priority defaults to none', () {
      final json = {
        'id': 'todo-456',
        'title': 'Antigua tarea ToDo',
        'category': 0,
        'isCompleted': false,
      };
      final todo = TodoItem.fromJson(json);
      expect(todo.priority, TaskPriority.none);
    });

    test('Serialization to/from Supabase map preserves priority', () {
      final todo = TodoItem.create(
        title: 'Sincronizar backlog',
        priority: TaskPriority.low,
      );
      final map = todo.toSupabaseMap();
      expect(map['priority'], TaskPriority.low.index);

      final restored = TodoItem.fromSupabaseMap(map);
      expect(restored.priority, TaskPriority.low);
    });
  });
}
