import 'coord.dart';
import 'bind.dart';
import 'rise.dart';

/// Base class for planets.
/// 
/// Usage:
/// ```dart
/// double jdTT = Julian.uTC2TT(jdUtc);
/// Geography location = Geography(lat, lon);
/// 
/// Jupiter jupiter = Jupiter(jdTT);
/// 
/// // JNow equatorial coordinates
/// Equatorial eqJNow = jupiter.getEquatorialJNow();
/// 
/// // Horizontal coordinates
/// Horizontal hz = jupiter.getHorizontal(location, jdUtc: jdUtc);
/// 
/// // J2000 equatorial coordinates
/// Equatorial eqJ2000 = jupiter.getEquatorialJ2000();
/// ```
abstract class Planet extends RiseTransitSet {
  Equatorial? eq;  // apparent position (JNow)
  Ecliptic? ecl;
  int? astroObject;
  double? planetSunDistance;
  double? earthSunDistance;
  double? planetEarthDistance;
  double? phaseAngle;
  double? magnitude;
  late double jd;  // TT Julian day

  // ============================================================
  // Unified API
  // ============================================================

  /// JNow equatorial coordinates (apparent position).
  /// 
  /// Planets need no parallax correction (too distant); returns the geocentric apparent position.
  Equatorial getEquatorialJNow([Geography? obs]) {
    return Equatorial(eq!.ra, eq!.dec);
  }

  /// J2000 equatorial coordinates.
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
  Equatorial? equatorialCoordinates(double jd) {
    return getEquatorialJNow();
  }

  @Deprecated('Use getHorizontal() instead')
  Horizontal azAlt(double jd, Geography obs) {
    return getHorizontal(obs, jdUtc: jd);
  }

  AstroTime times(DateTime date, Geography obs) {
    return super.astroTimes(date, astroObject!, obs, Stdh0Stellar);
  }

  /// Rise/set/transit within an explicit UTC window; same semantics as [Solar.timesForWindow].
  AstroTime timesForWindow(DateTime startUtc, DateTime endUtc, Geography obs) {
    return super.astroTimesWindow(startUtc, endUtc, astroObject!, obs, Stdh0Stellar);
  }

  // ============================================================
  // Phase and magnitude
  // ============================================================

  /// Phase angle (degrees).
  double calculatePhaseAngle() {
    return phaseAnglePlanet(planetSunDistance!, earthSunDistance!, planetEarthDistance!);
  }

  /// Magnitude.
  double calculateMagnitude(int planet) {
    return magnitudePlanet(planet, planetSunDistance!, planetEarthDistance!, phaseAngle!);
  }
}

// ============================================================
// Concrete planet classes
// ============================================================

/// Mercury
class Mercury extends Planet {
  final int planetId = 1;
  
  Mercury(double jdTT) {
    jd = jdTT;
    var planet = calculatePlanetaryDetails(jd, planetId, 1);
    eq = Equatorial(planet.ApparentGeocentricRA, planet.ApparentGeocentricDeclination);
    astroObject = AstroObject.MERCURY.index;
    planetSunDistance = Coord.instance.astronomicalUnit(jd, 0);
    earthSunDistance = Coord.instance.astronomicalUnit(jd, 99);
    planetEarthDistance = planet.ApparentGeocentricDistance;
    phaseAngle = calculatePhaseAngle();
    magnitude = calculateMagnitude(0);
  }
}

/// Venus
class Venus extends Planet {
  final int planetId = 2;
  
  Venus(double jdTT) {
    jd = jdTT;
    var planet = calculatePlanetaryDetails(jd, planetId, 1);
    eq = Equatorial(planet.ApparentGeocentricRA, planet.ApparentGeocentricDeclination);
    astroObject = AstroObject.VENUS.index;
    planetSunDistance = Coord.instance.astronomicalUnit(jd, 1);
    earthSunDistance = Coord.instance.astronomicalUnit(jd, 99);
    planetEarthDistance = planet.ApparentGeocentricDistance;
    phaseAngle = calculatePhaseAngle();
    magnitude = calculateMagnitude(1);
  }
}

