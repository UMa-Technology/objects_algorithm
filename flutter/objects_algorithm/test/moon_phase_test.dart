import 'package:flutter_test/flutter_test.dart';
import 'package:objects_algorithm/julian.dart';
import 'package:objects_algorithm/moon.dart';

/// Moon phase regression tests.
///
/// These cases were written for a bug that actually shipped: in `Moon.phaseAngle()`
/// the Sun-Earth distance comes from `Earth.radiusVector()` in AU, while the
/// Moon-Earth distance is in km. Feeding the two mixed-unit distances straight into
/// AA+'s PhaseAngle let the km-scale term swamp the atan2 denominator, so the phase
/// angle was always ~0 and illumination always ~100% -- **the Moon always showed as
/// full**. No error, no crash, green build; only visible by looking at the phase image.
///
/// Merely printing illumination values cannot catch this (the original moon_test.dart
/// did exactly that). We must assert that the new moon is near 0, so any unit mix-up
/// turns this red immediately.
void main() {
  final julian = Julian();

  double illuminationAt(DateTime utc) {
    final jdTT = Julian.uTC2TT(julian.timeToJD(utc));
    return Moon(jdTT).illuminated();
  }

  bool waxingAt(DateTime utc) {
    final jdTT = Julian.uTC2TT(julian.timeToJD(utc));
    return Moon(jdTT).isWaxing();
  }

  group('Moon phase illumination', () {
    test('new moon illumination is near 0', () {
      // 2024-01-11 11:57 UTC new moon
      final v = illuminationAt(DateTime.utc(2024, 1, 11, 11, 57));
      expect(v, lessThan(0.02), reason: 'new moon illumination should be near 0, got $v');
    });

    test('full moon illumination is near 1', () {
      // 2024-01-25 17:54 UTC full moon
      final v = illuminationAt(DateTime.utc(2024, 1, 25, 17, 54));
      expect(v, greaterThan(0.98), reason: 'full moon illumination should be near 1, got $v');
    });

    test('first quarter illumination is near 0.5', () {
      // 2024-01-18 03:53 UTC first quarter
      final v = illuminationAt(DateTime.utc(2024, 1, 18, 3, 53));
      expect(v, closeTo(0.5, 0.05), reason: 'first quarter illumination should be near 0.5, got $v');
    });

    test('illumination actually varies over a synodic month', () {
      // Under the unit bug these values all cluster near 1.0 and the range approaches 0.
      final samples = List.generate(30, (i) {
        return illuminationAt(DateTime.utc(2024, 1, 11, 12).add(Duration(days: i)));
      });
      final spread = samples.reduce((a, b) => a > b ? a : b) -
          samples.reduce((a, b) => a < b ? a : b);
      expect(spread, greaterThan(0.9), reason: 'illumination range over a synodic month should be near 1, got $spread');
    });
  });

  group('Waxing / waning', () {
    test('waxing between new moon and full moon', () {
      expect(waxingAt(DateTime.utc(2024, 1, 18, 3, 53)), isTrue);
    });

    test('waning between full moon and the next new moon', () {
      expect(waxingAt(DateTime.utc(2024, 2, 2, 23, 18)), isFalse);
    });

    test('waxing flips to waning around full moon', () {
      final full = DateTime.utc(2024, 1, 25, 17, 54);
      expect(waxingAt(full.subtract(const Duration(days: 2))), isTrue);
      expect(waxingAt(full.add(const Duration(days: 2))), isFalse);
    });
  });
}
