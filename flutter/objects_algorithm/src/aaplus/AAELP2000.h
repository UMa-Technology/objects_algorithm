/*
Module : AAELP2000.h
Purpose: Implementation for the algorithms for ELP2000-82B
Created: PJN / 28-12-2015
History: PJN / 28-12-2015 1. Initial public release.

Copyright (c) 2015 - 2026 by PJ Naughter (Web: www.naughter.com, Email: pjna@naughter.com)

All rights reserved.

Copyright / Usage Details:

You are allowed to include the source code in any product (commercial, shareware, freeware or otherwise)
when your product is released in binary form. You are allowed to modify the source code in any way you want
except you cannot modify the copyright details at the top of each module. If you want to distribute source
code with your application, then you are only allowed to distribute versions released by the author. This is
to maintain a single distribution point for the source code.

*/


//////////////////// Macros / Defines /////////////////////////////////////////

#if _MSC_VER > 1000
#pragma once
#endif

#ifndef __AAELP2000_H__
#define __AAELP2000_H__

#ifndef AAPLUS_EXT_CLASS
#define AAPLUS_EXT_CLASS
#endif


//////////////////// Includes /////////////////////////////////////////////////

#include <array>
#include <cstddef>
#include "AA3DCoordinate.h"


//////////////////// Classes //////////////////////////////////////////////////

struct AAPLUS_EXT_CLASS ELP2000MainProblemCoefficient
{
  std::array<int, 4> m_I;
  double m_A;
  std::array<double, 6> m_B;
};

struct AAPLUS_EXT_CLASS ELP2000EarthTidalMoonRelativisticSolarEccentricityCoefficient
{
  int m_IZ;
  std::array<int, 4> m_I;
  double m_O;
  double m_A;
  double m_P;
};

struct AAPLUS_EXT_CLASS ELP2000PlanetPertCoefficient
{
  std::array<int, 11> m_ip;
  double m_theta;
  double m_O;
  double m_P;
};

