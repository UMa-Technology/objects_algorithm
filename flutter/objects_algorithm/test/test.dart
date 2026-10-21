import 'package:objects_algorithm/coord.dart';
import 'package:objects_algorithm/rise.dart';
import 'package:objects_algorithm/solar.dart';
import 'package:flutter_test/flutter_test.dart';

const _solarTolerance = Duration(minutes: 15);
const _astroNightTolerance = Duration(minutes: 20);

// In 2026-08 the night start of the Paris May cases was corrected from nauticalDusk
// to astronomicalDusk: in high-latitude summer, astronomical dusk crosses local
// midnight into the next calendar day, and the old implementation's "dusk must be
// later than the same day's dawn" constraint could not pick it up, so it silently
// fell back to nautical dusk -- the night started ~70 minutes early and was
// asymmetric with the end, which used astronomical dawn. Anchors are now paired on
// the absolute time axis, and both ends are astronomical twilight.
// const _enableTestLogs = bool.fromEnvironment('ENABLE_TEST_LOGS');
const _enableTestLogs = true;

void main() {
  test('AstroNightStatus exposes stable int codes', () {
    expect(AstroNightStatus.complete, 0);
    expect(AstroNightStatus.polarNight, 1);
    expect(AstroNightStatus.polarDay, 2);
    expect(AstroNightStatus.noWindow, 3);
    expect(AstroNightStatus.invalidInput, 4);
  });

  // group('Solar.times AstroTime', () {
  //   final solar = Solar(2451545.0);

  //   for (final testCase in _solarTimeCases) {
  //     test(testCase.name, () {
  //       _runSolarTimeCase(solar, testCase);
  //     });
  //   }
  // });

  group('astroNightForSiteDate', () {
    for (final testCase in _astroNightCases) {
      test(testCase.name, () {
        _runAstroNightCase(testCase);
      });
    }
  });
}

void _expectCloseUtc(
  String label,
  DateTime? actual,
  DateTime? expected,
  Duration tolerance,
) {
  if (expected == null) {
    expect(actual, isNull, reason: '$label should not exist');
    return;
  }

  expect(actual, isNotNull, reason: '$label should exist');
  final delta = actual!.toUtc().difference(expected).abs();
  expect(
    delta,
    lessThanOrEqualTo(tolerance),
    reason: '$label actual=${actual.toUtc()} expected=$expected delta=$delta',
  );
}

void _runSolarTimeCase(Solar solar, _SolarTimeCase testCase) {
  final output =
      solar.times(testCase.date, Geography(testCase.lat, testCase.lon));
  _logSolarTimes(testCase, output);

  _expectCloseUtc(
      'civilDawn', output.civilDawn, testCase.civilDawn, _solarTolerance);
  _expectCloseUtc(
      'riseTime', output.riseTime, testCase.riseTime, _solarTolerance);
  _expectCloseUtc(
      'transitTime', output.transitTime, testCase.transitTime, _solarTolerance);
  _expectCloseUtc('setTime', output.setTime, testCase.setTime, _solarTolerance);
  _expectCloseUtc(
      'civilDusk', output.civilDusk, testCase.civilDusk, _solarTolerance);
  _expectCloseUtc('nauticalDawn', output.nauticalDawn, testCase.nauticalDawn,
      _solarTolerance);
  _expectCloseUtc('nauticalDusk', output.nauticalDusk, testCase.nauticalDusk,
      _solarTolerance);
  _expectCloseUtc('astronomicalDawn', output.astronomicalDawn,
      testCase.astronomicalDawn, _solarTolerance);
  _expectCloseUtc('astronomicalDusk', output.astronomicalDusk,
      testCase.astronomicalDusk, _solarTolerance);
}

