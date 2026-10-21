//
//  KPCAAMercury.m
//  SwiftAA
//
//  Created by Cédric Foellmi on 09/07/15.
//  Licensed under the MIT License (see LICENSE file)
//

#include "KPCAAMercury.h"
#include "../aaplus/AAMercury.h"

double KPCAAMercury_EclipticLongitude(double JD, bool highPrecision)
{
    return CAAMercury::EclipticLongitude(JD, highPrecision);
}

double KPCAAMercury_EclipticLatitude(double JD, bool highPrecision)
{
    return CAAMercury::EclipticLatitude(JD, highPrecision);
}

double KPCAAMercury_RadiusVector(double JD, bool highPrecision)
{
    return CAAMercury::RadiusVector(JD, highPrecision);
}

