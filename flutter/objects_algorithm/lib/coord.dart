import 'bind.dart';
import 'julian.dart';

class Equatorial {
  double ra;
  double dec;

  double StandardEpoch_J2000_0 = 2451545.0;

  Equatorial(this.ra, this.dec);

  /// J2000 -> JNow (precession + nutation)
  /// [jdNow] Julian day of the target epoch
  precessedCoordinates(double jdNow) {
    // 1. Apply precession first
    var newCoord = precessEquatorial(ra, dec, StandardEpoch_J2000_0, jdNow);
    double raPrec = newCoord.X;
    double decPrec = newCoord.Y;
    
    // 2. Then add the nutation correction
    double nutLon = nutationInLongitude(jdNow);      // nutation in longitude (arcsec)
    double nutObl = nutationInObliquity(jdNow);      // nutation in obliquity (arcsec)
    double obliquity = trueObliquityOfEcliptic(jdNow); // true obliquity of the ecliptic (deg)
    
    // Nutation corrections in RA and Dec (arcsec)
    double deltaRA = nutationInRightAscension(raPrec, decPrec, obliquity, nutLon, nutObl);
    double deltaDec = nutationInDeclination(raPrec, obliquity, nutLon, nutObl);
    
    // Apply the nutation correction
    ra = raPrec + deltaRA / 3600 / 15;  // arcsec -> hours
    dec = decPrec + deltaDec / 3600;    // arcsec -> degrees

    return this;
  }

  /// JNow -> J2000 (precession + nutation)
  /// [jdNow] Julian day of the current epoch
  regressCoordinates(double jdNow) {
    // 1. Remove the nutation correction first
    double nutLon = nutationInLongitude(jdNow);      // nutation in longitude (arcsec)
    double nutObl = nutationInObliquity(jdNow);      // nutation in obliquity (arcsec)
    double obliquity = trueObliquityOfEcliptic(jdNow); // true obliquity of the ecliptic (deg)
    
    // Nutation corrections in RA and Dec (arcsec)
    double deltaRA = nutationInRightAscension(ra, dec, obliquity, nutLon, nutObl);
    double deltaDec = nutationInDeclination(ra, obliquity, nutLon, nutObl);
    
    // Remove the nutation correction (subtract nutation)
    double raCorrected = ra - deltaRA / 3600 / 15;  // arcsec -> hours
    double decCorrected = dec - deltaDec / 3600;    // arcsec -> degrees
    
    // 2. Then precess back to J2000
    var newCoord = precessEquatorial(raCorrected, decCorrected, jdNow, StandardEpoch_J2000_0);
    ra = newCoord.X;
    dec = newCoord.Y;

    return this;
  }

  /// J2000 -> JNow (precession + nutation)
  /// Alias of [precessedCoordinates].
  j2k_to_jnow(double jdNow) => precessedCoordinates(jdNow);

  /// JNow -> J2000 (precession + nutation)
  /// Alias of [regressCoordinates].
  jnow_to_j2k(double jdNow) => regressCoordinates(jdNow);

}

class Horizontal {
  double az;
  double alt;
  String? direction;

  Horizontal(this.az, this.alt);
}

class Geography {
  double lat;
  double lon;
  double alt;

  Geography(this.lat, this.lon, [this.alt = 0]);
}

class Ecliptic {
  double celestialLongitude;
  double celestialLatitude;
  double epoch;
  double equinox;

  double StandardEpoch_J2000_0 = 2451545.0;

  Ecliptic(this.celestialLatitude, this.celestialLongitude, [this.epoch = 2451545.0, this.equinox = 2451545.0]);

  precessedCoordinates(double newEquinox) {
    var newCoord = precessEcliptic(celestialLongitude, celestialLatitude, StandardEpoch_J2000_0, newEquinox);
    celestialLongitude = newCoord.X;
    celestialLatitude = newCoord.Y;

    return this;
  }
}

class Coord {
  static final Coord _instance = Coord._internal();
  Coord._internal();
  static Coord get instance => _instance;