void _runAstroNightCase(_AstroNightCase testCase) {
  final output = astroNightForSiteDate(
    timezoneName: testCase.input.timezoneName,
    nowUtc: testCase.input.nowUtc,
    obs: testCase.input.obs,
  );

  _logAstroNight(testCase.name, testCase.input, output, testCase.expected);

  expect(output.status, isA<int>());
  expect(output.status, testCase.expected.status);
  if (testCase.expected.reason != null) {
    expect(output.reason, testCase.expected.reason);
  }
  if (testCase.expected.expectDawnAnchor) {
    expect(
        output.todayDawnAnchorSource, testCase.expected.todayDawnAnchorSource);
    _expectCloseUtc(
      'night.todayDawnAnchorUtc',
      output.todayDawnAnchorUtc,
      testCase.expected.todayDawnAnchorUtc,
      _solarTolerance,
    );
  }
  expect(output.startSource, testCase.expected.startSource);
  expect(output.endSource, testCase.expected.endSource);
  _expectCloseUtc(
    'night.startUtc',
    output.startUtc,
    testCase.expected.startUtc,
    _astroNightTolerance,
  );
  _expectCloseUtc(
    'night.endUtc',
    output.endUtc,
    testCase.expected.endUtc,
    _astroNightTolerance,
  );
  _expectAstroNightEvents(output, testCase.expected);
}

void _expectAstroNightEvents(
  AstroNight output,
  _AstroNightExpected expected,
) {
  if (!expected.expectSolarEvents) {
    return;
  }

  _expectCloseUtc(
      'night.riseTime', output.riseTime, expected.riseTime, _solarTolerance);
  _expectCloseUtc('night.transitTime', output.transitTime, expected.transitTime,
      _solarTolerance);
  _expectCloseUtc(
      'night.setTime', output.setTime, expected.setTime, _solarTolerance);
  _expectCloseUtc(
      'night.civilDawn', output.civilDawn, expected.civilDawn, _solarTolerance);
  _expectCloseUtc(
      'night.civilDusk', output.civilDusk, expected.civilDusk, _solarTolerance);
  _expectCloseUtc('night.nauticalDawn', output.nauticalDawn,
      expected.nauticalDawn, _solarTolerance);
  _expectCloseUtc('night.nauticalDusk', output.nauticalDusk,
      expected.nauticalDusk, _solarTolerance);
  _expectCloseUtc('night.astronomicalDawn', output.astronomicalDawn,
      expected.astronomicalDawn, _solarTolerance);
  _expectCloseUtc('night.astronomicalDusk', output.astronomicalDusk,
      expected.astronomicalDusk, _solarTolerance);
}

void _logSolarTimes(_SolarTimeCase testCase, AstroTime times) {
  if (!_enableTestLogs) {
    return;
  }

  // ignore: avoid_print
  print('''
[Solar.times]
case=${testCase.name}
input={
  dateUtc: ${testCase.date.toUtc()},
  lat: ${testCase.lat},
  lon: ${testCase.lon}
}
output={
  astronomicalDawn: ${times.astronomicalDawn?.toUtc()},
  nauticalDawn: ${times.nauticalDawn?.toUtc()},
  civilDawn: ${times.civilDawn?.toUtc()},
  riseTime: ${times.riseTime?.toUtc()},
  transitTime: ${times.transitTime?.toUtc()},
  setTime: ${times.setTime?.toUtc()},
  civilDusk: ${times.civilDusk?.toUtc()},
  nauticalDusk: ${times.nauticalDusk?.toUtc()},
  astronomicalDusk: ${times.astronomicalDusk?.toUtc()},
  transitAboveRiseSetThreshold: ${times.transitAboveRiseSetThreshold}
}
expected={
  astronomicalDawn: ${testCase.astronomicalDawn},
  nauticalDawn: ${testCase.nauticalDawn},
  civilDawn: ${testCase.civilDawn},
  riseTime: ${testCase.riseTime},
  transitTime: ${testCase.transitTime},
  setTime: ${testCase.setTime},
  civilDusk: ${testCase.civilDusk},
  nauticalDusk: ${testCase.nauticalDusk},
  astronomicalDusk: ${testCase.astronomicalDusk}
}
delta={
  astronomicalDawn: ${_deltaText(times.astronomicalDawn, testCase.astronomicalDawn)},
  nauticalDawn: ${_deltaText(times.nauticalDawn, testCase.nauticalDawn)},
  civilDawn: ${_deltaText(times.civilDawn, testCase.civilDawn)},
  riseTime: ${_deltaText(times.riseTime, testCase.riseTime)},
  transitTime: ${_deltaText(times.transitTime, testCase.transitTime)},
  setTime: ${_deltaText(times.setTime, testCase.setTime)},
  civilDusk: ${_deltaText(times.civilDusk, testCase.civilDusk)},
  nauticalDusk: ${_deltaText(times.nauticalDusk, testCase.nauticalDusk)},
  astronomicalDusk: ${_deltaText(times.astronomicalDusk, testCase.astronomicalDusk)}
}
''');
}

