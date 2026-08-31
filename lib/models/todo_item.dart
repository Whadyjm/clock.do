import 'package:uuid/uuid.dart';
import 'task_category.dart';

/// Modelo de una tarea ToDo (pendiente general sin horario ni fecha fija).
class TodoItem {
  final String id;
  final String title;
  final String? description;
  final TaskCategory category;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  const TodoItem({
    required this.id,
    required this.title,
    this.description,
    this.category = TaskCategory.none,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  /// Constructor de fábrica para crear un nuevo TodoItem con ID y fecha automáticos.
  factory TodoItem.create({
    required String title,
    String? description,
    TaskCategory category = TaskCategory.none,
  }) {
    return TodoItem(
      id: const Uuid().v4(),
      title: title.trim(),
      description: description?.trim().isEmpty ?? true ? null : description?.trim(),
      category: category,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
  }

  /// Crea una copia de la tarea con los campos proporcionados modificados.
  TodoItem copyWith({
    String? title,
    String? description,
    TaskCategory? category,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  /// Serializa a JSON para persistencia.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.index,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  /// Deserializa desde JSON.
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] != null && json['category'] is int
          ? TaskCategory.values[(json['category'] as int).clamp(0, TaskCategory.values.length - 1)]
          : TaskCategory.none,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'TodoItem($title, category: ${category.displayName}, isCompleted: $isCompleted)';
}
