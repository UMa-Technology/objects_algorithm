import 'package:flutter_test/flutter_test.dart';
import 'package:objects_algorithm/comet.dart';
import 'package:objects_algorithm/coord.dart';
import 'package:objects_algorithm/julian.dart';

Comet cometFromJsonLike({
  required double jdUtc,
  required double q,
  required double e,
  required double i,
  required double w,
  required double omega,
  required int periY,
  required int periM,
  required double periD,
  required int epochY,
  required int epochM,
  required int epochD,
}) {
  final julian = Julian();
  final periDay = periD.floor();
  final T = julian.gregorianToJD(periY, periM, periDay) + (periD - periDay);
  final jDEquinox =
      julian.gregorianToJD(epochY, epochM, epochD).toDouble();
  return Comet(
    Julian.uTC2TT(jdUtc),
    q: q,
    e: e,
    i: i,
    w: w,
    omega: omega,
    T: T,
    jDEquinox: jDEquinox,
  );
}

void main() {
  test('C/2013 F3 is visible in Suzhou on 2026-05-27', () {
    final obs = Geography(31.2989, 120.5853);
    final date = DateTime.utc(2026, 5, 27);
    final jdUtc = Julian().timeToJD(DateTime.utc(2026, 5, 27, 4, 0));
    final comet = cometFromJsonLike(
      jdUtc: jdUtc,
      q: 2.257243,
      e: 0.996464,
      i: 85.1208,
      w: 18.788,
      omega: 266.157,
      periY: 2013,
      periM: 5,
      periD: 21.431,
      epochY: 2026,
      epochM: 5,
      epochD: 26,
    );

    expect(comet.isVisibleOnDate(date, obs), isTrue);
    expect(comet.times(date, obs).transitTime, isNotNull);
  });

  test('northern comet is invisible all day from high southern latitude', () {
    final obs = Geography(-75.0, 0.0);
    final date = DateTime.utc(2026, 5, 27);
    final jdUtc = Julian().timeToJD(DateTime.utc(2026, 5, 27, 4, 0));
    final comet = cometFromJsonLike(
      jdUtc: jdUtc,
      q: 2.257243,
      e: 0.996464,
      i: 85.1208,
      w: 18.788,
      omega: 266.157,
      periY: 2013,
      periM: 5,
      periD: 21.431,
      epochY: 2026,
      epochM: 5,
      epochD: 26,
    );

    expect(comet.isVisibleOnDate(date, obs), isFalse);
  });
}
