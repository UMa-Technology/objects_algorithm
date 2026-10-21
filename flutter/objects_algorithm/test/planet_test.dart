import 'dart:math';
import 'package:objects_algorithm/bind.dart';
import 'package:objects_algorithm/coord.dart';
import 'package:objects_algorithm/julian.dart';
import 'package:objects_algorithm/planet.dart';

/// ============================================================
/// Planet coordinate calculation example (Jupiter)
/// ============================================================
/// 
/// Demonstrates the unified API of the Planet class
/// 
/// Reference data from Stellarium (JNOW):
///   RA: 07h 14m 23.3s, DEC: +22°38'54.6"
///   Az/Alt: 034°31'54.3", -27°30'05.4"
///   Time: 2026-02-03 12:30 Beijing time (UTC+8)
///   Location: Suzhou (31.2552°N, 120.7350°E)

void main() {
  print('=' * 60);
  print('Planet coordinate calculation example (unified API)');
  print('=' * 60);

  // ============================================================
  // 1. Setup
  // ============================================================
  Julian julian = Julian();

  // Observer location
  Geography location = Geography(31.2552, 120.7350);  // Suzhou

  // Observation time
  DateTime localTime = DateTime(2026, 2, 3, 12, 30, 0);
  DateTime utcTime = localTime.toUtc();
  double jdUtc = julian.timeToJD(utcTime);
  double jdTT = Julian.uTC2TT(jdUtc);

  print('\n[Observing conditions]');
  print('  Local time: $localTime');
  print('  UTC time:   $utcTime');
  print('  JD (UTC): ${jdUtc.toStringAsFixed(6)}');
  print('  JD (TT):  ${jdTT.toStringAsFixed(6)}');
  print('  Location: ${location.lat}°N, ${location.lon}°E');

  // ============================================================
  // 2. Compute Jupiter's position with the unified API
  // ============================================================
  print('\n' + '=' * 60);
  print('[Jupiter position]');
  print('=' * 60);

  // Create the Jupiter object (takes TT)
  Jupiter jupiter = Jupiter(jdTT);

  // JNow equatorial coordinates
  Equatorial eqJNow = jupiter.getEquatorialJNow();
  print('\nJupiter JNow equatorial coordinates:');
  print('  RA:  ${formatRA(eqJNow.ra)}');
  print('  DEC: ${formatDec(eqJNow.dec)}');

  // J2000 equatorial coordinates
  Equatorial eqJ2000 = jupiter.getEquatorialJ2000();
  print('\nJupiter J2000 equatorial coordinates:');
  print('  RA:  ${formatRA(eqJ2000.ra)}');
  print('  DEC: ${formatDec(eqJ2000.dec)}');

  // Horizontal coordinates
  Horizontal hz = jupiter.getHorizontal(location, jdUtc: jdUtc);
  print('\nJupiter horizontal coordinates:');
  print('  Az:  ${formatDMS(hz.az)} (${hz.direction})');
  print('  Alt: ${formatDMS(hz.alt)}');

  // Additional info
  print('\nJupiter additional info:');
  print('  Magnitude: ${jupiter.magnitude?.toStringAsFixed(2)}');
  print('  Phase angle: ${jupiter.phaseAngle?.toStringAsFixed(2)}°');
  print('  Distance: ${jupiter.planetEarthDistance?.toStringAsFixed(4)} AU');

  // ============================================================
  // 3. Verification: compare with Stellarium
  // ============================================================
  print('\n' + '=' * 60);
  print('[Verification] Compare with Stellarium');
  print('=' * 60);

  // Stellarium reference values
  double refRA = 7 + 14.0/60 + 23.3/3600;
  double refDec = 22 + 38.0/60 + 54.6/3600;
  double refAz = 34 + 31.0/60 + 54.3/3600;
  double refAlt = -(27 + 30.0/60 + 5.4/3600);

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
  // 4. Overview of all planet positions
  // ============================================================
  print('\n' + '=' * 60);
  print('[All planet positions]');
  print('=' * 60);

  Map<String, Planet> planets = {
    'Mercury': Mercury(jdTT),
    'Venus': Venus(jdTT),
    'Mars': Mars(jdTT),
    'Jupiter': Jupiter(jdTT),
    'Saturn': Saturn(jdTT),
    'Uranus': Uranus(jdTT),
    'Neptune': Neptune(jdTT),
  };

  print('\nPlanet  | RA           | DEC          | Mag   | Alt');
  print('-' * 60);
  
  for (var entry in planets.entries) {
    var eq = entry.value.getEquatorialJNow();
    var h = entry.value.getHorizontal(location, jdUtc: jdUtc);
    var mag = entry.value.magnitude?.toStringAsFixed(1).padLeft(5) ?? '  N/A';
    var altStr = h.alt >= 0 ? '↑${h.alt.toStringAsFixed(1)}°' : '↓${h.alt.abs().toStringAsFixed(1)}°';
    print('${entry.key.padRight(7)} | ${formatRA(eq.ra).padRight(12)} | ${formatDec(eq.dec).padRight(12)} | $mag | $altStr');
  }

  // ============================================================
  // 5. App usage example
  // ============================================================
  print('\n' + '=' * 60);
  print('[App usage example]');
  print('=' * 60);
  print('''
// === Compute a planet's position ===
DateTime utc = DateTime.now().toUtc();
double jdUtc = julian.timeToJD(utc);
double jdTT = Julian.uTC2TT(jdUtc);

Geography location = Geography(latitude, longitude);

// Create a planet object (Jupiter here)
Jupiter jupiter = Jupiter(jdTT);

// JNow equatorial coordinates
Equatorial eqJNow = jupiter.getEquatorialJNow();

// J2000 equatorial coordinates
Equatorial eqJ2000 = jupiter.getEquatorialJ2000();

// Horizontal coordinates
Horizontal hz = jupiter.getHorizontal(location, jdUtc: jdUtc);

// Additional info
double mag = jupiter.magnitude!;      // magnitude
double distance = jupiter.planetEarthDistance!;  // distance (AU)

// Is it above the horizon?
bool isVisible = hz.alt > 0;
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
  return '${h.toString().padLeft(2, '0')}h${m.toString().padLeft(2, '0')}m${s.toStringAsFixed(1)}s';
}

String formatDec(double dec) {
  String sign = dec >= 0 ? '+' : '-';
  dec = dec.abs();
  int d = dec.floor();
  double minFloat = (dec - d) * 60;
  int m = minFloat.floor();
  double s = (minFloat - m) * 60;
  return '$sign${d.toString().padLeft(2, '0')}°${m.toString().padLeft(2, '0')}\'${s.toStringAsFixed(0)}"';
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
