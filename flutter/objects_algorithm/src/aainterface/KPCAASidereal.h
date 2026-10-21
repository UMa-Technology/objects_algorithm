#pragma once

//
//  KPCAASidereal.h
//  SwiftAA
//
//  Created by Cédric Foellmi on 10/07/15.
//  Licensed under the MIT License (see LICENSE file)
//

#include "PlatformHelpers.h"

#ifdef __cplusplus
extern "C" {
#endif

double KPCAASidereal_MeanGreenwichSiderealTime(double JD);
double KPCAASidereal_ApparentGreenwichSiderealTime(double JD);

#if __cplusplus
}
#endif