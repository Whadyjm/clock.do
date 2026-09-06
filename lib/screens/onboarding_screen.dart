import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
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
    if (_currentPage < 3) {
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

    return Theme(
      // Forzar tema claro de alta fidelidad para el onboarding
      data: ThemeData.light(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFFF4F2FF),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6C5CE7),
          secondary: Color(0xFF00CEC9),
          surface: Colors.white,
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F2FF),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                              ),
                            ),
                            child: const Icon(Icons.access_time_filled_rounded,
                                size: 12, color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'CLOCK.DO',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Color(0xFF1E1B4B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Botón Saltar
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _currentPage < 3 ? 1.0 : 0.0,
                      child: TextButton(
                        key: const Key('onboarding_skip_button'),
                        onPressed: _currentPage < 3 ? _completeOnboarding : null,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6C5CE7),
                          backgroundColor: Colors.white.withValues(alpha: 0.8),
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

              // Contenido Deslizante (PageView)
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
                    ),
                    _buildPage(
                      badge: l10n.onboardingStep2Badge,
                      badgeColor: const Color(0xFF00B894),
                      title: l10n.onboardingStep2Title,
                      description: l10n.onboardingStep2Desc,
                      illustration: _TaskPlanningIllustration(anim: _animController),
                    ),
                    _buildPage(
                      badge: l10n.onboardingStep3Badge,
                      badgeColor: const Color(0xFF0984E3),
                      title: l10n.onboardingStep3Title,
                      description: l10n.onboardingStep3Desc,
                      illustration: _SmartAlertsIllustration(anim: _animController),
                    ),
                    _buildPage(
                      badge: l10n.onboardingStep4Badge,
                      badgeColor: const Color(0xFFFF7675),
                      title: l10n.onboardingStep4Title,
                      description: l10n.onboardingStep4Desc,
                      illustration: _WelcomeCelebrationIllustration(anim: _animController),
                    ),
                  ],
                ),
              ),

              // Barra Inferior (Indicadores + Botón Siguiente / Comenzar)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    // Indicadores de Página (Dots / Pills)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final isSelected = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: isSelected ? 28 : 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6C5CE7)
                                : const Color(0xFFDDD8F5),
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
                                _currentPage == 3
                                    ? l10n.onboardingGetStarted
                                    : l10n.onboardingNext,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (_currentPage < 3) ...[
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
  }) {
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
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      letterSpacing: -0.5,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Descripción
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B6789),
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
// ILUSTRACIÓN 2: PLANIFICACIÓN Y CARDS DE TAREAS
// ─────────────────────────────────────────────────────────────────────────────
class _TaskPlanningIllustration extends StatelessWidget {
  final Animation<double> anim;
  const _TaskPlanningIllustration({required this.anim});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fondo resplandeciente
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00B894).withValues(alpha: 0.08),
            ),
          ),

          // Tarjeta 3 (Fondo abajo con rotación suave)
          Positioned(
            bottom: 30,
            child: Transform.rotate(
              angle: 0.05,
              child: _buildMockCard(
                title: 'Lectura Diaria & Notas',
                time: '08:00 - 09:00 AM',
                category: 'Estudio',
                color: const Color(0xFFE17055),
                icon: Icons.menu_book_rounded,
                isCompleted: true,
                width: 250,
              ),
            ),
          ),

          // Tarjeta 2 (Intermedia)
          Positioned(
            top: 70,
            child: Transform.rotate(
              angle: -0.04,
              child: _buildMockCard(
                title: 'Entrenamiento Funcional',
                time: '06:30 - 07:30 AM',
                category: 'Salud',
                color: const Color(0xFF00B894),
                icon: Icons.fitness_center_rounded,
                isCompleted: true,
                width: 260,
              ),
            ),
          ),

          // Tarjeta 1 (Principal Arriba, animada suavemente)
          AnimatedBuilder(
            animation: anim,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -6 + 12 * anim.value),
                child: child,
              );
            },
            child: _buildMockCard(
              title: 'Diseño UX Clock.Do 🚀',
              time: '10:00 - 12:30 PM',
              category: 'Trabajo',
              color: const Color(0xFF6C5CE7),
              icon: Icons.palette_rounded,
              isCompleted: false,
              isHighlighted: true,
              width: 275,
            ),
          ),

          // Puntero de arrastre animado ("Drag & Drop")
          Positioned(
            bottom: 12,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Arrastra al Dial',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
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

  Widget _buildMockCard({
    required String title,
    required String time,
    required String category,
    required Color color,
    required IconData icon,
    required bool isCompleted,
    bool isHighlighted = false,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isHighlighted ? color : Colors.black).withValues(
              alpha: isHighlighted ? 0.16 : 0.06,
            ),
            blurRadius: isHighlighted ? 18 : 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isHighlighted ? color.withValues(alpha: 0.3) : const Color(0xFFF0EEFF),
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icono con fondo coloreado
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),

          // Título y Horario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E8AA7),
                  ),
                ),
              ],
            ),
          ),

          // Badge o Check
          if (isCompleted)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF00B894).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 14, color: Color(0xFF00B894)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ILUSTRACIÓN 3: ALERTAS INTELIGENTES & NUBE
// ─────────────────────────────────────────────────────────────────────────────
class _SmartAlertsIllustration extends StatelessWidget {
  final Animation<double> anim;
  const _SmartAlertsIllustration({required this.anim});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ondas de notificación expansivas
          AnimatedBuilder(
            animation: anim,
            builder: (context, _) {
              return Container(
                width: 160 + 30 * anim.value,
                height: 160 + 30 * anim.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0984E3).withValues(
                      alpha: (1.0 - anim.value * 0.7).clamp(0.0, 1.0) * 0.25,
                    ),
                    width: 2,
                  ),
                ),
              );
            },
          ),

          // Círculo central con campana de notificación
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF0984E3), Color(0xFF74B9FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0984E3).withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.notifications_active_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),

          // Banner superior de alerta simulada
          Positioned(
            top: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0984E3).withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFD6E9FF)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alarm_on_rounded, size: 18, color: Color(0xFF0984E3)),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¡En 15 minutos!',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0984E3),
                        ),
                      ),
                      Text(
                        'Reunión de Estrategia 🎯',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Badge inferior de sincronización en la nube
          Positioned(
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFF00CEC9).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done_rounded, size: 16, color: Color(0xFF00B894)),
                  SizedBox(width: 6),
                  Text(
                    'Sincronizado con la nube',
                    style: TextStyle(
                      fontSize: 11.5,
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
