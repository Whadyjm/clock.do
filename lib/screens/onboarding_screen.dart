import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../providers/clock_provider.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool fromSettings;

  const OnboardingScreen({super.key, this.fromSettings = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    if (widget.fromSettings) {
      Navigator.of(context).pop();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('clockdo_onboarding_completed', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 5) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ClockProvider? provider;
    try {
      provider = context.watch<ClockProvider>();
    } catch (_) {}

    final isDark = switch (provider?.themeMode ?? ThemeMode.system) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };

    final bgColor = isDark ? const Color(0xFF0F111E) : const Color(0xFFF4F2FF);

    return Theme(
      data: isDark
          ? ThemeData.dark(useMaterial3: true).copyWith(
              scaffoldBackgroundColor: bgColor,
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF6C5CE7),
                secondary: Color(0xFF00CEC9),
                surface: Color(0xFF181B2E),
              ),
            )
          : ThemeData.light(useMaterial3: true).copyWith(
              scaffoldBackgroundColor: bgColor,
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF6C5CE7),
                secondary: Color(0xFF00CEC9),
                surface: Colors.white,
              ),
            ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // Barra Superior (Brand pill + Botón Saltar)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF181B2E).withValues(alpha: 0.95)
                            : Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF6C5CE7)
                              .withValues(alpha: isDark ? 0.35 : 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7)
                                .withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/clickdologo.png',
                        key: const Key('brand_logo'),
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Botón Saltar
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _currentPage < 5 ? 1.0 : 0.0,
                      child: TextButton(
                        key: const Key('onboarding_skip_button'),
                        onPressed: _currentPage < 5 ? _completeOnboarding : null,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6C5CE7),
                          backgroundColor: isDark
                              ? const Color(0xFF181B2E)
                              : Colors.white.withValues(alpha: 0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          l10n.onboardingSkip,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido Deslizante (PageView con 6 pasos)
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (idx) {
                    setState(() => _currentPage = idx);
                  },
                  children: [
                    _buildPage(
                      badge: l10n.onboardingStep1Badge,
                      badgeColor: const Color(0xFF6C5CE7),
                      title: l10n.onboardingStep1Title,
                      description: l10n.onboardingStep1Desc,
                      illustration: _RadialClockIllustration(anim: _animController),
                      isDark: isDark,
                    ),
                    _buildPage(
                      badge: l10n.onboardingStep2Badge,
                      badgeColor: const Color(0xFF00CEC9),
                      title: l10n.onboardingStep2Title,
                      description: l10n.onboardingStep2Desc,
                      illustration: _KanbanBoardIllustration(anim: _animController),
                      isDark: isDark,
                    ),
                    _buildPage(
                      badge: l10n.onboardingStep3Badge,
                      badgeColor: const Color(0xFFFF5252),
                      title: l10n.onboardingStep3Title,
                      description: l10n.onboardingStep3Desc,
                      illustration: _PomodoroOrbitalIllustration(anim: _animController),
                      isDark: isDark,
                    ),
                    _buildPage(
                      badge: l10n.onboardingStep4Badge,
                      badgeColor: const Color(0xFF0984E3),
                      title: l10n.onboardingStep4Title,
                      description: l10n.onboardingStep4Desc,
                      illustration: _ReminderSetupIllustration(anim: _animController),
                      isDark: isDark,
                    ),
                    _buildPage(
                      badge: l10n.onboardingStep5Badge,
                      badgeColor: const Color(0xFF6C5CE7),
                      title: l10n.onboardingStep5Title,
                      description: l10n.onboardingStep5Desc,
                      illustration: _PreferencesSetupIllustration(anim: _animController),
                      isDark: isDark,
                    ),
                    _buildPage(
                      badge: l10n.onboardingStep6Badge,
                      badgeColor: const Color(0xFFFF7675),
                      title: l10n.onboardingStep6Title,
                      description: l10n.onboardingStep6Desc,
                      illustration: _WelcomeCelebrationIllustration(anim: _animController),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              // Barra Inferior (Indicadores + Botón Siguiente / Comenzar)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    // Indicadores de Página (Dots / Pills - 6 pasos)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        final isSelected = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: isSelected ? 28 : 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6C5CE7)
                                : (isDark
                                    ? const Color(0xFF2A2D45)
                                    : const Color(0xFFDDD8F5)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Botón Principal
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C5CE7), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C5CE7).withValues(alpha: 0.38),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          key: const Key('onboarding_action_button'),
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == 5
                                    ? l10n.onboardingGetStarted
                                    : l10n.onboardingNext,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (_currentPage < 5) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 20),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required String badge,
    required Color badgeColor,
    required String title,
    required String description,
    required Widget illustration,
    bool isDark = false,
  }) {
    final titleColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final descColor = isDark ? const Color(0xFFB0ACCB) : const Color(0xFF6B6789);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Ilustración dinámica responsive
          Expanded(
            flex: 5,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: illustration,
              ),
            ),
          ),

          // Textos informativos
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Título
                  if (title.contains('Clock.Do')) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title.replaceAll('Clock.Do', '').trim(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            letterSpacing: -0.5,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Image.asset(
                          'assets/clickdologo.png',
                          height: 20,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        letterSpacing: -0.5,
                        color: titleColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Descripción
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: descColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ILUSTRACIÓN 1: RELOJ RADIAL INTERACTIVO
// ─────────────────────────────────────────────────────────────────────────────
class _RadialClockIllustration extends StatelessWidget {
  final Animation<double> anim;
  const _RadialClockIllustration({required this.anim});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      height: 290,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Resplandor exterior de fondo
          AnimatedBuilder(
            animation: anim,
            builder: (context, _) {
              return Container(
                width: 270 + 10 * anim.value,
                height: 270 + 10 * anim.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6C5CE7).withValues(alpha: 0.18),
                      const Color(0xFF00CEC9).withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),

          // Disco del reloj con sombra premium
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _ClockDialPainter(),
            ),
          ),

          // Aguja animada
          AnimatedBuilder(
            animation: anim,
            builder: (context, _) {
              final angle = (anim.value * 0.5 + 0.3) * math.pi;
              return Transform.rotate(
                angle: angle,
                child: Container(
                  width: 4,
                  height: 90,
                  margin: const EdgeInsets.only(bottom: 70),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                    ),
                  ),
                ),
              );
            },
          ),

          // Centro del reloj
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C5CE7),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),

          // Tag flotante superior derecha
          Positioned(
            top: 20,
            right: 12,
            child: _buildFloatingPill(
              icon: Icons.bolt_rounded,
              color: const Color(0xFF6C5CE7),
              text: 'Deep Work · 2h',
            ),
          ),

          // Tag flotante inferior izquierda
          Positioned(
            bottom: 24,
            left: 8,
            child: _buildFloatingPill(
              icon: Icons.fitness_center_rounded,
              color: const Color(0xFF00CEC9),
              text: 'Gym & Salud · 1h',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingPill({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Arcos coloreados representando bloques de tiempo
    final rect = Rect.fromCircle(center: center, radius: radius - 20);

    // Bloque 1 (Púrpura / Trabajo)
    final paint1 = Paint()
      ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 0.7, false, paint1);

    // Bloque 2 (Cyan / Estudio)
    final paint2 = Paint()
      ..color = const Color(0xFF00CEC9).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi * 0.35, math.pi * 0.45, false, paint2);

    // Bloque 3 (Coral / Relax)
    final paint3 = Paint()
      ..color = const Color(0xFFFF7675).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi * 0.9, math.pi * 0.35, false, paint3);

    // Marcas de horas (12 notches)
    final tickPaint = Paint()
      ..color = const Color(0xFFDDD8F5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final start = Offset(
        center.dx + (radius - 10) * math.cos(angle),
        center.dy + (radius - 10) * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 4) * math.cos(angle),
        center.dy + (radius - 4) * math.sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// ILUSTRACIÓN 2: TABLERO KANBAN DINÁMICO & ARRASTRE ÁGIL
// ─────────────────────────────────────────────────────────────────────────────
class _KanbanBoardIllustration extends StatefulWidget {
  final Animation<double> anim;
  const _KanbanBoardIllustration({required this.anim});

  @override
  State<_KanbanBoardIllustration> createState() => _KanbanBoardIllustrationState();
}

class _KanbanBoardIllustrationState extends State<_KanbanBoardIllustration> {
  int _targetColumn = 1; // 0 = Backlog, 1 = En Progreso, 2 = Completadas

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 290,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Resplandor ambiental multicolor de fondo
          AnimatedBuilder(
            animation: widget.anim,
            builder: (context, _) {
              return Container(
                width: 290 + 14 * widget.anim.value,
                height: 250 + 14 * widget.anim.value,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00CEC9).withValues(
                        alpha: 0.18 + 0.06 * widget.anim.value,
                      ),
                      const Color(0xFF6C5CE7).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),

          // Contenedor del Tablero Kanban (Mini Board)
          Container(
            width: 310,
            height: 240,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.85),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Columna 1: Backlog
                Expanded(
                  child: _buildColumn(
                    title: 'BACKLOG',
                    count: '3',
                    color: const Color(0xFF6C5CE7),
                    icon: Icons.inbox_rounded,
                    isTarget: _targetColumn == 0,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _targetColumn = 0);
                    },
                    child: _buildMiniCard(
                      title: 'Research',
                      time: '45m',
                      tagColor: const Color(0xFFE17055),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Columna 2: En Progreso (Drop target activo con borde neón)
                Expanded(
                  child: _buildColumn(
                    title: 'EN CURSO',
                    count: '1',
                    color: const Color(0xFF00CEC9),
                    icon: Icons.timelapse_rounded,
                    isTarget: _targetColumn == 1,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _targetColumn = 1);
                    },
                    child: _buildDropZonePlaceholder(),
                  ),
                ),
                const SizedBox(width: 6),

                // Columna 3: Completadas
                Expanded(
                  child: _buildColumn(
                    title: 'HECHO',
                    count: '4',
                    color: const Color(0xFF00B894),
                    icon: Icons.check_circle_rounded,
                    isTarget: _targetColumn == 2,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _targetColumn = 2);
                    },
                    child: _buildMiniCard(
                      title: 'Pitch Deck',
                      time: 'Listo',
                      tagColor: const Color(0xFF00B894),
                      isDone: true,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tarjeta en vuelo / arrastre animado (Hero Card)
          AnimatedBuilder(
            animation: widget.anim,
            builder: (context, child) {
              final t = widget.anim.value;
              final double dx = switch (_targetColumn) {
                0 => -55.0 + 8.0 * (1 - t),
                2 => 55.0 - 8.0 * (1 - t),
                _ => -24.0 + 44.0 * t,
              };
              final double dy = -16.0 + 8.0 * math.sin(t * math.pi);
              final double rotation = -0.035 + 0.07 * t;

              return Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(
                  angle: rotation,
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _targetColumn = (_targetColumn + 1) % 3;
                });
              },
              child: _buildFlyingHeroCard(),
            ),
          ),

          // Pill inferior: Indicador interactivo Drag & Drop
          Positioned(
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF352F6E)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF00CEC9)),
                  SizedBox(width: 5),
                  Text(
                    'Arrastra entre Columnas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlyingHeroCard() {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFAFAFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00CEC9),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00CEC9).withValues(alpha: 0.38),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'TRABAJO',
                  style: TextStyle(
                    color: Color(0xFF6C5CE7),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7675).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 9, color: Color(0xFFFF7675)),
                    SizedBox(width: 2),
                    Text(
                      'Alta',
                      style: TextStyle(
                        color: Color(0xFFFF7675),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Diseño UX Clock.Do 🚀',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1B4B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 10, color: Color(0xFF8E8AA7)),
              const SizedBox(width: 3),
              const Expanded(
                child: Text(
                  '10:00 AM · 90m',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E8AA7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFF00CEC9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.touch_app_rounded,
                    size: 9, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropZonePlaceholder() {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xFF00CEC9).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00CEC9).withValues(alpha: 0.55),
          style: BorderStyle.solid,
          width: 1.4,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.file_download_outlined,
                size: 16, color: Color(0xFF00CEC9)),
            SizedBox(height: 2),
            Text(
              'Soltar aquí',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00CEC9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCard({
    required String title,
    required String time,
    required Color tagColor,
    bool isDone = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEAF8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: tagColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isDone
                        ? const Color(0xFF00B894)
                        : const Color(0xFF1E1B4B),
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isDone)
                const Icon(Icons.check_rounded,
                    size: 11, color: Color(0xFF00B894)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8AA7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn({
    required String title,
    required String count,
    required Color color,
    required IconData icon,
    required bool isTarget,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        decoration: BoxDecoration(
          color: isTarget
              ? color.withValues(alpha: 0.09)
              : const Color(0xFFF7F6FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTarget ? color : const Color(0xFFE9E5F8),
            width: isTarget ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ILUSTRACIÓN 3: MODO POMODORO & DEEP WORK ORBITAL
// ─────────────────────────────────────────────────────────────────────────────
class _PomodoroOrbitalIllustration extends StatefulWidget {
  final Animation<double> anim;
  const _PomodoroOrbitalIllustration({required this.anim});

  @override
  State<_PomodoroOrbitalIllustration> createState() =>
      _PomodoroOrbitalIllustrationState();
}

class _PomodoroOrbitalIllustrationState
    extends State<_PomodoroOrbitalIllustration> {
  bool _isBreakMode = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        _isBreakMode ? const Color(0xFF00CEC9) : const Color(0xFFFF5252);
    final secondaryColor =
        _isBreakMode ? const Color(0xFF00B894) : const Color(0xFFFF7675);
    final timeText = _isBreakMode ? '05:00' : '25:00';
    final phaseLabel = _isBreakMode ? '☕ PAUSA CORTA' : '🍅 DEEP WORK';

    return SizedBox(
      width: 300,
      height: 290,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Resplandor de respiración neón ambiental de fondo
          AnimatedBuilder(
            animation: widget.anim,
            builder: (context, _) {
              return Container(
                width: 255 + 16 * widget.anim.value,
                height: 255 + 16 * widget.anim.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withValues(
                        alpha: 0.22 + 0.08 * widget.anim.value,
                      ),
                      const Color(0xFF6C5CE7).withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),

          // Disco principal del Pomodoro con CustomPaint
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() => _isBreakMode = !_isBreakMode);
            },
            child: Container(
              width: 215,
              height: 215,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.24),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.95),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pintor del dial radial con arco de progreso neón
                  AnimatedBuilder(
                    animation: widget.anim,
                    builder: (context, _) {
                      return CustomPaint(
                        size: const Size(215, 215),
                        painter: _PomodoroDialPainter(
                          progress: _isBreakMode
                              ? 0.40 + 0.05 * widget.anim.value
                              : 0.72 + 0.04 * widget.anim.value,
                          primaryColor: primaryColor,
                          secondaryColor: secondaryColor,
                          pulse: widget.anim.value,
                        ),
                      );
                    },
                  ),

                  // Centro digital: Contador, Badge y Ciclos
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge de fase interactivo
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          phaseLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Contador Digital Principal
                      Text(
                        timeText,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                          height: 1.0,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Indicador de 4 Ciclos Pomodoro
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(4, (i) {
                          final isCompleted = i < (_isBreakMode ? 1 : 2);
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? primaryColor
                                  : primaryColor.withValues(alpha: 0.2),
                              boxShadow: isCompleted
                                  ? [
                                      BoxShadow(
                                        color: primaryColor.withValues(alpha: 0.5),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tag flotante superior derecho: "Ciclo 2 de 4"
          Positioned(
            top: 14,
            right: 8,
            child: _buildFloatingTag(
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFFF7675),
              text: 'Ciclo 2 de 4',
            ),
          ),

          // Tag flotante superior izquierdo: "Pausa · 5 min"
          Positioned(
            top: 18,
            left: 6,
            child: _buildFloatingTag(
              icon: Icons.coffee_rounded,
              color: const Color(0xFF00CEC9),
              text: 'Pausa · 5 min',
            ),
          ),

          // Tag flotante inferior: Tarea vinculada
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 14, color: Color(0xFF6C5CE7)),
                  SizedBox(width: 5),
                  Text(
                    'Tarea: Enfoque Sprint 🚀',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTag({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PomodoroDialPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final double pulse;

  _PomodoroDialPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final progressRadius = radius - 16.0;
    final trackThickness = 11.0;

    // Puntos orbitales
    const totalDots = 48;
    for (int i = 0; i < totalDots; i++) {
      final isMajor = i % 4 == 0;
      final angle = (i / totalDots) * 2 * math.pi - math.pi / 2;
      final dotPos = Offset(
        center.dx + (progressRadius + 9) * math.cos(angle),
        center.dy + (progressRadius + 9) * math.sin(angle),
      );
      canvas.drawCircle(
        dotPos,
        isMajor ? 1.8 : 1.0,
        Paint()
          ..color = (isMajor ? primaryColor : const Color(0xFFDDD8F5))
              .withValues(alpha: 0.6),
      );
    }

    // Pista de fondo
    final trackPaint = Paint()
      ..color = const Color(0xFFF0EEFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackThickness
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, progressRadius, trackPaint);

    // Resplandor neón del arco
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.35 + 0.15 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackThickness + 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    const startAngle = -math.pi / 2;
    final sweepAngle = (progress * 2 * math.pi).clamp(0.01, 2 * math.pi);
    final rect = Rect.fromCircle(center: center, radius: progressRadius);

    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    // Arco de progreso con gradiente
    final sweepGradient = SweepGradient(
      startAngle: 0.0,
      endAngle: 2 * math.pi,
      transform: const GradientRotation(-math.pi / 2),
      colors: [secondaryColor, primaryColor],
    );

    final progressPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackThickness
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

    // Cabezal indicador en la punta
    final tipAngle = startAngle + sweepAngle;
    final tipPos = Offset(
      center.dx + progressRadius * math.cos(tipAngle),
      center.dy + progressRadius * math.sin(tipAngle),
    );

    canvas.drawCircle(
      tipPos,
      trackThickness * 0.75,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(
      tipPos,
      trackThickness * 0.55,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _PomodoroDialPainter old) =>
      old.progress != progress ||
      old.pulse != pulse ||
      old.primaryColor != primaryColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// ILUSTRACIÓN 4: CONFIGURACIÓN DE RECORDATORIOS Y PERMISOS DEL SISTEMA
// ─────────────────────────────────────────────────────────────────────────────
class _ReminderSetupIllustration extends StatelessWidget {
  final Animation<double> anim;
  const _ReminderSetupIllustration({required this.anim});

  static const List<int> _reminderMinutes = [0, 5, 10, 15, 30];

  @override
  Widget build(BuildContext context) {
    ClockProvider? provider;
    try {
      provider = context.watch<ClockProvider>();
    } catch (_) {}

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = provider?.notificationsEnabled ?? false;
    final currentMinutes = provider?.reminderMinutesBefore ?? 5;
    final l10n = context.l10n;

    return SizedBox(
      width: 320,
      height: 290,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Resplandor ambiental de fondo
          AnimatedBuilder(
            animation: anim,
            builder: (context, _) {
              return Container(
                width: 270 + 16 * anim.value,
                height: 270 + 16 * anim.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0984E3).withValues(
                        alpha: isEnabled ? (0.22 + 0.08 * anim.value) : 0.08,
                      ),
                      const Color(0xFF6C5CE7).withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),

          // Tarjeta interactiva principal
          Container(
            width: 310,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF181B2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isEnabled
                    ? const Color(0xFF0984E3).withValues(alpha: 0.5)
                    : (isDark ? const Color(0xFF2B2E4A) : const Color(0xFFE8E5F8)),
                width: isEnabled ? 1.6 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isEnabled
                      ? const Color(0xFF0984E3).withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera: Icono Campana animada + Switch
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: anim,
                      builder: (context, child) {
                        final bounce = isEnabled
                            ? math.sin(anim.value * math.pi * 2) * 0.1
                            : 0.0;
                        return Transform.rotate(
                          angle: bounce,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isEnabled
                                ? [const Color(0xFF0984E3), const Color(0xFF74B9FF)]
                                : [const Color(0xFF9E98D4), const Color(0xFFB8B3E4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: isEnabled
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF0984E3).withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Textos descriptivos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.onboardingEnableReminders,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEnabled
                                ? l10n.onboardingRemindersActive
                                : l10n.onboardingRemindersDisabled,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: isEnabled
                                  ? const Color(0xFF00B894)
                                  : const Color(0xFF8E8AA7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Switch interactivo
                    Switch.adaptive(
                      key: const Key('onboarding_notifications_switch'),
                      value: isEnabled,
                      activeColor: const Color(0xFF0984E3),
                      onChanged: (val) {
                        HapticFeedback.mediumImpact();
                        provider?.setNotificationsEnabled(val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF262A43) : const Color(0xFFF0EEFF),
                ),
                const SizedBox(height: 10),

                // Selector de Anticipación
                Row(
                  children: [
                    Icon(
                      Icons.alarm_on_rounded,
                      size: 13,
                      color: isDark ? const Color(0xFF9E98D4) : const Color(0xFF6C5CE7),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      l10n.onboardingSelectAdvance,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? const Color(0xFF9E98D4) : const Color(0xFF6C5CE7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Chips de selección
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _reminderMinutes.map((minutes) {
                    final isSelected = currentMinutes == minutes;
                    final isRecommended = minutes == 5;
                    final label = minutes == 0 ? '0m' : '${minutes}m';

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: GestureDetector(
                          key: Key('onboarding_advance_chip_$minutes'),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            provider?.setReminderMinutes(minutes);
                            if (!isEnabled) {
                              provider?.setNotificationsEnabled(true);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0984E3)
                                  : (isDark ? const Color(0xFF22263F) : const Color(0xFFF5F3FF)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0984E3)
                                    : (isRecommended
                                        ? const Color(0xFF00CEC9).withValues(alpha: 0.6)
                                        : Colors.transparent),
                                width: 1.4,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0984E3).withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : const Color(0xFF1E1B4B)),
                                  ),
                                ),
                                if (isRecommended) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Top',
                                    style: TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : const Color(0xFF00B894),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),

                // Pill informativo en la base del card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0984E3).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 12, color: Color(0xFF0984E3)),
                        const SizedBox(width: 4),
                        Text(
                          currentMinutes == 0
                              ? 'Aviso en la hora exacta de inicio de la tarea'
                              : 'Aviso $currentMinutes minutos antes de iniciar',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0984E3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ILUSTRACIÓN 5: PERSONALIZACIÓN DE TEMA E IDIOMA EN TIEMPO REAL
// ─────────────────────────────────────────────────────────────────────────────
class _PreferencesSetupIllustration extends StatelessWidget {
  final Animation<double> anim;
  const _PreferencesSetupIllustration({required this.anim});

  @override
  Widget build(BuildContext context) {
    ClockProvider? provider;
    try {
      provider = context.watch<ClockProvider>();
    } catch (_) {}

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTheme = provider?.themeMode ?? ThemeMode.system;
    final currentLang = provider?.currentLanguageCode ?? 'system';
    final l10n = context.l10n;

    return SizedBox(
      width: 320,
      height: 290,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Resplandor ambiental de fondo
          AnimatedBuilder(
            animation: anim,
            builder: (context, _) {
              return Container(
                width: 270 + 16 * anim.value,
                height: 270 + 16 * anim.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6C5CE7).withValues(
                        alpha: 0.18 + 0.06 * anim.value,
                      ),
                      const Color(0xFFFF7675).withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),

          // Contenedor interactivo principal
          Container(
            width: 310,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF181B2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF2B2E4A) : const Color(0xFFE8E5F8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.16),
                  blurRadius: 26,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── SECCIÓN 1: TEMA ─────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.palette_rounded,
                        size: 13, color: Color(0xFF6C5CE7)),
                    const SizedBox(width: 5),
                    Text(
                      l10n.onboardingThemePreference,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF6C5CE7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3 opciones de tema
                Row(
                  children: [
                    _buildThemeCard(
                      keyName: 'onboarding_theme_light',
                      label: l10n.onboardingThemeLight,
                      icon: Icons.light_mode_rounded,
                      color: const Color(0xFFFFAA00),
                      isSelected: currentTheme == ThemeMode.light,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        provider?.setThemeMode(ThemeMode.light);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildThemeCard(
                      keyName: 'onboarding_theme_dark',
                      label: l10n.onboardingThemeDark,
                      icon: Icons.dark_mode_rounded,
                      color: const Color(0xFFA29BFE),
                      isSelected: currentTheme == ThemeMode.dark,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        provider?.setThemeMode(ThemeMode.dark);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildThemeCard(
                      keyName: 'onboarding_theme_system',
                      label: l10n.onboardingThemeSystem,
                      icon: Icons.smartphone_rounded,
                      color: const Color(0xFF00CEC9),
                      isSelected: currentTheme == ThemeMode.system,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        provider?.setThemeMode(ThemeMode.system);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF262A43) : const Color(0xFFF0EEFF),
                ),
                const SizedBox(height: 10),

                // ── SECCIÓN 2: IDIOMA ───────────────────────────
                Row(
                  children: [
                    const Icon(Icons.translate_rounded,
                        size: 13, color: Color(0xFF00CEC9)),
                    const SizedBox(width: 5),
                    Text(
                      l10n.onboardingLanguagePreference,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF00CEC9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3 opciones de idioma
                Row(
                  children: [
                    _buildLangCard(
                      keyName: 'onboarding_lang_es',
                      flag: '🇪🇸',
                      label: 'Español',
                      isSelected: currentLang == 'es',
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        provider?.setLocale(const Locale('es'));
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildLangCard(
                      keyName: 'onboarding_lang_en',
                      flag: '🇺🇸',
                      label: 'English',
                      isSelected: currentLang == 'en',
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        provider?.setLocale(const Locale('en'));
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildLangCard(
                      keyName: 'onboarding_lang_system',
                      flag: '🌐',
                      label: 'Auto',
                      isSelected: currentLang == 'system',
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        provider?.setLocale(null);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard({
    required String keyName,
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        key: Key(keyName),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6C5CE7)
                : (isDark ? const Color(0xFF22263F) : const Color(0xFFF7F6FD)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6C5CE7)
                  : (isDark ? const Color(0xFF2D3255) : const Color(0xFFEAE6FB)),
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF1E1B4B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangCard({
    required String keyName,
    required String flag,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        key: Key(keyName),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00CEC9)
                : (isDark ? const Color(0xFF22263F) : const Color(0xFFF7F6FD)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00CEC9)
                  : (isDark ? const Color(0xFF2D3255) : const Color(0xFFEAE6FB)),
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00CEC9).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                flag,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF1E1B4B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ILUSTRACIÓN 4: CELEBRACIÓN Y LOGO HERO
// ─────────────────────────────────────────────────────────────────────────────
class _WelcomeCelebrationIllustration extends StatelessWidget {
  final Animation<double> anim;
  const _WelcomeCelebrationIllustration({required this.anim});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo de brillo multicolor
          AnimatedBuilder(
            animation: anim,
            builder: (context, _) {
              return Container(
                width: 220 + 16 * anim.value,
                height: 220 + 16 * anim.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6C5CE7).withValues(alpha: 0.25),
                      const Color(0xFFFF7675).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),

          // Contenedor principal con el Icono de la App
          Container(
            width: 140,
            height: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.28),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/clockdoicon.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                      ),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),

          // Partículas decorativas / Estrellas flotantes
          Positioned(
            top: 28,
            right: 36,
            child: _buildSparkle(const Color(0xFFFFAA00), 24),
          ),
          Positioned(
            top: 50,
            left: 36,
            child: _buildSparkle(const Color(0xFF00CEC9), 18),
          ),
          Positioned(
            bottom: 36,
            right: 48,
            child: _buildSparkle(const Color(0xFFFF7675), 20),
          ),
          Positioned(
            bottom: 40,
            left: 42,
            child: _buildSparkle(const Color(0xFF6C5CE7), 22),
          ),
        ],
      ),
    );
  }

  Widget _buildSparkle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(Icons.star_rounded, size: size * 0.75, color: color),
      ),
    );
  }
}
