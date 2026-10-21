// import 'dart:ffi';

import 'coord.dart';

class Earth {
  final double _jd;

  Earth(this._jd);

  // The distance to the Sun.
  double radiusVector(){
    return Coord.instance.astronomicalUnit(_jd, 99);
  }

}