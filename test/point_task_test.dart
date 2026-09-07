import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clockdo/models/time_block.dart';
import 'package:clockdo/models/task_category.dart';
import 'package:clockdo/widgets/task_form_sheet.dart';
import 'package:clockdo/widgets/radial_clock_canvas.dart';
import 'package:clockdo/providers/clock_provider.dart';
import 'package:clockdo/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TimeBlock Point-in-Time Unit Tests', () {
    test('Creates point-in-time task when endHour is null', () {
      final block = TimeBlock.create(
        title: 'Tomar medicina',
        startHour: 14.5,
        endHour: null,
        category: TaskCategory.health,
      );

      expect(block.isPointInTime, isTrue);
      expect(block.endHour, isNull);
      expect(block.durationHours, 0.0);
      expect(block.toString(), contains('@14.5'));
    });

    test('Creates standard range task when endHour is provided', () {
      final block = TimeBlock.create(
        title: 'Reunión',
        startHour: 10.0,
        endHour: 11.5,
      );

      expect(block.isPointInTime, isFalse);
      expect(block.endHour, 11.5);
      expect(block.durationHours, 1.5);
      expect(block.toString(), contains('10.0–11.5'));
    });

    test('copyWith can convert between point and range tasks', () {
      final rangeBlock = TimeBlock.create(
        title: 'Test',
        startHour: 9.0,
        endHour: 10.0,
      );

      // Convert to point task
      final pointBlock = rangeBlock.copyWith(clearEndHour: true);
      expect(pointBlock.isPointInTime, isTrue);
      expect(pointBlock.endHour, isNull);

      // Convert back to range task
      final backToRange = pointBlock.copyWith(endHour: 11.0);
      expect(backToRange.isPointInTime, isFalse);
      expect(backToRange.endHour, 11.0);
    });

    test('JSON serialization roundtrip for point-in-time task', () {
      final block = TimeBlock.create(
        title: 'Alarma puntual',
        description: 'Verificar servidor',
        startHour: 18.25,
        category: TaskCategory.work,
        status: TaskStatus.inProgress,
      );

      final json = block.toJson();
      expect(json['endHour'], isNull);
      expect(json['startHour'], 18.25);

      final fromJson = TimeBlock.fromJson(json);
      expect(fromJson.id, block.id);
      expect(fromJson.title, block.title);
      expect(fromJson.isPointInTime, isTrue);
      expect(fromJson.endHour, isNull);
      expect(fromJson.startHour, 18.25);
    });

    test('Supabase map serialization roundtrip for point-in-time task', () {
      final block = TimeBlock.create(
        title: 'Llamar al cliente',
        date: DateTime(2026, 9, 6),
        startHour: 15.0,
        category: TaskCategory.work,
      );

      final map = block.toSupabaseMap();
      expect(map['end_hour'], isNull);
      expect(map['start_hour'], 15.0);

      final fromMap = TimeBlock.fromSupabaseMap(map);
      expect(fromMap.isPointInTime, isTrue);
      expect(fromMap.endHour, isNull);
      expect(fromMap.startHour, 15.0);
      expect(fromMap.title, 'Llamar al cliente');
    });

    test('overlapsWith handles point-in-time tasks properly', () {
      final pointAt10 = TimeBlock.create(
        title: 'Puntual 10:00',
        startHour: 10.0,
      );
      final range9To11 = TimeBlock.create(
        title: 'Rango 9-11',
        startHour: 9.0,
        endHour: 11.0,
      );
      final range11To12 = TimeBlock.create(
        title: 'Rango 11-12',
        startHour: 11.0,
        endHour: 12.0,
      );
      final pointAt10Also = TimeBlock.create(
        title: 'Otro a las 10:00',
        startHour: 10.02,
      );

      // Point task at 10 falls within 9-11
      expect(pointAt10.overlapsWith(range9To11), isTrue);
      expect(range9To11.overlapsWith(pointAt10), isTrue);

      // Point task at 10 does not overlap 11-12
      expect(pointAt10.overlapsWith(range11To12), isFalse);
      expect(range11To12.overlapsWith(pointAt10), isFalse);

      // Two point tasks close to each other overlap
      expect(pointAt10.overlapsWith(pointAt10Also), isTrue);
    });

    test('isActiveAt evaluates point-in-time tasks correctly', () {
      final pointTask = TimeBlock.create(
        title: 'Alarma',
        startHour: 14.0,
      );

      expect(pointTask.isActiveAt(14.0), isTrue);
      expect(pointTask.isActiveAt(14.1), isTrue);
      expect(pointTask.isActiveAt(14.3), isFalse);
    });
  });

  group('Point-in-Time Task Widget Tests', () {
    testWidgets('TaskFormSheet allows toggling to point-in-time task mode', (tester) async {
      final provider = ClockProvider();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: provider,
              child: const TaskFormSheet(
                suggestedStartHour: 14.0,
                suggestedEndHour: 15.0,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Deberían verse inicialmente los títulos de hora de inicio y fin
      expect(find.text('HORA DE INICIO'), findsOneWidget);
      expect(find.text('HORA DE FIN'), findsOneWidget);

      // Seleccionar opción de tarea puntual
      final pointTaskTab = find.text('Tarea puntual (sin fin)');
      expect(pointTaskTab, findsOneWidget);
      await tester.tap(pointTaskTab);
      await tester.pumpAndSettle();

      // Ahora debe mostrar la tarjeta para la hora de la tarea puntual
      expect(find.text('HORA DE LA TAREA'), findsOneWidget);

      // Limpiar provider timer
      provider.dispose();
    });

    testWidgets('RadialClockCanvas renders point-in-time marker and supports touch inspection', (tester) async {
      final pointBlock = TimeBlock.create(
        title: 'Hito puntual',
        startHour: 6.0,
        category: TaskCategory.work,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: RadialClockCanvas(
                  blocks: [pointBlock],
                  currentHour: 6.0,
                  is24h: false,
                  now: DateTime(2026, 9, 6, 6, 0),
                  onGestureComplete: (_, __) {},
                  onBlockTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // Verificar que el widget está montado
      expect(find.byType(RadialClockCanvas), findsOneWidget);

      // Activar modo lupa
      final magnifierBtn = find.text('Lupa');
      expect(magnifierBtn, findsOneWidget);
      await tester.tap(magnifierBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Comprobar que la tarjeta de inspección muestra el título y chip Puntual
      expect(find.text('Hito puntual'), findsOneWidget);
      expect(find.text('Puntual'), findsOneWidget);
    });
  });
}
