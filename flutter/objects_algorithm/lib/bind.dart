import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

/// Handle to this plugin's native library.
///
/// On Apple platforms CocoaPods compiles the C++ sources under src/ into the host process. Whether they are linked
/// statically into the main binary or built as a dynamic framework is up to the host app's Podfile (a host app may
/// use static on iOS and dynamic on macOS); only `DynamicLibrary.process()` works for both layouts —
/// with static linking there is no file for `open()` to open.
///
/// Android and Windows use a standalone shared library built by src/CMakeLists.txt, opened by file name.
final DynamicLibrary aaPlusLib = _openLibrary();

DynamicLibrary _openLibrary() {
  if (Platform.isIOS || Platform.isMacOS) {
    final process = DynamicLibrary.process();
    // In a real app the symbols are always in the process. The only case they are missing is the plain
    // Dart VM of `flutter test` — it does not link the plugin's native code, so process() is empty.
    // Fall back to the locally built library so the tests under test/ actually run.
    if (process.providesSymbol('KPCAADate_CreateWithDateTime')) return process;
    return DynamicLibrary.open(_hostTestLibraryPath('dylib'));
  }
  if (Platform.isWindows) return DynamicLibrary.open('objects_algorithm.dll');
  return DynamicLibrary.open('libobjects_algorithm.so');
}

/// Native library path for `flutter test`, built by `tool/build_host_library.sh`.
String _hostTestLibraryPath(String ext) {
  final path = '${Directory.current.path}/build/host/libobjects_algorithm.$ext';
  if (!File(path).existsSync()) {
    throw StateError(
      'No KPCAA symbols in the process and no host build found at: $path\n'
      'Run ./tool/build_host_library.sh in flutter/objects_algorithm first.',
    );
  }
  return path;
}

//------moon------

typedef SeparationNative = Double Function(Double, Double, Double, Double);
typedef SeparationDart = double Function(double, double, double, double);
final SeparationDart separation = aaPlusLib
    .lookup<NativeFunction<SeparationNative>>(
        'KPCAAAngularSeparation_Separation')
    .asFunction();

typedef GeocentricElongationNative = Double Function(
    Double, Double, Double, Double);
typedef GeocentricElongationDart = double Function(
    double, double, double, double);
final GeocentricElongationDart geocentricElongation = aaPlusLib
    .lookup<NativeFunction<GeocentricElongationNative>>(
        'KPCAAMoonIlluminatedFraction_GeocentricElongation')
    .asFunction();

typedef MoonRadiusVectorNative = Double Function(Double);
typedef MoonRadiusVectorDart = double Function(double);
final MoonRadiusVectorDart moonRadiusVector = aaPlusLib
    .lookup<NativeFunction<MoonRadiusVectorNative>>('KPCAAMoon_RadiusVector')
    .asFunction();

typedef MoonRadiusVectorToHorizontalParallaxNative = Double Function(Double);
typedef MoonRadiusVectorToHorizontalParallaxDart = double Function(double);
final MoonRadiusVectorToHorizontalParallaxDart moonParallax = aaPlusLib
    .lookup<NativeFunction<MoonRadiusVectorToHorizontalParallaxNative>>(
        'KPCAAMoon_RadiusVectorToHorizontalParallax')
    .asFunction();

typedef PhaseAngleMoonNative = Double Function(Double, Double, Double);
typedef PhaseAngleMoonDart = double Function(double, double, double);
final PhaseAngleMoonDart phaseAngleC = aaPlusLib
    .lookup<NativeFunction<PhaseAngleMoonNative>>(
        'KPCAAMoonIlluminatedFraction_PhaseAngle')
    .asFunction();

typedef IlluminatedFractionNative = Double Function(Double);
typedef IlluminatedFractionDart = double Function(double);
final IlluminatedFractionDart illuminatedFraction = aaPlusLib
    .lookup<NativeFunction<IlluminatedFractionNative>>(
        'KPCAAMoonIlluminatedFraction_IlluminatedFraction')
    .asFunction();

//------julianday--------

// Get the JD from a date
typedef DateToJulianDayNative = Double Function(Long, Long, Long, Int8);
typedef DateToJulianDayDart = double Function(int, int, int, int);
final DateToJulianDayDart dateToJD = aaPlusLib
    .lookup<NativeFunction<DateToJulianDayNative>>('KPCAADate_DateToJulianDay')
    .asFunction();

