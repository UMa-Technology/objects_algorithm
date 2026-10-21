import 'coord.dart';
import 'rise.dart';

class Astro {
  Equatorial? eq;

  Astro(this.eq);

  // Altitude and azimuth
  Horizontal azAlt(double jd, Geography obs) {
    Horizontal hz = Coord.instance.eqToHz(jd, eq!, obs);
    hz.direction = Coord.instance.azimuth2Direction(hz.az);
    return hz;
  }

  AstroTime riseTransitSet(
    DateTime date,
    Geography obs, [
    double? riseSetAltitude,
  ]) {
    RiseTransitSet rtsObj = RiseTransitSet();
    var rts = rtsObj.timesStationary(
      date,
      eq!,
      obs,
      riseSetAltitude ?? rtsObj.Stdh0Stellar,
    );

    return rts;
  }
}
