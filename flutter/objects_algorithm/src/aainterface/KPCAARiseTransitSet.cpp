//
//  KPCAARiseTransitSet.m
//  SwiftAA
//
//  Created by Cédric Foellmi on 10/07/15.
//  Licensed under the MIT License (see LICENSE file)
//

#include "KPCAARiseTransitSet.h"
#include "../aaplus/AARiseTransitSet.h"

KPCAARiseTransitSetDetails KPCAARiseTransitSet_Calculate(double JD,
                                                         double Alpha1,
                                                         double Delta1,
                                                         double Alpha2,
                                                         double Delta2,
                                                         double Alpha3,
                                                         double Delta3,
                                                         double Longitude,
                                                         double Latitude,
                                                         double h0)
{
    CAARiseTransitSetDetails detailsPlus = CAARiseTransitSet::Calculate(JD, Alpha1, Delta1, Alpha2, Delta2, Alpha3, Delta3, Longitude, Latitude, h0);
    
    KPCAARiseTransitSetDetails details;
    details.isRiseValid = detailsPlus.bRiseValid;
    details.Rise = detailsPlus.Rise;
    details.isTransitAboveHorizon = detailsPlus.bTransitAboveHorizon;
    details.Transit = detailsPlus.Transit;
    details.isSetValid = detailsPlus.bSetValid;
    details.Set = detailsPlus.Set;
    
    return details;
}