String _deltaText(DateTime? actual, DateTime? expected) {
  if (actual == null && expected == null) {
    return 'both null';
  }
  if (actual == null || expected == null) {
    return 'actual=${actual?.toUtc()} expected=$expected';
  }
  return actual.toUtc().difference(expected).toString();
}

void _logAstroNight(
  String label,
  _AstroNightInput input,
  AstroNight output,
  _AstroNightExpected expected,
) {
  if (!_enableTestLogs) {
    return;
  }

  // ignore: avoid_print
  print('''
[astroNightForSiteDate]
case=$label
input={
  timezoneName: ${input.timezoneName},
  nowUtc: ${input.nowUtc},
  lat: ${input.obs.lat},
  lon: ${input.obs.lon}
}
output={
  status: ${output.status},
  reason: ${output.reason},
  startUtc: ${output.startUtc?.toUtc()},
  endUtc: ${output.endUtc?.toUtc()},
  startSource: ${output.startSource},
  endSource: ${output.endSource},
  todayDawnAnchorUtc: ${output.todayDawnAnchorUtc?.toUtc()},
  todayDawnAnchorSource: ${output.todayDawnAnchorSource},
  astronomicalDawn: ${output.astronomicalDawn?.toUtc()},
  nauticalDawn: ${output.nauticalDawn?.toUtc()},
  civilDawn: ${output.civilDawn?.toUtc()},
  riseTime: ${output.riseTime?.toUtc()},
  transitTime: ${output.transitTime?.toUtc()},
  setTime: ${output.setTime?.toUtc()},
  civilDusk: ${output.civilDusk?.toUtc()},
  nauticalDusk: ${output.nauticalDusk?.toUtc()},
  astronomicalDusk: ${output.astronomicalDusk?.toUtc()}
}
''');
}

