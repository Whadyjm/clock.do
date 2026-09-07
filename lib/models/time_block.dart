import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'task_category.dart';
import '../l10n/app_localizations.dart';

/// Estado de una tarea en el sistema.
enum TaskStatus {
  pending,    // Pendiente
  inProgress, // En progreso
  completed;  // Completada

  String get displayName {
    switch (this) {
      case TaskStatus.pending:
        return 'Pendiente';
      case TaskStatus.inProgress:
        return 'En progreso';
      case TaskStatus.completed:
        return 'Completada';
    }
  }

  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case TaskStatus.pending:
        return l10n.statusPending;
      case TaskStatus.inProgress:
        return l10n.statusInProgress;
      case TaskStatus.completed:
        return l10n.statusCompleted;
    }
  }
}

/// Helper para normalizar fechas al día sin horas/minutos
DateTime normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

/// Modelo de un bloque de tiempo (tarea) en el reloj radial con soporte de calendario.
class TimeBlock {
  final String id;
  final String title;
  final String? description;

  /// Fecha en la que está agendada la tarea (año/mes/día).
  final DateTime date;

  /// Hora de inicio en formato decimal (ej: 9.5 = 9:30 AM).
  final double startHour;

  /// Hora de fin en formato decimal (ej: 11.0 = 11:00 AM).
  /// Si es null, representa una tarea puntual sin rango ni hora de término.
  final double? endHour;

  final TaskCategory category;
  final TaskStatus status;

  /// Índice del anillo concéntrico asignado por la lógica de solapamientos.
  /// 0 = anillo exterior, 1 = siguiente hacia adentro, etc.
  final int ringIndex;

  /// Indica si las notificaciones están activadas para este bloque específico.
  final bool notificationEnabled;

  /// Minutos de anticipación específicos para este bloque.
  /// Si es null, utiliza el valor global configurado en el sistema.
  final int? reminderMinutes;

  /// Indica si es una tarea puntual en una hora específica sin hora/fecha fin.
  bool get isPointInTime => endHour == null;

  TimeBlock({
    required this.id,
    required this.title,
    this.description,
    DateTime? date,
    required this.startHour,
    this.endHour,
    this.category = TaskCategory.none,
    this.status = TaskStatus.pending,
    this.ringIndex = 0,
    this.notificationEnabled = true,
    this.reminderMinutes,
  }) : date = normalizeDate(date ?? DateTime.now());

  /// Constructor de fábrica para crear un nuevo TimeBlock con ID automático.
  factory TimeBlock.create({
    required String title,
    String? description,
    DateTime? date,
    required double startHour,
    double? endHour,
    TaskCategory category = TaskCategory.none,
    TaskStatus status = TaskStatus.pending,
    bool notificationEnabled = true,
    int? reminderMinutes,
  }) {
    return TimeBlock(
      id: const Uuid().v4(),
      title: title,
      description: description,
      date: date ?? DateTime.now(),
      startHour: startHour,
      endHour: endHour,
      category: category,
      status: status,
      ringIndex: 0,
      notificationEnabled: notificationEnabled,
      reminderMinutes: reminderMinutes,
    );
  }

  /// Duración en horas decimales (0.0 si es tarea puntual).
  double get durationHours => isPointInTime ? 0.0 : (endHour! - startHour);

  /// Devuelve true si la tarea corresponde al mismo día dado.
  bool isOnDay(DateTime otherDate) {
    return date.year == otherDate.year &&
        date.month == otherDate.month &&
        date.day == otherDate.day;
  }

  /// Devuelve true si esta tarea se solapa con [other] (ambas en el mismo día).
  bool overlapsWith(TimeBlock other) {
    if (!isOnDay(other.date)) return false;
    if (isPointInTime && other.isPointInTime) {
      return (startHour - other.startHour).abs() < 0.08;
    }
    if (isPointInTime) {
      return startHour >= other.startHour && startHour < (other.endHour ?? other.startHour);
    }
    if (other.isPointInTime) {
      return other.startHour >= startHour && other.startHour < (endHour ?? startHour);
    }
    return startHour < other.endHour! && endHour! > other.startHour;
  }

