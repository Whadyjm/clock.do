import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/task_category.dart';
import '../../providers/clock_provider.dart';
import '../../l10n/app_localizations.dart';

/// Modal bottom sheet para vincular una tarea al temporizador Pomodoro.
class PomodoroTaskSelectorSheet extends StatefulWidget {
  const PomodoroTaskSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ClockProvider>(),
        child: const PomodoroTaskSelectorSheet(),
      ),
    );
  }

  @override
  State<PomodoroTaskSelectorSheet> createState() => _PomodoroTaskSelectorSheetState();
}

class _PomodoroTaskSelectorSheetState extends State<PomodoroTaskSelectorSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClockProvider>();
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final secondaryColor = isDark ? const Color(0xFF9E98D4) : const Color(0xFF6B7194);
    final screenH = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Tareas de hoy (sin completar)
    final dayBlocks = provider.selectedDateBlocks
        .where((b) => _searchQuery.isEmpty || b.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    // Tareas ToDo pendientes
    final pendingTodos = provider.pendingTodos
        .where((t) => _searchQuery.isEmpty || t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final activeTaskId = provider.pomodoroState.activeTask?.id;

    return Container(
      constraints: BoxConstraints(maxHeight: screenH * 0.85),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, -6),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF2A3C), Color(0xFFD63031)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2A3C).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text('🍅', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pomodoroSelectTask,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      l10n.pomodoroStartFocusPrompt,
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: secondaryColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Buscador rápido
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2238) : const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2E3352) : const Color(0xFFE0D8FF),
              ),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: textColor, fontSize: 13.5),
              decoration: InputDecoration(
                icon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF6C5CE7)),
                border: InputBorder.none,
                hintText: 'Buscar tarea...',
                hintStyle: TextStyle(color: secondaryColor, fontSize: 13),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Lista de opciones
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // 1. Opción: Enfoque Libre
                _buildTile(
                  context,
                  title: l10n.pomodoroFreeFocus,
                  subtitle: 'Sin vincular a ninguna tarea específica',
                  emoji: '🍅',
                  color: const Color(0xFFFF2A3C),
                  isSelected: activeTaskId == null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    provider.clearPomodoroActiveTask();
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(height: 12),

                // 2. Sección: Tareas de Hoy
                if (dayBlocks.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Text(
                      l10n.pomodoroChooseFromSchedule.toUpperCase(),
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  ...dayBlocks.map((block) => _buildTile(
                        context,
                        title: block.title,
                        subtitle: block.category.displayName,
                        icon: block.category.icon,
                        color: block.category.color,
                        isSelected: activeTaskId == block.id,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          provider.setPomodoroActiveTask(
                            id: block.id,
                            title: block.title,
                            category: block.category,
                            isTodo: false,
                          );
                          Navigator.pop(context);
                        },
                      )),
                  const SizedBox(height: 12),
                ],

                // 3. Sección: Tareas del Backlog ToDo
                if (pendingTodos.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Text(
                      l10n.pomodoroChooseFromBacklog.toUpperCase(),
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  ...pendingTodos.map((todo) => _buildTile(
                        context,
                        title: todo.title,
                        subtitle: todo.category.displayName,
                        icon: todo.category.icon,
                        color: todo.category.color,
                        isSelected: activeTaskId == todo.id,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          provider.setPomodoroActiveTask(
                            id: todo.id,
                            title: todo.title,
                            category: todo.category,
                            isTodo: true,
                          );
                          Navigator.pop(context);
                        },
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    IconData? icon,
    String? emoji,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : (isDark ? const Color(0xFF181B2C) : const Color(0xFFF9F8FD)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? color
                    : (isDark ? const Color(0xFF252940) : const Color(0xFFEBE7F7)),
                width: isSelected ? 1.6 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: emoji != null
                      ? Text(emoji, style: const TextStyle(fontSize: 16))
                      : Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