final _astroNightCases = <_AstroNightCase>[
  _AstroNightCase(
    name:
        'before dawn Paris returns yesterday dusk to today dawn',
    input: _AstroNightInput(
      timezoneName: 'Europe/Paris',
      nowUtc: DateTime.utc(2026, 5, 21, 0, 30),
      obs: Geography(48.8566, 2.3522),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.complete,
      reason: 'complete',
      startUtc: DateTime.utc(2026, 5, 20, 22, 18),
      endUtc: DateTime.utc(2026, 5, 21, 1, 18),
      startSource: 'astronomicalDusk',
      endSource: 'astronomicalDawn',
      expectDawnAnchor: true,
      todayDawnAnchorUtc: DateTime.utc(2026, 5, 21, 1, 18, 56),
      todayDawnAnchorSource: 'astronomicalDawn',
      expectSolarEvents: true,
      riseTime: DateTime.utc(2026, 5, 21, 4, 2, 0),
      transitTime: DateTime.utc(2026, 5, 20, 11, 47, 10),
      setTime: DateTime.utc(2026, 5, 20, 19, 33, 9),
      civilDawn: DateTime.utc(2026, 5, 21, 3, 22, 10),
      civilDusk: DateTime.utc(2026, 5, 20, 20, 13, 11),
      nauticalDawn: DateTime.utc(2026, 5, 21, 2, 30, 7),
      nauticalDusk: DateTime.utc(2026, 5, 20, 21, 5, 39),
      astronomicalDawn: DateTime.utc(2026, 5, 21, 1, 18, 56),
      astronomicalDusk: DateTime.utc(2026, 5, 20, 22, 18, 11),
    ),
  ),
  _AstroNightCase(
    name:
        'after dawn Paris returns today dusk to tomorrow dawn',
    input: _AstroNightInput(
      timezoneName: 'Europe/Paris',
      nowUtc: DateTime.utc(2026, 5, 21, 12),
      obs: Geography(48.8566, 2.3522),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.complete,
      reason: 'complete',
      startUtc: DateTime.utc(2026, 5, 21, 22, 18),
      endUtc: DateTime.utc(2026, 5, 22, 1, 17),
      startSource: 'astronomicalDusk',
      endSource: 'astronomicalDawn',
      expectDawnAnchor: true,
      todayDawnAnchorUtc: DateTime.utc(2026, 5, 21, 1, 18, 56),
      todayDawnAnchorSource: 'astronomicalDawn',
      expectSolarEvents: true,
      riseTime: DateTime.utc(2026, 5, 22, 4, 6, 28),
      transitTime: DateTime.utc(2026, 5, 21, 11, 47, 10),
      setTime: DateTime.utc(2026, 5, 21, 19, 33, 9),
      civilDawn: DateTime.utc(2026, 5, 22, 3, 21, 19),
      civilDusk: DateTime.utc(2026, 5, 21, 20, 13, 11),
      nauticalDawn: DateTime.utc(2026, 5, 22, 2, 28, 39),
      nauticalDusk: DateTime.utc(2026, 5, 21, 21, 5, 39),
      astronomicalDawn: DateTime.utc(2026, 5, 22, 1, 16, 5),
      astronomicalDusk: DateTime.utc(2026, 5, 21, 22, 18, 11),
    ),
  ),
  _AstroNightCase(
    name: 'rejects unknown timezone without throwing',
    input: _AstroNightInput(
      timezoneName: 'Mars/Olympus',
      nowUtc: DateTime.utc(2026, 5, 21, 12),
      obs: Geography(48.8566, 2.3522),
    ),
    expected: _AstroNightExpected.invalidInput(),
  ),
  _AstroNightCase(
    name: 'rejects non-UTC now without throwing',
    input: _AstroNightInput(
      timezoneName: 'Europe/Paris',
      nowUtc: DateTime(2026, 5, 21, 12),
      obs: Geography(48.8566, 2.3522),
    ),
    expected: _AstroNightExpected.invalidInput(),
  ),
  _AstroNightCase(
    name: 'uses timezone-derived site day boundaries',
    input: _AstroNightInput(
      timezoneName: 'Europe/Paris',
      nowUtc: DateTime.utc(2026, 5, 21, 12),
      obs: Geography(48.8566, 2.3522),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.complete,
      reason: 'complete',
      startUtc: DateTime.utc(2026, 5, 21, 22, 18),
      endUtc: DateTime.utc(2026, 5, 22, 1, 17),
      startSource: 'astronomicalDusk',
      endSource: 'astronomicalDawn',
    ),
  ),
  _AstroNightCase(
    name: 'uses 23-hour site day on Europe Paris DST start',
    input: _AstroNightInput(
      timezoneName: 'Europe/Paris',
      nowUtc: DateTime.utc(2026, 3, 29, 12),
      obs: Geography(-90, 0),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.polarNight,
      reason: 'polar night all day',
      startUtc: DateTime.utc(2026, 3, 28, 23),
      endUtc: DateTime.utc(2026, 3, 29, 22),
      startSource: 'siteDayStartUtc',
      endSource: 'siteDayEndUtc',
    ),
  ),
  _AstroNightCase(
    name: 'uses 25-hour site day on Europe Paris DST end',
    input: _AstroNightInput(
      timezoneName: 'Europe/Paris',
      nowUtc: DateTime.utc(2026, 10, 25, 12),
      obs: Geography(90, 0),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.polarNight,
      reason: 'polar night all day',
      startUtc: DateTime.utc(2026, 10, 24, 22),
      endUtc: DateTime.utc(2026, 10, 25, 23),
      startSource: 'siteDayStartUtc',
      endSource: 'siteDayEndUtc',
    ),
  ),
  _AstroNightCase(
    name:
        'uses after-dawn branch when now equals today dawn anchor',
    input: _AstroNightInput(
      timezoneName: 'Europe/Paris',
      nowUtc: DateTime.utc(2026, 5, 21, 1, 19, 10),
      obs: Geography(48.8566, 2.3522),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.complete,
      reason: 'complete',
      startUtc: DateTime.utc(2026, 5, 21, 22, 18),
      endUtc: DateTime.utc(2026, 5, 22, 1, 17),
      startSource: 'astronomicalDusk',
      endSource: 'astronomicalDawn',
    ),
  ),
  _AstroNightCase(
    name:
        'falls back to civil dawn and civil dusk when deeper twilight is missing',
    input: _AstroNightInput(
      timezoneName: 'Europe/Stockholm',
      nowUtc: DateTime.utc(2026, 5, 21, 12),
      obs: Geography(59.3293, 18.0686),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.complete,
      reason: 'complete',
      startUtc: DateTime.utc(2026, 5, 21, 20, 34),
      endUtc: DateTime.utc(2026, 5, 22, 0, 54),
      startSource: 'civilDusk',
      endSource: 'civilDawn',
    ),
  ),
  _AstroNightCase(
    name:
        'falls back to setTime and riseTime when all twilight anchors are missing',
    input: _AstroNightInput(
      timezoneName: 'Atlantic/Reykjavik',
      nowUtc: DateTime.utc(2026, 5, 21, 12),
      obs: Geography(64.1466, -21.9426),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.complete,
      reason: 'complete',
      startUtc: DateTime.utc(2026, 5, 21, 22, 44),
      endUtc: DateTime.utc(2026, 5, 22, 4, 4),
      startSource: 'setTime',
      endSource: 'riseTime',
    ),
  ),
  _AstroNightCase(
    name:
        'uses political timezone boundaries instead of longitude-derived days',
    input: _AstroNightInput(
      timezoneName: 'Asia/Shanghai',
      nowUtc: DateTime.utc(2026, 5, 21, 10),
      obs: Geography(39.4704, 75.9898),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.complete,
      reason: 'complete',
      startUtc: DateTime.utc(2026, 5, 21, 16, 0),
      endUtc: DateTime.utc(2026, 5, 21, 21, 44),
      startSource: 'astronomicalDusk',
      endSource: 'astronomicalDawn',
    ),
  ),
  _AstroNightCase(
    name: 'reports polar day without fabricating a window',
    input: _AstroNightInput(
      timezoneName: 'Europe/Oslo',
      nowUtc: DateTime.utc(2026, 6, 21, 12),
      obs: Geography(78.2232, 15.6469),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.polarDay,
      reason: 'sun above rise/set threshold all day',
      startUtc: null,
      endUtc: null,
      startSource: null,
      endSource: null,
      expectDawnAnchor: true,
      todayDawnAnchorUtc: null,
      todayDawnAnchorSource: null,
    ),
  ),
  _AstroNightCase(
    name: 'reports polar night as a complete all-day window',
    input: _AstroNightInput(
      timezoneName: 'Europe/Oslo',
      nowUtc: DateTime.utc(2026, 12, 21, 12),
      obs: Geography(78.2232, 15.6469),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.polarNight,
      reason: 'polar night all day',
      startUtc: DateTime.utc(2026, 12, 20, 23),
      endUtc: DateTime.utc(2026, 12, 21, 23),
      startSource: 'siteDayStartUtc',
      endSource: 'siteDayEndUtc',
      expectDawnAnchor: true,
      todayDawnAnchorUtc: null,
      todayDawnAnchorSource: null,
    ),
  ),
  _AstroNightCase(
    name:
        'App passes IANA timezone and consumes complete window',
    input: _AstroNightInput(
      timezoneName: 'Asia/Singapore',
      nowUtc: DateTime.utc(2026, 5, 21, 12),
      obs: Geography(1.3521, 103.8198),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.complete,
      reason: 'complete',
      startUtc: DateTime.utc(2026, 5, 21, 12, 20),
      endUtc: DateTime.utc(2026, 5, 21, 21, 42),
      startSource: 'astronomicalDusk',
      endSource: 'astronomicalDawn',
      expectSolarEvents: true,
      riseTime: DateTime.utc(2026, 5, 21, 22, 59, 17),
      transitTime: DateTime.utc(2026, 5, 21, 5, 1, 18),
      setTime: DateTime.utc(2026, 5, 21, 11, 6, 41),
      civilDawn: DateTime.utc(2026, 5, 21, 22, 33, 43),
      civilDusk: DateTime.utc(2026, 5, 21, 11, 29, 10),
      nauticalDawn: DateTime.utc(2026, 5, 21, 22, 8, 2),
      nauticalDusk: DateTime.utc(2026, 5, 21, 11, 54, 43),
      astronomicalDawn: DateTime.utc(2026, 5, 21, 21, 42, 14),
      astronomicalDusk: DateTime.utc(2026, 5, 21, 12, 20, 28),
    ),
  ),
  _AstroNightCase(
    name: 'covers west hemisphere DST timezone in New York',
    input: _AstroNightInput(
      timezoneName: 'America/New_York',
      nowUtc: DateTime.utc(2026, 5, 21, 16),
      obs: Geography(40.7128, -74.0060),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.complete,
      reason: 'complete',
      startUtc: DateTime.utc(2026, 5, 22, 2, 8),
      endUtc: DateTime.utc(2026, 5, 22, 7, 36),
      startSource: 'astronomicalDusk',
      endSource: 'astronomicalDawn',
    ),
  ),
  _AstroNightCase(
    name: 'covers west low latitude in Quito',
    input: _AstroNightInput(
      timezoneName: 'America/Guayaquil',
      nowUtc: DateTime.utc(2026, 5, 21, 17),
      obs: Geography(-0.1807, -78.4678),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.complete,
      reason: 'complete',
      startUtc: DateTime.utc(2026, 5, 22, 0, 27),
      endUtc: DateTime.utc(2026, 5, 22, 9, 53),
      startSource: 'astronomicalDusk',
      endSource: 'astronomicalDawn',
    ),
  ),
  _AstroNightCase(
    name: 'covers southern hemisphere winter in Sydney',
    input: _AstroNightInput(
      timezoneName: 'Australia/Sydney',
      nowUtc: DateTime.utc(2026, 6, 21, 2),
      obs: Geography(-33.8688, 151.2093),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.complete,
      reason: 'complete',
      startUtc: DateTime.utc(2026, 6, 21, 8, 23),
      endUtc: DateTime.utc(2026, 6, 21, 19, 30),
      startSource: 'astronomicalDusk',
      endSource: 'astronomicalDawn',
    ),
  ),
  _AstroNightCase(
    name: 'covers positive date-line timezone in Kiritimati',
    input: _AstroNightInput(
      timezoneName: 'Pacific/Kiritimati',
      nowUtc: DateTime.utc(2026, 5, 21),
      obs: Geography(1.8721, -157.4278),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.complete,
      reason: 'complete',
      startUtc: DateTime.utc(2026, 5, 21, 5, 46),
      endUtc: DateTime.utc(2026, 5, 21, 15, 6),
      startSource: 'astronomicalDusk',
      endSource: 'astronomicalDawn',
    ),
  ),
  _AstroNightCase(
    name: 'covers negative date-line timezone in Honolulu',
    input: _AstroNightInput(
      timezoneName: 'Pacific/Honolulu',
      nowUtc: DateTime.utc(2026, 5, 21, 22),
      obs: Geography(21.3069, -157.8583),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.complete,
      reason: 'complete',
      startUtc: DateTime.utc(2026, 5, 22, 6, 27),
      endUtc: DateTime.utc(2026, 5, 22, 14, 28),
      startSource: 'astronomicalDusk',
      endSource: 'astronomicalDawn',
    ),
  ),
  _AstroNightCase(
    name: 'covers half-hour timezone in Kolkata',
    input: _AstroNightInput(
      timezoneName: 'Asia/Kolkata',
      nowUtc: DateTime.utc(2026, 5, 21, 6, 30),
      obs: Geography(22.5726, 88.3639),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.complete,
      reason: 'complete',
      startUtc: DateTime.utc(2026, 5, 21, 14, 5),
      endUtc: DateTime.utc(2026, 5, 21, 22, 0),
      startSource: 'astronomicalDusk',
      endSource: 'astronomicalDawn',
    ),
  ),
  _AstroNightCase(
    name: 'covers forty-five-minute timezone in Chatham',
    input: _AstroNightInput(
      timezoneName: 'Pacific/Chatham',
      nowUtc: DateTime.utc(2026, 5, 20, 23, 15),
      obs: Geography(-43.9535, -176.5597),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.complete,
      reason: 'complete',
      startUtc: DateTime.utc(2026, 5, 21, 6, 6),
      endUtc: DateTime.utc(2026, 5, 21, 17, 19),
      startSource: 'astronomicalDusk',
      endSource: 'astronomicalDawn',
    ),
  ),
  _AstroNightCase(
    name:
        'uses 23-hour site day on America New York DST start',
    input: _AstroNightInput(
      timezoneName: 'America/New_York',
      nowUtc: DateTime.utc(2026, 3, 8, 16),
      obs: Geography(90, 0),
    ),
    expected: _AstroNightExpected(
      status: AstroNightStatus.polarNight,
      reason: 'polar night all day',
      startUtc: DateTime.utc(2026, 3, 8, 5),
      endUtc: DateTime.utc(2026, 3, 9, 4),
      startSource: 'siteDayStartUtc',
      endSource: 'siteDayEndUtc',
    ),
  ),
];

