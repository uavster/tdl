/* -- Default subspace (whole space) --
 * Default method: Derivatives at the end-points are computed by the Catmull-Rom method
 */

#include "list.hpp"
#include "cspline.hpp"
#include "linear.hpp"

template<class SampleT> SampleT CubicCatmullRomInterpolator<SampleT>::getValue(float t) {
	TimeSignal<SampleT>::KeyPoint keypoints[4];
	Interpolator<SampleT>::getSignal()->getNeighborKeyPoints(t, 4, keypoints);

	TimeSignal<SampleT>::KeyPoint *k0, *k1, *k2, *k3;
	k0 = &keypoints[0]; k1 = &keypoints[1]; k2 = &keypoints[2]; k3 = &keypoints[3];

	// Catmull-Rom method
	SampleT v0 = 	(k2->value - k0->value) * (1.0 / (k2->time - k0->time));
	SampleT v1 = 	(k3->value - k1->value) * (1.0 / (k3->time - k1->time));

	float dt = k2->time - k1->time;
	float normalizedTime = (t - k1->time) / dt;
	// Create spline with points and normalized derivatives (speeds)
	CSpline<SampleT> cspline(k1->value, v0 * dt, k2->value, v1 * dt);
	return cspline.solve(normalizedTime);
}

/* -- Whole space --
 * Finite Difference specialization: Derivatives at the end-points are computed by the Finite Difference method
 */

template<class SampleT> SampleT CubicFiniteDiffInterpolator<SampleT>::getValue(float t) {
	TimeSignal<SampleT>::KeyPoint keypoints[4];
	Interpolator<SampleT>::getSignal()->getNeighborKeyPoints(t, 4, keypoints);

	TimeSignal<SampleT>::KeyPoint *k0, *k1, *k2, *k3;
	k0 = &keypoints[0]; k1 = &keypoints[1]; k2 = &keypoints[2]; k3 = &keypoints[3];

	// Finite Difference method
	SampleT v0 = 	(k2->value - k1->value) * (0.5 / (k2->time - k1->time)) +
					(k1->value - k0->value) * (0.5 / (k1->time - k0->time));

	SampleT v1 = 	(k3->value - k2->value) * (0.5 / (k3->time - k2->time)) +
					(k2->value - k1->value) * (0.5 / (k2->time - k1->time));

	float dt = k2->time - k1->time;
	float normalizedTime = (t - k1->time) / dt;
	// Create spline with points and normalized derivatives (speeds)
	CSpline<SampleT> cspline(k1->value, dt * v0, k2->value, dt * v1);
	return cspline.solve(normalizedTime);
}

/* -- Spherical subspace --
 * Finite Difference specialization: Derivatives at the end-points are computed by the Finite Difference method
 */

template<class SampleT> SampleT CubicFiniteDiffSphericalInterpolator<SampleT>::getValue(float t) {
	if (!preprocessingDone) {
		LinearSphericalInterpolator<SampleT>::preprocess(Interpolator<SampleT>::getSignal());
		// TODO: preprocessingDone should be set to false every time the time signal is changed. An event producer-listener scheme is needed for that.
		preprocessingDone = true;
	}

	TimeSignal<SampleT>::KeyPoint keypoints[4];
	Interpolator<SampleT>::getSignal()->getNeighborKeyPoints(t, 4, keypoints);

	TimeSignal<SampleT>::KeyPoint *k0, *k1, *k2, *k3;
	k0 = &keypoints[0]; k1 = &keypoints[1]; k2 = &keypoints[2]; k3 = &keypoints[3];

	float dt = k2->time - k1->time;
	float normalizedTime = (t - k1->time) / dt;

	SampleT k1Inv = k1->value.inverse();
	SampleT tag1 = k1Inv.hProduct(k2->value).log();
	SampleT tag0 = k1Inv.hProduct(k0->value).log();
	SampleT s1 = k1->value.hProduct(((tag0 * (k2->time - k1->time) + tag1 * (k1->time - k0->time)) * (-0.5) / (k2->time - k0->time)).exp());
	SampleT k2Inv = k2->value.inverse();
	SampleT tag3 = k2Inv.hProduct(k3->value).log();
	SampleT tag2 = k2Inv.hProduct(k1->value).log();
	SampleT s2 = k2->value.hProduct(((tag2 * (k3->time - k2->time) + tag3 * (k2->time - k1->time)) * (-0.5) / (k3->time - k1->time)).exp());

//	SampleT s1 = k1->value.hProduct(((k1->value.inverse().hProduct(k0->value).log() * (k2->time - k1->time)) * (-0.5) / (k2->time - k0->time)).exp());
//	SampleT s2 = k2->value.hProduct(((k2->value.inverse().hProduct(k3->value).log() * (k2->time - k1->time)) * (-0.5) / (k3->time - k1->time)).exp());

	return squad(normalizedTime, k1->value, k2->value, s1, s2);
}

template<class SampleT> SampleT CubicFiniteDiffSphericalInterpolator<SampleT>::squad(float normalizedT, const SampleT &q0, const SampleT &q1, const SampleT &s0, const SampleT &s1) {
	return LinearSphericalInterpolator<SampleT>::slerp(
			2 * normalizedT * (1 - normalizedT),
			LinearSphericalInterpolator<SampleT>::slerp(normalizedT, q0, q1),
			LinearSphericalInterpolator<SampleT>::slerp(normalizedT, s0, s1)
			);
}

/* -- Spherical subspace --
 * Catmull-Rom specialization: Derivatives at the end-points are computed by the Catmull-Rom method
 */

template<class SampleT> SampleT CubicCatmullRomSphericalInterpolator<SampleT>::getValue(float t) {
	if (!preprocessingDone) {
		LinearSphericalInterpolator<SampleT>::preprocess(Interpolator<SampleT>::getSignal());
		// TODO: preprocessingDone should be set to false every time the time signal is changed. An event producer-listener scheme is needed for that.
		preprocessingDone = true;
	}

	TimeSignal<SampleT>::KeyPoint keypoints[4];
	Interpolator<SampleT>::getSignal()->getNeighborKeyPoints(t, 4, keypoints);

	TimeSignal<SampleT>::KeyPoint *k0, *k1, *k2, *k3;
	k0 = &keypoints[0]; k1 = &keypoints[1]; k2 = &keypoints[2]; k3 = &keypoints[3];

	float dt = k2->time - k1->time;
	float normalizedTime = (t - k1->time) / dt;

	SampleT s1 = k1->value.hProduct(((k1->value.inverse().hProduct(k0->value).log() * (k2->time - k1->time)) * (-0.5) / (k2->time - k0->time)).exp());
	SampleT s2 = k2->value.hProduct(((k2->value.inverse().hProduct(k3->value).log() * (k2->time - k1->time)) * (-0.5) / (k3->time - k1->time)).exp());

	return CubicFiniteDiffSphericalInterpolator<SampleT>::squad(normalizedTime, k1->value, k2->value, s1, s2);
}
