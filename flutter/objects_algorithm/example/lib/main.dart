import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:objects_algorithm/objects_algorithm.dart';

void main() => runApp(const ExampleApp());

/// Each row hits a different aainterface translation unit, to verify the symbols
/// really survive in every platform's build output (especially on Apple, where only
/// the keepalive chain keeps the linker from dropping them).
List<(String, String)> _probe() {
  final rows = <(String, String)>[];

  void row(String name, Object Function() f) {
    try {
      rows.add((name, '${f()}'));
    } catch (e) {
      rows.add((name, 'FAILED: $e'));
    }
  }

  const jd = 2451545.0; // J2000.0

  row('KPCAADate_DateToJulianDay', () => dateToJD(2000, 1, 1, 1));
  row('KPCAASun_GeometricEclipticLongitude', () => sunEclipticLongitude(jd, 1));
  row('KPCAAMoon_EclipticLongitude', () => moonEclipticLongitude(jd));
  row('KPCAAMoonIlluminatedFraction_IlluminatedFraction',
      () => illuminatedFraction(90.0));
  row('KPCAANutation_MeanObliquityOfEcliptic',
      () => meanObliquityOfEcliptic(jd));
  row('KPCAASidereal_ApparentGreenwichSiderealTime',
      () => apparentGreenwichSiderealTime(jd));
  row('KPCAAAngularSeparation_Separation',
      () => separation(0.0, 0.0, 1.0, 1.0));
  row('KPCAARefraction_RefractionFromTrueWithAltitude',
      () => refractionFromTrueWithAltitude(45.0, 1013.0, 10.0));
  row('KPCAADynamicalTime_UTC2TT', () => uTCToTT(jd));
  row('KPCAAElliptical_CalculatePlanetaryDetails', () {
    final d = calculatePlanetaryDetails(jd, 3, 1);
    return d.ApparentGeocentricRA.toStringAsFixed(4);
  });
  row('KPCAASaturnRings_Calculate', () {
    final r = saturnRingDetails(jd, 1);
    return r.B.toStringAsFixed(4);
  });
  row('KPCAACoordinateTransformation_Equatorial2Horizontal', () {
    final c = equatorial2Horizontal(0.0, 45.0, 30.0);
    return '${c.X.toStringAsFixed(3)}, ${c.Y.toStringAsFixed(3)}';
  });
  row('KPCAAIlluminatedFraction_MagnitudeAA',
      () => magnitudePlanet(3, 1.0, 1.0, 0.5));
  row('KPCAAPrecession_PrecessEquatorial', () {
    final c = precessEquatorial(0.0, 0.0, jd, jd + 365.25);
    return '${c.X.toStringAsFixed(6)}, ${c.Y.toStringAsFixed(6)}';
  });
  row('KPCAAParallax_Equatorial2Topocentric', () {
    final c = parallaxEquatorial2Topocentric(0.0, 0.0, 1.0, 0.0, 45.0, 0.0, jd);
    return '${c.X.toStringAsFixed(6)}, ${c.Y.toStringAsFixed(6)}';
  });
  row('KPCAARiseTransitSet2_Calculate', () {
    final p = calculate(jd, jd + 1, 0, 0.0, 45.0, -0.5667, 0.007, 1);
    final v = p.ref.jd;
    freeResults(p);
    return v.toStringAsFixed(4);
  });

  return rows;
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = _probe();
    final failed = rows.where((r) => r.$2.startsWith('FAILED')).length;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(failed == 0
              ? 'All ${rows.length} symbols available'
              : '$failed / ${rows.length} symbol lookups failed'),
          backgroundColor: failed == 0 ? Colors.green : Colors.red,
        ),
        body: ListView.separated(
          itemCount: rows.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => ListTile(
            dense: true,
            title: Text(rows[i].$1, style: const TextStyle(fontSize: 12)),
            subtitle: Text(rows[i].$2),
          ),
        ),
      ),
    );
  }
}
