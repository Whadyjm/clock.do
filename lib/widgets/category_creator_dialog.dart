import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task_category.dart';
import '../providers/clock_provider.dart';
import '../l10n/app_localizations.dart';

/// Modal para crear o editar una categoría personalizada.
class CategoryCreatorDialog extends StatefulWidget {
  final TaskCategory? existingCategory;

  const CategoryCreatorDialog({super.key, this.existingCategory});

  /// Muestra el modal como un bottom sheet moderno.
  static Future<TaskCategory?> show(BuildContext context, {TaskCategory? category}) {
    HapticFeedback.mediumImpact();
    final provider = context.read<ClockProvider>();
    return showModalBottomSheet<TaskCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: provider,
        child: CategoryCreatorDialog(existingCategory: category),
      ),
    );
  }

  @override
  State<CategoryCreatorDialog> createState() => _CategoryCreatorDialogState();
}

class _CategoryCreatorDialogState extends State<CategoryCreatorDialog> {
  late TextEditingController _nameCtrl;
  late Color _selectedColor;
  late IconData _selectedIcon;

  bool get _isEditing => widget.existingCategory != null;

  static const List<Color> _palette = [
    Color(0xFFFED330), // Amarillo suave (marca ClockDo)
    Color(0xFFFF6B81), // Coral pastel
    Color(0xFF2ED573), // Verde menta
    Color(0xFF70A1FF), // Azul cielo
    Color(0xFFA55EEA), // Violeta
    Color(0xFFFF9F43), // Naranja suave
    Color(0xFF1DD1A1), // Esmeralda / Turquesa
    Color(0xFF54A0FF), // Azul eléctrico
    Color(0xFFEE5253), // Rojo carmesí
    Color(0xFF00D2D3), // Cian vibrante
    Color(0xFF5F27CD), // Índigo profundo
    Color(0xFFFF7675), // Rosa melocotón
    Color(0xFFFD9644), // Mandarina
    Color(0xFF26DE81), // Lima fresca
    Color(0xFF45AAF2), // Azul cerúleo
    Color(0xFF747D8C), // Gris pizarra
  ];

