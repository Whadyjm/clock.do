import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockdo/providers/clock_provider.dart';
import 'package:clockdo/screens/home_screen.dart';
import 'package:clockdo/widgets/calendar/weekly_date_strip.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('es', null);
  });

  testWidgets('ClockDo app renders HomeScreen, WeeklyDateStrip, calendar and notification buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ClockProvider(),
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Avanzar un frame para que se dibuje la UI
    await tester.pump(const Duration(milliseconds: 300));

    // Verifica componentes principales
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(WeeklyDateStrip), findsOneWidget);
    expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    // Tocar el botón de ToDo para abrir la hoja
    await tester.tap(find.byIcon(Icons.checklist_rounded));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Tareas ToDo'), findsOneWidget);
    expect(find.text('Pendientes'), findsOneWidget);
  });
}
