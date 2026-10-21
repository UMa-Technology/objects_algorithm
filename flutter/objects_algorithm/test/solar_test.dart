import 'dart:math';
import 'package:objects_algorithm/bind.dart';
import 'package:objects_algorithm/coord.dart';
import 'package:objects_algorithm/julian.dart';
import 'package:objects_algorithm/solar.dart';

/// ============================================================
/// Sun coordinate calculation example
/// ============================================================
/// 
/// Demonstrates the unified API of the Solar class
/// 
/// Reference data from Stellarium (JNOW):
///   RA: 21h 07m 14.2s, DEC: -16°31'42.8"
///   Az/Alt: 186°11'47.8", +42°00'19.9"
///   Time: 2026-02-03 12:30 Beijing time (UTC+8)
///   Location: Suzhou (31.2552°N, 120.7350°E)

void main() {
  print('=' * 60);
  print('Sun coordinate calculation example (unified API)');
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
  // 2. Compute the Sun's position with the unified API
  // ============================================================
  print('\n' + '=' * 60);
  print('[Unified API example]');
  print('=' * 60);

  // Create the Solar object (takes TT)
  Solar sun = Solar(jdTT);

  // JNow equatorial coordinates
  Equatorial eqJNow = sun.getEquatorialJNow();
  print('\nSun JNow equatorial coordinates:');
  print('  RA:  ${formatRA(eqJNow.ra)}');
  print('  DEC: ${formatDec(eqJNow.dec)}');

  // J2000 equatorial coordinates
  Equatorial eqJ2000 = sun.getEquatorialJ2000();
  print('\nSun J2000 equatorial coordinates:');
  print('  RA:  ${formatRA(eqJ2000.ra)}');
  print('  DEC: ${formatDec(eqJ2000.dec)}');

  // Horizontal coordinates
  Horizontal hz = sun.getHorizontal(location, jdUtc: jdUtc);
  print('\nSun horizontal coordinates:');
  print('  Az:  ${formatDMS(hz.az)}');
  print('  Alt: ${formatDMS(hz.alt)}');

  // ============================================================
  // 3. Verification: compare with Stellarium
  // ============================================================
  print('\n' + '=' * 60);
  print('[Verification] Compare with Stellarium');
  print('=' * 60);

  // Stellarium reference values
  double refRA = 21 + 7.0/60 + 14.2/3600;
  double refDec = -(16 + 31.0/60 + 42.8/3600);
  double refAz = 186 + 11.0/60 + 47.8/3600;
  double refAlt = 42 + 0.0/60 + 19.9/3600;

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
// === Compute the Sun's position ===
DateTime utc = DateTime.now().toUtc();
double jdUtc = julian.timeToJD(utc);
double jdTT = Julian.uTC2TT(jdUtc);

Geography location = Geography(latitude, longitude);
Solar sun = Solar(jdTT);

// JNow equatorial coordinates (for display / comparison)
Equatorial eqJNow = sun.getEquatorialJNow();

// J2000 equatorial coordinates (for catalog comparison)
Equatorial eqJ2000 = sun.getEquatorialJ2000();

// Horizontal coordinates (to tell day from night)
Horizontal hz = sun.getHorizontal(location, jdUtc: jdUtc);

// Day / night
bool isDaytime = hz.alt > 0;
bool isTwilight = hz.alt > -18 && hz.alt <= 0;  // twilight
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
