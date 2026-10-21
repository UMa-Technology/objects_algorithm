#include "KPCAA3DCoordinate.h"
#include "../aaplus/AA3DCoordinate.h"

KPCAA3DCoordinateComponents KPCAA3DCoordinateComponentsMake(double X, double Y, double Z)
{
    KPCAA3DCoordinateComponents comps;
    comps.X = X;
    comps.Y = Y;
    comps.Z = Z;
    return comps;
}