//
//  KPCAAMoon.m
//  SwiftAA
//
//  Created by Cédric Foellmi on 09/07/15.
//  Licensed under the MIT License (see LICENSE file)
//

#include "KPCAAMoon.h"
#include "../aaplus/AAMoon.h"
#include "../aaplus/AAELP2000.h"

double KPCAAMoon_MeanLongitude(double JD)
{
    return CAAMoon::MeanLongitude(JD);
}

double KPCAAMoon_MeanElongation(double JD)
{
    return CAAMoon::MeanElongation(JD);
}

double KPCAAMoon_MeanAnomaly(double JD)
{
    return CAAMoon::MeanAnomaly(JD);
}

double KPCAAMoon_ArgumentOfLatitude(double JD)
{
    return CAAMoon::ArgumentOfLatitude(JD);
}

double KPCAAMoon_MeanLongitudeAscendingNode(double JD)
{
    return CAAMoon::MeanLongitudeAscendingNode(JD);
}

double KPCAAMoon_MeanLongitudePerigee(double JD)
{
    return CAAMoon::MeanLongitudePerigee(JD);
}

double KPCAAMoon_TrueLongitudeAscendingNode(double JD)
{
    return CAAMoon::TrueLongitudeAscendingNode(JD);
}


double KPCAAMoon_EclipticLongitude(double JD)
{
    return CAAMoon::EclipticLongitude(JD);
}

double KPCAAMoon_EclipticLatitude(double JD)
{
    return CAAMoon::EclipticLatitude(JD);
}

double KPCAAMoon_RadiusVector(double JD)
{
    return CAAMoon::RadiusVector(JD);
}


double KPCAAMoon_RadiusVectorToHorizontalParallax(double RadiusVector)
{
    return CAAMoon::RadiusVectorToHorizontalParallax(RadiusVector);
}

double KPCAAMoon_HorizontalParallaxToRadiusVector(double Parallax)
{
    return CAAMoon::HorizontalParallaxToRadiusVector(Parallax);
}

double KPCAAMoon_EclipticLongitudeByELP2000(double JD)
{
    return CAAELP2000::EclipticLongitude(JD);
}

double KPCAAMoon_EclipticLatitudeByELP2000(double JD)
{
    return CAAELP2000::EclipticLatitude(JD);
}