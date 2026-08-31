import 'package:flutter/material.dart';

/// Categorías de tareas con colores inspirados en el diseño minimalista de resaltador.
enum TaskCategory {
  work,
  personal,
  health,
  learning,
  social,
  none;

  String get displayName {
    switch (this) {
      case TaskCategory.work:
        return 'Trabajo';
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.health:
        return 'Salud';
      case TaskCategory.learning:
        return 'Enfoque';
      case TaskCategory.social:
        return 'Social';
      case TaskCategory.none:
        return 'General';
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.work:
        return const Color(0xFFFED330); // Amarillo resaltador suave (como en la foto)
      case TaskCategory.personal:
        return const Color(0xFFFF6B81); // Coral suave
      case TaskCategory.health:
        return const Color(0xFF2ED573); // Verde menta fresco
      case TaskCategory.learning:
        return const Color(0xFF70A1FF); // Azul cielo pastel
      case TaskCategory.social:
        return const Color(0xFFA55EEA); // Violeta / Lavanda
      case TaskCategory.none:
        return const Color(0xFF747D8C); // Gris pizarra suave
    }
  }

  IconData get icon {
    switch (this) {
      case TaskCategory.work:
        return Icons.work_rounded;
      case TaskCategory.personal:
        return Icons.favorite_rounded;
      case TaskCategory.health:
        return Icons.spa_rounded;
      case TaskCategory.learning:
        return Icons.bolt_rounded;
      case TaskCategory.social:
        return Icons.people_alt_rounded;
      case TaskCategory.none:
        return Icons.circle_rounded;
    }
  }
}