final _solarTimeCases = <_SolarTimeCase>[
  _SolarTimeCase(
    name: 'East longitude, low latitude: Singapore',
    lat: 1.3521,
    lon: 103.8198,
    civilDawn: DateTime.utc(2026, 5, 21, 22, 33, 30),
    riseTime: DateTime.utc(2026, 5, 21, 22, 55, 59),
    transitTime: DateTime.utc(2026, 5, 21, 5, 1, 18),
    setTime: DateTime.utc(2026, 5, 21, 11, 6, 41),
    civilDusk: DateTime.utc(2026, 5, 21, 11, 29, 10),
    nauticalDawn: DateTime.utc(2026, 5, 21, 22, 7, 56),
    nauticalDusk: DateTime.utc(2026, 5, 21, 11, 54, 43),
    astronomicalDawn: DateTime.utc(2026, 5, 21, 21, 42, 10),
    astronomicalDusk: DateTime.utc(2026, 5, 21, 12, 20, 28),
  ),
  _SolarTimeCase(
    name: 'West longitude, low latitude: Quito',
    lat: -0.1807,
    lon: -78.4678,
    civilDawn: DateTime.utc(2026, 5, 21, 10, 44, 56),
    riseTime: DateTime.utc(2026, 5, 21, 11, 7, 23),
    transitTime: DateTime.utc(2026, 5, 21, 17, 10, 27),
    setTime: DateTime.utc(2026, 5, 21, 23, 13, 37),
    civilDusk: DateTime.utc(2026, 5, 21, 23, 36, 5),
    nauticalDawn: DateTime.utc(2026, 5, 21, 10, 19, 25),
    nauticalDusk: DateTime.utc(2026, 5, 21, 0, 1, 28),
    astronomicalDawn: DateTime.utc(2026, 5, 21, 9, 53, 46),
    astronomicalDusk: DateTime.utc(2026, 5, 21, 0, 27, 7),
  ),
  _SolarTimeCase(
    name: 'East longitude, mid latitude: Paris',
    lat: 48.8566,
    lon: 2.3522,
    civilDawn: DateTime.utc(2026, 5, 21, 3, 22, 10),
    riseTime: DateTime.utc(2026, 5, 21, 4, 2, 0),
    transitTime: DateTime.utc(2026, 5, 21, 11, 47, 10),
    setTime: DateTime.utc(2026, 5, 21, 19, 33, 9),
    civilDusk: DateTime.utc(2026, 5, 21, 20, 13, 11),
    nauticalDawn: DateTime.utc(2026, 5, 21, 2, 30, 7),
    nauticalDusk: DateTime.utc(2026, 5, 21, 21, 5, 39),
    astronomicalDawn: DateTime.utc(2026, 5, 21, 1, 18, 56),
    astronomicalDusk: DateTime.utc(2026, 5, 21, 22, 18, 11),
  ),
  _SolarTimeCase(
    name: 'West longitude, mid latitude: New York',
    lat: 40.7128,
    lon: -74.0060,
    civilDawn: DateTime.utc(2026, 5, 21, 9, 1, 43),
    riseTime: DateTime.utc(2026, 5, 21, 9, 33, 59),
    transitTime: DateTime.utc(2026, 5, 21, 16, 52, 36),
    setTime: DateTime.utc(2026, 5, 21, 0, 10, 54),
    civilDusk: DateTime.utc(2026, 5, 21, 0, 43, 11),
    nauticalDawn: DateTime.utc(2026, 5, 21, 8, 22, 19),
    nauticalDusk: DateTime.utc(2026, 5, 21, 1, 22, 35),
    astronomicalDawn: DateTime.utc(2026, 5, 21, 7, 37, 42),
    astronomicalDusk: DateTime.utc(2026, 5, 21, 2, 7, 12),
  ),
  _SolarTimeCase(
    name: 'East longitude, high latitude: Stockholm',
    lat: 59.3293,
    lon: 18.0686,
    civilDawn: DateTime.utc(2026, 5, 21, 0, 56, 8),
    riseTime: DateTime.utc(2026, 5, 21, 2, 2, 46),
    transitTime: DateTime.utc(2026, 5, 21, 10, 44, 18),
    setTime: DateTime.utc(2026, 5, 21, 19, 27, 22),
    civilDusk: DateTime.utc(2026, 5, 21, 20, 34, 58),
    nauticalDawn: null,
    nauticalDusk: null,
    astronomicalDawn: null,
    astronomicalDusk: null,
  ),
  _SolarTimeCase(
    name: 'West longitude, high latitude: Reykjavik',
    lat: 64.1466,
    lon: -21.9426,
    civilDawn: null,
    riseTime: DateTime.utc(2026, 5, 21, 3, 54, 51),
    transitTime: DateTime.utc(2026, 5, 21, 13, 24, 21),
    setTime: DateTime.utc(2026, 5, 21, 22, 56, 24),
    civilDusk: null,
    nauticalDawn: null,
    nauticalDusk: null,
    astronomicalDawn: null,
    astronomicalDusk: null,
  ),
];