/// Mars
class Mars extends Planet {
  final int planetId = 3;
  
  Mars(double jdTT) {
    jd = jdTT;
    var planet = calculatePlanetaryDetails(jd, planetId, 1);
    eq = Equatorial(planet.ApparentGeocentricRA, planet.ApparentGeocentricDeclination);
    astroObject = AstroObject.MARS.index;
    planetSunDistance = Coord.instance.astronomicalUnit(jd, 2);
    earthSunDistance = Coord.instance.astronomicalUnit(jd, 99);
    planetEarthDistance = planet.ApparentGeocentricDistance;
    phaseAngle = calculatePhaseAngle();
    magnitude = calculateMagnitude(2);
  }
}

/// Jupiter
class Jupiter extends Planet {
  final int planetId = 4;
  
  Jupiter(double jdTT) {
    jd = jdTT;
    var planet = calculatePlanetaryDetails(jd, planetId, 1);
    eq = Equatorial(planet.ApparentGeocentricRA, planet.ApparentGeocentricDeclination);
    astroObject = AstroObject.JUPITER.index;
    planetSunDistance = Coord.instance.astronomicalUnit(jd, 3);
    earthSunDistance = Coord.instance.astronomicalUnit(jd, 99);
    planetEarthDistance = planet.ApparentGeocentricDistance;
    phaseAngle = calculatePhaseAngle();
    magnitude = calculateMagnitude(3);
  }
}

/// Saturn
class Saturn extends Planet {
  final int planetId = 5;
  
  Saturn(double jdTT) {
    jd = jdTT;
    var planet = calculatePlanetaryDetails(jd, planetId, 1);
    eq = Equatorial(planet.ApparentGeocentricRA, planet.ApparentGeocentricDeclination);
    astroObject = AstroObject.SATURN.index;
    planetSunDistance = Coord.instance.astronomicalUnit(jd, 4);
    earthSunDistance = Coord.instance.astronomicalUnit(jd, 99);
    planetEarthDistance = planet.ApparentGeocentricDistance;
    phaseAngle = calculatePhaseAngle();
    magnitude = _calculateSaturnMagnitude();
  }

  double _calculateSaturnMagnitude() {
    var saturnRings = saturnRingDetails(jd, 1);
    return saturnMagnitude(planetSunDistance!, planetEarthDistance!, saturnRings.DeltaU, saturnRings.B);
  }
}

/// Uranus
class Uranus extends Planet {
  final int planetId = 6;
  
  Uranus(double jdTT) {
    jd = jdTT;
    var planet = calculatePlanetaryDetails(jd, planetId, 1);
    eq = Equatorial(planet.ApparentGeocentricRA, planet.ApparentGeocentricDeclination);
    astroObject = AstroObject.URANUS.index;
    planetSunDistance = Coord.instance.astronomicalUnit(jd, 5);
    earthSunDistance = Coord.instance.astronomicalUnit(jd, 99);
    planetEarthDistance = planet.ApparentGeocentricDistance;
    phaseAngle = calculatePhaseAngle();
    magnitude = calculateMagnitude(5);
  }
}

/// Neptune
class Neptune extends Planet {
  final int planetId = 7;
  
  Neptune(double jdTT) {
    jd = jdTT;
    var planet = calculatePlanetaryDetails(jd, planetId, 1);
    eq = Equatorial(planet.ApparentGeocentricRA, planet.ApparentGeocentricDeclination);
    astroObject = AstroObject.NEPTUNE.index;
    planetSunDistance = Coord.instance.astronomicalUnit(jd, 6);
    earthSunDistance = Coord.instance.astronomicalUnit(jd, 99);
    planetEarthDistance = planet.ApparentGeocentricDistance;
    phaseAngle = calculatePhaseAngle();
    magnitude = calculateMagnitude(6);
  }
}
