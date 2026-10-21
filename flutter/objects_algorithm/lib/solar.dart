import 'bind.dart';
import 'rise.dart';
import 'coord.dart';

/// Solar position calculations.
/// 
/// Usage:
/// ```dart
/// double jdTT = Julian.uTC2TT(jdUtc);  // epoch uses TT
/// Geography location = Geography(lat, lon);
/// 
/// Solar sun = Solar(jdTT);
/// 
/// // JNow equatorial coordinates (used for horizontal coordinates)
/// Equatorial eqJNow = sun.getEquatorialJNow();
/// 
/// // Horizontal coordinates
/// Horizontal hz = sun.getHorizontal(location, jdUtc: jdUtc);
/// 
/// // J2000 equatorial coordinates
/// Equatorial eqJ2000 = sun.getEquatorialJ2000();
/// ```
/// 
/// Note: the Sun's parallax is tiny (about 8.8 arcsec) so no parallax correction is applied,
/// hence getEquatorialJNow/J2000 need no Geography argument.
class Solar extends RiseTransitSet {
  Equatorial? eq;
  Ecliptic? ecl;
  final double jd;  // TT Julian day (used for the epoch)

  Solar(this.jd) {
    double longitude = sunEclipticLongitude(jd, 1);
    double latitude = sunEclipticLatitude(jd, 1);
    ecl = Ecliptic(latitude, longitude, jd, jd);
  }

  // ============================================================
  // Unified API
  // ============================================================

  /// JNow equatorial coordinates (current epoch).
  /// 
  /// [obs] Observer location (not needed for the Sun; accepted for API consistency)
  /// 
  /// Note: the Sun's parallax is tiny, so no parallax correction is applied.
  Equatorial getEquatorialJNow([Geography? obs]) {
    // Ecliptic -> equatorial (JNow)
    return Coord.instance.eclToEq(ecl!.celestialLongitude, ecl!.celestialLatitude, ecl!.epoch);
  }

  /// J2000 equatorial coordinates (standard catalogue coordinates).
  /// 
  /// [obs] Observer location (not needed for the Sun; accepted for API consistency)
  Equatorial getEquatorialJ2000([Geography? obs]) {
    // Get JNow first
    var eqJNow = getEquatorialJNow();
    
    // JNow -> J2000 (undo precession + nutation)
    var eqJ2000 = Equatorial(eqJNow.ra, eqJNow.dec);
    eqJ2000.regressCoordinates(jd);
    
    return eqJ2000;
  }

  /// Horizontal (alt-az) coordinates.
  /// 
  /// [obs] Observer location
  /// [jdUtc] UTC Julian day (used for sidereal time); defaults to the instance's jd
  /// 
  /// Returns horizontal coordinates with atmospheric refraction applied.
  Horizontal getHorizontal(Geography obs, {double? jdUtc}) {
    jdUtc ??= jd;
    var eqJNow = getEquatorialJNow();
    return Coord.instance.eqToHz(jdUtc, eqJNow, obs);
  }

  // ============================================================
  // Legacy API (backward compatible; prefer the new API)
  // ============================================================

  @Deprecated('Use getEquatorialJNow() instead')
  Solar equatorialCoordinates() {
    eq = getEquatorialJNow();
    return this;
  }

  @Deprecated('Use getEquatorialJ2000() instead')
  Solar equatorialCoordinatesJ2000() {
    eq = getEquatorialJ2000();
    return this;
  }

  // ============================================================
  // Other methods
  // ============================================================

  AstroTime times(DateTime date, Geography obs) {
    return super.astroTimes(date, AstroObject.SUN.index, obs, Stdh0Solar);
  }

  /// Sunrise/sunset/transit within an explicit UTC window.
  ///
  /// Pass the UTC bounds of the site's local calendar day so rise/set match local almanacs (telescopius etc.) and the curve;
  /// [times] cuts the window by UTC calendar day, so when the local evening straddles a UTC date change it returns the next day's rise/set.
  AstroTime timesForWindow(DateTime startUtc, DateTime endUtc, Geography obs) {
    return super.astroTimesWindow(startUtc, endUtc, AstroObject.SUN.index, obs, Stdh0Solar);
  }
}