// Create a date object
typedef CreateWithDateTimeNative = Pointer Function(
    Long, Long, Double, Double, Double, Double, Int8);
typedef CreateWithDateTimeDart = Pointer Function(
    int, int, double, double, double, double, int);
final CreateWithDateTimeDart createWithDateTime = aaPlusLib
    .lookup<NativeFunction<CreateWithDateTimeNative>>(
        'KPCAADate_CreateWithDateTime')
    .asFunction();

// Create a JD object
typedef CreateWithJulianDayNative = Pointer Function(Double, Int8);
typedef CreateWithJulianDayDart = Pointer Function(double, int);
final CreateWithJulianDayDart createWithJulianDay = aaPlusLib
    .lookup<NativeFunction<CreateWithJulianDayNative>>(
        'KPCAADate_CreateWithJulianDay')
    .asFunction();

// Get the JD from a julian object
typedef JulianNative = Double Function(Pointer);
typedef JulianDart = double Function(Pointer);
final JulianDart julian = aaPlusLib
    .lookup<NativeFunction<JulianNative>>('KPCAADate_GetJulian')
    .asFunction();

typedef UTCToTTNative = Double Function(Double);
typedef UTCToTTDart = double Function(double);
final UTCToTTDart uTCToTT = aaPlusLib
    .lookup<NativeFunction<UTCToTTNative>>('KPCAADynamicalTime_UTC2TT')
    .asFunction();

typedef TTToUTCNative = Double Function(Double);
typedef TTToUTCDart = double Function(double);
final TTToUTCDart tTToUTC = aaPlusLib
    .lookup<NativeFunction<TTToUTCNative>>('KPCAADynamicalTime_TT2UTC')
    .asFunction();

// Get the date from a JD
// typedef GetDateTimeNative = Double Function(Pointer<Void> handle, Pointer<Int64> year, Pointer<Int64> month, Pointer<Int64> day, Pointer<Int64> hour, Pointer<Int64> minute, Pointer<Double> second);
// typedef GetDateTimeDart = double Function(Pointer<Void> handle, Pointer<Int64> year, Pointer<Int64> month, Pointer<Int64> day, Pointer<Int64> hour, Pointer<Int64> minute, Pointer<Double> second);
// final GetDateTimeDart getDateTime = aaPlusLib
//     .lookup<NativeFunction<GetDateTimeNative>>('KPCAADate_GetDateTime')
//     .asFunction();

// Get year/month/day/hour/minute/second from a julian object
typedef GetYearNative = Long Function(Pointer handle);
typedef GetYearDart = int Function(Pointer handle);
final GetYearDart getYear = aaPlusLib
    .lookup<NativeFunction<GetYearNative>>('KPCAADate_GetYear')
    .asFunction();
typedef GetMonthNative = Long Function(Pointer handle);
typedef GetMonthDart = int Function(Pointer handle);
final GetMonthDart getMonth = aaPlusLib
    .lookup<NativeFunction<GetMonthNative>>('KPCAADate_GetMonth')
    .asFunction();
typedef GetDayNative = Long Function(Pointer handle);
typedef GetDayDart = int Function(Pointer handle);
final GetDayDart getDay = aaPlusLib
    .lookup<NativeFunction<GetDayNative>>('KPCAADate_GetDay')
    .asFunction();
typedef GetHourNative = Long Function(Pointer handle);
typedef GetHourDart = int Function(Pointer handle);
final GetHourDart getHour = aaPlusLib
    .lookup<NativeFunction<GetHourNative>>('KPCAADate_GetHour')
    .asFunction();
typedef GetMinuteNative = Long Function(Pointer handle);
typedef GetMinuteDart = int Function(Pointer handle);
final GetMinuteDart getMinute = aaPlusLib
    .lookup<NativeFunction<GetMinuteNative>>('KPCAADate_GetMinute')
    .asFunction();
typedef GetSecondNative = Double Function(Pointer handle);
typedef GetSecondDart = double Function(Pointer handle);
final GetSecondDart getSecond = aaPlusLib
    .lookup<NativeFunction<GetSecondNative>>('KPCAADate_GetSecond')
    .asFunction();

typedef MeanGreenwichSiderealTimeNative = Double Function(Double);
typedef MeanGreenwichSiderealTimeDart = double Function(double);
final MeanGreenwichSiderealTimeDart meanGreenwichSiderealTime = aaPlusLib
    .lookup<NativeFunction<MeanGreenwichSiderealTimeNative>>(
        'KPCAASidereal_MeanGreenwichSiderealTime')
    .asFunction();
