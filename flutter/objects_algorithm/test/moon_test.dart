import 'dart:math';
import 'package:objects_algorithm/bind.dart';
import 'package:objects_algorithm/coord.dart';
import 'package:objects_algorithm/julian.dart';
import 'package:objects_algorithm/moon.dart';

/// ============================================================
/// Moon coordinate calculation example
/// ============================================================
/// 
/// Demonstrates the unified API of the Moon class
/// 
/// Reference data from Stellarium (JNOW):
///   RA: 10h 11m 18.0s, DEC: +11°18'19.9"
///   Az/Alt: 344°02'04.6", -46°06'00.3"
///   Time: 2026-02-03 12:30 Beijing time (UTC+8)
///   Location: Suzhou (31.2552°N, 120.7350°E)

void main() {
  print('=' * 60);
  print('Moon coordinate calculation example (unified API)');
  print('=' * 60);

  // ============================================================
  // 1. Setup
  // ============================================================
  Julian julian = Julian();

  // Observer location
  Geography location = Geography(31.2552, 120.7350);  // Suzhou

  // Observation time (local time → UTC → TT)
  DateTime localTime = DateTime(2026, 2, 3, 12, 30, 0);
  DateTime utcTime = localTime.toUtc();
  double jdUtc = julian.timeToJD(utcTime);  // UTC Julian Day
  double jdTT = Julian.uTC2TT(jdUtc);       // TT Julian Day

  print('\n[Observing conditions]');
  print('  Local time: $localTime');
  print('  UTC time:   $utcTime');
  print('  JD (UTC): ${jdUtc.toStringAsFixed(6)}');
  print('  JD (TT):  ${jdTT.toStringAsFixed(6)}');
  print('  Location: ${location.lat}°N, ${location.lon}°E');

  // ============================================================
  // 2. Compute the Moon's position with the unified API
  // ============================================================
  print('\n' + '=' * 60);
  print('[Unified API example]');
  print('=' * 60);

  // Create the Moon object (takes TT)
  Moon moon = Moon(jdTT);

  // JNow equatorial coordinates
  Equatorial eqJNow = moon.getEquatorialJNow(location, jdUtc: jdUtc);
  print('\nMoon JNow equatorial coordinates:');
  print('  RA:  ${formatRA(eqJNow.ra)}');
  print('  DEC: ${formatDec(eqJNow.dec)}');

  // J2000 equatorial coordinates
  Equatorial eqJ2000 = moon.getEquatorialJ2000(location, jdUtc: jdUtc);
  print('\nMoon J2000 equatorial coordinates:');
  print('  RA:  ${formatRA(eqJ2000.ra)}');
  print('  DEC: ${formatDec(eqJ2000.dec)}');

  // Horizontal coordinates
  Horizontal hz = moon.getHorizontal(location, jdUtc: jdUtc);
  print('\nMoon horizontal coordinates:');
  print('  Az:  ${formatDMS(hz.az)}');
  print('  Alt: ${formatDMS(hz.alt)}');

  // Additional info
  print('\nMoon additional info:');
  print('  Distance: ${moon.radiusVector!.toStringAsFixed(0)} km');
  print('  Parallax: ${(asin(6378.14 / moon.radiusVector!) * 180 / pi * 60).toStringAsFixed(1)}\'');
  print('  Illumination: ${(moon.illuminated() * 100).toStringAsFixed(1)}%');

  // ============================================================
  // 3. Verification: compare with Stellarium
  // ============================================================
  print('\n' + '=' * 60);
  print('[Verification] Compare with Stellarium');
  print('=' * 60);

  // Stellarium reference values
  double refRA = 10 + 11.0/60 + 18.0/3600;
  double refDec = 11 + 18.0/60 + 19.9/3600;
  double refAz = 344 + 2.0/60 + 4.6/3600;
  double refAlt = -(46 + 6.0/60 + 0.3/3600);

  print('\nStellarium reference values:');
  print('  RA:  ${formatRA(refRA)}');
  print('  DEC: ${formatDec(refDec)}');
  print('  Az:  ${formatDMS(refAz)}');
  print('  Alt: ${formatDMS(refAlt)}');

  double raErr = (eqJNow.ra - refRA) * 15 * 3600;
  double decErr = (eqJNow.dec - refDec) * 3600;
  double azErr = (hz.az - refAz) * 60;
  double altErr = (hz.alt - refAlt) * 60;

  print('\nComputation error:');
  print('  ΔRA:  ${raErr.toStringAsFixed(2)}" (${(raErr/15).toStringAsFixed(2)} s of time)');
  print('  ΔDEC: ${decErr.toStringAsFixed(2)}"');
  print('  ΔAz:  ${azErr.toStringAsFixed(2)}\'');
  print('  ΔAlt: ${altErr.toStringAsFixed(2)}\'');

  // ============================================================
  // 4. App usage example
  // ============================================================
  print('\n' + '=' * 60);
  print('[App usage example]');
  print('=' * 60);
  print('''
// === Compute the Moon's position ===
DateTime utc = DateTime.now().toUtc();
double jdUtc = julian.timeToJD(utc);
double jdTT = Julian.uTC2TT(jdUtc);

Geography location = Geography(latitude, longitude);
Moon moon = Moon(jdTT);

// JNow equatorial coordinates (for display / comparison)
Equatorial eqJNow = moon.getEquatorialJNow(location, jdUtc: jdUtc);

// J2000 equatorial coordinates (for catalog comparison)
Equatorial eqJ2000 = moon.getEquatorialJ2000(location, jdUtc: jdUtc);

// Horizontal coordinates (for telescope pointing)
Horizontal hz = moon.getHorizontal(location, jdUtc: jdUtc);

// Additional info
double illumination = moon.illuminated();  // illuminated fraction (0-1)
double distance = moon.radiusVector!;      // distance (km)
''');
}

// ============================================================
// Formatting helpers
// ============================================================

String formatRA(double ra) {
  ra = ra % 24;
  if (ra < 0) ra += 24;
  int h = ra.floor();
  double minFloat = (ra - h) * 60;
  int m = minFloat.floor();
  double s = (minFloat - m) * 60;
  return '${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m ${s.toStringAsFixed(2)}s';
}

String formatDec(double dec) {
  String sign = dec >= 0 ? '+' : '-';
  dec = dec.abs();
  int d = dec.floor();
  double minFloat = (dec - d) * 60;
  int m = minFloat.floor();
  double s = (minFloat - m) * 60;
  return '$sign${d.toString().padLeft(2, '0')}° ${m.toString().padLeft(2, '0')}\' ${s.toStringAsFixed(2)}"';
}

String formatDMS(double deg) {
  String sign = deg >= 0 ? '' : '-';
  deg = deg.abs();
  int d = deg.floor();
  double minFloat = (deg - d) * 60;
  int m = minFloat.floor();
  double s = (minFloat - m) * 60;
  return '$sign${d}° ${m.toString().padLeft(2, '0')}\' ${s.toStringAsFixed(1)}"';
}
