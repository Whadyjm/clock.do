import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/time_block.dart';
import '../models/task_category.dart';
import '../models/todo_item.dart';
import '../providers/clock_provider.dart';
import '../widgets/radial_clock_canvas.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/calendar/weekly_date_strip.dart';
import '../widgets/calendar/monthly_calendar_sheet.dart';
import '../widgets/settings/notification_settings_sheet.dart';
import '../widgets/todo/todo_list_sheet.dart';
import '../widgets/auth/auth_sheet.dart';
import '../utils/radial_math.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabCtrl;
  late Animation<double> _fabScale;
  late AnimationController _headerCtrl;
  late Animation<Offset> _headerSlide;
  late Animation<double> _headerFade;
  // Scroll de la lista de tareas — controla la altura del reloj
  late ScrollController _taskScrollCtrl;

  @override
  void initState() {
    super.initState();

    // FAB pulsante
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _fabScale = Tween(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _fabCtrl, curve: Curves.easeInOut),
    );

    // Header entrada
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _headerSlide = Tween(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _headerFade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    // Scroll de tareas
    _taskScrollCtrl = ScrollController();
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    _headerCtrl.dispose();
    _taskScrollCtrl.dispose();
    super.dispose();
  }

  void _openCreateSheet(
    BuildContext ctx, {
    double? startHour,
    double? endHour,
    DateTime? date,
    String? initialTitle,
    String? initialDescription,
    TaskCategory? initialCategory,
  }) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    final provider = context.read<ClockProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: TaskFormSheet(
          suggestedStartHour: startHour,
          suggestedEndHour: endHour,
          initialDate: date ?? provider.selectedDate,
          initialTitle: initialTitle,
          initialDescription: initialDescription,
          initialCategory: initialCategory,
        ),
      ),
    );
  }

  void _openEditSheet(BuildContext ctx, String blockId) {
    if (!mounted) return;
    HapticFeedback.selectionClick();
    final provider = context.read<ClockProvider>();
    final block = provider.allBlocks.where((b) => b.id == blockId).firstOrNull;
    if (block == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: TaskFormSheet(existingBlock: block),
      ),
    );
  }

  void _openMonthlyCalendar(BuildContext ctx) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    final provider = context.read<ClockProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const MonthlyCalendarSheet(),
      ),
    );
  }

  void _openTodoListSheet(BuildContext ctx) async {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    final provider = context.read<ClockProvider>();
    final TodoItem? itemToSchedule = await showModalBottomSheet<TodoItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const TodoListSheet(),
      ),
    );

    if (itemToSchedule != null && mounted) {
      _openCreateSheet(
        context,
        date: provider.selectedDate,
        initialTitle: itemToSchedule.title,
        initialDescription: itemToSchedule.description,
        initialCategory: itemToSchedule.category,
      );
    }
  }

  void _openNotificationSettings(BuildContext ctx) {
    if (!mounted) return;
    HapticFeedback.selectionClick();
    final provider = context.read<ClockProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const NotificationSettingsSheet(),
      ),
    );
  }

  void _openAuthSheet(BuildContext ctx) {
    if (!mounted) return;
    HapticFeedback.selectionClick();
    final provider = context.read<ClockProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const AuthSheet(),
      ),
    );
  }

  void _openThemeSelector(BuildContext ctx) {
    if (!mounted) return;
    HapticFeedback.selectionClick();
    final provider = context.read<ClockProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
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
            Text(
              'Tema de la Aplicación',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildThemeOption(
              context: context,
              title: 'Modo Claro',
              subtitle: 'Diseño brillante y tonos pastel',
              icon: Icons.light_mode_rounded,
              mode: ThemeMode.light,
              isSelected: provider.themeMode == ThemeMode.light,
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              context: context,
              title: 'Modo Oscuro',
              subtitle: 'Superficies profundas y contrastes vívidos',
              icon: Icons.dark_mode_rounded,
              mode: ThemeMode.dark,
              isSelected: provider.themeMode == ThemeMode.dark,
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              context: context,
              title: 'Seguir Sistema',
              subtitle: 'Se ajusta automáticamente a tu dispositivo',
              icon: Icons.brightness_auto_rounded,
              mode: ThemeMode.system,
              isSelected: provider.themeMode == ThemeMode.system,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.read<ClockProvider>().setThemeMode(mode);
        Navigator.of(context).pop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C5CE7).withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F6FD)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6C5CE7)
                    : (isDark ? const Color(0xFF2A2D42) : const Color(0xFFE8E4FF)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF6C5CE7),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF9E98D4),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF6C5CE7), size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final clockMaxH = screenH * 0.44;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header (fecha / hora / botones) ─────────────────
            FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: _buildHeader(context),
              ),
            ),
            // ── Tira semanal ───────────────────────────────
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const WeeklyDateStrip(),
            ),
            // ── Reloj colapsable (FUERA del scroll) ────────────
            // AnimatedBuilder escucha el scroll de la lista de tareas
            // y encoge la altura del reloj sin que haya competencia
            // de gestos entre el reloj y el scroll.
            AnimatedBuilder(
              animation: _taskScrollCtrl,
              builder: (ctx, _) {
                final offset = _taskScrollCtrl.hasClients
                    ? _taskScrollCtrl.offset.clamp(0.0, clockMaxH)
                    : 0.0;
                final clockH = (clockMaxH - offset).clamp(0.0, clockMaxH);
                final shrinkRatio = offset / clockMaxH;
                return SizedBox(
                  height: clockH,
                  child: _buildClockWidget(ctx, shrinkRatio),
                );
              },
            ),
            // ── Lista de tareas (scroll propio) ────────────────
            Expanded(
              child: CustomScrollView(
                controller: _taskScrollCtrl,
                physics: const BouncingScrollPhysics(),
                slivers: _buildTaskSlivers(context),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  // ──────────────────────────────────────────────
  // Header
  // ──────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final provider = context.watch<ClockProvider>();
    final selectedDate = provider.selectedDate;
    final isToday = provider.isViewingToday;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final buttonBg = isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF0EEFF);
    final timeStr = DateFormat('HH:mm').format(provider.now);

    final rawDateStr = DateFormat('EEEE, d MMMM', 'es').format(selectedDate);
    final dateStr = rawDateStr[0].toUpperCase() + rawDateStr.substring(1);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF6C5CE7).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Fecha y hora
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                        ).createShader(b),
                        child: Text(
                          timeStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      if (isToday) _LiveDot(),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isToday ? 'Hoy • $dateStr' : dateStr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isToday ? const Color(0xFF6C5CE7) : const Color(0xFF9E98D4),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Botones de acción del header (Cuenta/Cloud, ToDo, Recordatorios, Tema, Calendario, Toggle 12/24H)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón de Perfil / Nube Supabase
              _buildHeaderIconButton(
                buttonBg: buttonBg,
                tooltip: provider.isUserLoggedIn
                    ? 'Cuenta: ${provider.userEmail ?? "Conectado"}'
                    : 'Iniciar Sesión / Nube',
                icon: provider.isUserLoggedIn
                    ? (provider.isCloudSyncing
                        ? Icons.sync_rounded
                        : Icons.cloud_done_rounded)
                    : Icons.cloud_outlined,
                iconColor: provider.isUserLoggedIn
                    ? const Color(0xFF00CEC9)
                    : const Color(0xFF6C5CE7),
                onTap: () => _openAuthSheet(context),
              ),
              const SizedBox(width: 4),

              // Botón de Tareas ToDo (Backlog)
              _buildHeaderIconButton(
                buttonBg: buttonBg,
                tooltip: provider.pendingTodoCount == 1
                    ? '1 tarea pendiente'
                    : '${provider.pendingTodoCount} pendientes',
                icon: Icons.checklist_rounded,
                badgeCount: provider.pendingTodoCount,
                onTap: () => _openTodoListSheet(context),
              ),
              const SizedBox(width: 4),

              // Botón de Recordatorios / Notificaciones
              _buildHeaderIconButton(
                buttonBg: buttonBg,
                tooltip: provider.notificationsEnabled
                    ? 'Recordatorios: ${provider.reminderMinutesBefore == 0 ? "Al comenzar" : "${provider.reminderMinutesBefore}m antes"}'
                    : 'Recordatorios desactivados',
                icon: provider.notificationsEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                onTap: () => _openNotificationSettings(context),
              ),
              const SizedBox(width: 4),

              // Selector de Modo de Tema
              _buildHeaderIconButton(
                buttonBg: buttonBg,
                tooltip: 'Tema: ${provider.themeModeName}',
                icon: provider.themeModeIcon,
                onTap: () => _openThemeSelector(context),
              ),
              const SizedBox(width: 4),

              // Botón de Calendario Mensual
              _buildHeaderIconButton(
                buttonBg: buttonBg,
                tooltip: 'Calendario Mensual',
                icon: Icons.calendar_month_rounded,
                onTap: () => _openMonthlyCalendar(context),
              ),
              const SizedBox(width: 4),

              // Toggle 12h/24h
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.toggleClockMode();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                  decoration: BoxDecoration(
                    color: provider.is24h
                        ? const Color(0xFF6C5CE7)
                        : buttonBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    provider.is24h ? '24H' : '12H',
                    style: TextStyle(
                      color: provider.is24h
                          ? Colors.white
                          : const Color(0xFF6C5CE7),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required Color buttonBg,
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    int? badgeCount,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: buttonBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, color: iconColor ?? const Color(0xFF6C5CE7), size: 16),
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B81),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).cardColor,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
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
  // Reloj (widget puro, sin Expanded)
  // ──────────────────────────────────────────────

  Widget _buildClockWidget(BuildContext outerCtx, double shrinkRatio) {
    // Desvanece y achica el reloj conforme se colapsa
    final opacity = (1.0 - shrinkRatio * 1.4).clamp(0.0, 1.0);
    final scale   = (1.0 - shrinkRatio * 0.15).clamp(0.0, 1.0);

    // Consumer garantiza que el reloj se reconstruya cada segundo cuando
    // ClockProvider llama a notifyListeners(), sin depender del contexto
    // del SliverPersistentHeaderDelegate.
    return Consumer<ClockProvider>(
      builder: (ctx, provider, _) {
        final dayBlocks = provider.selectedDateBlocks;

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: RadialClockCanvas(
                  key: ValueKey(
                      '${provider.selectedDate.toIso8601String()}_${provider.is24h}'),
                  blocks: dayBlocks,
                  currentHour: provider.currentHourView,
                  is24h: provider.is24h,
                  onGestureComplete: (s, e) => _openCreateSheet(
                    ctx,
                    startHour: s,
                    endHour: e,
                    date: provider.selectedDate,
                  ),
                  onBlockTap: (id) => _openEditSheet(ctx, id),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // Lista de tareas como slivers
  // ──────────────────────────────────────────────

  List<Widget> _buildTaskSlivers(BuildContext context) {
    final provider = context.watch<ClockProvider>();
    final blocks = provider.selectedDateBlocks;
    final isToday = provider.isViewingToday;
    final dateLabel = isToday
        ? 'HOY'
        : DateFormat('d MMM', 'es').format(provider.selectedDate).toUpperCase();

    if (blocks.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.touch_app_rounded,
                      color: Color(0xFF6C5CE7),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isToday
                      ? 'No tienes tareas hoy'
                      : 'Sin tareas para este día',
                  style: const TextStyle(
                    color: Color(0xFF9E98D4),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Toca y arrastra en el reloj para agendar',
                  style: TextStyle(
                    color: Color(0xFFBBB5E8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      // Encabezado con conteo
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          child: Row(
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  color: Color(0xFF9E98D4),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${blocks.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Tarjetas de tareas
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          100 + MediaQuery.of(context).padding.bottom,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => TweenAnimationBuilder<double>(
              key: ValueKey(blocks[i].id),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 250 + i * 50),
              curve: Curves.easeOutCubic,
              builder: (_, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - v)),
                  child: child,
                ),
              ),
              child: _buildTaskTile(ctx, blocks[i]),
            ),
            childCount: blocks.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildTaskTile(BuildContext context, TimeBlock block) {
    final provider = context.read<ClockProvider>();
    final isCompleted  = block.status == TaskStatus.completed;
    final isInProgress = block.status == TaskStatus.inProgress;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);

    return _PressableTile(
      onTap: () => _openEditSheet(context, block.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: isInProgress
              ? Border.all(color: block.category.color.withValues(alpha: 0.5), width: 1.5)
              : (isDark ? Border.all(color: const Color(0xFF2A2D42), width: 1) : null),
          boxShadow: [
            BoxShadow(
              color: block.category.color.withValues(alpha: isInProgress ? 0.15 : (isDark ? 0.02 : 0.06)),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Pill de color
            Container(
              width: 4,
              height: 38,
              decoration: BoxDecoration(
                color: isCompleted
                    ? block.category.color.withValues(alpha: 0.3)
                : block.category.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),

            // Icono de categoría
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: block.category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                block.category.icon,
                size: 16,
                color: isCompleted
                    ? block.category.color.withValues(alpha: 0.4)
                    : block.category.color,
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.title,
                    style: TextStyle(
                      color: isCompleted
                          ? (isDark ? const Color(0xFF6B7194) : const Color(0xFFBBB5E8))
                          : textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: isDark ? const Color(0xFF6B7194) : const Color(0xFFBBB5E8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${RadialMath.decimalHoursToString(block.startHour)} – '
                    '${RadialMath.decimalHoursToString(block.endHour)}',
                    style: const TextStyle(
                      color: Color(0xFF9E98D4),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Chip de estado (tap para ciclar)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                provider.toggleStatus(block.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(block.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon(block.status),
                      size: 11,
                      color: _statusColor(block.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      block.status.displayName,
                      style: TextStyle(
                        color: _statusColor(block.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
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

  Color _statusColor(TaskStatus s) => switch (s) {
    TaskStatus.pending    => const Color(0xFF9E98D4),
    TaskStatus.inProgress => const Color(0xFF00CEC9),
    TaskStatus.completed  => const Color(0xFF00B894),
  };

  IconData _statusIcon(TaskStatus s) => switch (s) {
    TaskStatus.pending    => Icons.radio_button_unchecked_rounded,
    TaskStatus.inProgress => Icons.timelapse_rounded,
    TaskStatus.completed  => Icons.check_circle_rounded,
  };

  // ──────────────────────────────────────────────
  // FAB
  // ──────────────────────────────────────────────

  Widget _buildFAB(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset * 0.4 : 0),
      child: ScaleTransition(
        scale: _fabScale,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B7CF6), Color(0xFF6C5CE7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _openCreateSheet(context),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Widgets auxiliares de microinteracción
// ──────────────────────────────────────────────

/// Punto verde pulsante de "en vivo"
class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: Color.lerp(
          const Color(0xFF00CEC9),
          const Color(0xFF00B894),
          _anim.value,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00CEC9).withValues(alpha: _anim.value * 0.6),
            blurRadius: 6,
          ),
        ],
      ),
    ),
  );
}

/// Tile con efecto de escala al presionar
class _PressableTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableTile({required this.child, required this.onTap});

  @override
  State<_PressableTile> createState() => _PressableTileState();
}

class _PressableTileState extends State<_PressableTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
