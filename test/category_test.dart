import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockdo/models/task_category.dart';
import 'package:clockdo/models/time_block.dart';
import 'package:clockdo/models/todo_item.dart';
import 'package:clockdo/providers/clock_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TaskCategory Model & Custom Categories', () {
    test('Default categories have correct static properties and backward compatibility', () {
      expect(TaskCategory.defaultCategories.length, 6);
      expect(TaskCategory.values.length, 6);

      expect(TaskCategory.work.name, 'Trabajo');
      expect(TaskCategory.work.displayName, 'Trabajo');
      expect(TaskCategory.work.isDefault, isTrue);
      expect(TaskCategory.work.index, 0);

      expect(TaskCategory.personal.index, 1);
      expect(TaskCategory.none.name, 'General');
      expect(TaskCategory.none.index, 5);
    });

    test('Custom category creation with custom factory', () {
      final custom = TaskCategory.custom(
        name: 'Gimnasio',
        color: const Color(0xFF1DD1A1),
        icon: Icons.fitness_center_rounded,
      );

      expect(custom.name, 'Gimnasio');
      expect(custom.displayName, 'Gimnasio');
      expect(custom.color, const Color(0xFF1DD1A1));
      expect(custom.icon, Icons.fitness_center_rounded);
      expect(custom.isDefault, isFalse);
      expect(custom.id.isNotEmpty, isTrue);
      // Fallback index for legacy compatibility is 0
      expect(custom.index, 0);
    });

    test('toJson and fromJson preserves custom category data', () {
      final custom = TaskCategory.custom(
        name: 'Finanzas',
        color: const Color(0xFF5F27CD),
        icon: Icons.savings_rounded,
      );

      final json = custom.toJson();
      final restored = TaskCategory.fromJson(json);

      expect(restored.id, custom.id);
      expect(restored.name, 'Finanzas');
      expect(restored.color.toARGB32(), custom.color.toARGB32());
      expect(restored.icon.codePoint, Icons.savings_rounded.codePoint);
      expect(restored.isDefault, isFalse);
    });

    test('toSupabaseMap and fromSupabaseMap preserves custom category data', () {
      final custom = TaskCategory.custom(
        name: 'Lectura',
        color: const Color(0xFFFF9F43),
        icon: Icons.menu_book_rounded,
      );

      final map = custom.toSupabaseMap();
      expect(map['id'], custom.id);
      expect(map['name'], 'Lectura');
      expect(map['icon_code_point'], Icons.menu_book_rounded.codePoint);

      final restored = TaskCategory.fromSupabaseMap(map);
      expect(restored.id, custom.id);
      expect(restored.name, 'Lectura');
      expect(restored.icon.codePoint, Icons.menu_book_rounded.codePoint);
    });

    test('fromIdOrIndex resolves default categories and custom categories', () {
      final custom = TaskCategory.custom(
        id: 'cat-custom-123',
        name: 'Meditar',
        color: const Color(0xFF2ED573),
        icon: Icons.self_improvement_rounded,
      );

      // Resolve by default id
      expect(TaskCategory.fromIdOrIndex(id: 'work'), TaskCategory.work);
      expect(TaskCategory.fromIdOrIndex(id: 'health'), TaskCategory.health);

      // Resolve by custom id with customCategories list
      final resolved = TaskCategory.fromIdOrIndex(
        id: 'cat-custom-123',
        customCategories: [custom],
      );
      expect(resolved.name, 'Meditar');
      expect(resolved.id, 'cat-custom-123');

      // Resolve by legacy index
      expect(TaskCategory.fromIdOrIndex(index: 2), TaskCategory.health);

      // Fallback
      expect(TaskCategory.fromIdOrIndex(id: 'non-existent'), TaskCategory.none);
    });
  });

  group('TimeBlock & TodoItem with Custom Categories', () {
    test('TimeBlock preserves custom category in toJson and fromJson', () {
      final customCat = TaskCategory.custom(
        name: 'Estudio Flutter',
        color: const Color(0xFF70A1FF),
        icon: Icons.code_rounded,
      );

      final block = TimeBlock.create(
        title: 'Estudiar Custom Categories',
        startHour: 10.0,
        endHour: 12.0,
        category: customCat,
      );

      expect(block.category.name, 'Estudio Flutter');

      final json = block.toJson();
      expect(json['categoryId'], customCat.id);

      final restored = TimeBlock.fromJson(json, customCategories: [customCat]);
      expect(restored.category.name, 'Estudio Flutter');
      expect(restored.category.id, customCat.id);
    });

    test('TodoItem preserves custom category in toJson and fromJson', () {
      final customCat = TaskCategory.custom(
        name: 'Hogar',
        color: const Color(0xFFFF6B81),
        icon: Icons.home_rounded,
      );

      final todo = TodoItem.create(
        title: 'Limpiar sala',
        category: customCat,
      );

      final json = todo.toJson();
      expect(json['categoryId'], customCat.id);

      final restored = TodoItem.fromJson(json, customCategories: [customCat]);
      expect(restored.category.name, 'Hogar');
      expect(restored.category.id, customCat.id);
    });
  });

  group('ClockProvider Category Management', () {
    test('addCustomCategory, updateCustomCategory, and deleteCustomCategory', () {
      final provider = ClockProvider();

      expect(provider.customCategories.isEmpty, isTrue);
      expect(provider.allCategories.length, TaskCategory.defaultCategories.length);

      final newCat = TaskCategory.custom(
        name: 'Música',
        color: const Color(0xFFA55EEA),
        icon: Icons.music_note_rounded,
      );

      // Add
      provider.addCustomCategory(newCat);
      expect(provider.customCategories.length, 1);
      expect(provider.allCategories.contains(newCat), isTrue);

      // Update
      final updatedCat = TaskCategory.custom(
        id: newCat.id,
        name: 'Producción Musical',
        color: const Color(0xFF5F27CD),
        icon: Icons.music_note_rounded,
      );
      provider.updateCustomCategory(updatedCat);
      expect(provider.customCategories.first.name, 'Producción Musical');

      // Delete
      provider.deleteCustomCategory(newCat.id);
      expect(provider.customCategories.isEmpty, isTrue);
      expect(provider.allCategories.length, TaskCategory.defaultCategories.length);
    });

    test('deleteCustomCategory reassigns affected blocks and todos to TaskCategory.none', () {
      final provider = ClockProvider();

      final plantCat = TaskCategory.custom(
        name: 'Jardinería',
        color: const Color(0xFF2ED573),
        icon: Icons.local_florist_rounded,
      );
      provider.addCustomCategory(plantCat);

      final block = TimeBlock.create(
        title: 'Regar plantas',
        startHour: 8.0,
        endHour: 8.5,
        category: plantCat,
      );
      provider.addBlock(block);

      final todo = TodoItem.create(
        title: 'Comprar macetas',
        category: plantCat,
      );
      provider.addTodo(todo);

      expect(provider.allBlocks.first.category.id, plantCat.id);
      expect(provider.todoItems.first.category.id, plantCat.id);

      // Delete the category
      provider.deleteCustomCategory(plantCat.id);

      // Verify reassignment to TaskCategory.none
      expect(provider.allBlocks.first.category, TaskCategory.none);
      expect(provider.todoItems.first.category, TaskCategory.none);
    });
  });
}
