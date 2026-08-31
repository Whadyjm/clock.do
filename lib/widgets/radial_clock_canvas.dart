import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/time_block.dart';
import '../utils/radial_math.dart';

/// Paleta dinámica adaptativa de colores para el reloj minimalista de puntos y agujas.
class OrbitClockColors {
  final bool isDark;
  const OrbitClockColors({required this.isDark});

  Color get clockFace   => isDark ? const Color(0xFF13162B) : const Color(0xFFFFFFFF);
  Color get clockBorder => isDark ? const Color(0xFF2A2D42) : const Color(0xFFF0EEFF);
  Color get majorDot    => isDark ? const Color(0xFFDDD9F5) : const Color(0xFF1E1B4B);
  Color get minorDot    => isDark ? const Color(0xFF6B7194) : const Color(0xFF9E98D4);
  Color get innerTick   => isDark ? const Color(0xFF2A2D42) : const Color(0xFFDDD9F5);
  Color get numberText  => isDark ? Colors.white            : const Color(0xFF1E1B4B);
  Color get hourHand    => isDark ? Colors.white            : const Color(0xFF1E1B4B);
  Color get minuteHand  => isDark ? const Color(0xFFDDD9F5) : const Color(0xFF1E1B4B);
  Color get secondHand  => isDark ? const Color(0xFFFF6584) : const Color(0xFFFF5252);
  Color get centerPivot => isDark ? const Color(0xFFFF6584) : const Color(0xFFFF5252);
  Color get centerRing  => isDark ? Colors.white            : const Color(0xFF1E1B4B);
}

/// CustomPainter que replica el reloj orbital adaptándose tanto a modo claro como oscuro.
class RadialClockPainter extends CustomPainter {
  final List<TimeBlock> blocks;
  final DateTime now;
  final bool is24h;
  final bool isDark;
  final double? gestureStartAngle;
  final double? gestureCurrentAngle;

  final OrbitClockColors colors;

  RadialClockPainter({
    required this.blocks,
    required this.now,
    required this.is24h,
    required this.isDark,
    this.gestureStartAngle,
    this.gestureCurrentAngle,
  }) : colors = OrbitClockColors(isDark: isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;

    // Radios de los anillos concéntricos
    final outerOrbitR = maxRadius - 10.0;
    final innerOrbitR = maxRadius - 38.0;
    final dialFaceR   = maxRadius - 46.0;

    // 1. Cara del reloj interior
    _drawDialFace(canvas, center, dialFaceR);

    // 2. Anillos orbitales de puntos concéntricos (Exterior e Interior)
    _drawDottedOrbit(canvas, center, outerOrbitR, isOuter: true);
    _drawDottedOrbit(canvas, center, innerOrbitR, isOuter: false);

    // 3. Marcas sutiles y números del reloj (1 al 12)
    _drawInnerTicks(canvas, center, dialFaceR - 2);
    _drawClockNumbers(canvas, center, dialFaceR - 18);

    // 4. Arcos de tareas tipo resaltador entre los anillos
    final arcMidR = (outerOrbitR + innerOrbitR) / 2;
    final arcThickness = (outerOrbitR - innerOrbitR) - 4.0;

    for (final block in blocks) {
      final offsetR = block.ringIndex * 14.0;
      _drawTaskRibbon(
        canvas,
        center,
        arcMidR - offsetR,
        arcThickness,
        block,
      );
    }

    // 5. Gesto activo / arco fantasma de arrastre con cursor de burbuja
    if (gestureStartAngle != null && gestureCurrentAngle != null) {
      _drawGestureRibbon(
        canvas,
        center,
        arcMidR,
        arcThickness,
      );
    }

    // 6. Agujas clásicas del reloj: Horaria, Minutero, Segundero y Pivote Central
    _drawClockHands(canvas, center, dialFaceR);
  }

  // ── Esfera Central ────────────────────────────────────────

  void _drawDialFace(Canvas canvas, Offset center, double r) {
    // Sombra suave
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.03)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Fondo
    canvas.drawCircle(
      center,
      r,
      Paint()..color = colors.clockFace,
    );

    // Borde
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = colors.clockBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  // ── Anillos de Puntos Orbitales ───────────────────────────

  void _drawDottedOrbit(Canvas canvas, Offset center, double radius, {required bool isOuter}) {
    const totalHours = 12;
    const dotsPerHour = 5; // 60 puntos en total (1 por minuto)
    const totalDots = totalHours * dotsPerHour;

    for (var i = 0; i < totalDots; i++) {
      final isHour = i % dotsPerHour == 0;
      final angle = (i / totalDots) * 2 * pi - pi / 2;
      final pos = RadialMath.polarToCartesian(center, radius, angle);

      if (isHour) {
        // Punto principal de hora
        canvas.drawCircle(
          pos,
          isOuter ? 2.4 : 2.0,
          Paint()..color = colors.majorDot,
        );
      } else {
        // Punto menor intermedio
        canvas.drawCircle(
          pos,
          isOuter ? 1.1 : 0.9,
          Paint()..color = colors.minorDot.withValues(alpha: isDark ? 0.5 : 0.7),
        );
      }
    }
  }

