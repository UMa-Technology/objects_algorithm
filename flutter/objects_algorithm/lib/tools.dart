import 'dart:math';

  double fromSexa(String neg, int d, int m, double s){
    return fromSexaSec(neg, d, m, s) / 3600;
  }

  double fromSexaSec(String neg, int d, int m, double s){
    double s0 = (d*60+m)*60;
    s = (s0 + s);
    if (neg == '-') {
      return -s;
    }
    return s;
  }

  double mod(double x, double y) {
    return x - y * (x / y).floor();
  }
  double pMod(double x, y) {
    var r = mod(x, y);
    if (r < 0) {
      r += y;
    }
    return r;
  }

class Angle {
  double value;

  Angle([this.value = 0]);


  newAngle(String neg, int d, int m, double s) {
    return angleFromSec(fromSexaSec(neg, d, m, s));
  }

  double rad(){
    return value;
  }

  double deg(){
    return value * 180 / pi;
  }

  double min(){
    return value * 60 / 180 * pi;
  }

  double sec(){
    return value * 3600 / 180 * pi;
  }

  angleFromDeg(double deg) {
    return Angle(deg / 180 * pi);
  }
  
  angleFromMin(double min) {
    return Angle(min / 60 / 180 * pi);
  }

  angleFromSec(double sec) {
    return Angle(sec / 3600 / 180 * pi);
  }
}

class HourAngle {
  double value;

  HourAngle([this.value = 0]);

  newHourAngle(String neg, int h, int m, double s) {
    return HourAngle(fromSexa(neg, h, m, s) / 12 * pi);
  }

  hourAngleFromHour(double hour) {
    return HourAngle(hour / 12 * pi);
  }

  hourAngleFromMin(double min) {
    return HourAngle(min / 60 / 12 * pi);
  }

  hourAngleFromSec(double sec) {
    return HourAngle(sec / 3600 / 12 * pi);
  }

  double rad(){
    return value;
  }

  double hour(){
    return value * 12 / pi;
  }

  double min(){
    return value * 60 * 12 / pi;
  }

  double sec(){
    return value * 3600 * 12 / pi;
  }
}


class RA {
  double value;

  RA([this.value = 0]);

  newRa(int h, int m, double s) {
    return raFromRad(fromSexa('', h, m, s) / 12 * pi);
  }

  raFromRad(double rad) {
    return RA(pMod(rad, 2*pi));
  }

  raFromHour(double hour){
    return RA(raFromRad(hour / 12 * pi));
  }

  raFromDeg(double deg){
    return RA(raFromRad(deg / 180 * pi));
  }

  raFromMin(double min){
    return RA(raFromRad(min / 60 / 12 * pi));
  }

  raFromSec(double sec){
    return RA(raFromRad(sec / 3600 / 12 * pi));
  }

  double rad() {
    return value;
  }

  double deg(){
    return value * 180 / pi;
  }

  double hour(){
    return value * 12 / pi;
  }

  double min(){
    return value * 60 * 12 / pi;
  }

  double sec(){
    return value * 3600 * 12 / pi;
  }
}

class Tools {

  static final aU2m = 149597870700.0;

  static final rad2hour = 3.8197186342054880584532103209403;
  static final hour2rad = 0.26179938779914943653855361527329;
  static final rad2deg = 180.0/pi;
  static final deg2rad = pi/180.0;

  static (String, int, int, double) convertToHMS(double value) {
    // Integer part (truncated toward zero)
    int hours = value.abs().truncate();

    // Minutes
    double remaining = value.abs() - hours;
    int minutes = (remaining * 60).truncate();

    // Seconds
    double seconds = (remaining * 60 - minutes) * 60;

    // Sign
    String sign = value >= 0 ? '+' : '-';

    return (sign, hours, minutes, seconds);
  }
}

    // Rise = 1,               // rise
    // Set = 2,                // set
    // SouthernTransit = 3,    // southern transit
    // NorthernTransit = 4,    // northern transit
    // CivilDusk = 5,          // civil dusk
    // NauticalDusk = 6,       // nautical dusk
    // AstronomicalDusk = 7,   // astronomical dusk
    // AstronomicalDawn = 8,   // astronomical dawn
    // NauticalDawn = 9,       // nautical dawn
    // CivilDawn = 10          // civil dawn 