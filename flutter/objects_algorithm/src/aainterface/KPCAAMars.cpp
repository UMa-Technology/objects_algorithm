//
//  KPCAAMars.m
//  SwiftAA
//
//  Created by Cédric Foellmi on 09/07/15.
//  Licensed under the MIT License (see LICENSE file)
//

#include "KPCAAMars.h"
#include "../aaplus/AAMars.h"

double KPCAAMars_EclipticLongitude(double JD, bool highPrecision)
{
    return CAAMars::EclipticLongitude(JD, highPrecision);
}

double KPCAAMars_EclipticLatitude(double JD, bool highPrecision)
{
    return CAAMars::EclipticLatitude(JD, highPrecision);
}

double KPCAAMars_RadiusVector(double JD, bool highPrecision)
{
    return CAAMars::RadiusVector(JD, highPrecision);
}

