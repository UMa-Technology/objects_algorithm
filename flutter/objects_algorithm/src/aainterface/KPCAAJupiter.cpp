//
//  KPCAAJupiter.m
//  SwiftAA
//
//  Created by Cédric Foellmi on 09/07/15.
//  Licensed under the MIT License (see LICENSE file)
//

#include "KPCAAJupiter.h"
#include "../aaplus/AAJupiter.h"

double KPCAAJupiter_EclipticLongitude(double JD, bool highPrecision)
{
    return CAAJupiter::EclipticLongitude(JD, highPrecision);
}

double KPCAAJupiter_EclipticLatitude(double JD, bool highPrecision)
{
    return CAAJupiter::EclipticLatitude(JD, highPrecision);
}

double KPCAAJupiter_RadiusVector(double JD, bool highPrecision)
{
    return CAAJupiter::RadiusVector(JD, highPrecision);
}
