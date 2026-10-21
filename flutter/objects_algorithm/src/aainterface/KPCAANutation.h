#pragma once

//
//  KPCAANutation.h
//  SwiftAA
//
//  Created by Cédric Foellmi on 09/07/15.
//  Licensed under the MIT License (see LICENSE file)
//

#include "PlatformHelpers.h"

#ifdef __cplusplus
extern "C" {
#endif

double KPCAANutation_NutationInLongitude(double JD);
double KPCAANutation_NutationInObliquity(double JD);
double KPCAANutation_NutationInRightAscension(double Alpha, double Delta, double Obliquity, double NutationInLongitude, double NutationInObliquity);
double KPCAANutation_NutationInDeclination(double Alpha, double Obliquity, double NutationInLongitude, double NutationInObliquity);
double KPCAANutation_MeanObliquityOfEcliptic(double JD);
double KPCAANutation_TrueObliquityOfEcliptic(double JD);

/* SwiftAA Additions */
    
double KPCAANutation_ObliquityOfEcliptic(bool mean, double JD);
    
#if __cplusplus
}
#endif