typedef ApparentGreenwichSiderealTimeNative = Double Function(Double);
typedef ApparentGreenwichSiderealTimeDart = double Function(double);
final ApparentGreenwichSiderealTimeDart apparentGreenwichSiderealTime =
    aaPlusLib
        .lookup<NativeFunction<ApparentGreenwichSiderealTimeNative>>(
            'KPCAASidereal_ApparentGreenwichSiderealTime')
        .asFunction();

//------ rise ------

typedef CalculateStationaryNative = Pointer<KPCAARiseTransitSetDetails2>
    Function(Double, Double, Double, Double, Double, Double, Double, Double);
typedef CalculateStationaryDart = Pointer<KPCAARiseTransitSetDetails2> Function(
    double, double, double, double, double, double, double, double);
final CalculateStationaryDart calculateStationar = aaPlusLib
    .lookup<NativeFunction<CalculateStationaryNative>>(
        'KPCAARiseTransitSet2_CalculateStationary')
    .asFunction();

typedef CalculateNative = Pointer<KPCAARiseTransitSetDetails2> Function(
    Double, Double, Int32, Double, Double, Double, Double, Int8);
typedef CalculateDart = Pointer<KPCAARiseTransitSetDetails2> Function(
    double, double, int, double, double, double, double, int);
final CalculateDart calculate = aaPlusLib
    .lookup<NativeFunction<CalculateNative>>('KPCAARiseTransitSet2_Calculate')
    .asFunction();

// Free memory
typedef FreeResultsNative = Pointer<KPCAARiseTransitSetDetails2> Function(
    Pointer<KPCAARiseTransitSetDetails2>);
typedef FreeResultsDart = Pointer<KPCAARiseTransitSetDetails2> Function(
    Pointer<KPCAARiseTransitSetDetails2>);
final FreeResultsDart freeResults = aaPlusLib
    .lookup<NativeFunction<FreeResultsNative>>(
        'KPCAARiseTransitSet2_FreeResults')
    .asFunction();

// Layout of KPCAARiseTransitSetDetails2
final class KPCAARiseTransitSetDetails2 extends Struct {
  @Int32()
  external int type;

  @Double()
  external double jd;

  @Double()
  external double bearing;

  @Double()
  external double altitude;

  @Bool()
  external bool aboveHorizon;
}

//-----coord------

typedef PrecessEquatorialNative = CoordinateComponents Function(
    Double, Double, Double, Double);
typedef PrecessEquatorialDart = CoordinateComponents Function(
    double, double, double, double);
final PrecessEquatorialDart precessEquatorial = aaPlusLib
    .lookup<NativeFunction<PrecessEquatorialNative>>(
        'KPCAAPrecession_PrecessEquatorial')
    .asFunction();

typedef PrecessEclipticNative = CoordinateComponents Function(
    Double, Double, Double, Double);
typedef PrecessEclipticDart = CoordinateComponents Function(
    double, double, double, double);
final PrecessEclipticDart precessEcliptic = aaPlusLib
    .lookup<NativeFunction<PrecessEclipticNative>>(
        'KPCAAPrecession_PrecessEcliptic')
    .asFunction();

//moon
typedef MoonEclipticLongitudeNative = Double Function(Double);
typedef MoonEclipticLongitudeDart = double Function(double);
final MoonEclipticLongitudeDart moonEclipticLongitude = aaPlusLib
    .lookup<NativeFunction<MoonEclipticLongitudeNative>>(
        'KPCAAMoon_EclipticLongitude')
    .asFunction();
typedef MoonEclipticLatitudeNative = Double Function(Double);
typedef MoonEclipticLatitudeDart = double Function(double);
final MoonEclipticLatitudeDart moonEclipticLatitude = aaPlusLib
    .lookup<NativeFunction<MoonEclipticLatitudeNative>>(
        'KPCAAMoon_EclipticLatitude')
    .asFunction();

//sun
typedef SunEclipticLongitudeNative = Double Function(Double, Int8);
typedef SunEclipticLongitudeDart = double Function(double, int);
final SunEclipticLongitudeDart sunEclipticLongitude = aaPlusLib
    .lookup<NativeFunction<SunEclipticLongitudeNative>>(
        'KPCAASun_GeometricEclipticLongitude')
    .asFunction();
