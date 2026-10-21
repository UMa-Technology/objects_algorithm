#pragma once

//
//  KPCAARefraction.h
//  SwiftAA
//
//  Created by Cédric Foellmi on 10/07/15.
//  Licensed under the MIT License (see LICENSE file)
//

#include "PlatformHelpers.h"

#ifdef __cplusplus
extern "C" {
#endif

// Standard Pressure = 1010
// Standard Temperature = 10

double KPCAARefraction_RefractionFromApparentWithAltitude(double Altitude, double Pressure,  double Temperature);
double KPCAARefraction_RefractionFromTrueWithAltitude(double Altitude, double Pressure, double Temperature);

#if __cplusplus
}
#endif