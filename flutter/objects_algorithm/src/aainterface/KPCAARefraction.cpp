//
//  KPCAARefraction.m
//  SwiftAA
//
//  Created by Cédric Foellmi on 10/07/15.
//  Licensed under the MIT License (see LICENSE file)
//

#include "KPCAARefraction.h"
#include "../aaplus/AARefraction.h"

double KPCAARefraction_RefractionFromApparentWithAltitude(double Altitude, double Pressure,  double Temperature)
{
    return CAARefraction::RefractionFromApparent(Altitude, Pressure, Temperature);
}

double KPCAARefraction_RefractionFromTrueWithAltitude(double Altitude, double Pressure, double Temperature)
{
    return CAARefraction::RefractionFromTrue(Altitude, Pressure, Temperature);
}