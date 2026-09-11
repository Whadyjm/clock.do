import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/time_block.dart';
import '../../models/todo_item.dart';
import '../../providers/clock_provider.dart';
import '../../l10n/app_localizations.dart';
import 'kanban_card.dart';

enum KanbanColumnType {
  backlog,
  pending,
  inProgress,
  completed;

  TaskStatus? get taskStatus => switch (this) {
        KanbanColumnType.backlog => null,
        KanbanColumnType.pending => TaskStatus.pending,
        KanbanColumnType.inProgress => TaskStatus.inProgress,
        KanbanColumnType.completed => TaskStatus.completed,
      };

  Color get accentColor => switch (this) {
        KanbanColumnType.backlog => const Color(0xFF6C5CE7),
        KanbanColumnType.pending => const Color(0xFF9E98D4),
        KanbanColumnType.inProgress => const Color(0xFF00CEC9),
        KanbanColumnType.completed => const Color(0xFF00B894),
      };

  IconData get icon => switch (this) {
        KanbanColumnType.backlog => Icons.inbox_rounded,
        KanbanColumnType.pending => Icons.radio_button_unchecked_rounded,
        KanbanColumnType.inProgress => Icons.timelapse_rounded,
        KanbanColumnType.completed => Icons.check_circle_rounded,
      };

  String getLocalizedTitle(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case KanbanColumnType.backlog:
        return l10n.columnBacklog;
      case KanbanColumnType.pending:
        return l10n.columnPending;
      case KanbanColumnType.inProgress:
        return l10n.columnInProgress;
      case KanbanColumnType.completed:
        return l10n.columnCompleted;
    }
  }
}

/// Columna interactiva del tablero Kanban que acepta soltar tarjetas (DragTarget).
class KanbanColumn extends StatelessWidget {
  final KanbanColumnType columnType;
  final List<TimeBlock> blocks;
  final List<TodoItem> todos;
  final VoidCallback? onAddTask;
  final void Function(TimeBlock block)? onEditBlock;
  final void Function(TodoItem todo)? onEditTodo;

  const KanbanColumn({
    super.key,
    required this.columnType,
    this.blocks = const [],
    this.todos = const [],
    this.onAddTask,
    this.onEditBlock,
    this.onEditTodo,
  });

  bool get isBacklog => columnType == KanbanColumnType.backlog;
  int get itemCount => isBacklog ? todos.length : blocks.length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = columnType.accentColor;
    final columnBg = isDark ? const Color(0xFF131524) : const Color(0xFFF7F6FC);
    final borderColor = isDark ? const Color(0xFF23263B) : const Color(0xFFE6E2F5);

    return DragTarget<KanbanDragPayload>(
      onWillAcceptWithDetails: (details) {
        final payload = details.data;
        // Si ya está en esta columna, no resaltar
        if (isBacklog && payload.type == KanbanItemType.todo) return false;
        if (!isBacklog &&
            payload.type == KanbanItemType.block &&
            payload.currentStatus == columnType.taskStatus) {
          return false;
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        final payload = details.data;
        final provider = context.read<ClockProvider>();
        HapticFeedback.mediumImpact();

        if (isBacklog) {
          // Soltado en Backlog: convertir TimeBlock a TodoItem
          if (payload.type == KanbanItemType.block) {
            provider.moveBlockToBacklog(payload.id);
          }
        } else {
          // Soltado en Pending / InProgress / Completed
          final targetStatus = columnType.taskStatus!;
          if (payload.type == KanbanItemType.block) {
            provider.setBlockStatus(payload.id, targetStatus);
          } else if (payload.type == KanbanItemType.todo) {
            provider.convertTodoToScheduledBlock(
              todoId: payload.id,
              initialStatus: targetStatus,
            );
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isHovered
                ? accentColor.withValues(alpha: isDark ? 0.12 : 0.08)
                : columnBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHovered
                  ? accentColor
                  : borderColor,
              width: isHovered ? 2 : 1,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              // ── Encabezado de Columna ──────────────────
              _buildHeader(context, isHovered: isHovered),

              // ── Separador sutil ───────────────────────
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? const Color(0xFF23263B) : const Color(0xFFE9E5F7),
              ),

              // ── Lista de Tarjetas ─────────────────────
              Expanded(
                child: itemCount == 0
                    ? _buildEmptyState(context, isHovered: isHovered)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                        physics: const BouncingScrollPhysics(),
                        itemCount: itemCount,
                        itemBuilder: (ctx, index) {
                          if (isBacklog) {
                            final todo = todos[index];
                            return KanbanCard.forTodo(
                              key: ValueKey(todo.id),
                              todo: todo,
                              onTap: () => onEditTodo?.call(todo),
                              onEdit: () => onEditTodo?.call(todo),
                            );
                          } else {
                            final block = blocks[index];
                            return KanbanCard.forBlock(
                              key: ValueKey(block.id),
                              block: block,
                              onTap: () => onEditBlock?.call(block),
                              onEdit: () => onEditBlock?.call(block),
                            );
                          }
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isHovered}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = columnType.accentColor;
    final title = columnType.getLocalizedTitle(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: isHovered
            ? accentColor.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
      ),
      child: Row(
        children: [
          // Icono de columna con fondo
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(columnType.icon, size: 15, color: accentColor),
          ),
          const SizedBox(width: 8),

          // Título de Columna
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Contador de tarjetas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$itemCount',
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Botón "+" para añadir tarea directamente a esta columna
          Tooltip(
            message: context.l10n.addToColumn,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onAddTask?.call();
                },
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFF9E98D4) : const Color(0xFF6C5CE7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isHovered}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = columnType.accentColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isHovered
                    ? accentColor.withValues(alpha: 0.2)
                    : (isDark
                        ? const Color(0xFF1E2135)
                        : const Color(0xFFECE9F8)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isHovered ? Icons.download_rounded : columnType.icon,
                size: 22,
                color: isHovered ? accentColor : const Color(0xFF9E98D4),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isHovered
                  ? context.l10n.dragHereHint
                  : context.l10n.emptyColumnNoTasks,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isHovered
                    ? accentColor
                    : (isDark ? const Color(0xFF6B7194) : const Color(0xFF9E98D4)),
                fontSize: 12,
                fontWeight: isHovered ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
