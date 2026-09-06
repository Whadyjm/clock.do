import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockdo/models/task_category.dart';
import 'package:clockdo/models/time_block.dart';
import 'package:clockdo/providers/clock_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TimeBlock Notification Customization Model', () {
    test('create has default notificationEnabled = true and reminderMinutes = null', () {
      final block = TimeBlock.create(
        title: 'Revisión técnica',
        startHour: 10.0,
        endHour: 11.0,
      );

      expect(block.notificationEnabled, isTrue);
      expect(block.reminderMinutes, isNull);
    });

    test('create accepts custom notificationEnabled and reminderMinutes', () {
      final block = TimeBlock.create(
        title: 'Standup',
        startHour: 9.0,
        endHour: 9.5,
        notificationEnabled: false,
        reminderMinutes: 15,
      );

      expect(block.notificationEnabled, isFalse);
      expect(block.reminderMinutes, 15);
    });

    test('toJson and fromJson preserves notificationEnabled and reminderMinutes', () {
      final block = TimeBlock.create(
        title: 'Presentación cliente',
        description: 'Demo interactiva',
        startHour: 14.0,
        endHour: 15.5,
        category: TaskCategory.work,
        notificationEnabled: true,
        reminderMinutes: 30,
      );

      final json = block.toJson();
      expect(json['notificationEnabled'], isTrue);
      expect(json['reminderMinutes'], 30);

      final restored = TimeBlock.fromJson(json);
      expect(restored.id, block.id);
      expect(restored.title, block.title);
      expect(restored.notificationEnabled, isTrue);
      expect(restored.reminderMinutes, 30);
    });

    test('copyWith updates notification settings and supports clearReminderMinutes', () {
      final block = TimeBlock.create(
        title: 'Focus Time',
        startHour: 16.0,
        endHour: 18.0,
        reminderMinutes: 10,
      );

      expect(block.reminderMinutes, 10);

      // Disable notification
      final muted = block.copyWith(notificationEnabled: false);
      expect(muted.notificationEnabled, isFalse);
      expect(muted.reminderMinutes, 10);

      // Clear reminder minutes back to global default
      final restoredToGlobal = muted.copyWith(clearReminderMinutes: true);
      expect(restoredToGlobal.notificationEnabled, isFalse);
      expect(restoredToGlobal.reminderMinutes, isNull);
    });
  });

  group('ClockProvider Notification Customization Helpers', () {
    test('effectiveReminderMinutes uses block custom minutes or falls back to global', () {
      final provider = ClockProvider();
      // Default global is 5 min
      expect(provider.reminderMinutesBefore, 5);

      final blockDefault = TimeBlock.create(
        title: 'Tarea normal',
        startHour: 10.0,
        endHour: 11.0,
      );
      expect(provider.effectiveReminderMinutes(blockDefault), 5);

      final blockCustom = TimeBlock.create(
        title: 'Tarea con 15m',
        startHour: 10.0,
        endHour: 11.0,
        reminderMinutes: 15,
      );
      expect(provider.effectiveReminderMinutes(blockCustom), 15);

      final blockZero = TimeBlock.create(
        title: 'Tarea al comenzar',
        startHour: 10.0,
        endHour: 11.0,
        reminderMinutes: 0,
      );
      expect(provider.effectiveReminderMinutes(blockZero), 0);
    });

    test('isBlockNotificationActive considers both global switch and block switch', () {
      final provider = ClockProvider();
      expect(provider.notificationsEnabled, isTrue);

      final activeBlock = TimeBlock.create(
        title: 'Tarea con alerta',
        startHour: 10.0,
        endHour: 11.0,
        notificationEnabled: true,
      );
      final mutedBlock = TimeBlock.create(
        title: 'Tarea silenciada',
        startHour: 10.0,
        endHour: 11.0,
        notificationEnabled: false,
      );

      expect(provider.isBlockNotificationActive(activeBlock), isTrue);
      expect(provider.isBlockNotificationActive(mutedBlock), isFalse);

      // When global notifications are disabled, all are inactive
      provider.setNotificationsEnabled(false);
      expect(provider.isBlockNotificationActive(activeBlock), isFalse);
      expect(provider.isBlockNotificationActive(mutedBlock), isFalse);
    });
  });
}
