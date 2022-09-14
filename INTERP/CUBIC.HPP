#ifndef CUBICINTERPOLATOR_H_
#define CUBICINTERPOLATOR_H_

#include "intpltor.hpp"

typedef enum { CSPLINE_FINITE_DIFF, CSPLINE_CATMULL_ROM } CubicInterpolationMethod;

template<class SampleT> class CubicCatmullRomInterpolator : public Interpolator<SampleT> {
public:
	CubicCatmullRomInterpolator() : Interpolator<SampleT>() {}
	CubicCatmullRomInterpolator(TimeSignal<SampleT> &signal) : Interpolator<SampleT>(signal) {}

	virtual SampleT getValue(float t);
	virtual SubspaceType getSubspace() { return SUBSPACE_WHOLE; }
};

template<class SampleT> class CubicFiniteDiffInterpolator : public Interpolator<SampleT> {
public:
	CubicFiniteDiffInterpolator() : Interpolator<SampleT>() {}
	CubicFiniteDiffInterpolator(TimeSignal<SampleT> &signal) : Interpolator<SampleT>(signal) {}

	virtual SampleT getValue(float t);
	virtual SubspaceType getSubspace() { return SUBSPACE_WHOLE; }
};

template<class SampleT> class CubicCatmullRomSphericalInterpolator : public Interpolator<SampleT> {
public:
	CubicCatmullRomSphericalInterpolator() : Interpolator<SampleT>() {}
	CubicCatmullRomSphericalInterpolator(TimeSignal<SampleT> &signal) : Interpolator<SampleT>(signal) {}
	virtual void setSignal(TimeSignal<SampleT> &signal) { Interpolator<SampleT>::setSignal(signal); preprocessingDone = false; }

	virtual SampleT getValue(float t);
	virtual SubspaceType getSubspace() { return SUBSPACE_SPHERICAL; }

private:
	bool preprocessingDone;
};

template<class SampleT> class CubicFiniteDiffSphericalInterpolator : public Interpolator<SampleT> {
	friend class CubicCatmullRomSphericalInterpolator<SampleT>;
public:
	CubicFiniteDiffSphericalInterpolator() : Interpolator<SampleT>() {}
	CubicFiniteDiffSphericalInterpolator(TimeSignal<SampleT> &signal) : Interpolator<SampleT>(signal) {}
	virtual void setSignal(TimeSignal<SampleT> &signal) { Interpolator<SampleT>::setSignal(signal); preprocessingDone = false; }

	virtual SampleT getValue(float t);
	virtual SubspaceType getSubspace() { return SUBSPACE_SPHERICAL; }

protected:
	static SampleT squad(float normalizedT, const SampleT &q0, const SampleT &q1, const SampleT &s0, const SampleT &s1);
private:
	bool preprocessingDone;
};

#include "cubic.hh"

#endif /* CUBICINTERPOLATOR_H_ */