class _SolarTimeCase {
  _SolarTimeCase({
    required this.name,
    required this.lat,
    required this.lon,
    DateTime? date,
    required this.civilDawn,
    required this.riseTime,
    required this.transitTime,
    required this.setTime,
    required this.civilDusk,
    required this.nauticalDawn,
    required this.nauticalDusk,
    required this.astronomicalDawn,
    required this.astronomicalDusk,
  }) : date = date ?? DateTime.utc(2026, 5, 21);

  final String name;
  final double lat;
  final double lon;
  final DateTime date;
  final DateTime? civilDawn;
  final DateTime riseTime;
  final DateTime transitTime;
  final DateTime setTime;
  final DateTime? civilDusk;
  final DateTime? nauticalDawn;
  final DateTime? nauticalDusk;
  final DateTime? astronomicalDawn;
  final DateTime? astronomicalDusk;
}

class _AstroNightCase {
  _AstroNightCase({
    required this.name,
    required this.input,
    required this.expected,
  });

  final String name;
  final _AstroNightInput input;
  final _AstroNightExpected expected;
}

class _AstroNightInput {
  _AstroNightInput({
    required this.timezoneName,
    required this.nowUtc,
    required this.obs,
  });

  final String timezoneName;
  final DateTime nowUtc;
  final Geography obs;
}

