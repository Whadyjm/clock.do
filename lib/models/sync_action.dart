import 'package:uuid/uuid.dart';

/// Tipo de entidad que se sincroniza con Supabase
enum SyncEntityType {
  timeBlock,
  todo,
  category,
  gamification;

  static SyncEntityType fromString(String val) {
    return SyncEntityType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => SyncEntityType.timeBlock,
    );
  }
}

/// Tipo de operación pendiente en la cola de sincronización
enum SyncOperationType {
  upsert,
  delete;

  static SyncOperationType fromString(String val) {
    return SyncOperationType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => SyncOperationType.upsert,
    );
  }
}

/// Representa una acción de modificación de datos realizada en modo offline
/// que debe ser enviada a Supabase una vez se disponga de conexión.
class SyncAction {
  final String id;
  final String targetId;
  final SyncEntityType entityType;
  final SyncOperationType operation;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;

  const SyncAction({
    required this.id,
    required this.targetId,
    required this.entityType,
    required this.operation,
    this.payload,
    required this.createdAt,
  });

  factory SyncAction.create({
    required String targetId,
    required SyncEntityType entityType,
    required SyncOperationType operation,
    Map<String, dynamic>? payload,
  }) {
    return SyncAction(
      id: const Uuid().v4(),
      targetId: targetId,
      entityType: entityType,
      operation: operation,
      payload: payload,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetId': targetId,
        'entityType': entityType.name,
        'operation': operation.name,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SyncAction.fromJson(Map<String, dynamic> json) {
    return SyncAction(
      id: json['id'] as String,
      targetId: json['targetId'] as String,
      entityType: SyncEntityType.fromString(json['entityType'] as String),
      operation: SyncOperationType.fromString(json['operation'] as String),
      payload: json['payload'] != null
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  String toString() =>
      'SyncAction($operation $entityType #$targetId at $createdAt)';
}
