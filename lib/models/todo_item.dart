import 'package:uuid/uuid.dart';
import 'task_category.dart';
import 'task_priority.dart';

/// Modelo de una tarea ToDo (pendiente general sin horario ni fecha fija).
class TodoItem {
  final String id;
  final String title;
  final String? description;
  final TaskCategory category;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  const TodoItem({
    required this.id,
    required this.title,
    this.description,
    this.category = TaskCategory.none,
    this.priority = TaskPriority.none,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  /// Constructor de fábrica para crear un nuevo TodoItem con ID y fecha automáticos.
  factory TodoItem.create({
    required String title,
    String? description,
    TaskCategory category = TaskCategory.none,
    TaskPriority priority = TaskPriority.none,
  }) {
    return TodoItem(
      id: const Uuid().v4(),
      title: title.trim(),
      description: description?.trim().isEmpty ?? true ? null : description?.trim(),
      category: category,
      priority: priority,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
  }

  /// Crea una copia de la tarea con los campos proporcionados modificados.
  TodoItem copyWith({
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
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
      priority: priority ?? this.priority,
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
        'categoryId': category.id,
        'priority': priority.index,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  /// Serializa a Map en formato Postgres snake_case para Supabase.
  Map<String, dynamic> toSupabaseMap() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.index,
        'category_id': category.id,
        'priority': priority.index,
        'is_completed': isCompleted,
        'created_at': createdAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };

  /// Deserializa desde JSON.
  factory TodoItem.fromJson(
    Map<String, dynamic> json, {
    List<TaskCategory> customCategories = const [],
  }) {
    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: TaskCategory.fromIdOrIndex(
        id: json['categoryId'] as String? ?? json['category_id'] as String?,
        index: json['category'] as int?,
        customCategories: customCategories,
      ),
      priority: TaskPriority.fromIndex(json['priority'] as int?),
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }

  /// Deserializa desde registro Supabase.
  factory TodoItem.fromSupabaseMap(
    Map<String, dynamic> map, {
    List<TaskCategory> customCategories = const [],
  }) {
    return TodoItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: TaskCategory.fromIdOrIndex(
        id: map['category_id'] as String?,
        index: map['category'] as int?,
        customCategories: customCategories,
      ),
      priority: TaskPriority.fromIndex(map['priority'] as int?),
      isCompleted: map['is_completed'] as bool? ?? map['isCompleted'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : (map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
              : DateTime.now()),
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : (map['completedAt'] != null
              ? DateTime.tryParse(map['completedAt'] as String)
              : null),
    );
  }

  @override
  String toString() =>
      'TodoItem($title, category: ${category.displayName}, priority: ${priority.displayName}, isCompleted: $isCompleted)';
}
