#ifndef POSE3_INTERP_
#define POSE3_INTERP_

#include "vector3.hpp"
#include "quatnion.hpp"
#include "pose3.hpp"
#include "interp.hpp"

class Pose3Trajectory {
public:
	void addKeyPoint(float time, const Pose3 &pose);
	void removeKeyPoint(float time);

	TimeSignal<Vector3> &positions() const { return positions_; }
	TimeSignal<Quaternion> &orientations() const { return orientations_; }

private:
	TimeSignal<Vector3> positions_;
	TimeSignal<Quaternion> orientations_;
};

class Pose3Interpolator {
public:
	void setTrajectory(Pose3Trajectory &trajectory);
	Pose3 getValue(float t);
	
protected:
	virtual Interpolator<Vector3> &positionInterpolator();
	virtual Interpolator<Quaternion> &orientationInterpolator();
	
private:
	Pose3Trajectory *trajectory_;
};

class Pose3CubicCatmullRomInterpolator : public Pose3Interpolator {
protected:
	virtual Interpolator<Vector3> &positionInterpolator() { return position_interpolator; }
	virtual Interpolator<Quaternion> &orientationInterpolator() { return orientation_interpolator; }

private:
	CubicCatmullRomInterpolator<Vector3> position_interpolator;
	CubicCatmullRomSphericalInterpolator<Quaternion> orientation_interpolator;
};

class Pose3CubicFiniteDiffInterpolator : public Pose3Interpolator {
protected:
	virtual Interpolator<Vector3> &positionInterpolator() { return position_interpolator; }
	virtual Interpolator<Quaternion> &orientationInterpolator() { return orientation_interpolator; }

private:
	CubicFiniteDiffInterpolator<Vector3> position_interpolator;
	CubicFiniteDiffSphericalInterpolator<Quaternion> orientation_interpolator;
};

#endif	// #define POSE3_INTERP_