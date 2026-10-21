import 'dart:ffi';

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'bind.dart';
import 'coord.dart';
import 'julian.dart';

/// Celestial object types.
///
/// Identifies the object for the native library.
enum AstroObject { SUN, MOON, MERCURY, VENUS, MARS, JUPITER, SATURN, URANUS, NEPTUNE, STAR }

/// Rise/set/transit times plus dawn/dusk times for an object.
///
/// Holds the object's time events within one day:
/// - Basic events: rise, transit, set
/// - Sun only: civil/nautical/astronomical dawn and dusk
class AstroTime {
  DateTime? riseTime; // rise
  DateTime? transitTime; // transit
  DateTime? setTime; // set
  DateTime? civilDusk; // civil dusk (Sun at -6°)
  DateTime? civilDawn; // civil dawn (Sun at -6°)
  DateTime? nauticalDusk; // nautical dusk (Sun at -12°)
  DateTime? nauticalDawn; // nautical dawn (Sun at -12°)
  DateTime? astronomicalDusk; // astronomical dusk (Sun at -18°)
  DateTime? astronomicalDawn; // astronomical dawn (Sun at -18°)
  bool? transitAboveRiseSetThreshold; // whether the object is above the rise/set threshold at transit

  /// Geometric altitude at upper transit (the day's highest point), in degrees.
  ///
  /// During polar night this decides whether the whole day counts as astronomical night: only if even the Sun's highest point is below -18° can you shoot all day;
  /// in a shallow polar night (just inside the polar circle) the highest point may only reach -5°, leaving twilight all day.
  double? transitAltitudeDeg;

  AstroTime(
    this.riseTime,
    this.transitTime,
    this.setTime,
    this.civilDawn,
    this.civilDusk,
    this.nauticalDawn,
    this.nauticalDusk,
    this.astronomicalDawn,
    this.astronomicalDusk, {
    this.transitAboveRiseSetThreshold,
    this.transitAltitudeDeg,
  });
}

/// Number of event slots returned per native call; must match `kRiseTransitSetResultSlots` in
/// `KPCAARiseTransitSet2.cpp` — reading more runs past the end of the array.
/// Code that calls `calculate` directly (e.g. `AstroCalc.getMoonRiseSetForSiteDay`) must also iterate with it.
const int kAstroEventSlots = 20;

abstract final class AstroNightStatus {
  static const int complete = 0;
  static const int polarNight = 1;
  static const int polarDay = 2;
  static const int noWindow = 3;
  static const int invalidInput = 4;
}