  // ── Marcas Interiores Sutiles ─────────────────────────────

  void _drawInnerTicks(Canvas canvas, Offset center, double radius) {
    const totalTicks = 60;
    for (var i = 0; i < totalTicks; i++) {
      if (i % 5 != 0) continue;
      final angle = (i / totalTicks) * 2 * pi - pi / 2;
      final p1 = RadialMath.polarToCartesian(center, radius - 4, angle);
      final p2 = RadialMath.polarToCartesian(center, radius, angle);

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = colors.innerTick
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ── Números del Reloj (1 al 12) ───────────────────────────

  void _drawClockNumbers(Canvas canvas, Offset center, double radius) {
    final total = is24h ? 24 : 12;
    final step = is24h ? 2 : 1;

    for (var h = 1; h <= total; h += step) {
      final hourVal = is24h && h == 24 ? 0 : h;
      final angle = RadialMath.hourToAngle(hourVal.toDouble(), is24h: is24h);
      final pos = RadialMath.polarToCartesian(center, radius, angle);

      final label = '$hourVal';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: colors.numberText,
            fontSize: is24h ? 11 : 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }
  }

  // ── Arcos de Tareas Estilo Resaltador Suave ───────────────

  void _drawTaskRibbon(
    Canvas canvas,
    Offset center,
    double radius,
    double thickness,
    TimeBlock block,
  ) {
    final startH = is24h ? block.startHour : block.startHour % 12;
    final endH   = is24h ? block.endHour   : block.endHour   % 12;

    final startAngle = RadialMath.hourToAngle(startH, is24h: is24h);
    final endAngle   = RadialMath.hourToAngle(endH,   is24h: is24h);
    var sweep = RadialMath.sweepAngle(startAngle, endAngle);

    final total = is24h ? 24.0 : 12.0;
    final minSweep = (5.0 / 60.0 / total) * 2 * pi;
    if (sweep < minSweep) sweep = minSweep;

    final isCompleted = block.status == TaskStatus.completed;
    final baseColor = block.category.color;

    final ribbonPaint = Paint()
      ..color = baseColor.withValues(alpha: isCompleted ? (isDark ? 0.2 : 0.25) : (isDark ? 0.8 : 0.65))
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      ribbonPaint,
    );

    if (isCompleted) {
      final mid = RadialMath.arcMidpoint(center, radius, startAngle, sweep);
      final p = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        Path()
          ..moveTo(mid.dx - 4, mid.dy)
          ..lineTo(mid.dx - 1, mid.dy + 3)
          ..lineTo(mid.dx + 4, mid.dy - 3),
        p,
      );
    }
  }

  // ── Gesto de Arrastre con Burbuja Táctil ───────────────────

  void _drawGestureRibbon(
    Canvas canvas,
    Offset center,
    double radius,
    double thickness,
  ) {
    final startAngle = gestureStartAngle!;
    final currentAngle = gestureCurrentAngle!;
    final sweep = RadialMath.sweepAngle(startAngle, currentAngle);

    final ribbonPaint = Paint()
      ..color = const Color(0xFFFFEAA7).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      ribbonPaint,
    );

    final handlePos = RadialMath.polarToCartesian(center, radius, currentAngle);

