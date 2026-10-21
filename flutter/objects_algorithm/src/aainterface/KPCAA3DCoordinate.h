#pragma once

#include "PlatformHelpers.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct KPCAA3DCoordinateComponents {
    double X;
    double Y;
    double Z;
} KPCAA3DCoordinateComponents;

// Because we can't (and don't want) import C++ header in this one, one must go through the exposition of all vars.
KPCAA3DCoordinateComponents KPCAA3DCoordinateComponentsMake(double X, double Y, double Z);

#if __cplusplus
}
#endif