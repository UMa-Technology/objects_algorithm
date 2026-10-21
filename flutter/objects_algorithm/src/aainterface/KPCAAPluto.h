#pragma once

//
//  KPCAAPluto.h
//  SwiftAA
//
//  Created by Cédric Foellmi on 10/07/15.
//  Licensed under the MIT License (see LICENSE file)
//

#include "PlatformHelpers.h"

#ifdef __cplusplus
extern "C" {
#endif

double KPCAAPluto_EclipticLongitude(double JD);
double KPCAAPluto_EclipticLatitude(double JD);
double KPCAAPluto_RadiusVector(double JD);

#if __cplusplus
}
#endif