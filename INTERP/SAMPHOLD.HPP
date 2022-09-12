#ifndef SAMPLEHOLDINTERPOLATOR_H_
#define SAMPLEHOLDINTERPOLATOR_H_

#include "intpltor.hpp"

template<class _SampleT> class SampleHoldInterpolator : public virtual Interpolator<_SampleT> {
public:
	SampleHoldInterpolator() : Interpolator<_SampleT>() {}
	SampleHoldInterpolator(TimeSignal<_SampleT> &signal) : Interpolator<_SampleT>(signal) {}

	virtual _SampleT getValue(float time);
	virtual SubspaceType getSubspace() { return SUBSPACE_WHOLE; }
};

#include "samphold.hh"

#endif /* SAMPLEHOLDINTERPOLATOR_H_ */