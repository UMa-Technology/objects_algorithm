#pragma once

#include "PlatformHelpers.h"

#ifdef __cplusplus
extern "C" {
#endif

double KPCAAMoonIlluminatedFraction_GeocentricElongation(double ObjectAlpha, double ObjectDelta, double SunAlpha, double SunDelta);

double KPCAAMoonIlluminatedFraction_PhaseAngle(double GeocentricElongation, double EarthObjectDistance, double EarthSunDistance);

double KPCAAMoonIlluminatedFraction_IlluminatedFraction(double PhaseAngle);

double KPCAAMoonIlluminatedFraction_PositionAngle(double Alpha0, double Delta0, double Alpha, double Delta);

#if __cplusplus
}
#endif