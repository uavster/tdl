#ifndef INTERPOLATOR_H_
#define INTERPOLATOR_H_

#include "tsignal.hpp"

typedef enum { SUBSPACE_WHOLE, SUBSPACE_SPHERICAL } SubspaceType;

template<class SampleT> class Interpolator {
public:
	Interpolator() { this->signal = NULL; }
	Interpolator(TimeSignal<SampleT> &signal) {
		// Do not call virtual setSignal() from constructor.
		this->signal = &signal;
	}

	virtual void setSignal(TimeSignal<SampleT> &signal) { this->signal = &signal; }
	TimeSignal<SampleT> *getSignal() const { return signal; }

	virtual SampleT getValue(float time) = 0;
	virtual SubspaceType getSubspace() = 0;

private:
	TimeSignal<SampleT> *signal;
};

#endif /* INTERPOLATOR_H_ */