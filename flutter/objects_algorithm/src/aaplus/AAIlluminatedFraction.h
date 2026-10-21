/*
Module : AAIlluminatedFraction.h
Purpose: Implementation for the algorithms for a Planet's Phase Angle, Illuminated Fraction and Magnitude
Created: PJN / 29-12-2003

Copyright (c) 2003 - 2026 by PJ Naughter (Web: www.naughter.com, Email: pjna@naughter.com)

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
#endif //#if _MSC_VER > 1000

#ifndef __AAILLUMINATEDFRACTION_H__
#define __AAILLUMINATEDFRACTION_H__

#ifndef AAPLUS_EXT_CLASS
#define AAPLUS_EXT_CLASS
#endif //#ifndef AAPLUS_EXT_CLASS


//////////////////// Classes //////////////////////////////////////////////////

class AAPLUS_EXT_CLASS CAAIlluminatedFraction
{
public:
//Static methods
  [[nodiscard]] static double PhaseAngle(double r, double R, double Delta) noexcept;
  [[nodiscard]] static double PhaseAngle(double R, double R0, double B, double L, double L0, double Delta) noexcept;
  [[nodiscard]] static double PhaseAngleRectangular(double x, double y, double z, double B, double L, double Delta) noexcept;
  [[nodiscard]] static double IlluminatedFraction(double PhaseAngle) noexcept;

  [[nodiscard]] constexpr static double IlluminatedFraction(double r, double R, double Delta) noexcept
  {
    return (((r + Delta)*(r + Delta) - (R*R))/(4*r*Delta));
  }

  [[nodiscard]] static double MercuryMagnitudeMuller(double r, double Delta, double i) noexcept;
  [[nodiscard]] static double VenusMagnitudeMuller(double r, double Delta, double i) noexcept;
  [[nodiscard]] static double MarsMagnitudeMuller(double r, double Delta, double i) noexcept;
  [[nodiscard]] static double JupiterMagnitudeMuller(double r, double Delta) noexcept;
  [[nodiscard]] static double SaturnMagnitudeMuller(double r, double Delta, double DeltaU, double B) noexcept;
  [[nodiscard]] static double UranusMagnitudeMuller(double r, double Delta) noexcept;
  [[nodiscard]] static double NeptuneMagnitudeMuller(double r, double Delta) noexcept;
  [[nodiscard]] static double MercuryMagnitudeAA(double r, double Delta, double i) noexcept;
  [[nodiscard]] static double VenusMagnitudeAA(double r, double Delta, double i) noexcept;
  [[nodiscard]] static double MarsMagnitudeAA(double r, double Delta, double i) noexcept;
  [[nodiscard]] static double JupiterMagnitudeAA(double r, double Delta, double i) noexcept;
  [[nodiscard]] static double SaturnMagnitudeAA(double r, double Delta, double DeltaU, double B) noexcept;
  [[nodiscard]] static double UranusMagnitudeAA(double r, double Delta) noexcept;
  [[nodiscard]] static double NeptuneMagnitudeAA(double r, double Delta) noexcept;
  [[nodiscard]] static double PlutoMagnitudeAA(double r, double Delta) noexcept;
};


#endif //#ifndef __AAILLUMINATEDFRACTION_H__
