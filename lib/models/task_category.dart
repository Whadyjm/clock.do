import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Modelo de categoría de tarea con soporte para categorías predeterminadas y personalizadas.
class TaskCategory {
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final bool isDefault;

  const TaskCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.isDefault = false,
  });

  /// Factory para crear una nueva categoría personalizada con UUID único.
  factory TaskCategory.custom({
    required String name,
    required Color color,
    required IconData icon,
    String? id,
  }) {
    return TaskCategory(
      id: id ?? const Uuid().v4(),
      name: name,
      color: color,
      icon: icon,
      isDefault: false,
    );
  }

  /// Nombre para mostrar (compatibilidad con la API previa).
  String get displayName => name;

  // ──────────────────────────────────────────────
  // Categorías Predeterminadas
  // ──────────────────────────────────────────────

  static const TaskCategory work = TaskCategory(
    id: 'work',
    name: 'Trabajo',
    color: Color(0xFFFED330), // Amarillo resaltador
    icon: Icons.work_rounded,
    isDefault: true,
  );

  static const TaskCategory personal = TaskCategory(
    id: 'personal',
    name: 'Personal',
    color: Color(0xFFFF6B81), // Coral suave
    icon: Icons.favorite_rounded,
    isDefault: true,
  );

  static const TaskCategory health = TaskCategory(
    id: 'health',
    name: 'Salud',
    color: Color(0xFF2ED573), // Verde menta fresco
    icon: Icons.spa_rounded,
    isDefault: true,
  );

  static const TaskCategory learning = TaskCategory(
    id: 'learning',
    name: 'Enfoque',
    color: Color(0xFF70A1FF), // Azul cielo pastel
    icon: Icons.bolt_rounded,
    isDefault: true,
  );

  static const TaskCategory social = TaskCategory(
    id: 'social',
    name: 'Social',
    color: Color(0xFFA55EEA), // Violeta / Lavanda
    icon: Icons.people_alt_rounded,
    isDefault: true,
  );

  static const TaskCategory none = TaskCategory(
    id: 'none',
    name: 'General',
    color: Color(0xFF747D8C), // Gris pizarra suave
    icon: Icons.circle_rounded,
    isDefault: true,
  );

  /// Lista de categorías fijas predeterminadas del sistema.
  static const List<TaskCategory> defaultCategories = [
    work,
    personal,
    health,
    learning,
    social,
    none,
  ];

  /// Getter values para compatibilidad con llamadas tipo enum.
  static List<TaskCategory> get values => defaultCategories;

  /// Índice entero (0-5) para persistencia hacia atrás. Si es personalizada, retorna 0 (General).
  int get index {
    final idx = defaultCategories.indexWhere((c) => c.id == id);
    return idx != -1 ? idx : 0;
  }

  /// Serializa a JSON para persistencia local en SharedPreferences.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        // ignore: deprecated_member_use
        'color': color.value,
        'icon': icon.codePoint,
        'isDefault': isDefault,
      };

  /// Deserializa desde JSON de SharedPreferences.
  factory TaskCategory.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    // Si coincide con alguna predeterminada, devolver la constante
    for (final def in defaultCategories) {
      if (def.id == id) return def;
    }
    return TaskCategory(
      id: id,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// Serializa a Map en formato Postgres snake_case para Supabase.
  Map<String, dynamic> toSupabaseMap() => {
        'id': id,
        'name': name,
        // ignore: deprecated_member_use
        'color': color.value,
        'icon_code_point': icon.codePoint,
      };

  /// Deserializa desde registro Supabase.
  factory TaskCategory.fromSupabaseMap(Map<String, dynamic> map) {
    final id = map['id'] as String;
    for (final def in defaultCategories) {
      if (def.id == id) return def;
    }
    return TaskCategory(
      id: id,
      name: map['name'] as String,
      color: Color(map['color'] as int),
      icon: IconData(map['icon_code_point'] as int, fontFamily: 'MaterialIcons'),
      isDefault: false,
    );
  }

  /// Helper para resolver una categoría a partir de su ID o de su índice histórico.
  static TaskCategory fromIdOrIndex({
    String? id,
    int? index,
    List<TaskCategory> customCategories = const [],
  }) {
    if (id != null) {
      for (final def in defaultCategories) {
        if (def.id == id) return def;
      }
      for (final custom in customCategories) {
        if (custom.id == id) return custom;
      }
    }
    if (index != null && index >= 0 && index < defaultCategories.length) {
      return defaultCategories[index];
    }
    return none;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TaskCategory($id, $name)';
}