typedef SunEclipticLatitudeNative = Double Function(Double, Int8);
typedef SunEclipticLatitudeDart = double Function(double, int);
final SunEclipticLatitudeDart sunEclipticLatitude = aaPlusLib
    .lookup<NativeFunction<SunEclipticLatitudeNative>>(
        'KPCAASun_GeometricEclipticLatitude')
    .asFunction();

// Equatorial to horizontal coordinates
typedef Equatorial2HorizontalNative = CoordinateComponents Function(
    Double, Double, Double);
typedef Equatorial2HorizontalDart = CoordinateComponents Function(
    double, double, double);
final Equatorial2HorizontalDart equatorial2Horizontal = aaPlusLib
    .lookup<NativeFunction<Equatorial2HorizontalNative>>(
        'KPCAACoordinateTransformation_Equatorial2Horizontal')
    .asFunction();

// Horizontal to equatorial coordinates
typedef Horizontal2EquatorialNative = CoordinateComponents Function(
    Double, Double, Double);
typedef Horizontal2EquatorialDart = CoordinateComponents Function(
    double, double, double);
final Horizontal2EquatorialDart horizontal2Equatorial = aaPlusLib
    .lookup<NativeFunction<Horizontal2EquatorialNative>>(
        'KPCAACoordinateTransformation_Horizontal2Equatorial')
    .asFunction();

// Ecliptic to equatorial coordinates
typedef Ecliptic2EquatorialNative = CoordinateComponents Function(
    Double, Double, Double);
typedef Ecliptic2EquatorialDart = CoordinateComponents Function(
    double, double, double);
final Ecliptic2EquatorialDart ecliptic2Equatorial = aaPlusLib
    .lookup<NativeFunction<Ecliptic2EquatorialNative>>(
        'KPCAACoordinateTransformation_Ecliptic2Equatorial')
    .asFunction();
// Obliquity of the ecliptic
typedef MeanObliquityOfEclipticNative = Double Function(Double);
typedef MeanObliquityOfEclipticDart = double Function(double);
final MeanObliquityOfEclipticDart meanObliquityOfEcliptic = aaPlusLib
    .lookup<NativeFunction<MeanObliquityOfEclipticNative>>(
        'KPCAANutation_MeanObliquityOfEcliptic')
    .asFunction();

// True obliquity of the ecliptic
typedef TrueObliquityOfEclipticNative = Double Function(Double);
typedef TrueObliquityOfEclipticDart = double Function(double);
final TrueObliquityOfEclipticDart trueObliquityOfEcliptic = aaPlusLib
    .lookup<NativeFunction<TrueObliquityOfEclipticNative>>(
        'KPCAANutation_TrueObliquityOfEcliptic')
    .asFunction();

// Nutation in longitude
typedef NutationInLongitudeNative = Double Function(Double);
typedef NutationInLongitudeDart = double Function(double);
final NutationInLongitudeDart nutationInLongitude = aaPlusLib
    .lookup<NativeFunction<NutationInLongitudeNative>>(
        'KPCAANutation_NutationInLongitude')
    .asFunction();

// Nutation in obliquity
typedef NutationInObliquityNative = Double Function(Double);
typedef NutationInObliquityDart = double Function(double);
final NutationInObliquityDart nutationInObliquity = aaPlusLib
    .lookup<NativeFunction<NutationInObliquityNative>>(
        'KPCAANutation_NutationInObliquity')
    .asFunction();

// Nutation in right ascension (Alpha: RA in hours, Delta: Dec in degrees, Obliquity: obliquity in degrees)
// Returns arcseconds
typedef NutationInRightAscensionNative = Double Function(
    Double, Double, Double, Double, Double);
typedef NutationInRightAscensionDart = double Function(
    double, double, double, double, double);
final NutationInRightAscensionDart nutationInRightAscension = aaPlusLib
    .lookup<NativeFunction<NutationInRightAscensionNative>>(
        'KPCAANutation_NutationInRightAscension')
    .asFunction();

// Nutation in declination (Alpha: RA in hours, Obliquity: obliquity in degrees)
// Returns arcseconds
typedef NutationInDeclinationNative = Double Function(
    Double, Double, Double, Double);
typedef NutationInDeclinationDart = double Function(
    double, double, double, double);
