import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:objects_algorithm/bind.dart';
import 'package:objects_algorithm/coord.dart';
import 'package:objects_algorithm/julian.dart';

/// Nutation correction test
/// Tests the JNow -> J2000 and J2000 -> JNow conversions

void main() {
  test('prints nutation correction conversion', () {
  print('=' * 60);
  print('M31/M32 coordinate conversion test');
  print('=' * 60);
  
  // JD of the current time
  DateTime now = DateTime.now().toUtc();
  Julian julian = Julian();
  double jdNow = julian.timeToJD(now);
  
  print('\nTest time: $now');
  print('Julian Day: $jdNow');
  
  // ============================================================
  // M31/M32 specific test
  // ============================================================
  print('\n' + '=' * 60);
  print('M31/M32 coordinate conversion');
  print('=' * 60);
  
  // M31 J2000 coordinates: RA 00hr 42' 44", DEC 41º 16' 08"
  double m31_j2000_ra = 0 + 42.0/60 + 44.0/3600;  // to hours
  double m31_j2000_dec = 41 + 16.0/60 + 8.0/3600; // to degrees
  
  // M32 JNow coordinates: RA 00hr 44' 08", DEC 41º 00' 28"
  double m32_jnow_ra = 0 + 44.0/60 + 8.0/3600;    // to hours
  double m32_jnow_dec = 41 + 0.0/60 + 28.0/3600;  // to degrees
  
  print('\n--- M31: J2000 -> JNow ---');
  print('M31 J2000 input coordinates: RA=${formatRA(m31_j2000_ra)}, DEC=${formatDec(m31_j2000_dec)}');
  
  // M31 J2000 -> JNow
  Equatorial m31_with_nut = Equatorial(m31_j2000_ra, m31_j2000_dec);
  m31_with_nut.precessedCoordinates(jdNow);
  print('M31 JNow: RA=${formatRA(m31_with_nut.ra)}, DEC=${formatDec(m31_with_nut.dec)}');
  
  print('\n--- M32: JNow -> J2000 ---');
  print('M32 JNow input coordinates: RA=${formatRA(m32_jnow_ra)}, DEC=${formatDec(m32_jnow_dec)}');
  
  // M32 JNow -> J2000
  Equatorial m32_with_nut = Equatorial(m32_jnow_ra, m32_jnow_dec);
  m32_with_nut.regressCoordinates(jdNow);
  print('M32 J2000: RA=${formatRA(m32_with_nut.ra)}, DEC=${formatDec(m32_with_nut.dec)}');
  
  // Print decimal values for easy comparison
  print('\n--- Decimal values (for comparison) ---');
  print('M31 JNow: RA=${m31_with_nut.ra.toStringAsFixed(6)}h, DEC=${m31_with_nut.dec.toStringAsFixed(6)}°');
  print('M32 J2000: RA=${m32_with_nut.ra.toStringAsFixed(6)}h, DEC=${m32_with_nut.dec.toStringAsFixed(6)}°');
  
  // Show the current nutation parameters
  double nutLon = nutationInLongitude(jdNow);
  double nutObl = nutationInObliquity(jdNow);
  double trueObl = trueObliquityOfEcliptic(jdNow);
  double meanObl = meanObliquityOfEcliptic(jdNow);
  
  print('\nCurrent nutation parameters:');
  print('  Nutation in longitude: ${nutLon.toStringAsFixed(4)}" (arcsec)');
  print('  Nutation in obliquity: ${nutObl.toStringAsFixed(4)}" (arcsec)');
  print('  Mean obliquity: ${meanObl.toStringAsFixed(6)}°');
  print('  True obliquity: ${trueObl.toStringAsFixed(6)}°');
  
  print('\n' + '=' * 60);
  print('Test 1: J2000 -> JNow -> J2000 round trip');
  print('=' * 60);
  
  // Stars at a range of positions
  List<Map<String, dynamic>> testStars = [
    {'name': 'Polaris', 'ra': 2.5302, 'dec': 89.2641},      // high declination
    {'name': 'Vega', 'ra': 18.6156, 'dec': 38.7837},        // mid declination
    {'name': 'Sirius', 'ra': 6.7525, 'dec': -16.7161},      // negative declination
    {'name': 'Betelgeuse', 'ra': 5.9195, 'dec': 7.4070},    // low declination
    {'name': 'Acrux (Alpha Crucis)', 'ra': 12.4433, 'dec': -63.0990},    // high negative declination
    {'name': 'On the celestial equator', 'ra': 0.0, 'dec': 0.0},                      // equator
  ];
  
  for (var star in testStars) {
    print('\n--- ${star['name']} ---');
    print('J2000 input coordinates: RA=${formatRA(star['ra'])}, DEC=${formatDec(star['dec'])}');
    
    // 1. J2000 -> JNow
    Equatorial eqWithNut = Equatorial(star['ra'], star['dec']);
    eqWithNut.precessedCoordinates(jdNow);
    double jnowRaWithNut = eqWithNut.ra;
    double jnowDecWithNut = eqWithNut.dec;
    
    print('JNow: RA=${formatRA(jnowRaWithNut)}, DEC=${formatDec(jnowDecWithNut)}');
    
    // 2. JNow -> J2000 round trip
    Equatorial eqBackWithNut = Equatorial(jnowRaWithNut, jnowDecWithNut);
    eqBackWithNut.regressCoordinates(jdNow);
    
    // Round-trip error
    double raErrorWithNut = raDiffArcSeconds(eqBackWithNut.ra, star['ra']);
    double decErrorWithNut = (eqBackWithNut.dec - star['dec']) * 3600;      // arcsec
    
    print('Round-trip error: ΔRA=${raErrorWithNut.toStringAsFixed(4)}", ΔDec=${decErrorWithNut.toStringAsFixed(4)}"');
  }
  
  print('\n' + '=' * 60);
  print('Test 2: realistic scenario - observed JNow coordinates to J2000');
  print('=' * 60);
  
  // Simulate JNow coordinates measured by a telescope
  // Given a JNow position, convert it to J2000 for catalog matching
  print('\nSuppose the telescope observes a target in the JNow epoch:');
  
  // First generate "simulated observed" JNow coordinates (with nutation) from a known J2000 position
  double knownJ2000_RA = 5.9195;   // Betelgeuse
  double knownJ2000_Dec = 7.4070;
  
  Equatorial simObserved = Equatorial(knownJ2000_RA, knownJ2000_Dec);
  simObserved.precessedCoordinates(jdNow);  // simulated real JNow observation
  
  print('Simulated observed JNow coordinates: RA=${formatRA(simObserved.ra)}, DEC=${formatDec(simObserved.dec)}');
  print('True J2000 coordinates: RA=${formatRA(knownJ2000_RA)}, DEC=${formatDec(knownJ2000_Dec)}');
  
  // Test: convert the "observed" JNow coordinates back to J2000
  Equatorial testWithNut = Equatorial(simObserved.ra, simObserved.dec);
  testWithNut.regressCoordinates(jdNow);
  
  print('\nConverted back to J2000:');
  print('RA=${formatRA(testWithNut.ra)}, DEC=${formatDec(testWithNut.dec)}');
  
  double errorWithNut_RA = raDiffArcSeconds(testWithNut.ra, knownJ2000_RA);
  double errorWithNut_Dec = (testWithNut.dec - knownJ2000_Dec) * 3600;
  
  print('\nError:');
  print('ΔRA=${errorWithNut_RA.toStringAsFixed(4)}", ΔDec=${errorWithNut_Dec.toStringAsFixed(4)}"');
  
  double totalErrorWithNut = sqrt(errorWithNut_RA * errorWithNut_RA + errorWithNut_Dec * errorWithNut_Dec);
  
  print('\nTotal angular error:');
  print('${totalErrorWithNut.toStringAsFixed(4)}" (${(totalErrorWithNut/3600).toStringAsFixed(6)}°)');
  
  print('\n' + '=' * 60);
  print('Conclusion');
  print('=' * 60);
  print('J2000/JNow round-trip error is about ${totalErrorWithNut.toStringAsFixed(4)}"');
  });
}

double raDiffArcSeconds(double actual, double expected) {
  double diffHours = (actual - expected + 12) % 24 - 12;
  return diffHours * 15 * 3600;
}

/// Formats RA (hours) as HH:MM:SS.ss
String formatRA(double ra) {
  if (ra < 0) ra += 24;
  if (ra >= 24) ra -= 24;
  int h = ra.floor();
  double minFloat = (ra - h) * 60;
  int m = minFloat.floor();
  double s = (minFloat - m) * 60;
  return '${h.toString().padLeft(2, '0')}h${m.toString().padLeft(2, '0')}m${s.toStringAsFixed(2)}s';
}

/// Formats DEC (degrees) as ±DD°MM'SS.ss"
String formatDec(double dec) {
  String sign = dec >= 0 ? '+' : '-';
  dec = dec.abs();
  int d = dec.floor();
  double minFloat = (dec - d) * 60;
  int m = minFloat.floor();
  double s = (minFloat - m) * 60;
  return '$sign${d.toString().padLeft(2, '0')}°${m.toString().padLeft(2, '0')}\'${s.toStringAsFixed(2)}"';
}
