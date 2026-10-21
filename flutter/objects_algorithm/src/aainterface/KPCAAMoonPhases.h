#pragma once

#include "PlatformHelpers.h"

#ifdef __cplusplus
extern "C" {
#endif

double KPCAAMoonPhases_K(double Year);
double KPCAAMoonPhases_MeanPhase(double k);
double KPCAAMoonPhases_TruePhase(double k);

#if __cplusplus
}
#endif