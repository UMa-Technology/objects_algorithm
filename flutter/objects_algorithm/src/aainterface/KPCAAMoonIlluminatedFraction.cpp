#include "KPCAAMoonIlluminatedFraction.h"
#include "../aaplus/AAMoonIlluminatedFraction.h"


double KPCAAMoonIlluminatedFraction_GeocentricElongation(double ObjectAlpha, double ObjectDelta, double SunAlpha, double SunDelta)
{
    return CAAMoonIlluminatedFraction::GeocentricElongation(ObjectAlpha, ObjectDelta, SunAlpha, SunDelta);
}

double KPCAAMoonIlluminatedFraction_PhaseAngle(double GeocentricElongation, double EarthObjectDistance, double EarthSunDistance)
{
    return CAAMoonIlluminatedFraction::PhaseAngle(GeocentricElongation, EarthObjectDistance, EarthSunDistance);
}

double KPCAAMoonIlluminatedFraction_IlluminatedFraction(double PhaseAngle)
{
    return CAAMoonIlluminatedFraction::IlluminatedFraction(PhaseAngle);
}

double KPCAAMoonIlluminatedFraction_PositionAngle(double Alpha0, double Delta0, double Alpha, double Delta)
{
    return CAAMoonIlluminatedFraction::PositionAngle(Alpha0, Delta0, Alpha, Delta);
}