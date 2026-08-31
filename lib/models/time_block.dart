import 'package:uuid/uuid.dart';
import 'task_category.dart';

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
  final double endHour;

  final TaskCategory category;
  final TaskStatus status;

  /// Índice del anillo concéntrico asignado por la lógica de solapamientos.
  /// 0 = anillo exterior, 1 = siguiente hacia adentro, etc.
  final int ringIndex;

  TimeBlock({
    required this.id,
    required this.title,
    this.description,
    DateTime? date,
    required this.startHour,
    required this.endHour,
    this.category = TaskCategory.none,
    this.status = TaskStatus.pending,
    this.ringIndex = 0,
  }) : date = normalizeDate(date ?? DateTime.now());

  /// Constructor de fábrica para crear un nuevo TimeBlock con ID automático.
  factory TimeBlock.create({
    required String title,
    String? description,
    DateTime? date,
    required double startHour,
    required double endHour,
    TaskCategory category = TaskCategory.none,
    TaskStatus status = TaskStatus.pending,
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
    );
  }

  /// Duración en horas decimales.
  double get durationHours => endHour - startHour;

  /// Devuelve true si la tarea corresponde al mismo día dado.
  bool isOnDay(DateTime otherDate) {
    return date.year == otherDate.year &&
        date.month == otherDate.month &&
        date.day == otherDate.day;
  }

  /// Devuelve true si esta tarea se solapa con [other] (ambas en el mismo día).
  bool overlapsWith(TimeBlock other) {
    if (!isOnDay(other.date)) return false;
    return startHour < other.endHour && endHour > other.startHour;
  }

  /// Devuelve true si la tarea está activa en la hora dada.
  bool isActiveAt(double hour) {
    return hour >= startHour && hour < endHour;
  }

  /// Crea una copia del TimeBlock con los campos proporcionados modificados.
  TimeBlock copyWith({
    String? title,
    String? description,
    DateTime? date,
    double? startHour,
    double? endHour,
    TaskCategory? category,
    TaskStatus? status,
    int? ringIndex,
  }) {
    return TimeBlock(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      category: category ?? this.category,
      status: status ?? this.status,
      ringIndex: ringIndex ?? this.ringIndex,
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
        'status': status.index,
        'ringIndex': ringIndex,
      };

  /// Deserializa desde JSON.
  factory TimeBlock.fromJson(Map<String, dynamic> json) {
    return TimeBlock(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      startHour: (json['startHour'] as num).toDouble(),
      endHour: (json['endHour'] as num).toDouble(),
      category: TaskCategory.values[json['category'] as int],
      status: TaskStatus.values[json['status'] as int],
      ringIndex: json['ringIndex'] as int? ?? 0,
    );
  }

  @override
  String toString() =>
      'TimeBlock($title, ${date.toIso8601String().split('T').first}, $startHour–$endHour, ${category.displayName}, ${status.displayName})';
}