final NutationInDeclinationDart nutationInDeclination = aaPlusLib
    .lookup<NativeFunction<NutationInDeclinationNative>>(
        'KPCAANutation_NutationInDeclination')
    .asFunction();

// Atmospheric refraction
typedef RefractionFromTrueWithAltitudeNative = Double Function(
    Double, Double, Double);
typedef RefractionFromTrueWithAltitudeDart = double Function(
    double, double, double);
final RefractionFromTrueWithAltitudeDart refractionFromTrueWithAltitude =
    aaPlusLib
        .lookup<NativeFunction<RefractionFromTrueWithAltitudeNative>>(
            'KPCAARefraction_RefractionFromTrueWithAltitude')
        .asFunction();

// Atmospheric refraction (from apparent altitude)
typedef RefractionFromApparentWithAltitudeNative = Double Function(
    Double, Double, Double);
typedef RefractionFromApparentWithAltitudeDart = double Function(
    double, double, double);
final RefractionFromApparentWithAltitudeDart
    refractionFromApparentWithAltitude = aaPlusLib
        .lookup<NativeFunction<RefractionFromApparentWithAltitudeNative>>(
            'KPCAARefraction_RefractionFromApparentWithAltitude')
        .asFunction();

typedef RadiusVectorNative = Double Function(Double, Int8, Int8);
typedef RadiusVectorDart = double Function(double, int, int);
final RadiusVectorDart radiusVector = aaPlusLib
    .lookup<NativeFunction<RadiusVectorNative>>(
        'KPCAAEclipticalElement_RadiusVector')
    .asFunction();

// Parallax correction for equatorial coordinates
typedef ParallaxEquatorial2TopocentricNative = CoordinateComponents Function(
    Double, Double, Double, Double, Double, Double, Double);
typedef ParallaxEquatorial2TopocentricDart = CoordinateComponents Function(
    double, double, double, double, double, double, double);
final ParallaxEquatorial2TopocentricDart parallaxEquatorial2Topocentric =
    aaPlusLib
        .lookup<NativeFunction<ParallaxEquatorial2TopocentricNative>>(
            'KPCAAParallax_Equatorial2Topocentric')
        .asFunction();

final class CoordinateComponents extends Struct {
  @Double()
  external double X;

  @Double()
  external double Y;
}

final class Coordinate3D extends Struct {
  @Double()
  external double X;

  @Double()
  external double Y;

  @Double()
  external double Z;
}

// --------Planet--------
final class EllipticalPlanetaryDetails extends Struct {
  @Double()
  external double ApparentGeocentricLongitude;

  @Double()
  external double ApparentGeocentricLatitude;

  @Double() // distance from Earth
  external double ApparentGeocentricDistance;

  @Double()
  external double ApparentLightTime;

  @Double() // Ra
  external double ApparentGeocentricRA;

  @Double() //Dec
  external double ApparentGeocentricDeclination;
}

typedef CalculatePlanetaryDetailsNative = EllipticalPlanetaryDetails Function(
    Double, Int8, Int8);
typedef CalculatePlanetaryDetailsDart = EllipticalPlanetaryDetails Function(
    double, int, int);
final CalculatePlanetaryDetailsDart calculatePlanetaryDetails = aaPlusLib
    .lookup<NativeFunction<CalculatePlanetaryDetailsNative>>(
        'KPCAAElliptical_CalculatePlanetaryDetails')
    .asFunction();

// Magnitude
typedef MagnitudeNative = Double Function(Int8, Double, Double, Double);
typedef MagnitudeDart = double Function(int, double, double, double);
final MagnitudeDart magnitudePlanet = aaPlusLib
    .lookup<NativeFunction<MagnitudeNative>>(
        'KPCAAIlluminatedFraction_MagnitudeAA')
    .asFunction();

// Magnitude (Müller formulae)
typedef MagnitudeMullerNative = Double Function(Int8, Double, Double, Double);
typedef MagnitudeMullerDart = double Function(int, double, double, double);
final MagnitudeMullerDart magnitudeMullerPlanet = aaPlusLib
    .lookup<NativeFunction<MagnitudeMullerNative>>(
        'KPCAAIlluminatedFraction_MagnitudeMuller')
    .asFunction();

