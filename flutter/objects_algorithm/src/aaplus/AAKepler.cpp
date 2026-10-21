/*
Module : AAKepler.cpp
Purpose: Implementation for the algorithms which solve Kepler's equation
Created: PJN / 29-12-2003
History: PJN / 22-11-2021 1. Made some minor optimizations to the CAAKepler::Calculate method.
         PJN / 26-06-2022 1. Updated all the code in AAKepler.cpp to use C++ uniform initialization for all
                          variable declarations.
         PJN / 06-12-2025 1. Provided a new CAAKepler::CalculateRadians method which works in radians as 
                          opposed to degrees for the main CAAKepler::Calculate method.
                          2. Optimized the code in the new CAAKepler::CalculateRadians method.
                          3. Updated CAAKepler::Calculate and CAAKepler::CalculateRadians to use a "double
                          epsilon" value instead of an "int iterations" parameter. These improvements help
                          speed up the CAAKepler::Calculate method by a factor of two.

Copyright (c) 2003 - 2026 by PJ Naughter (Web: www.naughter.com, Email: pjna@naughter.com)

All rights reserved.

Copyright / Usage Details:

You are allowed to include the source code in any product (commercial, shareware, freeware or otherwise) 
when your product is released in binary form. You are allowed to modify the source code in any way you want 
except you cannot modify the copyright details at the top of each module. If you want to distribute source 
code with your application, then you are only allowed to distribute versions released by the author. This is 
to maintain a single distribution point for the source code.

*/


//////////////////// Includes /////////////////////////////////////////////////

#include "stdafx.h"
#include "AAKepler.h"
#include "AACoordinateTransformation.h"
#include <cmath>


//////////////////// Implementation ///////////////////////////////////////////

double CAAKepler::Calculate(double M, double e, double epsilon) noexcept
{
  return CAACoordinateTransformation::RadiansToDegrees(CalculateRadians(CAACoordinateTransformation::DegreesToRadians(M), e, CAACoordinateTransformation::DegreesToRadians(epsilon)));
}

double CAAKepler::CalculateRadians(double M, double e, double epsilon) noexcept
{
  constexpr double PI{CAACoordinateTransformation::PI()};
  constexpr double TWOPI{PI*2};
  //Reduce M to a value in the range -TWOPI < M < TWOPI
  double F{0};
  if (M < 0)
    F = -1;
  else if (M > 0)
    F = 1;
  else
    return 0;
  M = fabs(M)/TWOPI;
  M = (M - static_cast<int>(M))*TWOPI*F;
  //Make M a value in the range 0 < M < TWOPI
  if (M < 0)
    M += TWOPI;
  bool bPositive{true};
  if (M > PI)
  {
    M = TWOPI - M;
    bPositive = false;
  }
  else if (M == 0)
    return 0;
  const double e2{e/2};
  double E{M + e2};
  double D{e2};
  while (D > epsilon)
  {
    const double M1{E - (e*sin(E))};
    if (M > M1)
      E += D;
    else
      E -= D;
    D /= 2;
  }
  if (bPositive)
    return E;
  else
    return -E;
}
