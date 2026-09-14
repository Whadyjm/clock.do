import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockdo/models/pomodoro_state.dart';
import 'package:clockdo/models/task_category.dart';
import 'package:clockdo/models/time_block.dart';
import 'package:clockdo/models/todo_item.dart';
import 'package:clockdo/providers/clock_provider.dart';
import 'package:clockdo/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pomodoro Models Tests', () {
    test('PomodoroSettings default values and JSON serialization', () {
      const settings = PomodoroSettings();
      expect(settings.focusDurationMinutes, 25);
      expect(settings.shortBreakDurationMinutes, 5);
      expect(settings.longBreakDurationMinutes, 15);
      expect(settings.longBreakInterval, 4);
      expect(settings.autoStartBreaks, false);
      expect(settings.autoStartPomodoros, false);
      expect(settings.enableNotifications, true);
      expect(settings.soundEnabled, true);

      final json = settings.toJson();
      final fromJson = PomodoroSettings.fromJson(json);
      expect(fromJson.focusDurationMinutes, 25);
      expect(fromJson.shortBreakDurationMinutes, 5);
      expect(fromJson.longBreakDurationMinutes, 15);
      expect(fromJson.longBreakInterval, 4);
      expect(fromJson.enableNotifications, true);
      expect(fromJson.soundEnabled, true);
    });

    test('PomodoroSessionState defaults and progress calculation', () {
      const session = PomodoroSessionState(
        phase: PomodoroPhase.focus,
        status: PomodoroStatus.idle,
        remainingSeconds: 25 * 60,
        totalSeconds: 25 * 60,
      );

      expect(session.progress, 0.0);
      expect(session.formattedTime, '25:00');
      expect(session.minutes, 25);
      expect(session.seconds, 0);

      // Halfway elapsed
      final halfway = session.copyWith(remainingSeconds: 750);
      expect(halfway.progress, closeTo(0.5, 0.01));
      expect(halfway.formattedTime, '12:30');
    });

    test('PomodoroActiveTask serialization', () {
      const activeTask = PomodoroActiveTask(
        id: 'task-123',
        title: 'Diseñar Mockups',
        category: TaskCategory.work,
        isTodo: false,
      );

      final json = activeTask.toJson();
      final restored = PomodoroActiveTask.fromJson(json);
      expect(restored.id, 'task-123');
      expect(restored.title, 'Diseñar Mockups');
      expect(restored.category.id, TaskCategory.work.id);
      expect(restored.isTodo, false);
    });
  });

  group('ClockProvider Pomodoro Integration Tests', () {
    late ClockProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = ClockProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('Initial view mode and Pomodoro default state in provider', () {
      expect(provider.viewMode, AppViewMode.clock);
      expect(provider.pomodoroState.phase, PomodoroPhase.focus);
      expect(provider.pomodoroState.status, PomodoroStatus.idle);
      expect(provider.pomodoroState.remainingSeconds, 25 * 60);
      expect(provider.hasActivePomodoroSession, false);
      expect(provider.isPomodoroRunning, false);
    });

    test('setViewMode to AppViewMode.pomodoro updates viewMode', () {
      provider.setViewMode(AppViewMode.pomodoro);
      expect(provider.viewMode, AppViewMode.pomodoro);
    });

    test('startPomodoro, pausePomodoro, resumePomodoro, and resetPomodoro', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      // Iniciar
      provider.startPomodoro();
      expect(provider.pomodoroState.status, PomodoroStatus.running);
      expect(provider.isPomodoroRunning, true);
      expect(provider.hasActivePomodoroSession, true);

      // Pausar
      provider.pausePomodoro();
      expect(provider.pomodoroState.status, PomodoroStatus.paused);
      expect(provider.isPomodoroRunning, false);
      expect(provider.hasActivePomodoroSession, true);

      // Reanudar
      provider.resumePomodoro();
      expect(provider.pomodoroState.status, PomodoroStatus.running);

      // Reiniciar
      provider.resetPomodoro();
      expect(provider.pomodoroState.status, PomodoroStatus.idle);
      expect(provider.pomodoroState.remainingSeconds, 25 * 60);
      expect(provider.hasActivePomodoroSession, false);
      expect(notifyCount, greaterThanOrEqualTo(4));
    });

    test('adjustPomodoroTime modifies remaining and total seconds safely', () {
      provider.adjustPomodoroTime(5); // +5 min
      expect(provider.pomodoroState.remainingSeconds, 30 * 60);
      expect(provider.pomodoroState.totalSeconds, 30 * 60);

      provider.adjustPomodoroTime(-10); // -10 min
      expect(provider.pomodoroState.remainingSeconds, 20 * 60);

      // Clamping to minimum 60 seconds
      provider.adjustPomodoroTime(-30);
      expect(provider.pomodoroState.remainingSeconds, 60);
    });

    test('setPomodoroPhase manually switches between focus and breaks', () {
      provider.setPomodoroPhase(PomodoroPhase.shortBreak);
      expect(provider.pomodoroState.phase, PomodoroPhase.shortBreak);
      expect(provider.pomodoroState.remainingSeconds, 5 * 60);

      provider.setPomodoroPhase(PomodoroPhase.longBreak);
      expect(provider.pomodoroState.phase, PomodoroPhase.longBreak);
      expect(provider.pomodoroState.remainingSeconds, 15 * 60);

      provider.setPomodoroPhase(PomodoroPhase.focus);
      expect(provider.pomodoroState.phase, PomodoroPhase.focus);
      expect(provider.pomodoroState.remainingSeconds, 25 * 60);
    });

    test('skipPomodoroPhase advances cycles and switches to long break after N intervals', () {
      expect(provider.pomodoroState.completedCycles, 0);

      // Focus (ciclo 0) -> skip -> Short Break (ciclo 1)
      provider.skipPomodoroPhase();
      expect(provider.pomodoroState.phase, PomodoroPhase.shortBreak);
      expect(provider.pomodoroState.completedCycles, 1);

      // Short Break -> skip -> Focus (ciclo 1)
      provider.skipPomodoroPhase();
      expect(provider.pomodoroState.phase, PomodoroPhase.focus);
      expect(provider.pomodoroState.completedCycles, 1);

      // Focus (ciclo 1) -> skip -> Short Break (ciclo 2)
      provider.skipPomodoroPhase();
      expect(provider.pomodoroState.completedCycles, 2);

      provider.skipPomodoroPhase(); // Focus (ciclo 2)
      provider.skipPomodoroPhase(); // Short break (ciclo 3)
      provider.skipPomodoroPhase(); // Focus (ciclo 3)

      // Focus (ciclo 3) -> skip con 4to ciclo completado -> Long Break!
      provider.skipPomodoroPhase();
      expect(provider.pomodoroState.phase, PomodoroPhase.longBreak);
      expect(provider.pomodoroState.completedCycles, 0); // Reiniciado para siguiente ronda
    });

    test('setPomodoroActiveTask and completePomodoroTask for TimeBlock and TodoItem', () {
      final block = TimeBlock.create(
        title: 'Estudiar Arquitectura',
        startHour: 9.0,
        endHour: 10.0,
        category: TaskCategory.learning,
        status: TaskStatus.pending,
      );
      provider.addBlock(block);

      provider.setPomodoroActiveTask(
        id: block.id,
        title: block.title,
        category: block.category,
        isTodo: false,
      );

      expect(provider.pomodoroState.activeTask, isNotNull);
      expect(provider.pomodoroState.activeTask!.id, block.id);
      expect(provider.pomodoroState.activeTask!.title, 'Estudiar Arquitectura');

      // Completar la tarea desde Pomodoro
      provider.completePomodoroTask();
      expect(provider.allBlocks.first.status, TaskStatus.completed);

      // Probar con TodoItem
      final todo = TodoItem.create(
        title: 'Comprar café',
        category: TaskCategory.personal,
      );
      provider.addTodo(todo);

      provider.setPomodoroActiveTask(
        id: todo.id,
        title: todo.title,
        category: todo.category,
        isTodo: true,
      );

      provider.completePomodoroTask();
      expect(provider.todoItems.first.isCompleted, true);

      // Limpiar tarea activa
      provider.clearPomodoroActiveTask();
      expect(provider.pomodoroState.activeTask, isNull);
    });

    test('updatePomodoroSettings updates durations and recalculates idle session time', () {
      provider.updatePomodoroSettings(const PomodoroSettings(
        focusDurationMinutes: 50,
        shortBreakDurationMinutes: 10,
        longBreakDurationMinutes: 20,
        longBreakInterval: 3,
      ));

      expect(provider.pomodoroSettings.focusDurationMinutes, 50);
      expect(provider.pomodoroState.remainingSeconds, 50 * 60);
      expect(provider.pomodoroState.totalSeconds, 50 * 60);
    });

    test('Notification tap callback navigates to AppViewMode.pomodoro', () {
      provider.setViewMode(AppViewMode.clock);
      expect(provider.viewMode, AppViewMode.clock);

      NotificationService().onPomodoroNotificationTapped?.call();
      expect(provider.viewMode, AppViewMode.pomodoro);
    });
  });
}
