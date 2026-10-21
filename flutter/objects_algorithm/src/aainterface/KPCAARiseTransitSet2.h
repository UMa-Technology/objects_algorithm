#pragma once

#include "PlatformHelpers.h"
#include <vector>

typedef enum KPCAAObject {
    SUN,
    MOON,
    MERCURY,
    VENUS,
    MARS,
    JUPITER,
    SATURN,
    URANUS,
    NEPTUNE,
    STAR
} KPCAAObject;

typedef enum KPCAAMoonAlgorithm {
    MeeusTruncated = 0,
    ELP2000 = 1,
    ELPMPP02Nominal = 2,
    ELPMPP02LLR = 3,
    ELPMPP02DE405 = 4,
    ELPMPP02DE406 = 5
} KPCAAMoonAlgorithm;

#ifdef __cplusplus
extern "C" {
#endif

struct KPCAARiseTransitSetDetails2 {
  int type;          // event type
  double jd;         // Julian day
  double bearing;    // azimuth (bearing)
  double altitude;   // geometric altitude
  bool aboveHorizon; // whether above the horizon
};

// KPCAARiseTransitSetDetails2* KPCAARiseTransitSet2_CalculateMoon(double StartJD, double EndJD, double Longitude, double Latitude, double RefractionAtHorizon, double StepInterval, KPCAAMoonAlgorithm algorithm);
KPCAARiseTransitSetDetails2* KPCAARiseTransitSet2_CalculateStationary(double StartJD, double EndJD, double Alpha, double Delta, double Longitude, double Latitude, double h0, double StepInterval);
KPCAARiseTransitSetDetails2* KPCAARiseTransitSet2_Calculate(double StartJD, double EndJD, KPCAAObject object, double Longitude, double Latitude, double h0, double StepInterval, bool bHighPrecision);
// Free the result array
void KPCAARiseTransitSet2_FreeResults(KPCAARiseTransitSetDetails2* results);

#if __cplusplus
}
#endif