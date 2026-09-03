import 'package:flutter_test/flutter_test.dart';
import 'package:clockdo/models/task_category.dart';
import 'package:clockdo/models/time_block.dart';
import 'package:clockdo/models/todo_item.dart';
import 'package:clockdo/services/supabase_config.dart';
import 'package:clockdo/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase Config & Service Initialization', () {
    test('SupabaseConfig correctly identifies configuration state', () {
      // With real credentials configured, isConfigured is true
      expect(SupabaseConfig.isConfigured, isTrue);
    });

    test('SupabaseService handles unconfigured state gracefully', () async {
      final service = SupabaseService();
      expect(service.isInitialized, isFalse);
      expect(service.currentUser, isNull);
      expect(service.isAuthenticated, isFalse);

      final blocks = await service.fetchTimeBlocks();
      expect(blocks, isEmpty);

      final todos = await service.fetchTodos();
      expect(todos, isEmpty);
    });
  });

  group('Supabase Serialization Mapping', () {
    test('TimeBlock toSupabaseMap and fromSupabaseMap roundtrip', () {
      final block = TimeBlock.create(
        title: 'Reunión de Equipo',
        description: 'Revisión de sprint',
        date: DateTime(2026, 9, 2),
        startHour: 9.5,
        endHour: 10.5,
        category: TaskCategory.work,
        status: TaskStatus.inProgress,
      );

      final map = block.toSupabaseMap();
      expect(map['id'], block.id);
      expect(map['title'], 'Reunión de Equipo');
      expect(map['start_hour'], 9.5);
      expect(map['end_hour'], 10.5);
      expect(map['date'], '2026-09-02');
      expect(map['category'], TaskCategory.work.index);
      expect(map['status'], TaskStatus.inProgress.index);

      final fromMap = TimeBlock.fromSupabaseMap(map);
      expect(fromMap.id, block.id);
      expect(fromMap.title, block.title);
      expect(fromMap.description, block.description);
      expect(fromMap.startHour, block.startHour);
      expect(fromMap.endHour, block.endHour);
      expect(fromMap.category, block.category);
      expect(fromMap.status, block.status);
    });

    test('TodoItem toSupabaseMap and fromSupabaseMap roundtrip', () {
      final todo = TodoItem.create(
        title: 'Comprar insumos',
        description: 'Papel y café',
        category: TaskCategory.personal,
      );

      final map = todo.toSupabaseMap();
      expect(map['id'], todo.id);
      expect(map['title'], 'Comprar insumos');
      expect(map['is_completed'], isFalse);
      expect(map['category'], TaskCategory.personal.index);

      final fromMap = TodoItem.fromSupabaseMap(map);
      expect(fromMap.id, todo.id);
      expect(fromMap.title, todo.title);
      expect(fromMap.description, todo.description);
      expect(fromMap.category, todo.category);
      expect(fromMap.isCompleted, isFalse);
    });
  });
}