class _AstroNightExpected {
  _AstroNightExpected({
    required this.status,
    required this.reason,
    required this.startUtc,
    required this.endUtc,
    required this.startSource,
    required this.endSource,
    this.expectDawnAnchor = false,
    this.todayDawnAnchorUtc,
    this.todayDawnAnchorSource,
    this.expectSolarEvents = false,
    this.riseTime,
    this.transitTime,
    this.setTime,
    this.civilDawn,
    this.civilDusk,
    this.nauticalDawn,
    this.nauticalDusk,
    this.astronomicalDawn,
    this.astronomicalDusk,
  });

  _AstroNightExpected.invalidInput()
      : status = AstroNightStatus.invalidInput,
        reason = 'invalid input',
        startUtc = null,
        endUtc = null,
        startSource = null,
        endSource = null,
        expectDawnAnchor = false,
        todayDawnAnchorUtc = null,
        todayDawnAnchorSource = null,
        expectSolarEvents = false,
        riseTime = null,
        transitTime = null,
        setTime = null,
        civilDawn = null,
        civilDusk = null,
        nauticalDawn = null,
        nauticalDusk = null,
        astronomicalDawn = null,
        astronomicalDusk = null;

  final int status;
  final String? reason;
  final DateTime? startUtc;
  final DateTime? endUtc;
  final String? startSource;
  final String? endSource;
  final bool expectDawnAnchor;
  final DateTime? todayDawnAnchorUtc;
  final String? todayDawnAnchorSource;
  final bool expectSolarEvents;
  final DateTime? riseTime;
  final DateTime? transitTime;
  final DateTime? setTime;
  final DateTime? civilDawn;
  final DateTime? civilDusk;
  final DateTime? nauticalDawn;
  final DateTime? nauticalDusk;
  final DateTime? astronomicalDawn;
  final DateTime? astronomicalDusk;
}
