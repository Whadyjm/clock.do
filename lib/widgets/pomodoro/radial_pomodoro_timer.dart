import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/pomodoro_state.dart';

/// Painter orbital para el dial radial de Pomodoro.
class RadialPomodoroPainter extends CustomPainter {
  final double progress; // 0.0 a 1.0 (tiempo transcurrido)
  final PomodoroPhase phase;
  final bool isDark;
  final bool isRunning;
  final double pulseValue; // 0.0 a 1.0 animación de respiración

  RadialPomodoroPainter({
    required this.progress,
    required this.phase,
    required this.isDark,
    required this.isRunning,
    this.pulseValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;

    final outerRadius = maxRadius - 16.0;
    final progressRadius = maxRadius - 28.0;
    final trackThickness = 12.0;

    // 1. Resplandor ambiental de respiración cuando está corriendo
    if (isRunning) {
      final glowRadius = progressRadius + (pulseValue * 8.0);
      final glowPaint = Paint()
        ..color = phase.primaryColor.withValues(alpha: 0.12 + pulseValue * 0.10)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 + pulseValue * 10);
      canvas.drawCircle(center, glowRadius, glowPaint);
    }

    // 2. Fondo de la esfera central con sombra suave
    final faceRadius = progressRadius - (trackThickness / 2) - 8.0;
    canvas.drawCircle(
      center,
      faceRadius,
      Paint()
        ..color = isDark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    canvas.drawCircle(
      center,
      faceRadius,
      Paint()..color = isDark ? const Color(0xFF13162B) : Colors.white,
    );

    canvas.drawCircle(
      center,
      faceRadius,
      Paint()
        ..color = isDark ? const Color(0xFF232742) : const Color(0xFFEEEAF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 3. Puntos orbitales externos (estilo característico ClockDo)
    const totalDots = 60;
    final dotColor = isDark ? const Color(0xFF383D5E) : const Color(0xFFDDD9F5);
    final majorDotColor = isDark ? const Color(0xFF6B7194) : const Color(0xFF9E98D4);

    for (int i = 0; i < totalDots; i++) {
      final isMajor = i % 5 == 0;
      final angle = (i / totalDots) * 2 * pi - pi / 2;
      final dotPos = Offset(
        center.dx + outerRadius * cos(angle),
        center.dy + outerRadius * sin(angle),
      );
      canvas.drawCircle(
        dotPos,
        isMajor ? 2.2 : 1.2,
        Paint()..color = isMajor ? majorDotColor : dotColor,
      );
    }

    // 4. Pista de fondo del arco
    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF1E2238) : const Color(0xFFF0EEFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackThickness
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, progressRadius, trackPaint);

    // 5. Arco de progreso con gradiente y resplandor neón
    final sweepAngle = (progress * 2 * pi).clamp(0.001, 2 * pi);
    const startAngle = -pi / 2;

    // Resplandor del arco
    final glowArcPaint = Paint()
      ..color = phase.primaryColor.withValues(alpha: isDark ? 0.45 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackThickness + 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: progressRadius),
      startAngle,
      sweepAngle,
      false,
      glowArcPaint,
    );

    // Gradiente del arco principal
    final rect = Rect.fromCircle(center: center, radius: progressRadius);
    final sweepGradient = SweepGradient(
      startAngle: 0.0,
      endAngle: 2 * pi,
      transform: const GradientRotation(-pi / 2),
      colors: [
        phase.secondaryColor,
        phase.primaryColor,
      ],
    );

    final progressPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackThickness
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // 6. Cabezal indicador en la punta activa
    if (progress > 0.01 && progress < 0.99) {
      final tipAngle = startAngle + sweepAngle;
      final tipPos = Offset(
        center.dx + progressRadius * cos(tipAngle),
        center.dy + progressRadius * sin(tipAngle),
      );

      // Sombra del cabezal
      canvas.drawCircle(
        tipPos,
        trackThickness * 0.75,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Círculo blanco del cabezal
      canvas.drawCircle(
        tipPos,
        trackThickness * 0.65,
        Paint()..color = Colors.white,
      );

      // Centro del cabezal con color de la fase
      canvas.drawCircle(
        tipPos,
        trackThickness * 0.35,
        Paint()..color = phase.primaryColor,
      );
    }
  }

  @override
  bool shouldRepaint(RadialPomodoroPainter old) =>
      old.progress != progress ||
      old.phase != phase ||
      old.isDark != isDark ||
      old.isRunning != isRunning ||
      old.pulseValue != pulseValue;
}

/// Widget interactivo del temporizador radial con animaciones fluidas de respiración.
class RadialPomodoroTimer extends StatefulWidget {
  final PomodoroSessionState session;
  final PomodoroSettings settings;
  final VoidCallback? onTap;

  const RadialPomodoroTimer({
    super.key,
    required this.session,
    required this.settings,
    this.onTap,
  });

  @override
  State<RadialPomodoroTimer> createState() => _RadialPomodoroTimerState();
}

class _RadialPomodoroTimerState extends State<RadialPomodoroTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    if (widget.session.status.isRunning) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(RadialPomodoroTimer old) {
    super.didUpdateWidget(old);
    if (widget.session.status.isRunning && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.session.status.isRunning && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.animateTo(0.0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = widget.session;
    final phase = session.phase;

    return AspectRatio(
      aspectRatio: 1.0,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (ctx, _) {
            return CustomPaint(
              painter: RadialPomodoroPainter(
                progress: session.progress,
                phase: phase,
                isDark: isDark,
                isRunning: session.status.isRunning,
                pulseValue: _pulseAnim.value,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono / Mascota amigable de Pomodoro con pulso suave
                    Transform.scale(
                      scale: 1.0 + (_pulseAnim.value * 0.08),
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          color: phase.primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: phase.primaryColor.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: phase.primaryColor.withValues(alpha: 0.25),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          phase.isFocus
                              ? '🍅'
                              : (phase == PomodoroPhase.shortBreak ? '☕' : '🌿'),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),

                    // Badge de Fase
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: phase.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: phase.primaryColor.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (phase.isFocus) ...[
                            const Text('🍅', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                          ] else ...[
                            Icon(phase.icon, size: 12, color: phase.primaryColor),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            phase.getLocalizedName(context).toUpperCase(),
                            style: TextStyle(
                              color: phase.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Reloj Digital Principal MM:SS
                    Text(
                      session.formattedTime,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2.0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Indicador de Ciclos / Rondas (ej. 4 dots de Pomodoro)
                    _buildCycleDots(context, session, widget.settings, isDark),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCycleDots(
    BuildContext context,
    PomodoroSessionState session,
    PomodoroSettings settings,
    bool isDark,
  ) {
    final totalDots = settings.longBreakInterval;
    final completed = session.completedCycles;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalDots, (index) {
        final isFilled = index < completed;
        final isCurrent = index == completed && session.phase.isFocus;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isCurrent ? 14 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isFilled
                ? session.phase.primaryColor
                : (isCurrent
                    ? session.phase.primaryColor.withValues(alpha: 0.5)
                    : (isDark ? const Color(0xFF2A2D45) : const Color(0xFFDDD9F5))),
            borderRadius: BorderRadius.circular(4),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: session.phase.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
