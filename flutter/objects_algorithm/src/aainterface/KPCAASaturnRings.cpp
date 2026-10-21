//
//  KPCAASaturnRings.m
//  SwiftAA
//
//  Created by Cédric Foellmi on 10/07/15.
//  Licensed under the MIT License (see LICENSE file)
//

#include "KPCAASaturnRings.h"
#include "../aaplus/AASaturnRings.h"

KPCAASaturnRingDetails KPCAASaturnRings_Calculate(double JD, bool highPrecision)
{
    CAASaturnRingDetails details = CAASaturnRings::Calculate(JD, highPrecision);
    KPCAASaturnRingDetails results;
    results.B = details.B;
    results.Bdash = details.Bdash;
    results.P = details.P;
    results.a = details.a;
    results.b = details.b;
    results.DeltaU = details.DeltaU;
    results.U1 = details.U1;
    results.U2 = details.U2;
    return results;
}
