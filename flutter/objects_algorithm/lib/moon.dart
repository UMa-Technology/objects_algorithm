import 'dart:math';

import 'bind.dart';
import 'solar.dart';
import 'coord.dart';
import 'earth.dart';
import 'rise.dart';

/// Lunar position calculations.
///
/// Usage:
/// ```dart
/// double jdTT = Julian.uTC2TT(jdUtc);  // epoch uses TT
/// Geography location = Geography(lat, lon);
///
/// Moon moon = Moon(jdTT);
///
/// // JNow equatorial coordinates (used for horizontal coordinates)
/// Equatorial eqJNow = moon.getEquatorialJNow(location, jdUtc: jdUtc);
///
/// // Horizontal coordinates
/// Horizontal hz = moon.getHorizontal(location, jdUtc: jdUtc);
///
/// // J2000 equatorial coordinates
/// Equatorial eqJ2000 = moon.getEquatorialJ2000(location, jdUtc: jdUtc);
/// ```
class Moon extends RiseTransitSet {
  Equatorial? eq;
  Ecliptic? ecl;
  double? radiusVector;
  final double jd; // TT Julian day (used for the epoch)

  Moon(this.jd) {
    double longitude = moonEclipticLongitude(jd);
    double latitude = moonEclipticLatitude(jd);
    ecl = Ecliptic(latitude, longitude, jd, jd);
    radiusVector = _moonRadiusVector();
  }

  // ============================================================
  // Unified API
  // ============================================================

  /// JNow equatorial coordinates (current epoch, topocentric).
  ///
  /// [obs] Observer location (used for the parallax correction)
  /// [jdUtc] UTC Julian day (used for sidereal time); defaults to the instance's jd
  ///
  /// Returns topocentric equatorial coordinates with the parallax correction applied.
  Equatorial getEquatorialJNow(Geography obs, {double? jdUtc}) {
    jdUtc ??= jd;

    // Ecliptic -> geocentric equatorial (JNow)
    var eqGeo = Coord.instance.eclToEq(ecl!.celestialLongitude, ecl!.celestialLatitude, ecl!.epoch);

    // Apply parallax -> topocentric equatorial
    var moonRad = radiusVector! / 149597870.7; // km to AU
    var coords = parallaxEquatorial2Topocentric(
      eqGeo.ra,
      eqGeo.dec,
      moonRad,
      -obs.lon,
      obs.lat,
      obs.alt, // AA+ treats west longitude as positive
      jdUtc,
    );

    return Equatorial(coords.X, coords.Y);
  }

  /// J2000 equatorial coordinates (standard catalogue coordinates).
  ///
  /// [obs] Observer location (used for the parallax correction)
  /// [jdUtc] UTC Julian day (used for sidereal time); defaults to the instance's jd
  Equatorial getEquatorialJ2000(Geography obs, {double? jdUtc}) {
    // Get JNow first
    var eqJNow = getEquatorialJNow(obs, jdUtc: jdUtc);

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
    var eqJNow = getEquatorialJNow(obs, jdUtc: jdUtc);
    return Coord.instance.eqToHz(jdUtc, eqJNow, obs);
  }

  // ============================================================
  // Legacy API (backward compatible; prefer the new API)
  // ============================================================

  @Deprecated('Use getEquatorialJNow() instead')
  Moon equatorialCoordinates(Geography obs) {
    return equatorialCoordinatesWithJD(obs, jd);
  }

  @Deprecated('Use getEquatorialJNow() instead')
  Moon equatorialCoordinatesWithJD(Geography obs, double jdForSidereal) {
    eq = getEquatorialJNow(obs, jdUtc: jdForSidereal);
    return this;
  }

  // ============================================================
  // Other methods
  // ============================================================

