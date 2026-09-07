import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clockdo/models/time_block.dart';
import 'package:clockdo/models/task_category.dart';
import 'package:clockdo/providers/clock_provider.dart';
import 'package:clockdo/widgets/settings/device_calendar_sheet.dart';
import 'package:clockdo/widgets/task_form_sheet.dart';
import 'package:clockdo/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TimeBlock External Calendar Model Tests', () {
    test('Default TimeBlock has isExternalCalendar as false', () {
      final block = TimeBlock.create(
        title: 'Tarea Local',
        startHour: 9.0,
        endHour: 10.0,
      );

      expect(block.isExternalCalendar, isFalse);
      expect(block.externalEventId, isNull);
      expect(block.externalCalendarName, isNull);
    });

    test('TimeBlock created with external calendar parameters retains them', () {
      final block = TimeBlock.create(
        title: 'Reunión Google Meet',
        startHour: 15.0,
        endHour: 16.0,
        isExternalCalendar: true,
        externalEventId: 'evt_12345',
        externalCalendarName: 'Google: Trabajo',
      );

      expect(block.isExternalCalendar, isTrue);
      expect(block.externalEventId, 'evt_12345');
      expect(block.externalCalendarName, 'Google: Trabajo');
    });

    test('TimeBlock serializes and deserializes external calendar fields correctly (JSON)', () {
      final original = TimeBlock.create(
        title: 'Cita Médica iCloud',
        description: 'Chequeo general',
        startHour: 11.0,
        endHour: 12.0,
        isExternalCalendar: true,
        externalEventId: 'icloud_999',
        externalCalendarName: 'Personal',
      );

      final json = original.toJson();
      expect(json['isExternalCalendar'], isTrue);
      expect(json['externalEventId'], 'icloud_999');
      expect(json['externalCalendarName'], 'Personal');

      final restored = TimeBlock.fromJson(json);
      expect(restored.isExternalCalendar, isTrue);
      expect(restored.externalEventId, 'icloud_999');
      expect(restored.externalCalendarName, 'Personal');
      expect(restored.title, 'Cita Médica iCloud');
      expect(restored.description, 'Chequeo general');
    });

    test('TimeBlock serializes and deserializes Supabase Postgres map correctly', () {
      final original = TimeBlock.create(
        title: 'Sync Supabase Event',
        startHour: 14.0,
        endHour: 15.5,
        isExternalCalendar: true,
        externalEventId: 'spb_evt_777',
        externalCalendarName: 'Outlook',
      );

      final map = original.toSupabaseMap();
      expect(map['is_external_calendar'], isTrue);
      expect(map['external_event_id'], 'spb_evt_777');
      expect(map['external_calendar_name'], 'Outlook');

      final restored = TimeBlock.fromSupabaseMap(map);
      expect(restored.isExternalCalendar, isTrue);
      expect(restored.externalEventId, 'spb_evt_777');
      expect(restored.externalCalendarName, 'Outlook');
    });

    test('copyWith modifies or preserves external calendar fields', () {
      final original = TimeBlock.create(
        title: 'Original',
        startHour: 8.0,
        endHour: 9.0,
        isExternalCalendar: true,
        externalEventId: 'id_1',
        externalCalendarName: 'Cal1',
      );

      final updated = original.copyWith(
        title: 'Modificado',
        externalCalendarName: 'Cal2',
      );

      expect(updated.title, 'Modificado');
      expect(updated.isExternalCalendar, isTrue);
      expect(updated.externalEventId, 'id_1');
      expect(updated.externalCalendarName, 'Cal2');
    });
  });

  group('ClockProvider Device Calendar State Tests', () {
    test('Default device calendar settings are disabled', () {
      final provider = ClockProvider();
      expect(provider.deviceCalendarSyncEnabled, isFalse);
      expect(provider.selectedDeviceCalendarIds, isEmpty);
      expect(provider.isDeviceCalendarSyncing, isFalse);
      provider.dispose();
    });

    test('toggleDeviceCalendarSelection adds and removes calendar IDs', () async {
      final provider = ClockProvider();
      await provider.toggleDeviceCalendarSelection('cal_work');
      expect(provider.selectedDeviceCalendarIds, contains('cal_work'));

      await provider.toggleDeviceCalendarSelection('cal_personal');
      expect(provider.selectedDeviceCalendarIds, contains('cal_work'));
      expect(provider.selectedDeviceCalendarIds, contains('cal_personal'));

      await provider.toggleDeviceCalendarSelection('cal_work');
      expect(provider.selectedDeviceCalendarIds, isNot(contains('cal_work')));
      expect(provider.selectedDeviceCalendarIds, contains('cal_personal'));
      provider.dispose();
    });
  });

  group('Device Calendar Widgets Tests', () {
    testWidgets('DeviceCalendarSheet renders title, master toggle and empty state or calendars', (tester) async {
      final provider = ClockProvider();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<ClockProvider>.value(
            value: provider,
            child: const Scaffold(
              body: DeviceCalendarSheet(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check title and switch
      expect(find.text('Calendarios del Dispositivo'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Sincronizar eventos del dispositivo'), findsOneWidget);

      provider.dispose();
    });

    testWidgets('TaskFormSheet displays external calendar badge when editing external block', (tester) async {
      final provider = ClockProvider();
      final externalBlock = TimeBlock.create(
        title: 'Reunión Externa',
        startHour: 10.0,
        endHour: 11.0,
        isExternalCalendar: true,
        externalCalendarName: 'Google Meet',
        category: TaskCategory.work,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider<ClockProvider>.value(
            value: provider,
            child: Scaffold(
              body: TaskFormSheet(existingBlock: externalBlock),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Google Meet'), findsOneWidget);
      expect(find.byIcon(Icons.event_available_rounded), findsOneWidget);

      provider.dispose();
    });
  });
}