  /// Equatorial to horizontal coordinates.
  /// [jd] Julian day (UTC)
  /// [eq] Equatorial coordinates (RA: hours, DEC: degrees)
  /// [obs] Observer location (lat/lon in degrees, east positive)
  /// Returns: azimuth (clockwise from north, 0-360°) and altitude (with atmospheric refraction).
  Horizontal eqToHz(double jd, Equatorial eq, Geography obs) {
    var julian = Julian();
    double gast = julian.getGAST(jd);  // apparent sidereal time (includes nutation)
    // LAST = GAST + longitude (east positive, in hours)
    double lst = gast + obs.lon / 15;
    // Local hour angle = LST - RA
    double lha = lst - eq.ra;
    // Normalise to 0-24 hours
    lha = _positiveTruncatingRemainder(lha, 24);

    // AA+ returns X = azimuth (clockwise from south), Y = altitude (true altitude)
    var hz = equatorial2Horizontal(lha, eq.dec, obs.lat);
    
    // Azimuth: clockwise from south -> clockwise from north
    double az = _positiveTruncatingRemainder(hz.X + 180, 360);
    
    // Atmospheric refraction: true altitude -> apparent altitude
    // Use RefractionFromTrue because hz.Y is the true altitude
    double alt = hz.Y + _refractionFromTrue(hz.Y);

    Horizontal hzObj = Horizontal(az, alt);
    hzObj.direction = azimuth2Direction(az);
    return hzObj;
  }

  /// Equatorial to horizontal coordinates (no atmospheric refraction correction).
  Horizontal eqToHzNoRefraction(double jd, Equatorial eq, Geography obs) {
    var julian = Julian();
    double gast = julian.getGAST(jd);  // apparent sidereal time (includes nutation)
    double lst = gast + obs.lon / 15;
    double lha = lst - eq.ra;
    lha = _positiveTruncatingRemainder(lha, 24);

    var hz = equatorial2Horizontal(lha, eq.dec, obs.lat);
    double az = _positiveTruncatingRemainder(hz.X + 180, 360);

    Horizontal hzObj = Horizontal(az, hz.Y);
    hzObj.direction = azimuth2Direction(az);
    return hzObj;
  }

  /// Horizontal to equatorial coordinates.
  /// [jd] Julian day (UTC)
  /// [hz] Horizontal coordinates (az: degrees clockwise from north, alt: apparent altitude in degrees)
  /// [obs] Observer location
  /// [apparentAltitude] Whether the altitude is apparent (includes refraction); defaults to true
  /// Returns: equatorial coordinates (RA: hours, DEC: degrees).
  Equatorial hzToEq(double jd, Horizontal hz, Geography obs, {bool apparentAltitude = true}) {
    // Azimuth: clockwise from north -> clockwise from south (AA+ convention)
    double azSouth = _positiveTruncatingRemainder(hz.az - 180, 360);
    
    // For an apparent altitude, remove refraction to get the true altitude
    double trueAlt = hz.alt;
    if (apparentAltitude) {
      trueAlt = hz.alt - _refractionFromApparent(hz.alt);
    }
    
    // AA+ returns X = hour angle (hours), Y = declination (degrees)
    var eq = horizontal2Equatorial(azSouth, trueAlt, obs.lat);

    var julian = Julian();
    double gast = julian.getGAST(jd);  // apparent sidereal time (includes nutation)
    double lst = gast + obs.lon / 15;
    // RA = LST - HA
    double ra = _positiveTruncatingRemainder(lst - eq.X, 24);

    return Equatorial(ra, eq.Y);
  }

  // Ecliptic to equatorial coordinates
  Equatorial eclToEq(double lon, double lat, double eclestialEpoch) {
    // Obliquity of the ecliptic
    double eclipticObliquity = trueObliquityOfEcliptic(eclestialEpoch);
    var eq = ecliptic2Equatorial(lon, lat, eclipticObliquity);

    return Equatorial(eq.X, eq.Y);
  }

  String azimuth2Direction(double az) {
    List<String> directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
    int index = ((az + 22.5) / 45.0).floor() % 8;
    return directions[index];
  }

  // Distance to the Sun
  double astronomicalUnit(double jd, int planet, [int highPrecision = 1]) {
    return radiusVector(jd, planet, highPrecision);
  }

  /// Atmospheric refraction: true altitude -> refraction amount.
  /// Used to get apparent from true altitude: apparent = true + refraction.
  double _refractionFromTrue(double trueAlt) {
    return refractionFromTrueWithAltitude(trueAlt, 1010, 10);
  }

  /// Atmospheric refraction: apparent altitude -> refraction amount.
  /// Used to get true from apparent altitude: true = apparent - refraction.
  double _refractionFromApparent(double apparentAlt) {
    return refractionFromApparentWithAltitude(apparentAlt, 1010, 10);
  }

  // Truncating remainder
  double _positiveTruncatingRemainder(double dividend, double divisor) {
    double truncated = dividend % divisor;
    // If the remainder is negative, add the absolute value of the divisor
    if (truncated < 0) {
      truncated += divisor.abs();
    }

    return truncated;
  }

}