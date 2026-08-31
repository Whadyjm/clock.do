import 'dart:math';
import 'package:flutter/material.dart';

/// Utilidades matemáticas para el reloj radial.
/// Convierte entre horas del día, ángulos en radianes y coordenadas cartesianas.
class RadialMath {
  /// Convierte una hora del día a un ángulo en radianes.
  /// El ángulo 0 (top/norte) corresponde a las 12:00 (o 00:00 en modo 24h).
  /// Los ángulos crecen en sentido horario.
  ///
  /// [hour] debe estar en el rango [0, 12) para 12h o [0, 24) para 24h.
  static double hourToAngle(double hour, {bool is24h = false}) {
    final totalHours = is24h ? 24.0 : 12.0;
    // -π/2 para que 12 quede arriba (norte), sentido horario
    return (hour / totalHours) * 2 * pi - pi / 2;
  }

  /// Convierte un ángulo en radianes a una hora del día.
  /// Siempre retorna un valor positivo en el rango [0, totalHours).
  static double angleToHour(double angle, {bool is24h = false}) {
    final totalHours = is24h ? 24.0 : 12.0;
    // Normalizar ángulo a [0, 2π)
    var normalized = (angle + pi / 2) % (2 * pi);
    if (normalized < 0) normalized += 2 * pi;
    return (normalized / (2 * pi)) * totalHours;
  }

  /// Convierte un punto de toque (Offset) a un ángulo en radianes
  /// relativo al centro del canvas.
  static double offsetToAngle(Offset touch, Offset center) {
    final dx = touch.dx - center.dx;
    final dy = touch.dy - center.dy;
    return atan2(dy, dx);
  }

  /// Convierte coordenadas polares a coordenadas cartesianas (Offset).
  /// [center] es el origen, [radius] es el radio, [angle] en radianes.
  static Offset polarToCartesian(Offset center, double radius, double angle) {
    return Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );
  }

  /// Calcula la distancia entre un punto de toque y el centro del canvas.
  static double distanceFromCenter(Offset touch, Offset center) {
    final dx = touch.dx - center.dx;
    final dy = touch.dy - center.dy;
    return sqrt(dx * dx + dy * dy);
  }

  /// Verifica si un toque está dentro del anillo del reloj.
  static bool isInsideRing(
    Offset touch,
    Offset center,
    double innerRadius,
    double outerRadius,
  ) {
    final dist = distanceFromCenter(touch, center);
    return dist >= innerRadius && dist <= outerRadius;
  }

  /// Calcula el ángulo de barrido entre dos ángulos, siempre positivo (sentido horario).
  static double sweepAngle(double startAngle, double endAngle) {
    var sweep = endAngle - startAngle;
    if (sweep < 0) sweep += 2 * pi;
    return sweep;
  }

  /// Convierte horas y minutos a una fracción decimal de la hora.
  /// Ejemplo: 2h 30min → 2.5
  static double timeToDecimalHours(int hour, int minute) {
    return hour + minute / 60.0;
  }

  /// Calcula el punto medio de un arco (para labels de tareas).
  static Offset arcMidpoint(
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
  ) {
    final midAngle = startAngle + sweepAngle / 2;
    return polarToCartesian(center, radius, midAngle);
  }

  /// Convierte una hora decimal a formato "HH:mm".
  static String decimalHoursToString(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Normaliza un ángulo al rango [-π, π].
  static double normalizeAngle(double angle) {
    while (angle > pi) { angle -= 2 * pi; }
    while (angle < -pi) { angle += 2 * pi; }
    return angle;
  }
}
