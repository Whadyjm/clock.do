import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/time_block.dart';
import '../../models/todo_item.dart';
import '../../models/task_category.dart';
import '../../providers/clock_provider.dart';
import '../../utils/radial_math.dart';
import '../../l10n/app_localizations.dart';

enum KanbanItemType { block, todo }

/// Payload transferido durante el arrastre de una tarjeta en el tablero Kanban.
class KanbanDragPayload {
  final KanbanItemType type;
  final String id;
  final TaskStatus? currentStatus;

  const KanbanDragPayload({
    required this.type,
    required this.id,
    this.currentStatus,
  });
}

/// Tarjeta Kanban individual para un TimeBlock o un TodoItem (Backlog).
class KanbanCard extends StatelessWidget {
  final TimeBlock? block;
  final TodoItem? todo;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const KanbanCard.forBlock({
    super.key,
    required TimeBlock this.block,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : todo = null;

  const KanbanCard.forTodo({
    super.key,
    required TodoItem this.todo,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : block = null;

  bool get isBlock => block != null;
  String get id => isBlock ? block!.id : todo!.id;
  String get title => isBlock ? block!.title : todo!.title;
  String? get description => isBlock ? block!.description : todo!.description;
  TaskCategory get category => isBlock ? block!.category : todo!.category;
  bool get isCompleted => isBlock
      ? block!.status == TaskStatus.completed
      : todo!.isCompleted;
  bool get isInProgress => isBlock && block!.status == TaskStatus.inProgress;

  @override
  Widget build(BuildContext context) {
    final payload = KanbanDragPayload(
      type: isBlock ? KanbanItemType.block : KanbanItemType.todo,
      id: id,
      currentStatus: isBlock ? block!.status : null,
    );

    return LongPressDraggable<KanbanDragPayload>(
      data: payload,
      delay: const Duration(milliseconds: 150),
      hapticFeedbackOnStart: true,
      onDragStarted: () {
        HapticFeedback.selectionClick();
      },
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 280,
          child: Transform.rotate(
            angle: -0.03,
            child: Opacity(
              opacity: 0.94,
              child: _buildCardContent(context, isDragging: true),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _buildCardContent(context),
      ),
      child: _buildCardContent(context),
    );
  }

  Widget _buildCardContent(BuildContext context, {bool isDragging = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final accentColor = category.color;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.5, horizontal: 2),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDragging
              ? const Color(0xFF6C5CE7)
              : (isInProgress
                  ? accentColor.withValues(alpha: 0.6)
                  : (isDark
                      ? const Color(0xFF2A2D42)
                      : const Color(0xFFE8E5F8))),
          width: isDragging || isInProgress ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDragging
                ? const Color(0xFF6C5CE7).withValues(alpha: 0.3)
                : accentColor.withValues(alpha: isInProgress ? 0.16 : (isDark ? 0.08 : 0.05)),
            blurRadius: isDragging ? 18 : (isInProgress ? 12 : 6),
            offset: Offset(0, isDragging ? 8 : 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fila Superior: Badge Categoría + Menú / Acciones
                Row(
                  children: [
                    // Badge de Categoría
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(category.icon, size: 12, color: accentColor),
                          const SizedBox(width: 4),
                          Text(
                            category.displayName,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Si es TimeBlock y está en progreso, tag animado
                    if (isInProgress) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00CEC9).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timelapse_rounded, size: 11, color: Color(0xFF00CEC9)),
                            SizedBox(width: 3),
                            Text(
                              'EN CURSO',
                              style: TextStyle(
                                color: Color(0xFF00CEC9),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],

                    // Botón de opciones
                    _buildOptionsMenu(context),
                  ],
                ),

                const SizedBox(height: 8),

                // Título
                Text(
                  title,
                  style: TextStyle(
                    color: isCompleted
                        ? (isDark ? const Color(0xFF6B7194) : const Color(0xFFBBB5E8))
                        : textColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: isDark ? const Color(0xFF6B7194) : const Color(0xFFBBB5E8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Descripción (opcional)
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description!,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF9E98D4) : const Color(0xFF716B9E),
                      fontSize: 11.5,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 10),

                // Fila Inferior: Horario / Pin / Flechas de acción rápida
                Row(
                  children: [
                    // Badge de Horario / Backlog
                    if (isBlock) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2238) : const Color(0xFFF3F0FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              block!.isPointInTime ? Icons.push_pin_rounded : Icons.schedule_rounded,
                              size: 11,
                              color: const Color(0xFF9E98D4),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              block!.isPointInTime
                                  ? RadialMath.decimalHoursToString(block!.startHour)
                                  : '${RadialMath.decimalHoursToString(block!.startHour)} - '
                                    '${RadialMath.decimalHoursToString(block!.endHour!)}',
                              style: const TextStyle(
                                color: Color(0xFF9E98D4),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2238) : const Color(0xFFF3F0FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_rounded, size: 11, color: Color(0xFF9E98D4)),
                            SizedBox(width: 3),
                            Text(
                              'Backlog',
                              style: TextStyle(
                                color: Color(0xFF9E98D4),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Flechas rápidas de cambio de columna (Accesibilidad y comodidad)
                    _buildQuickMoveButtons(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMoveButtons(BuildContext context) {
    final provider = context.read<ClockProvider>();

    if (!isBlock) {
      // Es ToDo del Backlog: botón para mover a "Por hacer"
      return Tooltip(
        message: 'Mover a Por hacer',
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            HapticFeedback.mediumImpact();
            provider.convertTodoToScheduledBlock(
              todoId: id,
              initialStatus: TaskStatus.pending,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Agendar',
                  style: TextStyle(
                    color: Color(0xFF6C5CE7),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF6C5CE7)),
              ],
            ),
          ),
        ),
      );
    }

    // Es TimeBlock: flechas de navegación entre estados
    final currentStatus = block!.status;
    final canGoLeft = currentStatus != TaskStatus.pending;
    final canGoRight = currentStatus != TaskStatus.completed;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canGoLeft)
          _buildMiniButton(
            icon: Icons.chevron_left_rounded,
            tooltip: context.l10n.moveToPreviousStatus,
            onTap: () {
              HapticFeedback.selectionClick();
              final prevStatus = currentStatus == TaskStatus.completed
                  ? TaskStatus.inProgress
                  : TaskStatus.pending;
              provider.setBlockStatus(id, prevStatus);
            },
          ),
        if (canGoLeft && canGoRight) const SizedBox(width: 4),
        if (canGoRight)
          _buildMiniButton(
            icon: Icons.chevron_right_rounded,
            tooltip: context.l10n.moveToNextStatus,
            onTap: () {
              HapticFeedback.selectionClick();
              final nextStatus = currentStatus == TaskStatus.pending
                  ? TaskStatus.inProgress
                  : TaskStatus.completed;
              provider.setBlockStatus(id, nextStatus);
            },
          ),
      ],
    );
  }

  Widget _buildMiniButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF6C5CE7)),
        ),
      ),
    );
  }

  Widget _buildOptionsMenu(BuildContext context) {
    final provider = context.read<ClockProvider>();
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      iconSize: 16,
      icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF9E98D4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit?.call();
        } else if (value == 'delete') {
          HapticFeedback.mediumImpact();
          if (isBlock) {
            provider.deleteBlock(id);
          } else {
            provider.deleteTodo(id);
          }
        } else if (value == 'to_backlog' && isBlock) {
          HapticFeedback.mediumImpact();
          provider.moveBlockToBacklog(id);
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'edit',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF6C5CE7)),
              const SizedBox(width: 8),
              Text(context.l10n.edit, style: const TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        if (isBlock)
          const PopupMenuItem(
            value: 'to_backlog',
            height: 36,
            child: Row(
              children: [
                Icon(Icons.inbox_outlined, size: 15, color: Color(0xFF00CEC9)),
                SizedBox(width: 8),
                Text('Mover a Backlog', style: TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFFF6B81)),
              const SizedBox(width: 8),
              Text(
                context.l10n.delete,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFFFF6B81)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
