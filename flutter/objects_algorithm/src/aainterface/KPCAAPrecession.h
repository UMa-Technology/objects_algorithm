#pragma once

//
//  KPCAAPrecession.h
//  SwiftAA
//
//  Created by Cédric Foellmi on 10/07/15.
//  Licensed under the MIT License (see LICENSE file)
//

#include "PlatformHelpers.h"
#include "KPCAA2DCoordinate.h"

#ifdef __cplusplus
extern "C" {
#endif

KPCAA2DCoordinateComponents KPCAAPrecession_PrecessEquatorial(double Alpha, double Delta, double JD0, double JD);
KPCAA2DCoordinateComponents KPCAAPrecession_PrecessEquatorialFK4(double Alpha, double Delta, double JD0, double JD);
KPCAA2DCoordinateComponents KPCAAPrecession_PrecessEcliptic(double Lambda, double Beta, double JD0, double JD);

KPCAA2DCoordinateComponents KPCAAPrecession_EquatorialPMToEcliptic(double Alpha,
                                                                   double Delta,
                                                                   double Beta,
                                                                   double PMAlpha,
                                                                   double PMDelta,
                                                                   double Epsilon);

KPCAA2DCoordinateComponents KPCAAPrecession_AdjustPositionUsingUniformProperMotion(double t,
                                                                                   double Alpha,
                                                                                   double Delta,
                                                                                   double PMAlpha,
                                                                                   double PMDelta);

KPCAA2DCoordinateComponents KPCAAPrecession_AdjustPositionUsingMotionInSpace(double r,
                                                                             double deltar,
                                                                             double t,
                                                                             double Alpha,
                                                                             double Delta,
                                                                             double PMAlpha,
                                                                             double PMDelta);

#if __cplusplus
}
#endif