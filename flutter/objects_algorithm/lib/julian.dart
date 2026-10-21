import 'bind.dart';

class Julian {

    double timeToJD(DateTime time) {
        var dateHandle = createWithDateTime(time.year, time.month, time.day.toDouble(), time.hour.toDouble(), time.minute.toDouble(), time.second.toDouble(), 1);
        double jd = julian(dateHandle);

        return jd;
    }

    double gregorianToJD(int year, int month, int day) {
        double jd = dateToJD(year, month, day, 1);
        return jd;
    }

    DateTime jdToTime(double jd) {
        var dateHandle = createWithJulianDay(jd, 1);
        
        int year = getYear(dateHandle);
        int month = getMonth(dateHandle);
        int day = getDay(dateHandle);
        int hour = getHour(dateHandle);
        int minute = getMinute(dateHandle);
        double second = getSecond(dateHandle);

        DateTime time = DateTime.utc(year, month, day, hour, minute, second.toInt());
        return time;
    }

    double getGMST(double jd) {
        double gst = meanGreenwichSiderealTime(jd);
        return gst;
    }

    double getGAST(double jd) {
        double gst = apparentGreenwichSiderealTime(jd);

        return gst;
    }

    double midnightJD(double jd) {
        return (jd - 0.5).floorToDouble() + 0.5;
    }

    static double uTC2TT(double jd) {
        return uTCToTT(jd);
    }

    static double tT2UTC(double jd) {
      return tTToUTC(jd);
    }
}