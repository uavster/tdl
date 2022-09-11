#ifndef INTERPOLATOR_H_
#define INTERPOLATOR_H_

#include "tsignal.hpp"

typedef enum { SUBSPACE_WHOLE, SUBSPACE_SPHERICAL } SubspaceType;

template<class _T> class Interpolator {
public:
	Interpolator() { this->signal = NULL; }
	Interpolator(TimeSignal<_T> &signal) {
		// Do not call virtual setSignal() from constructor.
		this->signal = &signal;
	}

	virtual void setSignal(TimeSignal<_T> &signal) { printf("I::setSignal\n"); this->signal = &signal; }
	TimeSignal<_T> *getSignal() const { return signal; }

	virtual _T getValue(float time) = 0;
	virtual SubspaceType getSubspace() = 0;

private:
	TimeSignal<_T> *signal;
};

#endif /* INTERPOLATOR_H_ */