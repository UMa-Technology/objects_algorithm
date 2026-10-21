import 'package:flutter_test/flutter_test.dart';
import 'package:objects_algorithm/coord.dart';
import 'package:objects_algorithm/julian.dart';
import 'package:objects_algorithm/planet.dart';
import 'package:objects_algorithm/rise.dart';

void main() {
  test('planet rise and set times use stellar horizon threshold', () {
    final date = DateTime.utc(2026, 2, 3);
    final obs = Geography(31.2552, 120.7350);
    final julian = Julian();
    final jdUtc = julian.timeToJD(DateTime.utc(2026, 2, 3, 4, 30));
    final jupiter = Jupiter(Julian.uTC2TT(jdUtc));
    final calculator = RiseTransitSet();

    final actual = jupiter.times(date, obs);
    final expected = calculator.astroTimes(
      date,
      AstroObject.JUPITER.index,
      obs,
      calculator.Stdh0Stellar,
    );

    expect(actual.riseTime, isNotNull);
    expect(actual.setTime, isNotNull);
    expect(expected.riseTime, isNotNull);
    expect(expected.setTime, isNotNull);
    expect(
      actual.riseTime!.difference(expected.riseTime!).abs(),
      lessThanOrEqualTo(const Duration(seconds: 1)),
    );
    expect(
      actual.setTime!.difference(expected.setTime!).abs(),
      lessThanOrEqualTo(const Duration(seconds: 1)),
    );
  });
}
