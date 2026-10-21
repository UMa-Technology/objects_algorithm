/*
Module : AAHyperbolic.cpp
Purpose: Implementation for the algorithms for a Hyperbolic orbit
Created: PJN / 03-12-2025
History: PJN / 28-12-2025 1. Initial creation.
         PJN / 07-12-2025 1. Updated CAAHyperbolic::Calculate to return the radius vector and the true anomaly.

Copyright (c) 2025 - 2026 by PJ Naughter (Web: www.naughter.com, Email: pjna@naughter.com)

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
#include "AAHyperbolic.h"
#include "AACoordinateTransformation.h"
#include "AASun.h"
#include "AANutation.h"
#include "AAElliptical.h"
#include <cmath>


//////////////////// Implementation ///////////////////////////////////////////

double CAAHyperbolic::CalculateKeplers(double M, double e, double epsilon) noexcept
{
  bool bRecalc{true};
  double Hk{M};
  while (bRecalc)
  {
    const double Hk1{Hk - ((e*sinh(Hk) - Hk - M)/((e*cosh(Hk)) - 1))};

    //Prepare for the next loop around
    bRecalc = (fabs(Hk1 - Hk) > epsilon);
    Hk = Hk1;
  }

  return Hk;
}

void CAAHyperbolic::CalculateTrueAnomalyAndRadius(double JD, const CAAHyperbolicObjectElements& elements, double& v, double& r, double epsilon) noexcept
{
  const double a{elements.q/(elements.e - 1)};
  const double n{sqrt(0.0002959122082855911025/pow(fabs(a), 3))};
  const double M{(JD - elements.T)*n};
  const double H{CalculateKeplers(M, elements.e, epsilon)};
  v = 2*atan(sqrt((elements.e + 1)/(elements.e - 1))*tanh(H/2));
  r = fabs(a)*(elements.e*cosh(H) - 1);
}

CAAHyperbolicObjectDetails CAAHyperbolic::Calculate(double JD, const CAAHyperbolicObjectElements& elements, bool bHighPrecision, double epsilon) noexcept
{
  double Epsilon{CAANutation::MeanObliquityOfEcliptic(elements.JDEquinox)};
  double JD0{JD};

  //What will be the return value
  CAAHyperbolicObjectDetails details;

  Epsilon = CAACoordinateTransformation::DegreesToRadians(Epsilon);
  const double omega{CAACoordinateTransformation::DegreesToRadians(elements.omega)};
  const double w{CAACoordinateTransformation::DegreesToRadians(elements.w)};
  const double i{CAACoordinateTransformation::DegreesToRadians(elements.i)};

  const double sinEpsilon{sin(Epsilon)};
  const double cosEpsilon{cos(Epsilon)};
  const double sinOmega{sin(omega)};
  const double cosOmega{cos(omega)};
  const double cosi{cos(i)};
  const double sini{sin(i)};

  const double F{cosOmega};
  const double G{sinOmega*cosEpsilon};
  const double H{sinOmega*sinEpsilon};
  const double P{-sinOmega*cosi};
  const double Q{(cosOmega*cosi*cosEpsilon) - (sini*sinEpsilon)};
  const double R{(cosOmega*cosi*sinEpsilon) + (sini*cosEpsilon)};
  const double a{sqrt((F*F) + (P*P))};
  const double b{sqrt((G*G) + (Q*Q))};
  const double c{sqrt((H*H) + (R*R))};
  const double A{atan2(F, P)};
  const double B{atan2(G, Q)};
  const double C{atan2(H, R)};

  const CAA3DCoordinate SunCoord{CAASun::EquatorialRectangularCoordinatesAnyEquinox(JD, elements.JDEquinox, bHighPrecision)};
  for (int j{0}; j<2; j++)
  {
    double v{0};
    double r{0};
    CalculateTrueAnomalyAndRadius(JD0, elements, v, r, epsilon);
    const double x{r*a*sin(A + w + v)};
    const double y{r*b*sin(B + w + v)};
    const double z{r*c*sin(C + w + v)};

    if (j == 0)
    {
      details.r = r;
      details.v = CAACoordinateTransformation::RadiansToDegrees(v);
      details.HeliocentricRectangularEquatorial.X = x;
      details.HeliocentricRectangularEquatorial.Y = y;
      details.HeliocentricRectangularEquatorial.Z = z;

      //Calculate the heliocentric ecliptic coordinates also
      const double u{w + v};
      const double cosu{cos(u)};
      const double sinu{sin(u)};

      details.HeliocentricRectangularEcliptical.X = r*((cosOmega*cosu) - (sinOmega*sinu*cosi));
      details.HeliocentricRectangularEcliptical.Y = r*((sinOmega*cosu) + (cosOmega*sinu*cosi));
      details.HeliocentricRectangularEcliptical.Z = r*sini*sinu;

      details.HeliocentricEclipticLongitude = CAACoordinateTransformation::MapTo0To360Range(CAACoordinateTransformation::RadiansToDegrees(atan2(details.HeliocentricRectangularEcliptical.Y, details.HeliocentricRectangularEcliptical.X)));
      details.HeliocentricEclipticLatitude = CAACoordinateTransformation::RadiansToDegrees(asin(details.HeliocentricRectangularEcliptical.Z/r));
    }

    const double psi{SunCoord.X + x};
    const double psi2{psi*psi};
    const double nu{SunCoord.Y + y};
    const double nu2{nu*nu};
    const double sigma{SunCoord.Z + z};

    double Alpha{atan2(nu, psi)};
    Alpha = CAACoordinateTransformation::RadiansToDegrees(Alpha);
    double Delta{atan2(sigma, sqrt(psi2 + nu2))};
    Delta = CAACoordinateTransformation::RadiansToDegrees(Delta);
    const double Distance{sqrt(psi2 + nu2 + (sigma*sigma))};
    const double Distance2{Distance*Distance};

    if (j == 0)
    {
      details.TrueGeocentricRA = CAACoordinateTransformation::MapTo0To24Range(Alpha/15);
      details.TrueGeocentricDeclination = Delta;
      details.TrueGeocentricDistance = Distance;
      details.TrueGeocentricLightTime = CAAElliptical::DistanceToLightTime(Distance);
    }
    else
    {
      details.AstrometricGeocentricRA = CAACoordinateTransformation::MapTo0To24Range(Alpha/15);
      details.AstrometricGeocentricDeclination = Delta;
      details.AstrometricGeocentricDistance = Distance;
      details.AstrometricGeocentricLightTime = CAAElliptical::DistanceToLightTime(Distance);

      const double RES{sqrt((SunCoord.X*SunCoord.X) + (SunCoord.Y*SunCoord.Y) + (SunCoord.Z*SunCoord.Z))};
      const double RES2{RES*RES};
      const double r2{r*r};

      details.Elongation = CAACoordinateTransformation::RadiansToDegrees(acos((RES2 + Distance2 - r2) / (2*RES*Distance)));
      details.PhaseAngle = CAACoordinateTransformation::RadiansToDegrees(acos((r2 + Distance2 - RES2) / (2*r*Distance)));
    }

    if (j == 0) //Prepare for the next loop around
      JD0 = JD - details.TrueGeocentricLightTime;
  }

  return details;
}
