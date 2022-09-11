// #include "cubic.hpp"
#include "intpltor.hpp"

#ifndef LINEARINTERPOLATOR_H_
#define LINEARINTERPOLATOR_H_

template<class _T> class LinearInterpolator : public Interpolator<_T> {
public:
	LinearInterpolator() : Interpolator<_T>() {}
	LinearInterpolator(TimeSignal<_T> &signal) : Interpolator<_T>(signal) {}

	virtual _T getValue(float t);
	virtual SubspaceType getSubspace() { return SUBSPACE_WHOLE; }
	virtual void setSignal(TimeSignal<_T> &signal) { Interpolator<_T>::setSignal(signal); }

protected:
	static _T lerp(float normalizedT, const _T &kp0, const _T &kp1);
};

template<class _T> class LinearInterpolatorSpherical : public LinearInterpolator<_T> {
	// template<class _SampleT, SubspaceType _SubspaceT, CubicInterpolationMethod _Method> friend class CubicInterpolator;
public:
	LinearInterpolatorSpherical() : LinearInterpolator<_T>() {}
	LinearInterpolatorSpherical(TimeSignal<_T> &signal) : LinearInterpolator<_T>(signal), preprocessingDone(false) {}
	virtual void setSignal(TimeSignal<_T> &signal) { LinearInterpolator<_T>::setSignal(signal); preprocessingDone = false; }

	virtual _T getValue(float t);
	virtual SubspaceType getSubspace() { return SUBSPACE_SPHERICAL; }

protected:
	static _T slerp(float normalizedT, const _T &kp0, const _T &kp1);
	static void preprocess(TimeSignal<_T> *ts);
private:
	bool preprocessingDone;
};

#include "linear.hh"

#endif /* LINEARINTERPOLATOR_H_ */