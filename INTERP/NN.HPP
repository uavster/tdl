#ifndef NEARESTNEIGHBORINTERPOLATOR_H_
#define NEARESTNEIGHBORINTERPOLATOR_H_

#include "intpltor.hpp"

template<class _SampleT> class NearestNeighborInterpolator : public virtual Interpolator<_SampleT> {
public:
	NearestNeighborInterpolator() : Interpolator<_SampleT>() {}
	NearestNeighborInterpolator(TimeSignal<_SampleT> &signal) : Interpolator<_SampleT>(signal) {}

	virtual _SampleT getValue(float time);
	virtual SubspaceType getSubspace() { return SUBSPACE_WHOLE; }
};

#include "nn.hh"

#endif /* NEARESTNEIGHBORINTERPOLATOR_H_ */