  static const List<IconData> _icons = [
    // Trabajo y Tecnología
    Icons.work_rounded,
    Icons.laptop_mac_rounded,
    Icons.code_rounded,
    Icons.terminal_rounded,
    Icons.analytics_rounded,
    Icons.assignment_rounded,
    Icons.psychology_rounded,
    Icons.business_center_rounded,

    // Estudio y Conocimiento
    Icons.menu_book_rounded,
    Icons.school_rounded,
    Icons.science_rounded,
    Icons.translate_rounded,
    Icons.history_edu_rounded,
    Icons.auto_stories_rounded,

    // Salud, Fitness y Bienestar
    Icons.fitness_center_rounded,
    Icons.directions_run_rounded,
    Icons.directions_bike_rounded,
    Icons.pool_rounded,
    Icons.self_improvement_rounded,
    Icons.spa_rounded,
    Icons.favorite_rounded,
    Icons.monitor_heart_rounded,
    Icons.water_drop_rounded,
    Icons.bedtime_rounded,

    // Finanzas y Compras
    Icons.attach_money_rounded,
    Icons.savings_rounded,
    Icons.shopping_bag_rounded,
    Icons.shopping_cart_rounded,
    Icons.credit_card_rounded,
    Icons.account_balance_rounded,
    Icons.receipt_long_rounded,
    Icons.trending_up_rounded,

    // Hogar y Familia
    Icons.home_rounded,
    Icons.cleaning_services_rounded,
    Icons.kitchen_rounded,
    Icons.pets_rounded,
    Icons.child_care_rounded,
    Icons.build_rounded,

    // Gastronomía y Café
    Icons.local_cafe_rounded,
    Icons.restaurant_rounded,
    Icons.lunch_dining_rounded,
    Icons.local_bar_rounded,
    Icons.bakery_dining_rounded,

    // Arte, Creatividad y Entretenimiento
    Icons.brush_rounded,
    Icons.palette_rounded,
    Icons.music_note_rounded,
    Icons.camera_alt_rounded,
    Icons.movie_rounded,
    Icons.sports_esports_rounded,
    Icons.piano_rounded,
    Icons.headphones_rounded,

    // Viajes, Aire Libre y Social
    Icons.flight_takeoff_rounded,
    Icons.explore_rounded,
    Icons.directions_car_rounded,
    Icons.beach_access_rounded,
    Icons.people_alt_rounded,
    Icons.celebration_rounded,
    Icons.chat_bubble_rounded,
    Icons.call_rounded,

    // Plantas, Naturaleza y Jardinería
    Icons.local_florist_rounded,
    Icons.park_rounded,
    Icons.forest_rounded,
    Icons.eco_rounded,
    Icons.energy_savings_leaf_rounded,
    Icons.yard_rounded,
    Icons.grass_rounded,
    Icons.nature_rounded,
    Icons.agriculture_rounded,
    Icons.compost_rounded,
    Icons.terrain_rounded,
    Icons.landscape_rounded,
    Icons.wb_sunny_rounded,
    Icons.cloud_rounded,
    Icons.waves_rounded,

    // Metas y Utilidades
    Icons.star_rounded,
    Icons.timer_rounded,
    Icons.alarm_rounded,
    Icons.lightbulb_rounded,
    Icons.bolt_rounded,
    Icons.flag_rounded,
    Icons.bookmark_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingCategory?.name ?? '');
    _selectedColor = widget.existingCategory?.color ?? _palette[1];
    _selectedIcon = widget.existingCategory?.icon ?? _icons[0];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      HapticFeedback.vibrate();
      return;
    }

    HapticFeedback.mediumImpact();
    final category = TaskCategory.custom(
      id: widget.existingCategory?.id,
      name: name,
      color: _selectedColor,
      icon: _selectedIcon,
    );

    Navigator.of(context).pop(category);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    HapticFeedback.heavyImpact();
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.delete),
        content: Text(l10n.deleteCategoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7675),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<ClockProvider>().deleteCustomCategory(widget.existingCategory!.id);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final fieldFillColor = isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F6FD);
    final borderColor = isDark ? const Color(0xFF2A2D42) : const Color(0xFFE8E4FF);
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    final previewName = _nameCtrl.text.trim().isEmpty ? l10n.categoryOther : _nameCtrl.text.trim();

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 14,
        bottom: keyboardInset + (keyboardInset > 0 ? 16 : 24 + bottomSafe),
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withValues(alpha: 0.2),
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
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2D42) : const Color(0xFFDDD9F5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _selectedColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_selectedIcon, color: _selectedColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  _isEditing ? l10n.editCategoryTitle : l10n.newCategoryTitle,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                if (_isEditing && !widget.existingCategory!.isDefault)
                  IconButton(
                    tooltip: 'Eliminar categoría',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7675).withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFFF7675), size: 22),
                    onPressed: () => _confirmDelete(context),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Vista previa del chip
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedColor.withValues(alpha: isDark ? 0.25 : 0.15),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _selectedColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_selectedIcon, color: _selectedColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      previewName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Campo de Nombre
            TextField(
              controller: _nameCtrl,
              onChanged: (_) => setState(() {}),
              autofocus: true,
              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: l10n.categoryNameHint,
                hintStyle: const TextStyle(color: Color(0xFF9E98D4), fontSize: 14),
                prefixIcon: const Icon(Icons.label_outline_rounded, color: Color(0xFF6C5CE7), size: 20),
                filled: true,
                fillColor: fieldFillColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: _selectedColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Paleta de Colores
            Text(
              l10n.categoryColorLabel.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF9E98D4),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _palette.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedColor = color);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.55),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(Icons.check_rounded, color: Colors.white, size: 20),
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // Grilla de Iconos
            Text(
              l10n.categoryIconLabel.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF9E98D4),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 180,
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _icons.length,
                itemBuilder: (ctx, index) {
                  final icon = _icons[index];
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedIcon = icon);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withValues(alpha: 0.25)
                            : (isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F6FD)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? _selectedColor : borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? _selectedColor : const Color(0xFF9E98D4),
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Botón Guardar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: _selectedColor.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isEditing ? l10n.saveCategoryButton : l10n.createCategoryButton,
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
}
