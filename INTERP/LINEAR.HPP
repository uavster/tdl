#include "cubic.hpp"
#include "intpltor.hpp"

#ifndef LINEARINTERPOLATOR_H_
#define LINEARINTERPOLATOR_H_

template<class SampleT> class LinearInterpolator : public Interpolator<SampleT> {
public:
	LinearInterpolator() : Interpolator<SampleT>() {}
	LinearInterpolator(TimeSignal<SampleT> &signal) : Interpolator<SampleT>(signal) {}

	virtual SampleT getValue(float t);
	virtual SubspaceType getSubspace() { return SUBSPACE_WHOLE; }
	virtual void setSignal(TimeSignal<SampleT> &signal) { Interpolator<SampleT>::setSignal(signal); }

protected:
	static SampleT lerp(float normalizedT, const SampleT &kp0, const SampleT &kp1);
};

template<class SampleT> class LinearSphericalInterpolator : public LinearInterpolator<SampleT> {
	friend class CubicCatmullRomSphericalInterpolator<SampleT>;
	friend class CubicFiniteDiffSphericalInterpolator<SampleT>;
public:
	LinearSphericalInterpolator() : LinearInterpolator<SampleT>() {}
	LinearSphericalInterpolator(TimeSignal<SampleT> &signal) : LinearInterpolator<SampleT>(signal), preprocessingDone(false) {}
	virtual void setSignal(TimeSignal<SampleT> &signal) { LinearInterpolator<SampleT>::setSignal(signal); preprocessingDone = false; }

	virtual SampleT getValue(float t);
	virtual SubspaceType getSubspace() { return SUBSPACE_SPHERICAL; }

protected:
	static SampleT slerp(float normalizedT, const SampleT &kp0, const SampleT &kp1);
	static void preprocess(TimeSignal<SampleT> *ts);
private:
	bool preprocessingDone;
};

#include "linear.hh"

#endif /* LINEARINTERPOLATOR_H_ */