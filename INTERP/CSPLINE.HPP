#ifndef CSPLINE_H_
#define CSPLINE_H_

#include "bezier.hpp"

template<class SampleT> class CSpline {
public:
	// p0, v0: position and velocity at t=0.0; p1, v1: position and velocity at t=1.0
	CSpline(const SampleT &p0, const SampleT &v0, const SampleT &p1, const SampleT &v1);
	void setControlPoints(const SampleT &p0, const SampleT &v0, const SampleT &p1, const SampleT &v1);

	// Start point is at 0.0 and end point is at 1.0
	inline SampleT solve(float time) { return bezier_.solve(time); }

private:
	Bezier<SampleT> bezier_;
};

#include "cspline.hh"

#endif /* CSPLINE_H_ */