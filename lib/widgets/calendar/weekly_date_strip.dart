import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/time_block.dart';
import '../../providers/clock_provider.dart';

/// Barra horizontal interactiva de fechas estilo tira semanal / mensual con soporte de temas.
class WeeklyDateStrip extends StatefulWidget {
  const WeeklyDateStrip({super.key});

  @override
  State<WeeklyDateStrip> createState() => _WeeklyDateStripState();
}

class _WeeklyDateStripState extends State<WeeklyDateStrip> {
  late ScrollController _scrollCtrl;
  final int _rangeDays = 30; // 30 días antes y 30 días después de hoy
  final double _itemWidth = 62.0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected(animate: false));
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToSelected({bool animate = true}) {
    if (!_scrollCtrl.hasClients) return;
    final provider = context.read<ClockProvider>();
    final today = normalizeDate(DateTime.now());
    final diff = provider.selectedDate.difference(today).inDays;
    final targetIndex = _rangeDays + diff;
    final offset = (targetIndex * _itemWidth) - (MediaQuery.of(context).size.width / 2) + (_itemWidth / 2);

    final clampedOffset = offset.clamp(0.0, _scrollCtrl.position.maxScrollExtent);

    if (animate) {
      _scrollCtrl.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollCtrl.jumpTo(clampedOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClockProvider>();
    final today = normalizeDate(DateTime.now());
    final totalItems = (_rangeDays * 2) + 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);

    return Column(
      children: [
        SizedBox(
          height: 82,
          child: ListView.builder(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: totalItems,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final dayOffset = index - _rangeDays;
              final date = today.add(Duration(days: dayOffset));
              final isSelected = date.year == provider.selectedDate.year &&
                  date.month == provider.selectedDate.month &&
                  date.day == provider.selectedDate.day;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final categories = provider.categoriesForDate(date);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.selectDate(date);
                  _scrollToSelected(animate: true);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 52,
                  margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6C5CE7)
                        : cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: isToday && !isSelected
                        ? Border.all(color: const Color(0xFF6C5CE7), width: 1.5)
                        : Border.all(color: isDark ? const Color(0xFF2A2D42) : Colors.transparent),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF6C5CE7).withValues(alpha: 0.35)
                            : (isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF6C5CE7).withValues(alpha: 0.05)),
                        blurRadius: isSelected ? 12 : 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE', 'es').format(date).toUpperCase().replaceAll('.', ''),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : const Color(0xFF9E98D4),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Indicadores de categorías / tareas programadas
                      SizedBox(
                        height: 5,
                        child: categories.isEmpty
                            ? (isToday
                                ? Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF6C5CE7),
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : const SizedBox.shrink())
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: categories.take(3).map((cat) {
                                  return Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
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
        ),
      ],
    );
  }
}
