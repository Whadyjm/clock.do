import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/time_block.dart';
import '../models/task_category.dart';
import '../providers/clock_provider.dart';
import '../utils/radial_math.dart';

/// Bottom sheet con soporte completo de temas (Claro/Oscuro) para crear o editar tareas.
class TaskFormSheet extends StatefulWidget {
  final TimeBlock? existingBlock;
  final double? suggestedStartHour;
  final double? suggestedEndHour;
  final DateTime? initialDate;
  final String? initialTitle;
  final String? initialDescription;
  final TaskCategory? initialCategory;

  const TaskFormSheet({
    super.key,
    this.existingBlock,
    this.suggestedStartHour,
    this.suggestedEndHour,
    this.initialDate,
    this.initialTitle,
    this.initialDescription,
    this.initialCategory,
  });

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TaskCategory _selectedCategory;
  late DateTime _selectedDate;
  late double _startHour;
  late double _endHour;

  bool get _isEditing => widget.existingBlock != null;

  @override
  void initState() {
    super.initState();
    final block = widget.existingBlock;
    _titleCtrl = TextEditingController(text: block?.title ?? widget.initialTitle ?? '');
    _descCtrl = TextEditingController(text: block?.description ?? widget.initialDescription ?? '');
    _selectedCategory = block?.category ?? widget.initialCategory ?? TaskCategory.work;
    _selectedDate = block?.date ?? widget.initialDate ?? normalizeDate(DateTime.now());
    _startHour = block?.startHour ??
        widget.suggestedStartHour ??
        DateTime.now().hour.toDouble();
    _endHour = block?.endHour ??
        widget.suggestedEndHour ??
        (_startHour + 1.0);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      HapticFeedback.vibrate();
      return;
    }

    HapticFeedback.mediumImpact();
    final provider = context.read<ClockProvider>();

    if (_isEditing) {
      provider.updateBlock(widget.existingBlock!.copyWith(
        title: title,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        date: _selectedDate,
        startHour: _startHour,
        endHour: _endHour,
        category: _selectedCategory,
      ));
    } else {
      provider.addBlock(TimeBlock.create(
        title: title,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        date: _selectedDate,
        startHour: _startHour,
        endHour: _endHour,
        category: _selectedCategory,
      ));
    }

    Navigator.of(context).pop();
  }

  void _delete(BuildContext context) {
    if (!_isEditing) return;
    HapticFeedback.heavyImpact();
    context.read<ClockProvider>().deleteBlock(widget.existingBlock!.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final fieldFillColor = isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F6FD);
    final borderColor = isDark ? const Color(0xFF2A2D42) : const Color(0xFFE8E4FF);
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 14,
        bottom: keyboardInset + (keyboardInset > 0 ? 20 : 24 + bottomSafe),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 46,
                height: 5,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2D42) : const Color(0xFFDDD9F5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Título del bottom sheet con badge de acción
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _selectedCategory.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _isEditing ? Icons.edit_calendar_rounded : Icons.auto_awesome_rounded,
                    color: _selectedCategory.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isEditing ? 'Editar bloque' : 'Nuevo bloque',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                if (_isEditing)
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7675).withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFFF7675), size: 22),
                    onPressed: () => _delete(context),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Selector de fecha
            _buildDatePickerCard(fieldFillColor, borderColor, textColor),
            const SizedBox(height: 14),

            // Título de la tarea
            _buildTextField(
              controller: _titleCtrl,
              label: '¿En qué vas a enfocarte?',
              icon: Icons.edit_note_rounded,
              fillColor: fieldFillColor,
              textColor: textColor,
            ),
            const SizedBox(height: 14),

            // Descripción opcional
            _buildTextField(
              controller: _descCtrl,
              label: 'Notas adicionales (opcional)',
              icon: Icons.chat_bubble_outline_rounded,
              fillColor: fieldFillColor,
              textColor: textColor,
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Selector de hora visual tipo cards
            Row(
              children: [
                Expanded(
                  child: _buildTimeCard(
                    label: 'INICIO',
                    value: _startHour,
                    color: _selectedCategory.color,
                    fillColor: fieldFillColor,
                    borderColor: borderColor,
                    onChanged: (v) => setState(() => _startHour = v),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF0EEFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF6C5CE7),
                    size: 16,
                  ),
                ),
                Expanded(
                  child: _buildTimeCard(
                    label: 'FIN',
                    value: _endHour,
                    color: _selectedCategory.color,
                    fillColor: fieldFillColor,
                    borderColor: borderColor,
                    onChanged: (v) => setState(() => _endHour = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Categoría
            const Text(
              'CATEGORÍA',
              style: TextStyle(
                color: Color(0xFF9E98D4),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _buildCategorySelector(isDark),
            const SizedBox(height: 26),

            // Botón animado y llamativo
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedCategory.color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: _selectedCategory.color.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isEditing ? 'Guardar Cambios' : 'Agendar Bloque',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerCard(Color fillColor, Color borderColor, Color textColor) {
    final dateStr = DateFormat('EEEE, d MMMM', 'es').format(_selectedDate);
    final capitalized = dateStr[0].toUpperCase() + dateStr.substring(1);

    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) {
          setState(() => _selectedDate = normalizeDate(picked));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: _selectedCategory.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FECHA AGENDADA',
                    style: TextStyle(
                      color: Color(0xFF9E98D4),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    capitalized,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9E98D4)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color fillColor,
    required Color textColor,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(
          color: Color(0xFF9E98D4),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF6C5CE7), size: 20),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: _selectedCategory.color.withValues(alpha: 0.8),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard({
    required String label,
    required double value,
    required Color color,
    required Color fillColor,
    required Color borderColor,
    required void Function(double) onChanged,
  }) {
    final hour = value.floor() % 24;
    final minute = ((value - value.floor()) * 60).round();
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
        );
        if (picked != null) {
          HapticFeedback.lightImpact();
          onChanged(RadialMath.timeToDecimalHours(picked.hour, picked.minute));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9E98D4),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: TaskCategory.values.map((cat) {
        final isSelected = cat == _selectedCategory;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedCategory = cat);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? cat.color
                  : cat.color.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cat.color.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cat.icon,
                  color: isSelected ? Colors.white : cat.color,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  cat.displayName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : cat.color,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