    canvas.drawCircle(
      handlePos,
      12.0,
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.25 : 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(
      handlePos,
      11.0,
      Paint()..color = (isDark ? const Color(0xFF1E2235) : Colors.white).withValues(alpha: 0.9),
    );

    canvas.drawCircle(
      handlePos,
      11.0,
      Paint()
        ..color = isDark ? const Color(0xFF6C5CE7) : const Color(0xFFDDD9F5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      handlePos,
      3.0,
      Paint()..color = const Color(0xFF6C5CE7),
    );
  }

  // ── Agujas del Reloj Clásicas ─────────────────────────────

  void _drawClockHands(Canvas canvas, Offset center, double faceRadius) {
    final hour = now.hour % 12;
    final minute = now.minute;
    final second = now.second + now.millisecond / 1000.0;

    final hourAngle = ((hour + minute / 60.0) / 12.0) * 2 * pi - pi / 2;
    final minuteAngle = ((minute + second / 60.0) / 60.0) * 2 * pi - pi / 2;
    final secondAngle = (second / 60.0) * 2 * pi - pi / 2;

    // 1. Aguja de las Horas
    final hourHandLength = faceRadius * 0.52;
    final hourTip = RadialMath.polarToCartesian(center, hourHandLength, hourAngle);
    canvas.drawLine(
      center,
      hourTip,
      Paint()
        ..color = colors.hourHand
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round,
    );

    // 2. Aguja de los Minutos
    final minuteHandLength = faceRadius * 0.78;
    final minuteTip = RadialMath.polarToCartesian(center, minuteHandLength, minuteAngle);
    canvas.drawLine(
      center,
      minuteTip,
      Paint()
        ..color = colors.minuteHand
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // 3. Aguja de los Segundos
    final secondHandLength = faceRadius * 0.86;
    final secondTailLength = faceRadius * 0.22;
    final secondTip  = RadialMath.polarToCartesian(center, secondHandLength, secondAngle);
    final secondTail = RadialMath.polarToCartesian(center, -secondTailLength, secondAngle);

    canvas.drawLine(
      secondTail,
      secondTip,
      Paint()
        ..color = colors.secondHand
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // 4. Pivote central
    canvas.drawCircle(
      center,
      4.5,
      Paint()..color = colors.centerPivot,
    );
    canvas.drawCircle(
      center,
      4.5,
      Paint()
        ..color = colors.centerRing
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(RadialClockPainter old) =>
      old.blocks != blocks ||
      old.now.second != now.second ||
      old.now.minute != now.minute ||
      old.is24h != is24h ||
      old.isDark != isDark ||
      old.gestureStartAngle != gestureStartAngle ||
      old.gestureCurrentAngle != gestureCurrentAngle;
}

// ──────────────────────────────────────────────────────────
// Widget con interacción táctil y animaciones elásticas
// ──────────────────────────────────────────────────────────

class RadialClockCanvas extends StatefulWidget {
  final List<TimeBlock> blocks;
  final double currentHour;
  final bool is24h;
  final void Function(double startHour, double endHour) onGestureComplete;
  final void Function(String id)? onBlockTap;

  const RadialClockCanvas({
    super.key,
    required this.blocks,
    required this.currentHour,
    required this.is24h,
    required this.onGestureComplete,
    this.onBlockTap,
  });

  @override
  State<RadialClockCanvas> createState() => _RadialClockCanvasState();
}

class _RadialClockCanvasState extends State<RadialClockCanvas>
    with SingleTickerProviderStateMixin {
  double? _gestureStartAngle;
  double? _gestureCurrentAngle;
  Offset? _center;
  double? _clockRadius;

  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bounceAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.97), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.02), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _updateGeometry(Size size) {
    _center = Offset(size.width / 2, size.height / 2);
    _clockRadius = min(size.width, size.height) / 2;
  }

  bool _isOnRing(Offset pos) {
    if (_center == null || _clockRadius == null) return false;
    final d = RadialMath.distanceFromCenter(pos, _center!);
    return d >= _clockRadius! * 0.45 && d <= _clockRadius! + 15;
  }

  TimeBlock? _blockAt(double angle) {
    if (_center == null) return null;
    final h = RadialMath.angleToHour(angle, is24h: widget.is24h);
    for (final b in widget.blocks) {
      final s = widget.is24h ? b.startHour : b.startHour % 12;
      final e = widget.is24h ? b.endHour   : b.endHour   % 12;
      if (h >= s && h < e) return b;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(builder: (ctx, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      _updateGeometry(size);

      return AnimatedBuilder(
        animation: _bounceAnim,
        builder: (_, child) => Transform.scale(
          scale: _bounceAnim.value,
          child: child,
        ),
        child: GestureDetector(
          onPanStart: (d) {
            if (!_isOnRing(d.localPosition)) return;
            HapticFeedback.selectionClick();
            final angle = RadialMath.offsetToAngle(d.localPosition, _center!);
            setState(() {
              _gestureStartAngle   = angle;
              _gestureCurrentAngle = angle;
            });
          },
          onPanUpdate: (d) {
            if (_gestureStartAngle == null) return;
            setState(() => _gestureCurrentAngle =
                RadialMath.offsetToAngle(d.localPosition, _center!));
          },
          onPanEnd: (_) {
            if (_gestureStartAngle == null || _gestureCurrentAngle == null) return;
            final sweep = RadialMath.sweepAngle(
                _gestureStartAngle!, _gestureCurrentAngle!);
            if (sweep > 0.08) {
              HapticFeedback.lightImpact();
              final startH = RadialMath.angleToHour(
                  _gestureStartAngle!, is24h: widget.is24h);
              var endH = RadialMath.angleToHour(
                  _gestureCurrentAngle!, is24h: widget.is24h);
              final total = widget.is24h ? 24.0 : 12.0;
              if (endH <= startH) endH += total;
              _bounceCtrl.forward(from: 0);
              widget.onGestureComplete(startH, endH);
            }
            setState(() {
              _gestureStartAngle   = null;
              _gestureCurrentAngle = null;
            });
          },
          onTapUp: (d) {
            if (_center == null) return;
            HapticFeedback.selectionClick();
            final angle = RadialMath.offsetToAngle(d.localPosition, _center!);
            final block = _blockAt(angle);
            if (block != null) widget.onBlockTap?.call(block.id);
          },
          child: CustomPaint(
            size: size,
            painter: RadialClockPainter(
              blocks: widget.blocks,
              now: DateTime.now(),
              is24h: widget.is24h,
              isDark: isDark,
              gestureStartAngle: _gestureStartAngle,
              gestureCurrentAngle: _gestureCurrentAngle,
            ),
          ),
        ),
      );
    });
  }
}
