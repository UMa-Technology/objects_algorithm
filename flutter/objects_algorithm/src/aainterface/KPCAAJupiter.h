#pragma once

//
//  KPCAAJupiter.h
//  SwiftAA
//
//  Created by Cédric Foellmi on 09/07/15.
//  Licensed under the MIT License (see LICENSE file)
//

#include "PlatformHelpers.h"

#ifdef __cplusplus
extern "C" {
#endif

double KPCAAJupiter_EclipticLongitude(double JD, bool highPrecision);
double KPCAAJupiter_EclipticLatitude(double JD, bool highPrecision);
double KPCAAJupiter_RadiusVector(double JD, bool highPrecision);

#if __cplusplus
}
#endif