import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Tipos de frecuencia de repetición para tareas frecuentes.
enum RecurrenceFrequency {
  none,       // Tarea única, sin repetición
  daily,      // Todos los días
  weekdays,   // Días laborables (Lunes a Viernes)
  weekly,     // Semanal (mismo día de la semana)
  customDays; // Cada N días

  String get displayName {
    switch (this) {
      case RecurrenceFrequency.none:
        return 'No se repite';
      case RecurrenceFrequency.daily:
        return 'Todos los días';
      case RecurrenceFrequency.weekdays:
        return 'Días laborables (Lun - Vie)';
      case RecurrenceFrequency.weekly:
        return 'Semanalmente';
      case RecurrenceFrequency.customDays:
        return 'Personalizado';
    }
  }

  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case RecurrenceFrequency.none:
        return l10n.recurrenceNone;
      case RecurrenceFrequency.daily:
        return l10n.recurrenceDaily;
      case RecurrenceFrequency.weekdays:
        return l10n.recurrenceWeekdays;
      case RecurrenceFrequency.weekly:
        return l10n.recurrenceWeekly;
      case RecurrenceFrequency.customDays:
        return l10n.recurrenceCustom;
    }
  }
}

/// Regla de recurrencia y configuración de recordatorios periódicos por intervalo.
class RecurrenceRule {
  final RecurrenceFrequency frequency;
  final int interval; // Factor multiplicador (ej. cada N días)
  final int? reminderIntervalMinutes; // Recordar cada N minutos (ej. 30, 60, 120)
  final DateTime? endDate; // Fecha límite opcional

  const RecurrenceRule({
    this.frequency = RecurrenceFrequency.none,
    this.interval = 1,
    this.reminderIntervalMinutes,
    this.endDate,
  });

  bool get isRepeating => frequency != RecurrenceFrequency.none;
  bool get hasIntervalReminder => reminderIntervalMinutes != null && reminderIntervalMinutes! > 0;
  int? get intervalMinutes => reminderIntervalMinutes;

  /// Retorna un texto descriptivo del recordatorio periódico (ej. "Cada 30 min", "Cada 1 h")
  String formatIntervalDescription(BuildContext context) {
    if (!hasIntervalReminder) return '';
    final mins = reminderIntervalMinutes!;
    final l10n = AppLocalizations.of(context);
    if (mins >= 60 && mins % 60 == 0) {
      final hours = mins ~/ 60;
      return l10n.everyXHours(hours);
    }
    return l10n.everyXMinutes(mins);
  }

  /// Determina si una tarea agendada en [baseDate] debe ocurrir en [targetDate].
  bool occursOnDate(DateTime baseDate, DateTime targetDate) {
    final base = DateTime(baseDate.year, baseDate.month, baseDate.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);

    if (!isRepeating) {
      return base == target;
    }

    // No se proyecta a fechas anteriores al inicio de la tarea
    if (target.isBefore(base)) return false;

    // Si tiene fecha límite y ya venció
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (target.isAfter(end)) return false;
    }

    switch (frequency) {
      case RecurrenceFrequency.none:
        return base == target;
      case RecurrenceFrequency.daily:
        final daysDiff = target.difference(base).inDays;
        return daysDiff >= 0 && (daysDiff % (interval > 0 ? interval : 1) == 0);
      case RecurrenceFrequency.weekdays:
        return target.weekday >= DateTime.monday && target.weekday <= DateTime.friday;
      case RecurrenceFrequency.weekly:
        if (target.weekday != base.weekday) return false;
        final daysDiff = target.difference(base).inDays;
        final weeksDiff = daysDiff ~/ 7;
        return weeksDiff % (interval > 0 ? interval : 1) == 0;
      case RecurrenceFrequency.customDays:
        final daysDiff = target.difference(base).inDays;
        return daysDiff >= 0 && (daysDiff % (interval > 0 ? interval : 1) == 0);
    }
  }

  /// Calcula las horas (en formato decimal) donde debe dispararse el recordatorio periódico.
  List<double> calculateReminderHours({
    required double startHour,
    double? endHour,
  }) {
    if (!hasIntervalReminder) return [];
    final intervalH = reminderIntervalMinutes! / 60.0;
    if (intervalH <= 0) return [];

    final list = <double>[];
    final end = endHour ?? (startHour + 8.0).clamp(startHour, 24.0);

    double current = startHour + intervalH;
    while (current < end) {
      list.add(double.parse(current.toStringAsFixed(2)));
      current += intervalH;
    }
    return list;
  }

  RecurrenceRule copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    int? reminderIntervalMinutes,
    bool clearReminderInterval = false,
    DateTime? endDate,
    bool clearEndDate = false,
  }) {
    return RecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      reminderIntervalMinutes: clearReminderInterval
          ? null
          : (reminderIntervalMinutes ?? this.reminderIntervalMinutes),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }

  Map<String, dynamic> toJson() => {
        'frequency': frequency.index,
        'interval': interval,
        'reminderIntervalMinutes': reminderIntervalMinutes,
        'endDate': endDate?.toIso8601String(),
      };

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.values[(json['frequency'] as int? ?? 0)
          .clamp(0, RecurrenceFrequency.values.length - 1)],
      interval: json['interval'] as int? ?? 1,
      reminderIntervalMinutes: json['reminderIntervalMinutes'] as int?,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
    );
  }
}
