import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Niveles de prioridad para las tareas de ClockDo (TimeBlock y TodoItem).
enum TaskPriority {
  none,   // Sin prioridad específica
  low,    // Baja
  medium, // Media
  high,   // Alta
  urgent; // Urgente

  String get displayName {
    switch (this) {
      case TaskPriority.none:
        return 'Sin prioridad';
      case TaskPriority.low:
        return 'Baja';
      case TaskPriority.medium:
        return 'Media';
      case TaskPriority.high:
        return 'Alta';
      case TaskPriority.urgent:
        return 'Urgente';
    }
  }

  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case TaskPriority.none:
        return l10n.priorityNone;
      case TaskPriority.low:
        return l10n.priorityLow;
      case TaskPriority.medium:
        return l10n.priorityMedium;
      case TaskPriority.high:
        return l10n.priorityHigh;
      case TaskPriority.urgent:
        return l10n.priorityUrgent;
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.none:
        return const Color(0xFF9E98D4);
      case TaskPriority.low:
        return const Color(0xFF3867D6);
      case TaskPriority.medium:
        return const Color(0xFFFA8231);
      case TaskPriority.high:
        return const Color(0xFFFF4757);
      case TaskPriority.urgent:
        return const Color(0xFFEB3B5A);
    }
  }

  IconData get icon {
    switch (this) {
      case TaskPriority.none:
        return Icons.outlined_flag_rounded;
      case TaskPriority.low:
        return Icons.flag_outlined;
      case TaskPriority.medium:
        return Icons.flag_rounded;
      case TaskPriority.high:
        return Icons.flag_rounded;
      case TaskPriority.urgent:
        return Icons.priority_high_rounded;
    }
  }

  bool get hasPriority => this != TaskPriority.none;
  bool get isHighOrUrgent => this == TaskPriority.high || this == TaskPriority.urgent;

  static TaskPriority fromIndex(int? index) {
    if (index == null || index < 0 || index >= TaskPriority.values.length) {
      return TaskPriority.none;
    }
    return TaskPriority.values[index];
  }

  static TaskPriority fromName(String? name) {
    if (name == null) return TaskPriority.none;
    return TaskPriority.values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => TaskPriority.none,
    );
  }
}
