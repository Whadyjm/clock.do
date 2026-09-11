import 'package:flutter_test/flutter_test.dart';
import 'package:clockdo/models/recurrence_rule.dart';
import 'package:clockdo/models/time_block.dart';
import 'package:clockdo/models/task_category.dart';
import 'package:clockdo/models/task_priority.dart';

void main() {
  group('RecurrenceRule Unit Tests', () {
    test('RecurrenceRule defaults and properties', () {
      const rule = RecurrenceRule();
      expect(rule.frequency, RecurrenceFrequency.none);
      expect(rule.interval, 1);
      expect(rule.reminderIntervalMinutes, isNull);
      expect(rule.intervalMinutes, isNull);
      expect(rule.endDate, isNull);
      expect(rule.isRepeating, isFalse);
      expect(rule.hasIntervalReminder, isFalse);
    });

    test('Daily recurrence occursOnDate', () {
      final base = DateTime(2026, 3, 9); // Monday
      const rule = RecurrenceRule(frequency: RecurrenceFrequency.daily);

      expect(rule.occursOnDate(base, DateTime(2026, 3, 8)), isFalse); // Before base
      expect(rule.occursOnDate(base, DateTime(2026, 3, 9)), isTrue);  // Same day
      expect(rule.occursOnDate(base, DateTime(2026, 3, 10)), isTrue); // Next day
      expect(rule.occursOnDate(base, DateTime(2026, 3, 20)), isTrue); // Future day
    });

    test('Daily recurrence with interval (every 2 days)', () {
      final base = DateTime(2026, 3, 9);
      const rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 2,
      );

      expect(rule.occursOnDate(base, DateTime(2026, 3, 9)), isTrue);
      expect(rule.occursOnDate(base, DateTime(2026, 3, 10)), isFalse);
      expect(rule.occursOnDate(base, DateTime(2026, 3, 11)), isTrue);
      expect(rule.occursOnDate(base, DateTime(2026, 3, 12)), isFalse);
    });

    test('Weekdays recurrence occursOnDate', () {
      final base = DateTime(2026, 3, 9); // Monday
      const rule = RecurrenceRule(frequency: RecurrenceFrequency.weekdays);

      expect(rule.occursOnDate(base, DateTime(2026, 3, 9)), isTrue);   // Monday
      expect(rule.occursOnDate(base, DateTime(2026, 3, 10)), isTrue);  // Tuesday
      expect(rule.occursOnDate(base, DateTime(2026, 3, 13)), isTrue);  // Friday
      expect(rule.occursOnDate(base, DateTime(2026, 3, 14)), isFalse); // Saturday
      expect(rule.occursOnDate(base, DateTime(2026, 3, 15)), isFalse); // Sunday
    });

    test('Weekly recurrence occursOnDate', () {
      final base = DateTime(2026, 3, 9); // Monday
      const rule = RecurrenceRule(frequency: RecurrenceFrequency.weekly);

      expect(rule.occursOnDate(base, DateTime(2026, 3, 9)), isTrue);   // Monday
      expect(rule.occursOnDate(base, DateTime(2026, 3, 10)), isFalse); // Tuesday
      expect(rule.occursOnDate(base, DateTime(2026, 3, 16)), isTrue);  // Next Monday
      expect(rule.occursOnDate(base, DateTime(2026, 3, 23)), isTrue);  // Monday in 2 weeks
    });

    test('Recurrence with endDate boundary', () {
      final base = DateTime(2026, 3, 9);
      final end = DateTime(2026, 3, 15);
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        endDate: end,
      );

      expect(rule.occursOnDate(base, DateTime(2026, 3, 15)), isTrue);
      expect(rule.occursOnDate(base, DateTime(2026, 3, 16)), isFalse); // Past end date
    });

    test('calculateReminderHours splits interval accurately', () {
      const rule = RecurrenceRule(reminderIntervalMinutes: 30);
      expect(rule.hasIntervalReminder, isTrue);

      final hours = rule.calculateReminderHours(startHour: 9.0, endHour: 11.0);
      // Expected reminder points: 9.5, 10.0, 10.5
      expect(hours, equals([9.5, 10.0, 10.5]));
    });

    test('calculateReminderHours with 60 min intervals', () {
      const rule = RecurrenceRule(reminderIntervalMinutes: 60);
      final hours = rule.calculateReminderHours(startHour: 10.0, endHour: 13.0);
      // Expected: 11.0, 12.0
      expect(hours, equals([11.0, 12.0]));
    });

    test('RecurrenceRule JSON serialization round-trip', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
        reminderIntervalMinutes: 45,
        endDate: DateTime(2026, 12, 31),
      );

      final map = rule.toJson();
      final restored = RecurrenceRule.fromJson(map);

      expect(restored.frequency, RecurrenceFrequency.weekly);
      expect(restored.interval, 2);
      expect(restored.reminderIntervalMinutes, 45);
      expect(restored.endDate?.year, 2026);
      expect(restored.endDate?.month, 12);
      expect(restored.endDate?.day, 31);
    });

    test('TimeBlock with recurrence integration', () {
      final block = TimeBlock.create(
        title: 'Entrenamiento Diario',
        startHour: 7.0,
        endHour: 8.0,
        category: TaskCategory.health,
        priority: TaskPriority.high,
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          reminderIntervalMinutes: 15,
        ),
      );

      expect(block.isRecurring, isTrue);
      expect(block.hasIntervalReminder, isTrue);
      expect(block.occursOnDate(DateTime.now().add(const Duration(days: 3))), isTrue);

      // JSON round trip
      final json = block.toJson();
      final fromJsonBlock = TimeBlock.fromJson(json);
      expect(fromJsonBlock.isRecurring, isTrue);
      expect(fromJsonBlock.recurrence?.frequency, RecurrenceFrequency.daily);
      expect(fromJsonBlock.recurrence?.reminderIntervalMinutes, 15);

      // Supabase map round trip
      final supabaseMap = block.toSupabaseMap();
      expect(supabaseMap['recurrence'], isNotNull);
      final fromSupabaseBlock = TimeBlock.fromSupabaseMap(supabaseMap);
      expect(fromSupabaseBlock.isRecurring, isTrue);
      expect(fromSupabaseBlock.recurrence?.frequency, RecurrenceFrequency.daily);
      expect(fromSupabaseBlock.recurrence?.reminderIntervalMinutes, 15);
    });
  });
}
