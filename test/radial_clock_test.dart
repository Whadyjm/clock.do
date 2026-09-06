import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:clockdo/utils/radial_math.dart';

void main() {
  group('RadialMath and Clock format hand positions', () {
    test('hourToAngle calculates different angles for 12h vs 24h at the same time', () {
      // 15:00 (3 PM)
      final hour12 = 15 % 12; // 3.0
      final hour24 = 15.0;

      final angle12 = RadialMath.hourToAngle(hour12.toDouble(), is24h: false);
      final angle24 = RadialMath.hourToAngle(hour24, is24h: true);

      // In 12h: 3 o'clock is to the right (angle = 0 radians)
      expect((angle12 - 0.0).abs() < 1e-6, isTrue);

      // In 24h: 15 o'clock is at (15 / 24) * 2 * pi - pi / 2 = 1.25 * pi - 0.5 * pi = 0.75 * pi
      // which is in the lower-left quadrant (different from 12h)
      expect((angle24 - (0.75 * pi)).abs() < 1e-6, isTrue);

      expect(angle12, isNot(equals(angle24)));
    });

    test('24h dial places 0 at top and 12 at bottom', () {
      final angle0 = RadialMath.hourToAngle(0.0, is24h: true);
      final angle12 = RadialMath.hourToAngle(12.0, is24h: true);

      // Top is -pi / 2
      expect((angle0 - (-pi / 2)).abs() < 1e-6, isTrue);
      // Bottom is pi / 2
      expect((angle12 - (pi / 2)).abs() < 1e-6, isTrue);
    });
  });
}