class AstroNight {
  const AstroNight({
    required this.startUtc,
    required this.endUtc,
    required this.startSource,
    required this.endSource,
    required this.status,
    required this.reason,
    this.curveStartUtc,
    this.sunTransitAltitudeDeg,
    this.todayDawnAnchorUtc,
    this.todayDawnAnchorSource,
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

  final DateTime? startUtc;
  final DateTime? endUtc;
  final String? startSource;
  final String? endSource;
  final int status;
  final String reason;

  /// Start (UTC) of the altitude-curve canvas window; the window is always 24h long.
  ///
  /// It spans "local noon before the current observing night -> next noon"; the solar event fields (rise/set/dusk/dawn)
  /// all come from this window. Apps should draw the x axis and night shading from it directly rather than derive it from the site calendar day.
  final DateTime? curveStartUtc;

  /// Geometric altitude of the Sun at upper transit (the day's highest point), in degrees. Used during polar night to decide whether the whole day is astronomical night.
  final double? sunTransitAltitudeDeg;
  final DateTime? todayDawnAnchorUtc;
  final String? todayDawnAnchorSource;
  final DateTime? riseTime;
  final DateTime? transitTime;
  final DateTime? setTime;
  final DateTime? civilDawn;
  final DateTime? civilDusk;
  final DateTime? nauticalDawn;
  final DateTime? nauticalDusk;
  final DateTime? astronomicalDawn;
  final DateTime? astronomicalDusk;

  //toString
  @override
  String toString() {
    //toLocal
    String formatTime(DateTime? time) {
      return time?.toLocal().toIso8601String() ?? 'null';
    }

    return 'AstroNight(startUtc: ${formatTime(startUtc)}, endUtc: ${formatTime(endUtc)}, startSource: $startSource, endSource: $endSource, status: $status, reason: $reason, curveStartUtc: ${formatTime(curveStartUtc)}, todayDawnAnchorUtc: ${formatTime(todayDawnAnchorUtc)}, todayDawnAnchorSource: $todayDawnAnchorSource, riseTime: ${formatTime(riseTime)}, transitTime: ${formatTime(transitTime)}, setTime: ${formatTime(setTime)}, civilDawn: ${formatTime(civilDawn)}, civilDusk: ${formatTime(civilDusk)}, nauticalDawn: ${formatTime(nauticalDawn)}, nauticalDusk: ${formatTime(nauticalDusk)}, astronomicalDawn: ${formatTime(astronomicalDawn)}, astronomicalDusk: ${formatTime(astronomicalDusk)})';
  }
}

class _AstroNightAnchor {
  const _AstroNightAnchor(this.timeUtc, this.source);

  final DateTime timeUtc;
  final String source;
}

/// Raw solar events within one window, bucketed by type (no earliest/latest aggregation).
///
/// [AstroTime] keeps only one event per type, which is enough for the curve but not for finding night anchors: when a 24h window boundary falls near dawn,
/// the window can contain two astronomical dawns (e.g. `[01-11 05:00, 01-12 05:00)` contains both 01-11 05:00:30
/// and 01-12 04:59:53); aggregation keeps only the earliest, so dusk->dawn pairing skips a whole night and the night length comes out as 30h+.
class _SolarEventLists {
  final rises = <DateTime>[];
  final sets = <DateTime>[];
  final civilDawns = <DateTime>[];
  final civilDusks = <DateTime>[];
  final nauticalDawns = <DateTime>[];
  final nauticalDusks = <DateTime>[];
  final astronomicalDawns = <DateTime>[];
  final astronomicalDusks = <DateTime>[];

  /// Anchor fallback chain: astronomical twilight -> nautical -> civil -> rise/set. The index is the layer, shared by [duskLayer] / [dawnLayer].
  static const layerSources = [
    ('astronomicalDusk', 'astronomicalDawn'),
    ('nauticalDusk', 'nauticalDawn'),
    ('civilDusk', 'civilDawn'),
    ('setTime', 'riseTime'),
  ];

  List<DateTime> duskLayer(int level) => [astronomicalDusks, nauticalDusks, civilDusks, sets][level];

  List<DateTime> dawnLayer(int level) => [astronomicalDawns, nauticalDawns, civilDawns, rises][level];
}

class _SiteDayBounds {
  const _SiteDayBounds({
    required this.previousSiteDayStartUtc,
    required this.siteDayStartUtc,
    required this.siteDayEndUtc,
    required this.nextSiteDayEndUtc,
    required this.previousSiteNoonUtc,
    required this.siteNoonUtc,
    required this.nextSiteNoonUtc,
  });

  final DateTime previousSiteDayStartUtc;
  final DateTime siteDayStartUtc;
  final DateTime siteDayEndUtc;
  final DateTime nextSiteDayEndUtc;
  final DateTime previousSiteNoonUtc;
  final DateTime siteNoonUtc;
  final DateTime nextSiteNoonUtc;
}

bool _timezoneDatabaseInitialized = false;

AstroNight astroNightForSiteDate({required String timezoneName, required DateTime nowUtc, required Geography obs}) {
  final calculator = RiseTransitSet();
  if (!nowUtc.isUtc) {
    return calculator._astroNightInvalidInput();
  }

  final location = _timezoneLocation(timezoneName);
  if (location == null) {
    return calculator._astroNightInvalidInput();
  }

  final bounds = _siteDayBounds(location, nowUtc);
  return calculator._astroNightForUtcWindow(
    previousSiteDayStartUtc: bounds.previousSiteDayStartUtc,
    siteDayStartUtc: bounds.siteDayStartUtc,
    siteDayEndUtc: bounds.siteDayEndUtc,
    nextSiteDayEndUtc: bounds.nextSiteDayEndUtc,
    previousSiteNoonUtc: bounds.previousSiteNoonUtc,
    siteNoonUtc: bounds.siteNoonUtc,
    nextSiteNoonUtc: bounds.nextSiteNoonUtc,
    nowUtc: nowUtc,
    obs: obs,
  );
}

tz.Location? _timezoneLocation(String timezoneName) {
  try {
    final location = tz.getLocation(timezoneName);
    if (timezoneName.toUpperCase() != 'UTC') {
      _timezoneDatabaseInitialized = true;
    }
    return location;
  } catch (_) {
    if (!_timezoneDatabaseInitialized) {
      tzdata.initializeTimeZones();
      _timezoneDatabaseInitialized = true;
    }
  }

  try {
    return tz.getLocation(timezoneName);
  } catch (_) {
    return null;
  }
}

_SiteDayBounds _siteDayBounds(tz.Location location, DateTime nowUtc) {
  final localNow = tz.TZDateTime.from(nowUtc, location);

  return _SiteDayBounds(
    previousSiteDayStartUtc: tz.TZDateTime(location, localNow.year, localNow.month, localNow.day - 1).toUtc(),
    siteDayStartUtc: tz.TZDateTime(location, localNow.year, localNow.month, localNow.day).toUtc(),
    siteDayEndUtc: tz.TZDateTime(location, localNow.year, localNow.month, localNow.day + 1).toUtc(),
    nextSiteDayEndUtc: tz.TZDateTime(location, localNow.year, localNow.month, localNow.day + 2).toUtc(),
    previousSiteNoonUtc: tz.TZDateTime(location, localNow.year, localNow.month, localNow.day - 1, 12).toUtc(),
    siteNoonUtc: tz.TZDateTime(location, localNow.year, localNow.month, localNow.day, 12).toUtc(),
    nextSiteNoonUtc: tz.TZDateTime(location, localNow.year, localNow.month, localNow.day + 1, 12).toUtc(),
  );
}

/// Base class for rise/set/transit calculations.
///
/// Computes rise, set and transit times of an object.
/// Moon, Solar, Planet, Comet and others extend this class.
class RiseTransitSet {
  /// Standard altitude for stars (-34 arcmin, accounting for atmospheric refraction).
  ///
  /// Unit: **degrees**. The native `CAARiseTransitSet2::Calculate` subtracts h0 directly from the altitude (degrees);
  /// passing radians shrinks the threshold to 1/57 and shifts sunrise/sunset by more than 4 minutes each.
  double get Stdh0Stellar => _degFromMin(-34);

  /// Standard altitude for the Sun (-50 arcmin = 16' semi-diameter + 34' refraction), in degrees.
  double get Stdh0Solar => _degFromMin(-50);

  /// Mean standard altitude for the Moon (0.125°), in degrees.
  double get Stdh0LunarMean => 0.125;

  /// Mean atmospheric refraction (34 arcmin), in degrees.
  double get _meanRefraction => _degFromMin(34);

  /// Rise/set/transit times of a solar-system object.
  ///
  /// [date] Date to compute (local time)
  /// [object] Object type (AstroObject.index)
  /// [obs] Observer location
  /// [h0] Standard altitude (radians)
  ///
  /// Returns an AstroTime with the rise, set and transit times.
  /// For the Sun it also includes civil/nautical/astronomical dawn and dusk.
  AstroTime astroTimes(DateTime date, int object, Geography obs, double h0) {
    var julian = Julian();
    var jd1 = julian.gregorianToJD(date.year, date.month, date.day);
    var date2 = date.add(const Duration(days: 1));
    var jd2 = julian.gregorianToJD(date2.year, date2.month, date2.day);

    // Note: the native library treats west longitude as positive, so the longitude is negated
    final resultPtr = calculate(jd1, jd2, object, -obs.lon, obs.lat, h0, 0.007, 0);
    try {
      return _parseEventArray(resultPtr, eventCount: kAstroEventSlots);
    } finally {
      freeResults(resultPtr);
    }
  }

  /// Rise/set/transit events within an explicit UTC window [startUtc, endUtc).
  ///
  /// Unlike [astroTimes] (always the UTC calendar day 00:00->00:00), the window bounds are arbitrary;
  /// pass the UTC bounds of the site's local calendar day so rise/set match local almanacs (e.g. telescopius).
  AstroTime astroTimesWindow(DateTime startUtc, DateTime endUtc, int object, Geography obs, double h0) {
    final julian = Julian();
    final jd1 = julian.timeToJD(startUtc);
    final jd2 = julian.timeToJD(endUtc);
    // Note: the native library treats west longitude as positive, so the longitude is negated
    final resultPtr = calculate(jd1, jd2, object, -obs.lon, obs.lat, h0, 0.007, 0);
    try {
      return _parseEventArray(resultPtr, eventCount: kAstroEventSlots, startUtc: startUtc, endUtc: endUtc);
    } finally {
      freeResults(resultPtr);
    }
  }

  AstroNight _astroNightForUtcWindow({
    required DateTime previousSiteDayStartUtc,
    required DateTime siteDayStartUtc,
    required DateTime siteDayEndUtc,
    required DateTime nextSiteDayEndUtc,
    required DateTime previousSiteNoonUtc,
    required DateTime siteNoonUtc,
    required DateTime nextSiteNoonUtc,
    required DateTime nowUtc,
    required Geography obs,
  }) {
    if (!_validAstroNightInput(previousSiteDayStartUtc, siteDayStartUtc, siteDayEndUtc, nextSiteDayEndUtc, nowUtc)) {
      return _astroNightInvalidInput();
    }

    // Site-calendar-day events are only used for two things: "is today polar day/night" and todayDawnAnchor —
    // both are defined in terms of the site calendar. Night-window anchors use the now-centred window below.
    final todayEvents = _solarEventsForUtcWindow(siteDayStartUtc, siteDayEndUtc, obs);

    if (todayEvents.riseTime == null && todayEvents.setTime == null) {
      // Polar day/night has no usable night anchor, so the canvas falls back to "current local noon -> next noon".
      // The events must come from that canvas window: pairing site-day events with the canvas start misaligns them,
      // and events fall off the axis when the app draws the x axis from curveStartUtc.
      final polarCurveStart = nowUtc.isBefore(siteNoonUtc) ? previousSiteNoonUtc : siteNoonUtc;
      final polarCurveEvents = _solarEventsForUtcWindow(
        polarCurveStart,
        polarCurveStart.add(const Duration(hours: 24)),
        obs,
      );
      if (todayEvents.transitAboveRiseSetThreshold == true) {
        return _astroNightWithSolarEvents(
          events: polarCurveEvents,
          startUtc: null,
          endUtc: null,
          startSource: null,
          endSource: null,
          status: AstroNightStatus.polarDay,
          reason: 'sun above rise/set threshold all day',
          curveStartUtc: polarCurveStart,
        );
      }
      if (todayEvents.transitAboveRiseSetThreshold == false) {
        return _astroNightWithSolarEvents(
          events: polarCurveEvents,
          startUtc: siteDayStartUtc,
          endUtc: siteDayEndUtc,
          startSource: 'siteDayStartUtc',
          endSource: 'siteDayEndUtc',
          status: AstroNightStatus.polarNight,
          reason: 'polar night all day',
          curveStartUtc: polarCurveStart,
        );
      }
      return _astroNightNoWindow('polar undetermined', events: todayEvents);
    }

    // Only used to return the informational todayDawnAnchorUtc field; missing it does not affect the night window below.
    // In high-latitude transition seasons (e.g. Tromsø in late July, just out of polar day) the site day may have a sunset but no dawn/sunrise,
    // yet the night itself exists, so the whole window must not be dropped just because this field is unavailable.
    final todayDawn = _dawnAnchor(todayEvents);

    // Night-window anchors are searched in contiguous UTC windows rather than site calendar days: calendar-day bounds depend on the time zone,
    // so the same instant under a different zone name would collect a different anchor set and produce a different night.
    //
    // Windows are aligned to whole UTC days instead of sliding with nowUtc: native scans in 10-minute steps and interpolates linearly,
    // so moving the window start jitters the same event by tens of seconds. Aligned to whole days, every nowUtc in the same day
    // lands on the same grid, rise/set times are stable, and night assignment at anchor boundaries does not flip back and forth.
    // Four 24h segments cover [yesterday 00:00, day after tomorrow 24:00) UTC, enough for a full dusk->dawn pair on each side of now.
    final utcDayStart = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    final anchorStart = utcDayStart.subtract(const Duration(hours: 24));
    final anchorWindows = [
      for (var i = 0; i < 4; i++)
        _solarEventListsForUtcWindow(
          anchorStart.add(Duration(hours: 24 * i)),
          anchorStart.add(Duration(hours: 24 * (i + 1))),
          obs,
        ),
    ];
    final (start, end) = _resolveNightPair(anchorWindows, nowUtc);

    if (start == null || end == null) {
      return _astroNightNoWindow('dusk and dawn fallback exhausted', events: todayEvents);
    }
    if (!start.timeUtc.isBefore(end.timeUtc)) {
      return _astroNightNoWindow('window inverted', events: todayEvents);
    }

    final (curveStartUtc, curveEvents) = _curveWindow(
      nightStartUtc: start.timeUtc,
      nightEndUtc: end.timeUtc,
      siteNoonCandidates: [previousSiteNoonUtc, siteNoonUtc, nextSiteNoonUtc],
      obs: obs,
    );

    return _astroNightWithSolarEvents(
      events: curveEvents,
      startUtc: start.timeUtc,
      endUtc: end.timeUtc,
      startSource: start.source,
      endSource: end.source,
      status: AstroNightStatus.complete,
      reason: 'complete',
      curveStartUtc: curveStartUtc,
      todayDawnAnchorUtc: todayDawn?.timeUtc,
      todayDawnAnchorSource: todayDawn?.source,
    );
  }

  /// The night [nowUtc] belongs to; when now is in daytime, the upcoming night.
  ///
  /// First check the latest dusk before now — if its paired dawn has not arrived yet, now is inside that night;
  /// otherwise that night is over, so take the next night starting at the first dusk after now.
  (_AstroNightAnchor?, _AstroNightAnchor?) _nightPair(
    List<_AstroNightAnchor> dusks,
    List<_AstroNightAnchor> dawns,
    DateTime nowUtc,
  ) {
    for (final dusk in [_lastAtOrBefore(dusks, nowUtc), _firstAfter(dusks, nowUtc)]) {
      if (dusk == null) continue;
      final dawn = _firstAfter(dawns, dusk.timeUtc);
      if (dawn != null && dawn.timeUtc.isAfter(nowUtc)) {
        return (dusk, dawn);
      }
    }
    return (null, null);
  }

  /// Curve canvas window: start + the solar events within it. The window is always 24h long.
  ///
  /// Prefers the site's local noon to keep the existing x-axis convention, but verifies that the night lies entirely within the window
  /// and that sunset/astronomical dusk/astronomical dawn/sunrise are in order. When the site time zone does not match the observer's longitude, site noon can fall in the local
  /// night and the noon anchor splits the night in two (this night's sunset is cut off the window while the next night's sunset slips in at the end),
  /// so the shading cannot be drawn. If the check fails, fall back to local apparent solar noon: 12 hours before the night's midpoint (≈ the Sun's lower transit),
  /// which always centres the night on the canvas.
  (DateTime, AstroTime) _curveWindow({
    required DateTime nightStartUtc,
    required DateTime nightEndUtc,
    required List<DateTime> siteNoonCandidates,
    required Geography obs,
  }) {
    final nightMidUtc = nightStartUtc.add(nightEndUtc.difference(nightStartUtc) ~/ 2);
    for (final noon in siteNoonCandidates) {
      final offset = nightMidUtc.difference(noon);
      // Only worth trying if the night midpoint is roughly mid-window; saves a native call for clearly impossible candidates
      if (offset < const Duration(hours: 6) || offset > const Duration(hours: 18)) {
        continue;
      }
      final events = _solarEventsForUtcWindow(noon, noon.add(const Duration(hours: 24)), obs);
      if (_curveWindowFits(events, nightStartUtc, nightEndUtc, noon)) {
        return (noon, events);
      }
    }
    final fallback = nightMidUtc.subtract(const Duration(hours: 12));
    return (fallback, _solarEventsForUtcWindow(fallback, fallback.add(const Duration(hours: 24)), obs));
  }

  /// Whether the canvas window is consistent: the whole night is inside it and the four shading boundaries are ordered sunset < astronomical dusk < astronomical dawn < sunrise.
  /// Missing boundaries are normal at high latitudes without astronomical twilight; no shading is drawn then, so it is not a reason to reject.
  bool _curveWindowFits(AstroTime events, DateTime nightStartUtc, DateTime nightEndUtc, DateTime windowStartUtc) {
    final windowEndUtc = windowStartUtc.add(const Duration(hours: 24));
    if (nightStartUtc.isBefore(windowStartUtc) || nightEndUtc.isAfter(windowEndUtc)) {
      return false;
    }
    final set = events.setTime;
    final dusk = events.astronomicalDusk;
    final dawn = events.astronomicalDawn;
    final rise = events.riseTime;
    if (set == null || dusk == null || dawn == null || rise == null) {
      return true;
    }
    return set.isBefore(dusk) && dusk.isBefore(dawn) && dawn.isBefore(rise);
  }

  /// Finds the night [nowUtc] belongs to (or the upcoming one), falling back layer by layer.
  ///
  /// Fall back a whole layer at a time, and decide by whether a complete night can be paired, not merely whether the layer is non-empty:
  /// - Mixing layers breaks: in high-latitude transition seasons it is common to have no astronomical dusk one day and an astronomical dawn the next; pairing civil dusk with astronomical dawn
  ///   reaches into another night and gives a night longer than 26 hours;
  /// - Non-empty is not enough either: when astronomical night is disappearing (Reykjavík in mid-April) the layer still has scattered
  ///   dusks and dawns, but none pair up around now; fall back to the nautical layer instead of reporting no window.
  (_AstroNightAnchor?, _AstroNightAnchor?) _resolveNightPair(List<_SolarEventLists> windows, DateTime nowUtc) {
    for (var level = 0; level < _SolarEventLists.layerSources.length; level++) {
      final (duskSource, dawnSource) = _SolarEventLists.layerSources[level];
      final dusks = _collect(windows, (w) => w.duskLayer(level), duskSource);
      final dawns = _collect(windows, (w) => w.dawnLayer(level), dawnSource);
      if (dusks.isEmpty || dawns.isEmpty) {
        continue;
      }
      final pair = _nightPair(dusks, dawns, nowUtc);
      if (pair.$1 != null && pair.$2 != null) {
        return pair;
      }
    }
    return (null, null);
  }

  List<_AstroNightAnchor> _collect(
    List<_SolarEventLists> windows,
    List<DateTime> Function(_SolarEventLists) pick,
    String source,
  ) {
    final anchors = <_AstroNightAnchor>[];
    final seen = <int>{};
    for (final window in windows) {
      for (final time in pick(window)) {
        if (seen.add(time.millisecondsSinceEpoch)) {
          anchors.add(_AstroNightAnchor(time, source));
        }
      }
    }
    anchors.sort((a, b) => a.timeUtc.compareTo(b.timeUtc));
    return anchors;
  }

  _AstroNightAnchor? _lastAtOrBefore(List<_AstroNightAnchor> anchors, DateTime utc) {
    _AstroNightAnchor? found;
    for (final anchor in anchors) {
      if (anchor.timeUtc.isAfter(utc)) break;
      found = anchor;
    }
    return found;
  }

  _AstroNightAnchor? _firstAfter(List<_AstroNightAnchor> anchors, DateTime utc) {
    for (final anchor in anchors) {
      if (anchor.timeUtc.isAfter(utc)) return anchor;
    }
    return null;
  }

  AstroNight _astroNightWithSolarEvents({
    required AstroTime events,
    required DateTime? startUtc,
    required DateTime? endUtc,
    required String? startSource,
    required String? endSource,
    required int status,
    required String reason,
    DateTime? curveStartUtc,
    DateTime? todayDawnAnchorUtc,
    String? todayDawnAnchorSource,
  }) {
    return AstroNight(
      startUtc: startUtc,
      endUtc: endUtc,
      startSource: startSource,
      endSource: endSource,
      status: status,
      reason: reason,
      curveStartUtc: curveStartUtc?.toUtc(),
      sunTransitAltitudeDeg: events.transitAltitudeDeg,
      todayDawnAnchorUtc: todayDawnAnchorUtc?.toUtc(),
      todayDawnAnchorSource: todayDawnAnchorSource,
      riseTime: events.riseTime?.toUtc(),
      transitTime: events.transitTime?.toUtc(),
      setTime: events.setTime?.toUtc(),
      civilDawn: events.civilDawn?.toUtc(),
      civilDusk: events.civilDusk?.toUtc(),
      nauticalDawn: events.nauticalDawn?.toUtc(),
      nauticalDusk: events.nauticalDusk?.toUtc(),
      astronomicalDawn: events.astronomicalDawn?.toUtc(),
      astronomicalDusk: events.astronomicalDusk?.toUtc(),
    );
  }

  /// All solar events in the window bucketed by type, for night-anchor pairing only; see [_SolarEventLists] for why.
  _SolarEventLists _solarEventListsForUtcWindow(DateTime startUtc, DateTime endUtc, Geography obs) {
    final julian = Julian();
    final resultPtr = calculate(
      julian.timeToJD(startUtc),
      julian.timeToJD(endUtc),
      AstroObject.SUN.index,
      -obs.lon,
      obs.lat,
      Stdh0Solar,
      0.007,
      0,
    );
    final lists = _SolarEventLists();
    try {
      for (var i = 0; i < kAstroEventSlots; i++) {
        final event = (resultPtr + i).ref;
        if (event.type <= 0 || event.jd < 1 || event.altitude > 90 || event.altitude < -90 || event.jd.isNaN) {
          continue;
        }
        final eventUtc = julian.jdToTime(event.jd).toUtc();
        if (eventUtc.isBefore(startUtc) || !eventUtc.isBefore(endUtc)) {
          continue;
        }
        switch (event.type) {
          case 1:
            lists.rises.add(eventUtc);
          case 2:
            lists.sets.add(eventUtc);
          case 5:
            lists.civilDusks.add(eventUtc);
          case 6:
            lists.nauticalDusks.add(eventUtc);
          case 7:
            lists.astronomicalDusks.add(eventUtc);
          case 8:
            lists.astronomicalDawns.add(eventUtc);
          case 9:
            lists.nauticalDawns.add(eventUtc);
          case 10:
            lists.civilDawns.add(eventUtc);
        }
      }
    } finally {
      freeResults(resultPtr);
    }
    return lists;
  }

  AstroTime _solarEventsForUtcWindow(DateTime startUtc, DateTime endUtc, Geography obs) {
    final julian = Julian();
    final jd1 = julian.timeToJD(startUtc);
    final jd2 = julian.timeToJD(endUtc);
    final resultPtr = calculate(jd1, jd2, AstroObject.SUN.index, -obs.lon, obs.lat, Stdh0Solar, 0.007, 0);

    try {
      return _parseEventArray(resultPtr, eventCount: kAstroEventSlots, startUtc: startUtc, endUtc: endUtc);
    } finally {
      freeResults(resultPtr);
    }
  }

  AstroTime _parseEventArray(
    Pointer<KPCAARiseTransitSetDetails2> resultPtr, {
    required int eventCount,
    DateTime? startUtc,
    DateTime? endUtc,
  }) {
    final julian = Julian();
    DateTime? riseTime, transitTime, setTime;
    DateTime? civilDusk, civilDawn, nauticalDusk, nauticalDawn;
    DateTime? astronomicalDusk, astronomicalDawn;
    double? transitAltitude;
    bool? transitAboveRiseSetThreshold;

    for (var i = 0; i < eventCount; i++) {
      final event = (resultPtr + i).ref;
      if (event.type <= 0 || event.jd < 1 || event.altitude > 90 || event.altitude < -90 || event.jd.isNaN) {
        continue;
      }

      final eventUtc = julian.jdToTime(event.jd).toUtc();
      if (startUtc != null && eventUtc.isBefore(startUtc)) {
        continue;
      }
      if (endUtc != null && !eventUtc.isBefore(endUtc)) {
        continue;
      }

      switch (event.type) {
        case 1:
          riseTime = _earliest(riseTime, eventUtc);
          break;
        case 2:
          setTime = _latest(setTime, eventUtc);
          break;
        case 3:
        case 4:
          if (transitAltitude == null || event.altitude > transitAltitude) {
            transitAltitude = event.altitude;
            transitTime = eventUtc;
            transitAboveRiseSetThreshold = event.aboveHorizon;
          }
          break;
        case 5:
          civilDusk = _latest(civilDusk, eventUtc);
          break;
        case 6:
          nauticalDusk = _latest(nauticalDusk, eventUtc);
          break;
        case 7:
          astronomicalDusk = _latest(astronomicalDusk, eventUtc);
          break;
        case 8:
          astronomicalDawn = _earliest(astronomicalDawn, eventUtc);
          break;
        case 9:
          nauticalDawn = _earliest(nauticalDawn, eventUtc);
          break;
        case 10:
          civilDawn = _earliest(civilDawn, eventUtc);
          break;
      }
    }

    return AstroTime(
      riseTime,
      transitTime,
      setTime,
      civilDawn,
      civilDusk,
      nauticalDawn,
      nauticalDusk,
      astronomicalDawn,
      astronomicalDusk,
      transitAboveRiseSetThreshold: transitAboveRiseSetThreshold,
      transitAltitudeDeg: transitAltitude,
    );
  }

  DateTime _earliest(DateTime? current, DateTime candidate) {
    if (current == null || candidate.isBefore(current)) {
      return candidate;
    }
    return current;
  }

  DateTime _latest(DateTime? current, DateTime candidate) {
    if (current == null || candidate.isAfter(current)) {
      return candidate;
    }
    return current;
  }

  _AstroNightAnchor? _dawnAnchor(AstroTime events) {
    return _firstAnchor(
      [
        _AstroNightAnchor(events.astronomicalDawn?.toUtc() ?? DateTime.utc(0), 'astronomicalDawn'),
        _AstroNightAnchor(events.nauticalDawn?.toUtc() ?? DateTime.utc(0), 'nauticalDawn'),
        _AstroNightAnchor(events.civilDawn?.toUtc() ?? DateTime.utc(0), 'civilDawn'),
        _AstroNightAnchor(events.riseTime?.toUtc() ?? DateTime.utc(0), 'riseTime'),
      ],
      [events.astronomicalDawn, events.nauticalDawn, events.civilDawn, events.riseTime],
    );
  }

  _AstroNightAnchor? _firstAnchor(List<_AstroNightAnchor> anchors, List<DateTime?> values) {
    for (var i = 0; i < anchors.length; i++) {
      final value = values[i];
      if (value == null) {
        continue;
      }
      return _AstroNightAnchor(value.toUtc(), anchors[i].source);
    }
    return null;
  }

  bool _validAstroNightInput(
    DateTime previousSiteDayStartUtc,
    DateTime siteDayStartUtc,
    DateTime siteDayEndUtc,
    DateTime nextSiteDayEndUtc,
    DateTime nowUtc,
  ) {
    if (!previousSiteDayStartUtc.isUtc ||
        !siteDayStartUtc.isUtc ||
        !siteDayEndUtc.isUtc ||
        !nextSiteDayEndUtc.isUtc ||
        !nowUtc.isUtc) {
      return false;
    }
    if (!previousSiteDayStartUtc.isBefore(siteDayStartUtc) ||
        !siteDayStartUtc.isBefore(siteDayEndUtc) ||
        !siteDayEndUtc.isBefore(nextSiteDayEndUtc)) {
      return false;
    }
    if (nowUtc.isBefore(siteDayStartUtc) || !nowUtc.isBefore(siteDayEndUtc)) {
      return false;
    }
    return _validSiteDayLength(previousSiteDayStartUtc, siteDayStartUtc) &&
        _validSiteDayLength(siteDayStartUtc, siteDayEndUtc) &&
        _validSiteDayLength(siteDayEndUtc, nextSiteDayEndUtc);
  }

  bool _validSiteDayLength(DateTime startUtc, DateTime endUtc) {
    final length = endUtc.difference(startUtc);
    return length >= const Duration(hours: 22) && length <= const Duration(hours: 26);
  }

  AstroNight _astroNightInvalidInput() {
    return const AstroNight(
      startUtc: null,
      endUtc: null,
      startSource: null,
      endSource: null,
      status: AstroNightStatus.invalidInput,
      reason: 'invalid input',
    );
  }

  AstroNight _astroNightNoWindow(String reason, {AstroTime? events}) {
    if (events != null) {
      return _astroNightWithSolarEvents(
        events: events,
        startUtc: null,
        endUtc: null,
        startSource: null,
        endSource: null,
        status: AstroNightStatus.noWindow,
        reason: reason,
      );
    }

    return AstroNight(
      startUtc: null,
      endUtc: null,
      startSource: null,
      endSource: null,
      status: AstroNightStatus.noWindow,
      reason: reason,
    );
  }

  /// Rise/set/transit times of a star or deep-sky object.
  ///
  /// [date] Date to compute (local time)
  /// [eq] Equatorial coordinates of the object (J2000 or JNow)
  /// [obs] Observer location
  /// [h0] Standard altitude (radians)
  ///
  /// For objects whose position is relatively fixed, such as stars, deep-sky objects and comets.
  /// Dawn/dusk times are not computed.
  ///
  /// Optimisation: first try a 24h window (covers most typical targets); only when no complete rise+set
  /// pair is found and a rise/set did occur within 24h, recompute with a 48h window.
  /// The result is field-for-field identical to using a 48h window directly, so upstream UI / sorting is unaffected.
  AstroTime timesStationary(DateTime date, Equatorial eq, Geography obs, double h0) {
    final r24 = _calcStationaryWindow(date, eq, obs, h0, days: 1);
    if (r24.result.riseTime != null && r24.result.setTime != null) return r24.result;
    // No rise/set within 24h: circumpolar / never rises / never reaches the threshold;
    // a wider window will not help, so skip a native call
    if (!r24.hasRiseOrSet) return r24.result;
    // A rise or set within 24h but pairing failed (target already up at now, or transit period > 24h)
    return _calcStationaryWindow(date, eq, obs, h0, days: 2).result;
  }

  /// A single native call computing rise/set/transit events for the given window length.
  ///
  /// [hasRiseOrSet] lets the caller decide whether to fall back to a wider window: false means the window has no
  /// rise/set events at all, so widening will not yield anything new.
  ({AstroTime result, bool hasRiseOrSet}) _calcStationaryWindow(
    DateTime date,
    Equatorial eq,
    Geography obs,
    double h0, {
    required int days,
  }) {
    var julian = Julian();
    var jd1 = julian.gregorianToJD(date.year, date.month, date.day);
    var date2 = date.add(Duration(days: days));
    var jd2 = julian.gregorianToJD(date2.year, date2.month, date2.day);

    // Note: the native library treats west longitude as positive, so the longitude is negated
    final resultPtr = calculateStationar(jd1, jd2, eq.ra, eq.dec, -obs.lon, obs.lat, h0, 0.007);

    final rises = <DateTime>[];
    final sets = <DateTime>[];
    // (time, altitude, aboveHorizon)
    final transits = <(DateTime, double, bool)>[];

    for (var i = 0; i < kAstroEventSlots; i++) {
      final event = (resultPtr + i).ref;

      if (event.jd < 1 || event.altitude > 90 || event.altitude < -90 || event.jd.isNaN) {
        continue;
      }

      switch (event.type) {
        case 1:
          rises.add(julian.jdToTime(event.jd));
          break;
        case 2:
          sets.add(julian.jdToTime(event.jd));
          break;
        case 3:
        case 4:
          transits.add((julian.jdToTime(event.jd), event.altitude, event.aboveHorizon));
          break;
      }
    }

    freeResults(resultPtr);

    rises.sort();
    sets.sort();
    transits.sort((a, b) => a.$1.compareTo(b.$1));

    DateTime? riseTime;
    DateTime? setTime;
    DateTime? transitTime;

    if (rises.isNotEmpty) {
      riseTime = rises.first;
      for (final s in sets) {
        if (s.isAfter(riseTime)) {
          setTime = s;
          break;
        }
      }
    }

    if (riseTime != null && setTime != null) {
      for (final t in transits) {
        if (t.$3 && t.$1.isAfter(riseTime) && t.$1.isBefore(setTime)) {
          transitTime = t.$1;
          break;
        }
      }
    } else {
      double maxAlt = double.negativeInfinity;
      for (final t in transits) {
        if (t.$3 && t.$2 > maxAlt) {
          maxAlt = t.$2;
          transitTime = t.$1;
        }
      }
    }

    if (riseTime == null || setTime == null) {
      riseTime = null;
      setTime = null;
    }

    return (
      result: AstroTime(riseTime, transitTime, setTime, null, null, null, null, null, null),
      hasRiseOrSet: rises.isNotEmpty || sets.isNotEmpty,
    );
  }

  /// Arcminutes to degrees.
  double _degFromMin(double m) {
    return m / 60;
  }

  /// Standard altitude for the Moon, in degrees.
  ///
  /// h0 = 0.7275 * π − 34' (Meeus, Astronomical Algorithms, §15.1)
  ///
  /// [a] Geocentric parallax of the Moon (degrees)
  double stdh0Lunar(double a) {
    return a * 0.7275 - _meanRefraction;
  }
}
