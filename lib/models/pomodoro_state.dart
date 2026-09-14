import 'package:flutter/material.dart';
import 'task_category.dart';
import '../l10n/app_localizations.dart';

/// Fases del ciclo Pomodoro.
enum PomodoroPhase {
  focus,
  shortBreak,
  longBreak;

  bool get isFocus => this == PomodoroPhase.focus;
  bool get isBreak => !isFocus;

  String getLocalizedName(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case PomodoroPhase.focus:
        return l10n.pomodoroFocus;
      case PomodoroPhase.shortBreak:
        return l10n.pomodoroShortBreak;
      case PomodoroPhase.longBreak:
        return l10n.pomodoroLongBreak;
    }
  }

  /// Color temático característico de cada fase
  Color get primaryColor {
    switch (this) {
      case PomodoroPhase.focus:
        return const Color(0xFFFF2A3C); // Rojo tomate intenso, vibrante y enérgico
      case PomodoroPhase.shortBreak:
        return const Color(0xFF00CEC9); // Menta / Turquesa fresco
      case PomodoroPhase.longBreak:
        return const Color(0xFF6C5CE7); // Violeta / Púrpura profundo relajante
    }
  }

  Color get secondaryColor {
    switch (this) {
      case PomodoroPhase.focus:
        return const Color(0xFFD63031); // Rojo carmesí profundo para contrastes y gradientes
      case PomodoroPhase.shortBreak:
        return const Color(0xFF81ECEC);
      case PomodoroPhase.longBreak:
        return const Color(0xFFA29BFE);
    }
  }

  IconData get icon {
    switch (this) {
      case PomodoroPhase.focus:
        return Icons.local_fire_department_rounded;
      case PomodoroPhase.shortBreak:
        return Icons.coffee_rounded;
      case PomodoroPhase.longBreak:
        return Icons.spa_rounded;
    }
  }
}

/// Estados de ejecución del temporizador Pomodoro.
enum PomodoroStatus {
  idle,
  running,
  paused;

  bool get isIdle => this == PomodoroStatus.idle;
  bool get isRunning => this == PomodoroStatus.running;
  bool get isPaused => this == PomodoroStatus.paused;
}

/// Configuración personalizada del temporizador Pomodoro.
class PomodoroSettings {
  final int focusDurationMinutes;
  final int shortBreakDurationMinutes;
  final int longBreakDurationMinutes;
  final int longBreakInterval;
  final bool autoStartBreaks;
  final bool autoStartPomodoros;
  final bool enableNotifications;
  final bool soundEnabled;

  const PomodoroSettings({
    this.focusDurationMinutes = 25,
    this.shortBreakDurationMinutes = 5,
    this.longBreakDurationMinutes = 15,
    this.longBreakInterval = 4,
    this.autoStartBreaks = false,
    this.autoStartPomodoros = false,
    this.enableNotifications = true,
    this.soundEnabled = true,
  });

  PomodoroSettings copyWith({
    int? focusDurationMinutes,
    int? shortBreakDurationMinutes,
    int? longBreakDurationMinutes,
    int? longBreakInterval,
    bool? autoStartBreaks,
    bool? autoStartPomodoros,
    bool? enableNotifications,
    bool? soundEnabled,
  }) {
    return PomodoroSettings(
      focusDurationMinutes: focusDurationMinutes ?? this.focusDurationMinutes,
      shortBreakDurationMinutes: shortBreakDurationMinutes ?? this.shortBreakDurationMinutes,
      longBreakDurationMinutes: longBreakDurationMinutes ?? this.longBreakDurationMinutes,
      longBreakInterval: longBreakInterval ?? this.longBreakInterval,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartPomodoros: autoStartPomodoros ?? this.autoStartPomodoros,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'focusDurationMinutes': focusDurationMinutes,
    'shortBreakDurationMinutes': shortBreakDurationMinutes,
    'longBreakDurationMinutes': longBreakDurationMinutes,
    'longBreakInterval': longBreakInterval,
    'autoStartBreaks': autoStartBreaks,
    'autoStartPomodoros': autoStartPomodoros,
    'enableNotifications': enableNotifications,
    'soundEnabled': soundEnabled,
  };

  factory PomodoroSettings.fromJson(Map<String, dynamic> json) {
    return PomodoroSettings(
      focusDurationMinutes: json['focusDurationMinutes'] as int? ?? 25,
      shortBreakDurationMinutes: json['shortBreakDurationMinutes'] as int? ?? 5,
      longBreakDurationMinutes: json['longBreakDurationMinutes'] as int? ?? 15,
      longBreakInterval: json['longBreakInterval'] as int? ?? 4,
      autoStartBreaks: json['autoStartBreaks'] as bool? ?? false,
      autoStartPomodoros: json['autoStartPomodoros'] as bool? ?? false,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
    );
  }
}

/// Tarea activa vinculada a la sesión de Pomodoro.
class PomodoroActiveTask {
  final String id;
  final String title;
  final TaskCategory category;
  final bool isTodo; // true si es TodoItem, false si es TimeBlock

