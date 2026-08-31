import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/todo_item.dart';
import '../../models/task_category.dart';
import '../../providers/clock_provider.dart';
import '../task_form_sheet.dart';

enum _TodoFilter { pending, completed, all }

/// Modal interactivo para la gestión de tareas ToDo (backlog de pendientes sin hora fija).
class TodoListSheet extends StatefulWidget {
  const TodoListSheet({super.key});

  @override
  State<TodoListSheet> createState() => _TodoListSheetState();
}

class _TodoListSheetState extends State<TodoListSheet> {
  final TextEditingController _quickTitleCtrl = TextEditingController();
  final TextEditingController _quickDescCtrl = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  _TodoFilter _currentFilter = _TodoFilter.pending;
  TaskCategory? _selectedCategoryFilter;
  TaskCategory _newCategory = TaskCategory.none;
  bool _showDescriptionField = false;

  @override
  void dispose() {
    _quickTitleCtrl.dispose();
    _quickDescCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _addQuickTodo() {
    final title = _quickTitleCtrl.text.trim();
    if (title.isEmpty) {
      HapticFeedback.vibrate();
      return;
    }

    HapticFeedback.mediumImpact();
    final provider = context.read<ClockProvider>();
    final desc = _quickDescCtrl.text.trim();

    provider.addTodo(TodoItem.create(
      title: title,
      description: desc.isEmpty ? null : desc,
      category: _newCategory,
    ));

    _quickTitleCtrl.clear();
    _quickDescCtrl.clear();
    setState(() {
      _showDescriptionField = false;
    });
  }

  void _openEditDialog(BuildContext context, TodoItem item) {
    HapticFeedback.selectionClick();
    final titleCtrl = TextEditingController(text: item.title);
    final descCtrl = TextEditingController(text: item.description ?? '');
    TaskCategory cat = item.category;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return Dialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editar Tarea ToDo',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      autofocus: true,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Título',
                        labelStyle: const TextStyle(color: Color(0xFF9E98D4), fontSize: 13),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F6FD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Notas / Detalles (opcional)',
                        labelStyle: const TextStyle(color: Color(0xFF9E98D4), fontSize: 13),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F6FD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Categoría:',
                      style: TextStyle(color: Color(0xFF9E98D4), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: TaskCategory.values.map((c) {
                        final isSel = c == cat;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setDialogState(() => cat = c);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? c.color.withValues(alpha: 0.2) : (isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF0EEFF)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel ? c.color : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(c.icon, size: 13, color: c.color),
                                const SizedBox(width: 5),
                                Text(
                                  c.displayName,
                                  style: TextStyle(
                                    color: isSel ? c.color : (isDark ? Colors.white70 : const Color(0xFF4B4869)),
                                    fontSize: 11,
                                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9E98D4))),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final newTitle = titleCtrl.text.trim();
                            if (newTitle.isNotEmpty) {
                              HapticFeedback.mediumImpact();
                              context.read<ClockProvider>().updateTodo(
                                item.copyWith(
                                  title: newTitle,
                                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                                  category: cat,
                                ),
                              );
                              Navigator.of(dialogCtx).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C5CE7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _scheduleTodoInClock(BuildContext context, TodoItem item) {
    HapticFeedback.mediumImpact();
    final provider = context.read<ClockProvider>();
    Navigator.of(context).pop(); // Cerrar hoja de ToDos

    // Abrir hoja de agendamiento en el reloj
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: TaskFormSheet(
          initialTitle: item.title,
          initialDescription: item.description,
          initialCategory: item.category,
          initialDate: provider.selectedDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClockProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final screenH = MediaQuery.of(context).size.height;

    // Filtrar tareas
    var filteredList = switch (_currentFilter) {
      _TodoFilter.pending   => provider.pendingTodos,
      _TodoFilter.completed => provider.completedTodos,
      _TodoFilter.all       => provider.todoItems,
    };

    if (_selectedCategoryFilter != null) {
      filteredList = filteredList.where((t) => t.category == _selectedCategoryFilter).toList();
    }

    final pendingCount = provider.pendingTodoCount;
    final completedCount = provider.completedTodos.length;
    final totalCount = provider.todoItems.length;

    return Container(
      constraints: BoxConstraints(maxHeight: screenH * 0.88),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: keyboardInset + (keyboardInset > 0 ? 16 : 20 + bottomSafe),
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2D42) : const Color(0xFFDDD9F5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B7CF6), Color(0xFF6C5CE7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.checklist_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tareas ToDo',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      pendingCount == 1 ? '1 tarea pendiente' : '$pendingCount tareas pendientes',
                      style: const TextStyle(
                        color: Color(0xFF9E98D4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (completedCount > 0)
                Tooltip(
                  message: 'Limpiar completadas',
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      provider.clearCompletedTodos();
                    },
                    icon: const Icon(Icons.cleaning_services_rounded, size: 20, color: Color(0xFF9E98D4)),
                  ),
                ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : const Color(0xFF6C5CE7)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Barra de Agregar Tarea Rápida
          _buildQuickAddBar(context, isDark, textColor),

          const SizedBox(height: 12),

          // Filtros de estado (Tabs)
          _buildStatusFilterTabs(isDark, pendingCount, completedCount, totalCount),

          const SizedBox(height: 8),

          // Selector de filtro de categorías
          _buildCategoryFilterRow(isDark),

          const SizedBox(height: 10),

          // Lista de tareas ToDo
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredList.length,
                    itemBuilder: (ctx, i) {
                      final item = filteredList[i];
                      return _buildTodoCard(ctx, item, isDark, textColor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Barra de entrada rápida
  // ──────────────────────────────────────────────

  Widget _buildQuickAddBar(BuildContext context, bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F6FD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Selector de categoría rápida
              PopupMenuButton<TaskCategory>(
                tooltip: 'Cambiar categoría',
                initialValue: _newCategory,
                onSelected: (cat) {
                  HapticFeedback.selectionClick();
                  setState(() => _newCategory = cat);
                },
                itemBuilder: (ctx) => TaskCategory.values.map((cat) {
                  return PopupMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(cat.icon, color: cat.color, size: 16),
                        const SizedBox(width: 8),
                        Text(cat.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _newCategory.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_newCategory.icon, size: 18, color: _newCategory.color),
                ),
              ),

              const SizedBox(width: 10),

              // Campo de texto de título
              Expanded(
                child: TextField(
                  controller: _quickTitleCtrl,
                  focusNode: _inputFocus,
                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                  onSubmitted: (_) => _addQuickTodo(),
                  decoration: const InputDecoration(
                    hintText: 'Agregar pendiente sin fecha...',
                    hintStyle: TextStyle(color: Color(0xFF9E98D4), fontSize: 13, fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),

              // Botón para expandir notas
              IconButton(
                icon: Icon(
                  _showDescriptionField ? Icons.notes_rounded : Icons.note_add_outlined,
                  size: 20,
                  color: _showDescriptionField ? const Color(0xFF6C5CE7) : const Color(0xFF9E98D4),
                ),
                tooltip: _showDescriptionField ? 'Ocultar notas' : 'Agregar notas',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showDescriptionField = !_showDescriptionField);
                },
              ),

              // Botón de agregar
              GestureDetector(
                onTap: _addQuickTodo,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B7CF6), Color(0xFF6C5CE7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),

          // Campo opcional de notas
          if (_showDescriptionField) ...[
            const Divider(height: 12, thickness: 0.8, color: Color(0x229E98D4)),
            TextField(
              controller: _quickDescCtrl,
              style: TextStyle(color: textColor, fontSize: 12.5),
              decoration: const InputDecoration(
                hintText: 'Notas o descripción adicional (opcional)...',
                hintStyle: TextStyle(color: Color(0xFF9E98D4), fontSize: 12),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Tabs de Filtro de Estado
  // ──────────────────────────────────────────────

  Widget _buildStatusFilterTabs(bool isDark, int pending, int completed, int total) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildFilterTab(
            label: 'Pendientes',
            count: pending,
            filter: _TodoFilter.pending,
            isDark: isDark,
          ),
          _buildFilterTab(
            label: 'Completadas',
            count: completed,
            filter: _TodoFilter.completed,
            isDark: isDark,
          ),
          _buildFilterTab(
            label: 'Todas',
            count: total,
            filter: _TodoFilter.all,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required int count,
    required _TodoFilter filter,
    required bool isDark,
  }) {
    final isSelected = _currentFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _currentFilter = filter);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6C5CE7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF6C5CE7)),
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isDark ? const Color(0xFF2A2D42) : const Color(0xFFDDD9F5)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white60 : const Color(0xFF6C5CE7)),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Filtro de Categorías Horizontal
  // ──────────────────────────────────────────────

  Widget _buildCategoryFilterRow(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Pill "Todas"
          _buildCategoryFilterPill(
            title: 'Todas las categorías',
            icon: Icons.apps_rounded,
            color: const Color(0xFF6C5CE7),
            isSelected: _selectedCategoryFilter == null,
            onTap: () => setState(() => _selectedCategoryFilter = null),
            isDark: isDark,
          ),
          const SizedBox(width: 6),
          ...TaskCategory.values.map((cat) {
            final isSel = _selectedCategoryFilter == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _buildCategoryFilterPill(
                title: cat.displayName,
                icon: cat.icon,
                color: cat.color,
                isSelected: isSel,
                onTap: () {
                  setState(() {
                    _selectedCategoryFilter = isSel ? null : cat;
                  });
                },
                isDark: isDark,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterPill({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F6FD)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.3,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : (isDark ? Colors.white60 : const Color(0xFF747D8C)),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Tarjeta de Tarea ToDo
  // ──────────────────────────────────────────────

  Widget _buildTodoCard(BuildContext context, TodoItem item, bool isDark, Color textColor) {
    final provider = context.read<ClockProvider>();
    final isDone = item.isCompleted;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B81),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        HapticFeedback.heavyImpact();
        provider.deleteTodo(item.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161826) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF24273C) : const Color(0xFFEDE9FE),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: item.category.color.withValues(alpha: isDark ? 0.02 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox interactivo
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                provider.toggleTodo(item.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF00B894)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDone ? const Color(0xFF00B894) : const Color(0xFF9E98D4),
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : null,
              ),
            ),

            const SizedBox(width: 12),

            // Contenido principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Badge de categoría
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.category.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(item.category.icon, size: 10, color: item.category.color),
                            const SizedBox(width: 4),
                            Text(
                              item.category.displayName,
                              style: TextStyle(
                                color: item.category.color,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.title,
                    style: TextStyle(
                      color: isDone
                          ? (isDark ? const Color(0xFF6B7194) : const Color(0xFFBBB5E8))
                          : textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: isDark ? const Color(0xFF6B7194) : const Color(0xFFBBB5E8),
                    ),
                  ),
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : const Color(0xFF9E98D4),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Acciones: Agendar en el reloj y menú
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón "Agendar en Reloj"
                Tooltip(
                  message: 'Agendar en el reloj',
                  child: GestureDetector(
                    onTap: () => _scheduleTodoInClock(context, item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF6C5CE7)),
                          SizedBox(width: 4),
                          Text(
                            'Agendar',
                            style: TextStyle(
                              color: Color(0xFF6C5CE7),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Menú de opciones (Editar / Eliminar)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF9E98D4)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openEditDialog(context, item);
                    } else if (val == 'delete') {
                      HapticFeedback.heavyImpact();
                      provider.deleteTodo(item.id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16, color: Color(0xFF6C5CE7)),
                          SizedBox(width: 8),
                          Text('Editar tarea', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFFF6B81)),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Color(0xFFFF6B81), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Estado Vacío (Empty State)
  // ──────────────────────────────────────────────

  Widget _buildEmptyState(bool isDark) {
    final String message;
    final String subtitle;
    final IconData icon;

    switch (_currentFilter) {
      case _TodoFilter.pending:
        message = '¡Estás al día!';
        subtitle = 'No tienes tareas pendientes sin programar.';
        icon = Icons.done_all_rounded;
        break;
      case _TodoFilter.completed:
        message = 'Sin tareas completadas';
        subtitle = 'Completa tus pendientes para verlos aquí.';
        icon = Icons.checklist_rounded;
        break;
      case _TodoFilter.all:
        message = 'Lista de ToDo vacía';
        subtitle = 'Agrega pendientes arriba para organizarte mejor.';
        icon = Icons.post_add_rounded;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 28, color: const Color(0xFF6C5CE7)),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF9E98D4),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFBBB5E8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
