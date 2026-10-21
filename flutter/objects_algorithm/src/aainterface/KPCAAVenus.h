#pragma once

//
//  KPCAAVenus.h
//  SwiftAA
//
//  Created by Cédric Foellmi on 10/07/15.
//  Licensed under the MIT License (see LICENSE file)
//

#include "PlatformHelpers.h"

#ifdef __cplusplus
extern "C" {
#endif

double KPCAAVenus_EclipticLongitude(double JD, bool highPrecision);
double KPCAAVenus_EclipticLatitude(double JD, bool highPrecision);
double KPCAAVenus_RadiusVector(double JD, bool highPrecision);

#if __cplusplus
}
#endif