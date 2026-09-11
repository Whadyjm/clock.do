import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockdo/models/gamification_data.dart';
import 'package:clockdo/models/task_category.dart';
import 'package:clockdo/models/time_block.dart';
import 'package:clockdo/models/todo_item.dart';
import 'package:clockdo/providers/clock_provider.dart';
import 'package:clockdo/widgets/gamification/gamification_sheet.dart';
import 'package:clockdo/widgets/gamification/achievement_unlocked_dialog.dart';
import 'package:clockdo/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GamificationData & WatchmakerLevel Models', () {
    test('WatchmakerLevel.fromTicks calculates correct levels and thresholds', () {
      expect(WatchmakerLevel.fromTicks(0).level, 1);
      expect(WatchmakerLevel.fromTicks(50).level, 1);
      expect(WatchmakerLevel.fromTicks(100).level, 2);
      expect(WatchmakerLevel.fromTicks(249).level, 2);
      expect(WatchmakerLevel.fromTicks(250).level, 3);
      expect(WatchmakerLevel.fromTicks(500).level, 4);
      expect(WatchmakerLevel.fromTicks(1000).level, 5);
      expect(WatchmakerLevel.fromTicks(2500).level, 6);
    });

    test('GamificationData JSON local serialization works bidirectionally', () {
      final now = DateTime.now().toUtc();
      final data = GamificationData(
        ticks: 350,
        currentStreak: 5,
        bestStreak: 7,
        lastActiveDate: DateTime(2026, 9, 6),
        streakFreezeCount: 2,
        totalCompletedTasks: 14,
        totalFocusMinutes: 420,
        unlockedAchievements: {'first_step': now},
      );

      final json = data.toJson();
      final restored = GamificationData.fromJson(json);

      expect(restored.ticks, 350);
      expect(restored.currentStreak, 5);
      expect(restored.bestStreak, 7);
      expect(restored.streakFreezeCount, 2);
      expect(restored.totalCompletedTasks, 14);
      expect(restored.totalFocusMinutes, 420);
      expect(restored.unlockedAchievements.containsKey('first_step'), isTrue);
      expect(restored.currentLevel.level, 3);
    });

    test('GamificationData Supabase Map serialization works bidirectionally', () {
      final data = GamificationData(
        ticks: 500,
        currentStreak: 3,
        bestStreak: 4,
        lastActiveDate: DateTime(2026, 9, 5),
        streakFreezeCount: 1,
        totalCompletedTasks: 10,
        totalFocusMinutes: 300,
        unlockedAchievements: {'early_bird': DateTime.now().toUtc()},
      );

      final map = data.toSupabaseMap();
      expect(map['ticks'], 500);
      expect(map['level'], 4);
      expect(map['current_streak'], 3);
      expect(map['best_streak'], 4);
      expect(map['streak_freeze_count'], 1);
      expect(map['last_active_date'], '2026-09-05');
      expect((map['unlocked_achievements'] as List).length, 1);

      final restored = GamificationData.fromSupabaseMap(map);
      expect(restored.ticks, 500);
      expect(restored.currentStreak, 3);
      expect(restored.bestStreak, 4);
      expect(restored.unlockedAchievements.containsKey('early_bird'), isTrue);
    });
  });

  group('ClockProvider Gamification Logic & Achievements', () {
    test('Completing a time block awards Ticks and unlocks first_step achievement', () async {
      final provider = ClockProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.gamification.ticks, 0);
      expect(provider.gamification.totalCompletedTasks, 0);

      final block = TimeBlock.create(
        title: 'Bloque de Estudio',
        startHour: 10.0,
        endHour: 11.5,
      );
      provider.addBlock(block);

      // Pending -> InProgress -> Completed
      provider.toggleStatus(block.id); // InProgress
      expect(provider.gamification.ticks, 0);

      provider.toggleStatus(block.id); // Completed
      expect(provider.gamification.ticks, greaterThanOrEqualTo(25));
      expect(provider.gamification.totalCompletedTasks, 1);
      expect(provider.gamification.currentStreak, 1);
      expect(provider.gamification.unlockedAchievements.containsKey('first_step'), isTrue);
    });

    test('Completing a ToDo item awards +15 Ticks', () async {
      final provider = ClockProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final initialTicks = provider.gamification.ticks;
      final todo = TodoItem.create(title: 'Organizar escritorio');
      provider.addTodo(todo);

      provider.toggleTodo(todo.id);
      expect(provider.gamification.ticks, initialTicks + 15);
    });

    test('Golden Dial calculation: achieves golden status at >= 80% with >= 2 tasks', () async {
      final provider = ClockProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.isGoldenDialAchieved, isFalse);

      final b1 = TimeBlock.create(title: 'T1', startHour: 9.0, endHour: 10.0);
      final b2 = TimeBlock.create(title: 'T2', startHour: 10.0, endHour: 11.0);
      final b3 = TimeBlock.create(title: 'T3', startHour: 11.0, endHour: 12.0);

      provider.addBlock(b1);
      provider.addBlock(b2);
      provider.addBlock(b3);

      expect(provider.isGoldenDialAchieved, isFalse);

      // Complete 1 out of 3 (33%)
      provider.toggleStatus(b1.id);
      provider.toggleStatus(b1.id);
      expect(provider.isGoldenDialAchieved, isFalse);

      // Complete 2 out of 3 (66%)
      provider.toggleStatus(b2.id);
      provider.toggleStatus(b2.id);
      expect(provider.isGoldenDialAchieved, isFalse);

      // Complete 3 out of 3 (100% >= 80%)
      provider.toggleStatus(b3.id);
      provider.toggleStatus(b3.id);
      expect(provider.isGoldenDialAchieved, isTrue);
      expect(provider.dailyCompletionRatio, 1.0);
    });

    test('Category Rewards: completing 5 Work blocks unlocks work_starter badge', () {
      final provider = ClockProvider();

      for (int i = 0; i < 5; i++) {
        final b = TimeBlock.create(
          title: 'Work Task $i',
          startHour: 9.0 + i,
          endHour: 10.0 + i,
          category: TaskCategory.work,
        );
        provider.addBlock(b);
        provider.setBlockStatus(b.id, TaskStatus.completed);
      }

      expect(provider.gamification.getCompletedCountForCategory('work'), 5);
      expect(provider.gamification.unlockedAchievements.containsKey('work_starter'), isTrue);
    });
  });

  group('Gamification UI Widgets', () {
    Widget buildTestApp(Widget child) {
      return ChangeNotifierProvider(
        create: (_) => ClockProvider(),
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('GamificationSheet renders level card, streak, and achievements list', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(const GamificationSheet()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Maestría del Tiempo'), findsOneWidget);
      expect(find.text('Racha Actual'), findsOneWidget);
      expect(find.text('Maestría por Categorías'), findsOneWidget);
      expect(find.text('Medallas de Logros'), findsOneWidget);
      expect(find.text('Primer Paso'), findsOneWidget);
      expect(find.text('Madrugador'), findsOneWidget);
      expect(find.text('Escudos de Racha'), findsOneWidget);
    });

    testWidgets('AchievementCelebrationDialog renders badge celebration and dismiss button', (tester) async {
      final ach = Achievement.catalog.first;
      await tester.pumpWidget(
        buildTestApp(
          AchievementCelebrationDialog(achievement: ach),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('¡Nueva medalla desbloqueada: Primer Paso!'), findsOneWidget);
      expect(find.text('+25 Ticks 🪙'), findsOneWidget);
      expect(find.text('¡Genial!'), findsOneWidget);

      await tester.tap(find.text('¡Genial!'));
      await tester.pump();
    });
  });
}