// Magnitude (Saturn)
typedef SaturnMagnitudeNative = Double Function(Double, Double, Double, Double);
typedef SaturnMagnitudeDart = double Function(double, double, double, double);
final SaturnMagnitudeDart saturnMagnitude = aaPlusLib
    .lookup<NativeFunction<SaturnMagnitudeNative>>(
        'KPCAAIlluminatedFraction_SaturnMagnitudeAA')
    .asFunction();

// Phase angle
typedef PhaseAngleNative = Double Function(Double, Double, Double);
typedef PhaseAngleDart = double Function(double, double, double);
final PhaseAngleDart phaseAnglePlanet = aaPlusLib
    .lookup<NativeFunction<PhaseAngleNative>>(
        'KPCAAIlluminatedFraction_PhaseAngle')
    .asFunction();

// Saturn's rings
final class SaturnRingDetails extends Struct {
  @Double()
  external double B;

  @Double()
  external double Bdash;

  @Double()
  external double P;

  @Double()
  external double a;

  @Double()
  external double b;

  @Double()
  external double DeltaU;

  @Double()
  external double U1;

  @Double()
  external double U2;
}

typedef SaturnRingDetailsNative = SaturnRingDetails Function(Double, Int8);
typedef SaturnRingDetailsDart = SaturnRingDetails Function(double, int);
final SaturnRingDetailsDart saturnRingDetails = aaPlusLib
    .lookup<NativeFunction<SaturnRingDetailsNative>>(
        'KPCAASaturnRings_Calculate')
    .asFunction();

// Comets
final class NearParabolicObjectElements extends Struct {
  @Double()
  external double q; // perihelion distance q [AU]

  @Double()
  external double i; // inclination i [°]

  @Double()
  external double w; // argument of perihelion ω [°]

  @Double()
  external double omega; // longitude of ascending node Ω [°]

  @Double()
  external double JDEquinox; // epoch; always the J2000 JD 2451545.0

  @Double()
  external double T; // time of perihelion T (JD)

  @Double()
  external double e; // eccentricity e (>1 hyperbolic)
}

final class NearParabolicObjectDetails extends Struct {
  external Coordinate3D HeliocentricRectangularEquatorialCoordinateComponents;
  external Coordinate3D HeliocentricRectangularEclipticalCoordinateComponents;

  @Double()
  external double HeliocentricEclipticLongitude;

  @Double()
  external double HeliocentricEclipticLatitude;

  @Double()
  external double TrueGeocentricRA;

  @Double()
  external double TrueGeocentricDeclination;

  @Double()
  external double TrueGeocentricDistance;

  @Double()
  external double TrueGeocentricLightTime;

  @Double()
  external double AstrometricGeocentricRA;

  @Double()
  external double AstrometricGeocentricDeclination;

  @Double()
  external double AstrometricGeocentricDistance;

  @Double()
  external double AstrometricGeocentricLightTime;

  @Double()
  external double Elongation;

  @Double()
  external double PhaseAngle;
}

typedef NearParabolicObjectCalculateNative = NearParabolicObjectDetails
    Function(Double, NearParabolicObjectElements, Int8);
typedef NearParabolicObjectCalculateDart = NearParabolicObjectDetails Function(
    double, NearParabolicObjectElements, int);
final NearParabolicObjectCalculateDart _nearParabolicObjectCalculate = aaPlusLib
    .lookup<NativeFunction<NearParabolicObjectCalculateNative>>(
        'KPCAANearParabolic_CalculateObjectDetails')
    .asFunction();

/// Position of a near-parabolic object (comet).
///
/// [jd] Julian day (TT)
/// [q] Perihelion distance (AU)
/// [e] Eccentricity
/// [i] Inclination (degrees)
/// [w] Argument of perihelion (degrees)
/// [omega] Longitude of ascending node (degrees)
/// [T] Time of perihelion (JD)
/// [jDEquinox] Epoch of the elements (JD)
/// [highPrecision] Whether to use high precision (1 = yes, 0 = no)
NearParabolicObjectDetails calculateNearParabolicObject(double jd, double q,
    double e, double i, double w, double omega, double T, double jDEquinox,
    [int highPrecision = 1]) {
  final ptr = calloc<NearParabolicObjectElements>();
  ptr.ref
    ..q = q
    ..i = i
    ..w = w
    ..omega = omega
    ..JDEquinox = jDEquinox
    ..T = T
    ..e = e;

  final result = _nearParabolicObjectCalculate(jd, ptr.ref, highPrecision);
  calloc.free(ptr);
  return result;
}
