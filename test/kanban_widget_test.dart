import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockdo/providers/clock_provider.dart';
import 'package:clockdo/widgets/kanban/kanban_board_view.dart';
import 'package:clockdo/widgets/kanban/kanban_column.dart';
import 'package:clockdo/models/time_block.dart';
import 'package:clockdo/models/task_category.dart';
import 'package:clockdo/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('KanbanBoardView renders columns, scope selector, and task cards', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider<ClockProvider>(
        create: (_) {
          final p = ClockProvider();
          p.addBlock(TimeBlock.create(
            title: 'Prueba Kanban',
            startHour: 9.0,
            endHour: 10.0,
            category: TaskCategory.work,
            status: TaskStatus.pending,
          ));
          return p;
        },
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: Scaffold(
            body: KanbanBoardView(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    // Verificar que las columnas existan
    expect(find.byType(KanbanColumn), findsNWidgets(4)); // Backlog, Por hacer, En progreso, Completadas
    expect(find.text('Por hacer'), findsOneWidget);
    expect(find.text('En progreso'), findsOneWidget);
    expect(find.text('Completadas'), findsOneWidget);
    expect(find.text('Prueba Kanban'), findsOneWidget);

    // Desmontar el widget tree para que ChangeNotifierProvider llame a dispose()
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
