import 'dart:math';
import 'package:objects_algorithm/astro.dart';
import 'package:objects_algorithm/bind.dart';
import 'package:objects_algorithm/coord.dart';
import 'package:objects_algorithm/julian.dart';

/// ============================================================
/// Star / deep-sky object coordinate conversion example
/// ============================================================
/// 
/// Demonstrates converting between equatorial and horizontal coordinates
/// 
/// Coordinate systems:
/// - J2000: standard catalog coordinates (epoch 2000.0)
/// - JNow:  coordinates of the current epoch (precession + nutation applied)
/// - Alt/Az: horizontal coordinates (observer's view)
/// 
/// Conversion pipeline:
/// J2000 <-> JNow (precession + nutation) <-> Alt/Az (sidereal time + observer location)
/// 
/// Reference data: M31, the Andromeda Galaxy
///   J2000: RA=00h42m44s, DEC=+41°16'08"
///   Alt/Az at test time taken from Telescopius

void main() {
  print('=' * 60);
  print('Star / deep-sky object coordinate conversion example');
  print('=' * 60);

  // ============================================================
  // 1. Setup
  // ============================================================
  Julian julian = Julian();
  Coord coord = Coord.instance;

  // Observer location
  Geography location = Geography(31.2552, 120.7350);  // Suzhou

  // Observation time
  DateTime localTime = DateTime(2026, 2, 3, 12, 30, 0);
  DateTime utcTime = localTime.toUtc();
  double jd = julian.timeToJD(utcTime);

  // Sidereal time
  double gast = julian.getGAST(jd);
  double last = gast + location.lon / 15;
  if (last >= 24) last -= 24;

  print('\n[Observing conditions]');
  print('  Local time: $localTime');
  print('  UTC time:   $utcTime');
  print('  JD: ${jd.toStringAsFixed(6)}');
  print('  GAST: ${formatRA(gast)}');
  print('  LAST: ${formatRA(last)}');
  print('  Location: ${location.lat}°N, ${location.lon}°E');

  // ============================================================
  // 2. J2000 → JNow → Alt/Az (forward conversion)
  // ============================================================
  print('\n' + '=' * 60);
  print('[Example 1] J2000 → Alt/Az (forward computation for a star)');
  print('=' * 60);

  // M31 (Andromeda Galaxy) J2000 coordinates
  double m31_ra_j2000 = 0 + 42.0/60 + 44.0/3600;   // 00h 42m 44s
  double m31_dec_j2000 = 41 + 16.0/60 + 8.0/3600;  // +41° 16' 08"

  print('\nM31 J2000 coordinates:');
  print('  RA:  ${formatRA(m31_ra_j2000)}');
  print('  DEC: ${formatDec(m31_dec_j2000)}');

  // Step 1: J2000 → JNow (precession + nutation)
  Equatorial m31_jnow = Equatorial(m31_ra_j2000, m31_dec_j2000);
  m31_jnow.precessedCoordinates(jd);

  print('\nM31 JNow coordinates:');
  print('  RA:  ${formatRA(m31_jnow.ra)}');
  print('  DEC: ${formatDec(m31_jnow.dec)}');

  // Step 2: JNow → Alt/Az
  Horizontal m31_hz = coord.eqToHz(jd, m31_jnow, location);

  print('\nM31 horizontal coordinates:');
  print('  Az:  ${formatDMS(m31_hz.az)}');
  print('  Alt: ${formatDMS(m31_hz.alt)}');
  print('  Direction: ${coord.azimuth2Direction(m31_hz.az)}');

  // ============================================================
  // 3. Alt/Az → JNow → J2000 (inverse conversion)
  // ============================================================
  print('\n' + '=' * 60);
  print('[Example 2] Alt/Az → J2000 (solve for catalog coordinates)');
  print('=' * 60);

  // Input Alt/Az (simulated telescope encoder readings)
  double inputAz = 61 + 15.0/60 + 27.7/3600;   // 061°15'27.7"
  double inputAlt = 49 + 29.0/60 + 12.2/3600;  // +49°29'12.2"

  print('\nInput horizontal coordinates:');
  print('  Az:  ${formatDMS(inputAz)}');
  print('  Alt: ${formatDMS(inputAlt)}');

  // Step 1: Alt/Az → JNow
  Horizontal inputHz = Horizontal(inputAz, inputAlt);
  Equatorial eq_jnow = coord.hzToEq(jd, inputHz, location, apparentAltitude: true);

  print('\nComputed JNow coordinates:');
  print('  RA:  ${formatRA(eq_jnow.ra)}');
  print('  DEC: ${formatDec(eq_jnow.dec)}');

  // Step 2: JNow → J2000 (undo precession + nutation)
  Equatorial eq_j2000 = Equatorial(eq_jnow.ra, eq_jnow.dec);
  eq_j2000.regressCoordinates(jd);

  print('\nComputed J2000 coordinates:');
  print('  RA:  ${formatRA(eq_j2000.ra)}');
  print('  DEC: ${formatDec(eq_j2000.dec)}');

  // Compare against the M31 catalog position
  double raErr = (eq_j2000.ra - m31_ra_j2000) * 15 * 3600;
  double decErr = (eq_j2000.dec - m31_dec_j2000) * 3600;
  print('\nDifference from the M31 catalog position:');
  print('  ΔRA:  ${raErr.toStringAsFixed(2)}"');
  print('  ΔDEC: ${decErr.toStringAsFixed(2)}"');

  // ============================================================
  // 4. Minimal usage example (for apps)
  // ============================================================
  print('\n' + '=' * 60);
  print('[App usage example]');
  print('=' * 60);
  print('''
// === 1. J2000 → Alt/Az (show a catalog object's position) ===
DateTime utc = DateTime.now().toUtc();
double jd = julian.timeToJD(utc);
Geography location = Geography(latitude, longitude);

// J2000 coordinates from a catalog
double ra_j2000 = ...;   // unit: hours
double dec_j2000 = ...;  // unit: degrees

// J2000 → JNow
Equatorial eq = Equatorial(ra_j2000, dec_j2000);
eq.precessedCoordinates(jd);

// JNow → Alt/Az
Horizontal hz = coord.eqToHz(jd, eq, location);
double az = hz.az;   // azimuth
double alt = hz.alt; // altitude

// === 2. Alt/Az → J2000 (solve from telescope readings) ===
// Horizontal coordinates read from the telescope
double az = ...;   // azimuth
double alt = ...;  // altitude (apparent)

// Alt/Az → JNow
Horizontal hz = Horizontal(az, alt);
Equatorial eq_jnow = coord.hzToEq(jd, hz, location, apparentAltitude: true);

// JNow → J2000
Equatorial eq_j2000 = Equatorial(eq_jnow.ra, eq_jnow.dec);
eq_j2000.regressCoordinates(jd);

double ra = eq_j2000.ra;   // J2000 right ascension
double dec = eq_j2000.dec; // J2000 declination
''');

  // ============================================================
  // 5. Summary of coordinate conversion methods
  // ============================================================
  print('\n' + '=' * 60);
  print('[Coordinate conversion summary]');
  print('=' * 60);
  print('''
┌─────────────────────────────────────────────────────────┐
│  J2000 coordinates                                      │
│  (catalog coordinates)                                  │
└────────────────────────┬────────────────────────────────┘
                         │ precessedCoordinates(jd)
                         │ (precession + nutation)
                         ↓
┌─────────────────────────────────────────────────────────┐
│  JNow coordinates                                       │
│  (current epoch)                                        │
└────────────────────────┬────────────────────────────────┘
                         │ coord.eqToHz(jd, eq, location)
                         │ (sidereal time + observer location)
                         ↓
┌─────────────────────────────────────────────────────────┐
│  Alt/Az coordinates                                     │
│  (horizontal coordinates)                               │
└─────────────────────────────────────────────────────────┘

Inverse: regressCoordinates(jd) + coord.hzToEq(jd, hz, location)
''');

  // ============================================================
  // 6. NGC 67 rise / transit / set from Iceland
  // ============================================================
  print('\n' + '=' * 60);
  print('[Example 6] Reykjavik, Iceland - NGC 67 - 2026-05-27 rise/transit/set');
  print('=' * 60);

  final reykjavik = Geography(64.1466, -21.9426);
  final siteDate = DateTime.utc(2026, 5, 27);
  final siteJd = julian.gregorianToJD(siteDate.year, siteDate.month, siteDate.day);

  // NGC 67 J2000 (Wikipedia / NED PGC 138159)
  const ngc67RaJ2000 = 0 + 18.0 / 60 + 12.2 / 3600;
  const ngc67DecJ2000 = 30 + 3.0 / 60 + 20.0 / 3600;

  final ngc67Eq = Equatorial(ngc67RaJ2000, ngc67DecJ2000)
      .precessedCoordinates(siteJd + 0.5);
  final ngc67 = Astro(ngc67Eq);
  final ngc67Times = ngc67.riseTransitSet(siteDate, reykjavik);

  print('\nLocation: Reykjavik ${reykjavik.lat}°N, ${reykjavik.lon}°W (UTC+0)');
  print('Date: ${siteDate.toIso8601String().split('T').first}');
  print('Object: NGC 67 (J2000 RA ${formatRA(ngc67RaJ2000)}, DEC ${formatDec(ngc67DecJ2000)})');
  print('  JNow @ site noon: RA ${formatRA(ngc67Eq.ra)}, DEC ${formatDec(ngc67Eq.dec)}');
  final circumpolar = ngc67Eq.dec > (90 - reykjavik.lat);
  print('Rise    riseTime:    ${_fmtRts(ngc67Times.riseTime, circumpolar)}');
  print('Transit transitTime: ${_fmtUtc(ngc67Times.transitTime)}');
  print('Set     setTime:     ${_fmtRts(ngc67Times.setTime, circumpolar)}');
  if (circumpolar) {
    print('Note: DEC ${formatDec(ngc67Eq.dec)} > 90°-φ ${(90 - reykjavik.lat).toStringAsFixed(2)}° → circumpolar: no rise or set, transit only');
  }
}

String _fmtRts(DateTime? t, bool circumpolar) {
  if (t != null) return _fmtUtc(t);
  if (circumpolar) return 'none (circumpolar, visible all day)';
  return 'none (does not rise on this date)';
}

String _fmtUtc(DateTime? t) {
  if (t == null) return 'none';
  final u = t.toUtc();
  return '${u.year}-${u.month.toString().padLeft(2, '0')}-${u.day.toString().padLeft(2, '0')} '
      '${u.hour.toString().padLeft(2, '0')}:${u.minute.toString().padLeft(2, '0')}:${u.second.toString().padLeft(2, '0')} UTC';
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
