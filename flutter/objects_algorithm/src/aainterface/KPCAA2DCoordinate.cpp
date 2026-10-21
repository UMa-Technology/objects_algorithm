#include "KPCAA2DCoordinate.h"
#include "../aaplus/AA2DCoordinate.h"

KPCAA2DCoordinateComponents KPCAA2DCoordinateComponentsMake(double X, double Y)
{
    KPCAA2DCoordinateComponents comps;
    comps.X = X;
    comps.Y = Y;
    return comps;
}