class AAPLUS_EXT_CLASS CAAELP2000
{
public:
//Static methods
  [[nodiscard]] static double EclipticLongitude(double JD) noexcept;
  [[nodiscard]] static double EclipticLongitude(const double* pT, int nTSize) noexcept;
  [[nodiscard]] static double EclipticLatitude(double JD) noexcept;
  [[nodiscard]] static double EclipticLatitude(const double* pT, int nTSize) noexcept;
  [[nodiscard]] static double RadiusVector(double JD) noexcept;
  [[nodiscard]] static double RadiusVector(const double* pT, int nTSize) noexcept;
  [[nodiscard]] static CAA3DCoordinate EclipticRectangularCoordinates(double JD) noexcept;
  [[nodiscard]] static CAA3DCoordinate EclipticRectangularCoordinatesJ2000(double JD) noexcept;
  [[nodiscard]] static CAA3DCoordinate EquatorialRectangularCoordinatesFK5(double JD) noexcept;
  [[nodiscard]] static double MoonMeanMeanLongitude(const double* pT, int nTSize) noexcept;
  [[nodiscard]] static double MoonMeanMeanLongitude(double JD) noexcept;
  [[nodiscard]] static double MeanLongitudeLunarPerigee(const double* pT, int nTSize) noexcept;
  [[nodiscard]] static double MeanLongitudeLunarPerigee(double JD) noexcept;
  [[nodiscard]] static double MeanLongitudeLunarAscendingNode(const double* pT, int nTSize) noexcept;
  [[nodiscard]] static double MeanLongitudeLunarAscendingNode(double JD) noexcept;
  [[nodiscard]] static double MeanHeliocentricMeanLongitudeEarthMoonBarycentre(const double* pT, int nTSize) noexcept;
  [[nodiscard]] static double MeanHeliocentricMeanLongitudeEarthMoonBarycentre(double JD) noexcept;
  [[nodiscard]] static double MeanLongitudeOfPerihelionOfEarthMoonBarycentre(const double* pT, int nTSize) noexcept;
  [[nodiscard]] static double MeanLongitudeOfPerihelionOfEarthMoonBarycentre(double JD) noexcept;
  [[nodiscard]] static double MoonMeanSolarElongation(const double* pT, int nTSize) noexcept;
  [[nodiscard]] static double MoonMeanSolarElongation(double JD) noexcept;
  [[nodiscard]] static double SunMeanAnomaly(const double* pT, int nTSize) noexcept;
  [[nodiscard]] static double SunMeanAnomaly(double JD) noexcept;
  [[nodiscard]] static double MoonMeanAnomaly(const double* pT, int nTSize) noexcept;
  [[nodiscard]] static double MoonMeanAnomaly(double JD) noexcept;
  [[nodiscard]] static double MoonMeanArgumentOfLatitude(const double* pT, int nTSize) noexcept;
  [[nodiscard]] static double MoonMeanArgumentOfLatitude(double JD) noexcept;
  [[nodiscard]] static double MercuryMeanLongitude(double T) noexcept;
  [[nodiscard]] static double VenusMeanLongitude(double T) noexcept;
  [[nodiscard]] static double MarsMeanLongitude(double T) noexcept;
  [[nodiscard]] static double JupiterMeanLongitude(double T) noexcept;
  [[nodiscard]] static double SaturnMeanLongitude(double T) noexcept;
  [[nodiscard]] static double UranusMeanLongitude(double T) noexcept;
  [[nodiscard]] static double NeptuneMeanLongitude(double T) noexcept;

protected:
//static methods
  [[nodiscard]] static double Accumulate(const ELP2000MainProblemCoefficient* pCoefficients, size_t nCoefficients, double fD, double fldash, double fl, double fF) noexcept;
  [[nodiscard]] static double Accumulate_2(const ELP2000MainProblemCoefficient* pCoefficients, size_t nCoefficients, double fD, double fldash, double fl, double fF) noexcept;
  [[nodiscard]] static double Accumulate(const double* pT, int nTSize, const ELP2000EarthTidalMoonRelativisticSolarEccentricityCoefficient* pCoefficients, size_t nCoefficients, double fD, double fldash, double fl, double fF, bool bI1isZero) noexcept;
  [[nodiscard]] static double Accumulate_2(const double* pT, int nTSize, const ELP2000EarthTidalMoonRelativisticSolarEccentricityCoefficient* pCoefficients, size_t nCoefficients, double fD, double fldash, double fl, double fF, bool bI1isZero) noexcept;
  [[nodiscard]] static double AccumulateTable1(const ELP2000PlanetPertCoefficient* pCoefficients, size_t nCoefficients, double fD, double fl, double fF, double fMe, double fV, double fT, double fMa, double fJ, double fS, double fU, double fN) noexcept;
  [[nodiscard]] static double AccumulateTable1_2(const double* pT, int nTSize, const ELP2000PlanetPertCoefficient* pCoefficients, size_t nCoefficients, double fD, double fl, double fF, double fMe, double fV, double fT, double fMa, double fJ, double fS, double fU, double fN) noexcept;
  [[nodiscard]] static double AccumulateTable2(const ELP2000PlanetPertCoefficient* pCoefficients, size_t nCoefficients, double fD, double fldash, double fl, double fF, double fMe, double fV, double fT, double fMa, double fJ, double fS, double fU) noexcept;
  [[nodiscard]] static double AccumulateTable2_2(const double* pT, int nTSize, const ELP2000PlanetPertCoefficient* pCoefficients, size_t nCoefficients, double fD, double fldash, double fl, double fF, double fMe, double fV, double fT, double fMa, double fJ, double fS, double fU) noexcept;
  [[nodiscard]] static double Accumulate_3(const double* pT, int nTSize, const ELP2000EarthTidalMoonRelativisticSolarEccentricityCoefficient* pCoefficients, size_t nCoefficients, double fD, double fldash, double fl, double fF) noexcept;
};


#endif //#ifndef __AAELP2000_H__