  /// Devuelve true si la tarea está activa en la hora dada.
  bool isActiveAt(double hour) {
    if (isPointInTime) {
      return (hour - startHour).abs() < 0.25;
    }
    return hour >= startHour && hour < endHour!;
  }

  /// Crea una copia del TimeBlock con los campos proporcionados modificados.
  TimeBlock copyWith({
    String? title,
    String? description,
    DateTime? date,
    double? startHour,
    double? endHour,
    bool clearEndHour = false,
    TaskCategory? category,
    TaskStatus? status,
    int? ringIndex,
    bool? notificationEnabled,
    int? reminderMinutes,
    bool clearReminderMinutes = false,
  }) {
    return TimeBlock(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startHour: startHour ?? this.startHour,
      endHour: clearEndHour ? null : (endHour ?? this.endHour),
      category: category ?? this.category,
      status: status ?? this.status,
      ringIndex: ringIndex ?? this.ringIndex,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      reminderMinutes: clearReminderMinutes
          ? null
          : (reminderMinutes ?? this.reminderMinutes),
    );
  }

  /// Serializa a JSON para persistencia en SharedPreferences.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'startHour': startHour,
        'endHour': endHour,
        'category': category.index,
        'categoryId': category.id,
        'status': status.index,
        'ringIndex': ringIndex,
        'notificationEnabled': notificationEnabled,
        'reminderMinutes': reminderMinutes,
      };

  /// Serializa a Map en formato Postgres snake_case para Supabase.
  Map<String, dynamic> toSupabaseMap() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String().split('T').first,
        'start_hour': startHour,
        'end_hour': endHour,
        'category': category.index,
        'category_id': category.id,
        'status': status.index,
        'notification_enabled': notificationEnabled,
        'reminder_minutes': reminderMinutes,
      };

  /// Deserializa desde JSON.
  factory TimeBlock.fromJson(
    Map<String, dynamic> json, {
    List<TaskCategory> customCategories = const [],
  }) {
    return TimeBlock(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      startHour: (json['startHour'] as num).toDouble(),
      endHour: (json['endHour'] as num?)?.toDouble(),
      category: TaskCategory.fromIdOrIndex(
        id: json['categoryId'] as String? ?? json['category_id'] as String?,
        index: json['category'] as int?,
        customCategories: customCategories,
      ),
      status: TaskStatus.values[json['status'] as int],
      ringIndex: json['ringIndex'] as int? ?? 0,
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      reminderMinutes: json['reminderMinutes'] as int?,
    );
  }

  /// Deserializa desde registro Supabase.
  factory TimeBlock.fromSupabaseMap(
    Map<String, dynamic> map, {
    List<TaskCategory> customCategories = const [],
  }) {
    return TimeBlock(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      startHour: (map['start_hour'] as num? ?? map['startHour'] as num).toDouble(),
      endHour: (map['end_hour'] as num? ?? map['endHour'] as num?)?.toDouble(),
      category: TaskCategory.fromIdOrIndex(
        id: map['category_id'] as String?,
        index: (map['category'] as int? ?? 0).clamp(0, TaskCategory.values.length - 1),
        customCategories: customCategories,
      ),
      status: TaskStatus.values[
          (map['status'] as int? ?? 0).clamp(0, TaskStatus.values.length - 1)],
      ringIndex: 0,
      notificationEnabled: map['notification_enabled'] as bool? ?? true,
      reminderMinutes: map['reminder_minutes'] as int?,
    );
  }

  @override
  String toString() =>
      'TimeBlock($title, ${date.toIso8601String().split('T').first}, ${isPointInTime ? '@$startHour' : '$startHour–$endHour'}, ${category.displayName}, ${status.displayName})';
}
