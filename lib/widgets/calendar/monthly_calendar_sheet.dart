import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/time_block.dart';
import '../../providers/clock_provider.dart';

/// Modal interactivo con vista de calendario mensual completo y soporte de temas (Claro/Oscuro).
class MonthlyCalendarSheet extends StatefulWidget {
  const MonthlyCalendarSheet({super.key});

  @override
  State<MonthlyCalendarSheet> createState() => _MonthlyCalendarSheetState();
}

class _MonthlyCalendarSheetState extends State<MonthlyCalendarSheet> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ClockProvider>();
    _displayedMonth = DateTime(provider.selectedDate.year, provider.selectedDate.month, 1);
  }

  void _prevMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClockProvider>();
    final today = normalizeDate(DateTime.now());
    final selectedDate = provider.selectedDate;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final buttonBg = isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F6FD);

    // Calcular días para la cuadrícula del mes
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final startWeekday = firstDayOfMonth.weekday; // 1 = Lunes
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final prevMonthDays = DateTime(_displayedMonth.year, _displayedMonth.month, 0).day;

    final gridCells = <DateTime>[];
    for (var i = startWeekday - 1; i > 0; i--) {
      gridCells.add(DateTime(_displayedMonth.year, _displayedMonth.month - 1, prevMonthDays - i + 1));
    }
    for (var i = 1; i <= daysInMonth; i++) {
      gridCells.add(DateTime(_displayedMonth.year, _displayedMonth.month, i));
    }
    final remaining = 7 - (gridCells.length % 7);
    if (remaining < 7) {
      for (var i = 1; i <= remaining; i++) {
        gridCells.add(DateTime(_displayedMonth.year, _displayedMonth.month + 1, i));
      }
    }

    final monthTitle = DateFormat('MMMM yyyy', 'es').format(_displayedMonth);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
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
        children: [
          // Handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2D42) : const Color(0xFFDDD9F5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header de Navegación del Mes
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF6C5CE7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                monthTitle[0].toUpperCase() + monthTitle.substring(1),
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: buttonBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF6C5CE7)),
                onPressed: _prevMonth,
              ),
              const SizedBox(width: 4),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: buttonBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF6C5CE7)),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Días de la semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['L', 'M', 'M', 'J', 'V', 'S', 'D'].map((d) {
              return SizedBox(
                width: 38,
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      color: Color(0xFF9E98D4),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Cuadrícula de Días
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gridCells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final cellDate = gridCells[index];
              final isCurrentMonth = cellDate.month == _displayedMonth.month;
              final isSelected = cellDate.year == selectedDate.year &&
                  cellDate.month == selectedDate.month &&
                  cellDate.day == selectedDate.day;
              final isToday = cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;
              final categories = provider.categoriesForDate(cellDate);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.selectDate(cellDate);
                  Navigator.of(context).pop();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6C5CE7)
                        : (isToday
                            ? const Color(0xFF6C5CE7).withValues(alpha: 0.15)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(14),
                    border: isToday && !isSelected
                        ? Border.all(color: const Color(0xFF6C5CE7), width: 1.5)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${cellDate.day}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isCurrentMonth
                                  ? textColor
                                  : (isDark ? const Color(0xFF4A4E6A) : const Color(0xFFDDD9F5))),
                          fontSize: 14,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w900
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Puntos de tareas
                      SizedBox(
                        height: 4,
                        child: categories.isEmpty
                            ? const SizedBox.shrink()
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: categories.take(3).map((cat) {
                                  return Container(
                                    width: 3.5,
                                    height: 3.5,
                                    margin: const EdgeInsets.symmetric(horizontal: 0.8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : cat.color,
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Botón rápido de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    provider.jumpToToday();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6C5CE7),
                    side: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.today_rounded, size: 18),
                  label: const Text(
                    'Ir a Hoy',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
