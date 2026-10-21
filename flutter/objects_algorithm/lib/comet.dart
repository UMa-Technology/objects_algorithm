import 'bind.dart';
import 'rise.dart';
import 'coord.dart';
import 'julian.dart';

/// Comet position calculations.
/// 
/// Usage:
/// ```dart
/// double jdTT = Julian.uTC2TT(jdUtc);  // epoch uses TT
/// Geography location = Geography(lat, lon);
/// 
/// // Comet orbital elements (from the MPC)
/// // Source: https://minorplanetcenter.net/data
/// // https://www.minorplanetcenter.net/iau/MPCORB/CometEls.txt
/// Comet comet = Comet(
///   jdTT,
///   q: 0.462651,       // perihelion distance (AU)
///   e: 1.008249,       // eccentricity
///   i: 112.7088,       // inclination (deg)
///   w: 47.5667,        // argument of perihelion (deg)
///   omega: 91.8839,    // longitude of ascending node (deg)
///   T: 2460630.0402,   // time of perihelion (JD)
///   jDEquinox: 2460635.5, // epoch of the elements (JD)
/// );
/// 
/// // JNow equatorial coordinates
/// Equatorial eqJNow = comet.getEquatorialJNow();
/// 
/// // Horizontal coordinates
/// Horizontal hz = comet.getHorizontal(location, jdUtc: jdUtc);
/// 
/// // J2000 equatorial coordinates
/// Equatorial eqJ2000 = comet.getEquatorialJ2000();
/// ```
/// 
/// Orbital elements:
/// | Parameter | Meaning | Unit |
/// |------|------|------|
/// | q | Perihelion distance | AU |
/// | e | Eccentricity | - |
/// | i | Inclination | deg |
/// | w | Argument of perihelion | deg |
/// | omega | Longitude of ascending node | deg |
/// | T | Time of perihelion | JD |
/// | jDEquinox | Epoch | JD |
class Comet extends RiseTransitSet {
  Equatorial? eq;
  final double jd;  // TT Julian day (used for the epoch)
  
  // Orbital elements
  final double q;         // perihelion distance (AU)
  final double e;         // eccentricity
  final double i;         // inclination (deg)
  final double w;         // argument of perihelion (deg)
  final double omega;     // longitude of ascending node (deg)
  final double T;         // time of perihelion (JD)
  final double jDEquinox; // epoch of the elements (JD)

  Comet(
    this.jd, {
    required this.q,
    required this.e,
    required this.i,
    required this.w,
    required this.omega,
    required this.T,
    required this.jDEquinox,
  }) {
    // Compute the position at construction time
    _calculatePosition();
  }

  void _calculatePosition() {
    final result = calculateNearParabolicObject(jd, q, e, i, w, omega, T, jDEquinox);
    eq = Equatorial(result.TrueGeocentricRA, result.TrueGeocentricDeclination);
  }

  // ============================================================
  // Unified API
  // ============================================================

  /// JNow equatorial coordinates (apparent position).
  /// 
  /// Comets need no parallax correction (distant enough); returns the geocentric apparent position.
  Equatorial getEquatorialJNow([Geography? obs]) {
    return Equatorial(eq!.ra, eq!.dec);
  }

  /// J2000 equatorial coordinates (standard catalogue coordinates).
  Equatorial getEquatorialJ2000([Geography? obs]) {
    var eqJ2000 = Equatorial(eq!.ra, eq!.dec);
    eqJ2000.regressCoordinates(jd);
    return eqJ2000;
  }

  /// Horizontal (alt-az) coordinates.
  /// 
  /// [obs] Observer location
  /// [jdUtc] UTC Julian day (used for sidereal time); defaults to the instance's jd
  Horizontal getHorizontal(Geography obs, {double? jdUtc}) {
    jdUtc ??= jd;
    var eqJNow = getEquatorialJNow();
    var hz = Coord.instance.eqToHz(jdUtc, eqJNow, obs);
    hz.direction = Coord.instance.azimuth2Direction(hz.az);
    return hz;
  }

  // ============================================================
  // Legacy API (backward compatible)
  // ============================================================

  @Deprecated('Use getEquatorialJNow() instead')
  Equatorial equatorialCoordinates(double jd) {
    return getEquatorialJNow();
  }

  @Deprecated('Use getHorizontal() instead')
  Horizontal azAlt(double jd, Geography obs) {
    return getHorizontal(obs, jdUtc: jd);
  }

  // ============================================================
  // Other methods
  // ============================================================

  /// Rise/transit/set times.
  AstroTime times(DateTime date, Geography obs) {
    return super.timesStationary(date, eq!, obs, Stdh0Stellar);
  }

  /// Whether there is any period on [date] when the comet is above the rise/set threshold.
  ///
  /// Consistent with [times]: uses the position computed at construction; [date]'s year/month/day define a UTC calendar day;
  /// the threshold is [Stdh0Stellar] (-34', including refraction). Naked-eye vs. telescopic magnitude is not considered.
  ///
  /// Example for an app list:
  /// ```dart
  /// comets.where((c) => c.isVisibleOnDate(siteDateUtc, obs))
  /// ```
  bool isVisibleOnDate(DateTime date, Geography obs) {
    final t = times(date, obs);
    if (t.riseTime != null && t.setTime != null) return true;
    if (t.transitTime != null) return true;

    // Fallback: covers cases where times gives no rise/set, e.g. already above the horizon at the start of the day.
    // Stdh0Stellar is already in degrees; do not convert it to radians.
    final jdStart = Julian().gregorianToJD(date.year, date.month, date.day);
    for (var i = 0; i < 24; i++) {
      final hz = getHorizontal(obs, jdUtc: jdStart + (i + 0.5) / 24);
      if (hz.alt > Stdh0Stellar) return true;
    }
    return false;
  }
}
