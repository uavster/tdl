#ifndef SAMPLEHOLDINTERPOLATOR_H_
#define SAMPLEHOLDINTERPOLATOR_H_

#include "intpltor.hpp"

template<class SampleT> class SampleHoldInterpolator : public virtual Interpolator<SampleT> {
public:
	SampleHoldInterpolator() : Interpolator<SampleT>() {}
	SampleHoldInterpolator(TimeSignal<SampleT> &signal) : Interpolator<SampleT>(signal) {}

	virtual SampleT getValue(float time);
	virtual SubspaceType getSubspace() { return SUBSPACE_WHOLE; }
};

#include "samphold.hh"

#endif /* SAMPLEHOLDINTERPOLATOR_H_ */