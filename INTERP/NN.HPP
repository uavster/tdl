#ifndef NEARESTNEIGHBORINTERPOLATOR_H_
#define NEARESTNEIGHBORINTERPOLATOR_H_

#include "intpltor.hpp"

template<class SampleT> class NearestNeighborInterpolator : public virtual Interpolator<SampleT> {
public:
	NearestNeighborInterpolator() : Interpolator<SampleT>() {}
	NearestNeighborInterpolator(TimeSignal<SampleT> &signal) : Interpolator<SampleT>(signal) {}

	virtual SampleT getValue(float time);
	virtual SubspaceType getSubspace() { return SUBSPACE_WHOLE; }
};

#include "nn.hh"

#endif /* NEARESTNEIGHBORINTERPOLATOR_H_ */