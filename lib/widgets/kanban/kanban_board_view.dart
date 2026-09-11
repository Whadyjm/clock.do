import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/time_block.dart';
import '../../models/todo_item.dart';
import '../../providers/clock_provider.dart';
import '../../l10n/app_localizations.dart';
import 'kanban_column.dart';

enum KanbanScope { selectedDay, allTasks }

/// Vista completa del Tablero Kanban con filtrado por alcance, categoría y columnas interactivas.
class KanbanBoardView extends StatefulWidget {
  final void Function({
    TaskStatus? initialStatus,
    DateTime? date,
  })? onOpenCreateSheet;
  final void Function(TimeBlock block)? onEditBlock;
  final void Function(TodoItem todo)? onEditTodo;

  const KanbanBoardView({
    super.key,
    this.onOpenCreateSheet,
    this.onEditBlock,
    this.onEditTodo,
  });

  @override
  State<KanbanBoardView> createState() => _KanbanBoardViewState();
}

class _KanbanBoardViewState extends State<KanbanBoardView> {
  KanbanScope _scope = KanbanScope.selectedDay;
  String? _selectedCategoryId; // null = todas las categorías
  bool _showBacklog = true;
  late final ScrollController _horizontalScrollCtrl;

  @override
  void initState() {
    super.initState();
    _horizontalScrollCtrl = ScrollController();
  }

  @override
  void dispose() {
    _horizontalScrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClockProvider>();

    // Obtener bloques según el alcance (Día seleccionado vs Todas)
    List<TimeBlock> rawBlocks = _scope == KanbanScope.selectedDay
        ? provider.selectedDateBlocks
        : provider.allBlocks;

    // Filtrar por categoría si está seleccionada
    if (_selectedCategoryId != null) {
      rawBlocks = rawBlocks.where((b) => b.category.id == _selectedCategoryId).toList();
    }

    // Filtrar Todos del Backlog
    List<TodoItem> backlogTodos = provider.pendingTodos;
    if (_selectedCategoryId != null) {
      backlogTodos = backlogTodos.where((t) => t.category.id == _selectedCategoryId).toList();
    }

    final pendingBlocks = rawBlocks.where((b) => b.status == TaskStatus.pending).toList();
    final inProgressBlocks = rawBlocks.where((b) => b.status == TaskStatus.inProgress).toList();
    final completedBlocks = rawBlocks.where((b) => b.status == TaskStatus.completed).toList();

    return Column(
      children: [
        // ── Barra de Herramientas y Filtros ──────────────
        _buildToolbar(context, provider),

        const SizedBox(height: 6),

        // ── Tablero de Columnas Kanban ───────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final columnWidth = isWide
                  ? (constraints.maxWidth - 32) / (_showBacklog ? 4 : 3)
                  : (constraints.maxWidth * 0.82).clamp(280.0, 340.0);

              return SingleChildScrollView(
                controller: _horizontalScrollCtrl,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Columna 0: Backlog (opcional / toggleable)
                    if (_showBacklog)
                      SizedBox(
                        width: columnWidth,
                        child: KanbanColumn(
                          columnType: KanbanColumnType.backlog,
                          todos: backlogTodos,
                          onAddTask: () => widget.onOpenCreateSheet?.call(),
                          onEditTodo: widget.onEditTodo,
                        ),
                      ),

                    // Columna 1: Por hacer (Pendientes)
                    SizedBox(
                      width: columnWidth,
                      child: KanbanColumn(
                        columnType: KanbanColumnType.pending,
                        blocks: pendingBlocks,
                        onAddTask: () => widget.onOpenCreateSheet?.call(
                          initialStatus: TaskStatus.pending,
                          date: provider.selectedDate,
                        ),
                        onEditBlock: widget.onEditBlock,
                      ),
                    ),

                    // Columna 2: En progreso
                    SizedBox(
                      width: columnWidth,
                      child: KanbanColumn(
                        columnType: KanbanColumnType.inProgress,
                        blocks: inProgressBlocks,
                        onAddTask: () => widget.onOpenCreateSheet?.call(
                          initialStatus: TaskStatus.inProgress,
                          date: provider.selectedDate,
                        ),
                        onEditBlock: widget.onEditBlock,
                      ),
                    ),

                    // Columna 3: Completadas
                    SizedBox(
                      width: columnWidth,
                      child: KanbanColumn(
                        columnType: KanbanColumnType.completed,
                        blocks: completedBlocks,
                        onAddTask: () => widget.onOpenCreateSheet?.call(
                          initialStatus: TaskStatus.completed,
                          date: provider.selectedDate,
                        ),
                        onEditBlock: widget.onEditBlock,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, ClockProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCategories = provider.allCategories;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fila 1: Selector de Alcance (Día / Todas) + Toggle Backlog
          Row(
            children: [
              // Segmented Scope Chip: Día vs Todas
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2135) : const Color(0xFFECE9F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildScopeButton(
                      title: context.l10n.kanbanScopeDay,
                      icon: Icons.calendar_today_rounded,
                      isSelected: _scope == KanbanScope.selectedDay,
                      onTap: () {
                        setState(() => _scope = KanbanScope.selectedDay);
                      },
                    ),
                    _buildScopeButton(
                      title: context.l10n.kanbanScopeAll,
                      icon: Icons.dashboard_rounded,
                      isSelected: _scope == KanbanScope.allTasks,
                      onTap: () {
                        setState(() => _scope = KanbanScope.allTasks);
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Chip Toggle para mostrar/ocultar columna Backlog
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showBacklog = !_showBacklog);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: _showBacklog
                        ? const Color(0xFF6C5CE7).withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF1E2135) : const Color(0xFFECE9F8)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _showBacklog
                          ? const Color(0xFF6C5CE7).withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 13,
                        color: _showBacklog ? const Color(0xFF6C5CE7) : const Color(0xFF9E98D4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Backlog (${provider.pendingTodoCount})',
                        style: TextStyle(
                          color: _showBacklog ? const Color(0xFF6C5CE7) : const Color(0xFF9E98D4),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Fila 2: Chips horizontales de categorías
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                // Chip "Todas"
                _buildCategoryFilterChip(
                  label: context.l10n.filterAllCategories,
                  icon: Icons.all_inclusive_rounded,
                  color: const Color(0xFF6C5CE7),
                  isSelected: _selectedCategoryId == null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategoryId = null);
                  },
                ),
                const SizedBox(width: 6),

                // Categorías existentes
                ...allCategories.map((cat) {
                  final isSelected = _selectedCategoryId == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildCategoryFilterChip(
                      label: cat.displayName,
                      icon: cat.icon,
                      color: cat.color,
                      isSelected: isSelected,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedCategoryId = isSelected ? null : cat.id;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF6C5CE7) : const Color(0xFF6C5CE7))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? Colors.white : const Color(0xFF9E98D4),
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF9E98D4),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : (isDark ? const Color(0xFF1B1E30) : const Color(0xFFF2F0FA)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? color : (isDark ? const Color(0xFF9E98D4) : const Color(0xFF7B75A8)),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : (isDark ? const Color(0xFFBBB5E8) : const Color(0xFF4A4468)),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
