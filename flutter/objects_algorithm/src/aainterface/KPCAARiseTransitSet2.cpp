#include "KPCAARiseTransitSet2.h"
#include "../aaplus/AARiseTransitSet2.h"

namespace {
// The sun has at most 10 events in a 24h window (rise, set, upper/lower transit, three dawn
// twilights, three dusk twilights), but when the window boundaries fall between events, each
// end can carry an extra event of the same kind -- up to 11 observed in practice. Sizing for 10
// drops the trailing twilight, the caller's dusk->dawn pairing jumps to the next day, and the
// night comes out longer than 30 hours. Keep a 2x margin.
constexpr size_t kRiseTransitSetResultSlots = 20;

KPCAARiseTransitSetDetails2* CopyResults(const std::vector<CAARiseTransitSetDetails2>& results) {
    auto kpResults = new KPCAARiseTransitSetDetails2[kRiseTransitSetResultSlots];
    for (size_t i = 0; i < kRiseTransitSetResultSlots; i++) {
        kpResults[i].type = 0;
        kpResults[i].jd = 0;
        kpResults[i].bearing = 0;
        kpResults[i].altitude = 0;
        kpResults[i].aboveHorizon = false;
    }

    const size_t count = results.size() < kRiseTransitSetResultSlots
        ? results.size()
        : kRiseTransitSetResultSlots;
    for (size_t i = 0; i < count; i++) {
        const auto& result = results[i];
        kpResults[i].type = static_cast<int>(result.type);
        kpResults[i].jd = result.JD;
        kpResults[i].bearing = result.Bearing;
        kpResults[i].altitude = result.GeometricAltitude;
        kpResults[i].aboveHorizon = result.bAboveHorizon;
    }

    return kpResults;
}
}

KPCAARiseTransitSetDetails2* KPCAARiseTransitSet2_CalculateStationary(double startJD,
                                                                    double endJD,
                                                                    double alpha,
                                                                    double delta,
                                                                    double longitude, 
                                                                    double latitude, 
                                                                    double h0 = -0.5667, 
                                                                    double stepInterval = 0.007) 
{
    // Call the C++ implementation
    auto results = CAARiseTransitSet2::CalculateStationary(
        startJD, endJD, alpha, delta, longitude, latitude, h0, stepInterval);

    return CopyResults(results);
}

KPCAARiseTransitSetDetails2 *KPCAARiseTransitSet2_Calculate(double StartJD, double EndJD, KPCAAObject object, double Longitude, double Latitude, double h0, double StepInterval = 0.007, bool bHighPrecision = false)
{
    // Call the C++ implementation
    auto results = CAARiseTransitSet2::Calculate(StartJD, EndJD, (CAARiseTransitSet2::Object)object, Longitude, Latitude, h0, StepInterval, bHighPrecision);

    return CopyResults(results);
}


// Free the result array
void KPCAARiseTransitSet2_FreeResults(KPCAARiseTransitSetDetails2* results) {
    delete[] results;
}