  /// Rise/set altitude threshold using the Moon's actual parallax at this time, in degrees (the native h0 contract is degrees).
  ///
  /// Uses the actual parallax instead of Meeus's mean approximation Stdh0LunarMean (0.125°). The Moon's geocentric parallax is
  /// π = arcsin(R_earth / d_moon), with R_earth ≈ 6378.14 km and d_moon = radiusVector (km);
  /// perigee and apogee distances differ by ~12%, so the mean approximation puts rise/set ~20 minutes off Stellarium / SkySafari.
  double get _h0 => stdh0Lunar(asin(6378.14 / radiusVector!) * 180 / pi);

  AstroTime times(DateTime date, Geography obs) {
    return super.astroTimes(date, AstroObject.MOON.index, obs, _h0);
  }

  /// Moonrise/moonset/transit within an explicit UTC window.
  ///
  /// Pass the UTC bounds of the site's local calendar day (e.g. local midnight and +1 day, converted to UTC) so rise/set match
  /// local almanacs (telescopius etc.): within one calendar day the moonset may come before the moonrise.
  AstroTime timesForWindow(DateTime startUtc, DateTime endUtc, Geography obs) {
    return super.astroTimesWindow(startUtc, endUtc, AstroObject.MOON.index, obs, _h0);
  }

  /// Angular distance to another object (degrees).
  ///
  /// [other] Equatorial coordinates of the other object
  /// [obs] Observer location (used for the Moon's topocentric coordinates)
  /// [jdUtc] UTC Julian day
  double distanceTo(Equatorial other, Geography obs, {double? jdUtc}) {
    var moonEq = getEquatorialJNow(obs, jdUtc: jdUtc);
    return separation(moonEq.ra, moonEq.dec, other.ra, other.dec);
  }

  @Deprecated('Use distanceTo() instead')
  double distance(Equatorial eq1) {
    if (eq == null) throw StateError('Call getEquatorialJNow() or equatorialCoordinates() first');
    return separation(eq!.ra, eq!.dec, eq1.ra, eq1.dec);
  }

  /// Phase angle (degrees).
  double phaseAngle() {
    Earth earth = Earth(jd);
    double geoElong = geoElongation();
    // AA+ PhaseAngle does no unit conversion, so both distances must be in the same unit (km).
    // The Earth-Moon distance is in km and the Earth-Sun distance in AU; convert to km first, otherwise the
    // Earth-Moon distance (km) swamps the atan2 denominator, the phase angle stays ≈0 and illumination ≈100% (always a full moon).
    double earthSunDistance = earth.radiusVector() * 149597870.7; // AU → km
    double moonEarthDistance = radiusVector!;
    return phaseAngleC(geoElong, moonEarthDistance, earthSunDistance);
  }

  /// Illuminated fraction (0-1).
  double illuminated() {
    double pa = phaseAngle();
    return illuminatedFraction(pa);
  }

  /// Whether the Moon is waxing.
  ///
  /// Determined from the elongation in longitude: Moon longitude − Sun longitude, normalised to 0-360°.
  /// 0-180° is waxing (lit side on the right in the northern hemisphere), 180-360° is waning (lit side on the left).
  bool isWaxing() {
    final sun = Solar(jd);
    // Dart's % returns a non-negative result for a positive divisor, so diff ∈ [0, 360)
    final double diff = (ecl!.celestialLongitude - sun.ecl!.celestialLongitude) % 360;
    return diff < 180;
  }

  /// Distance to the Moon (km).
  double _moonRadiusVector() {
    return moonRadiusVector(jd);
  }

  /// Geocentric elongation (degrees).
  ///
  /// Angle between the Moon and the Sun from geocentric coordinates.
  double geoElongation() {
    // Use geocentric coordinates (no parallax correction needed)
    var moonEqGeo = Coord.instance.eclToEq(ecl!.celestialLongitude, ecl!.celestialLatitude, ecl!.epoch);
    Solar sun = Solar(jd);
    var sunEq = sun.getEquatorialJNow();
    return geocentricElongation(moonEqGeo.ra, moonEqGeo.dec, sunEq.ra, sunEq.dec);
  }
}
