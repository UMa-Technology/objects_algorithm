#pragma once

//
//  KPCAASaturnRings.h
//  SwiftAA
//
//  Created by Cédric Foellmi on 10/07/15.
//  Licensed under the MIT License (see LICENSE file)
//

#include "PlatformHelpers.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct KPCAASaturnRingDetails {
    double B;
    double Bdash;
    double P;
    double a;
    double b;
    double DeltaU;
    double U1;
    double U2;
} KPCAASaturnRingDetails;

KPCAASaturnRingDetails KPCAASaturnRings_Calculate(double JD, bool highPrecision);

#if __cplusplus
}
#endif