  const PomodoroActiveTask({
    required this.id,
    required this.title,
    required this.category,
    this.isTodo = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category.toJson(),
    'isTodo': isTodo,
  };

  factory PomodoroActiveTask.fromJson(Map<String, dynamic> json) {
    return PomodoroActiveTask(
      id: json['id'] as String,
      title: json['title'] as String,
      category: TaskCategory.fromJson(json['category'] as Map<String, dynamic>),
      isTodo: json['isTodo'] as bool? ?? false,
    );
  }
}

/// Estado en memoria y persistible de la sesión Pomodoro actual.
class PomodoroSessionState {
  final PomodoroPhase phase;
  final PomodoroStatus status;
  final int remainingSeconds;
  final int totalSeconds;
  final int completedCycles; // Ciclos completados en la ronda actual (0 a longBreakInterval)
  final int totalPomodorosToday;
  final int totalFocusMinutesToday;
  final PomodoroActiveTask? activeTask;

  const PomodoroSessionState({
    this.phase = PomodoroPhase.focus,
    this.status = PomodoroStatus.idle,
    this.remainingSeconds = 25 * 60,
    this.totalSeconds = 25 * 60,
    this.completedCycles = 0,
    this.totalPomodorosToday = 0,
    this.totalFocusMinutesToday = 0,
    this.activeTask,
  });

  /// Proporción del tiempo transcurrido (0.0 a 1.0) para animar el dial radial
  double get progress {
    if (totalSeconds <= 0) return 0.0;
    final elapsed = totalSeconds - remainingSeconds;
    return (elapsed / totalSeconds).clamp(0.0, 1.0);
  }

  /// Minutos restantes redondeados hacia abajo
  int get minutes => remainingSeconds ~/ 60;

  /// Segundos restantes módulo 60
  int get seconds => remainingSeconds % 60;

  /// Cadena formateada MM:SS (ej: "24:59")
  String get formattedTime {
    final m = minutes.toString().padLeft(2, '0');
    final s = seconds.toString().padLeft(2, '0');
    return '$m:$s';
  }

  PomodoroSessionState copyWith({
    PomodoroPhase? phase,
    PomodoroStatus? status,
    int? remainingSeconds,
    int? totalSeconds,
    int? completedCycles,
    int? totalPomodorosToday,
    int? totalFocusMinutesToday,
    PomodoroActiveTask? activeTask,
    bool clearActiveTask = false,
  }) {
    return PomodoroSessionState(
      phase: phase ?? this.phase,
      status: status ?? this.status,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      completedCycles: completedCycles ?? this.completedCycles,
      totalPomodorosToday: totalPomodorosToday ?? this.totalPomodorosToday,
      totalFocusMinutesToday: totalFocusMinutesToday ?? this.totalFocusMinutesToday,
      activeTask: clearActiveTask ? null : (activeTask ?? this.activeTask),
    );
  }

  Map<String, dynamic> toJson() => {
    'phase': phase.name,
    'status': status.name,
    'remainingSeconds': remainingSeconds,
    'totalSeconds': totalSeconds,
    'completedCycles': completedCycles,
    'totalPomodorosToday': totalPomodorosToday,
    'totalFocusMinutesToday': totalFocusMinutesToday,
    'activeTask': activeTask?.toJson(),
  };

  factory PomodoroSessionState.fromJson(Map<String, dynamic> json) {
    PomodoroPhase parsePhase(String? name) {
      return PomodoroPhase.values.firstWhere(
        (p) => p.name == name,
        orElse: () => PomodoroPhase.focus,
      );
    }

    PomodoroStatus parseStatus(String? name) {
      return PomodoroStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => PomodoroStatus.idle,
      );
    }

    return PomodoroSessionState(
      phase: parsePhase(json['phase'] as String?),
      status: parseStatus(json['status'] as String?),
      remainingSeconds: json['remainingSeconds'] as int? ?? 25 * 60,
      totalSeconds: json['totalSeconds'] as int? ?? 25 * 60,
      completedCycles: json['completedCycles'] as int? ?? 0,
      totalPomodorosToday: json['totalPomodorosToday'] as int? ?? 0,
      totalFocusMinutesToday: json['totalFocusMinutesToday'] as int? ?? 0,
      activeTask: json['activeTask'] != null
          ? PomodoroActiveTask.fromJson(json['activeTask'] as Map<String, dynamic>)
          : null,
    );
  }
}
