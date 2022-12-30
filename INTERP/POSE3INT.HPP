#ifndef POSE3_INTERP_
#define POSE3_INTERP_

#include "vector3.hpp"
#include "quatnion.hpp"
#include "pose3.hpp"
#include "interp.hpp"

using namespace std;

class Pose3Trajectory {
public:
	class KeyPoint {
	public:
		KeyPoint(float time, const Pose3 &pose) : time_(time), pose_(pose) {}
		
		float time() const { return time_; }
		const Pose3 &pose() const { return pose_; }
	private:
		float time_;
		Pose3 pose_;
	};
	void addKeyPoint(float time, const Pose3 &pose);
	void addKeyPoint(const KeyPoint &key_point);
	void removeKeyPoint(float time);

	class const_iterator {
	friend class Pose3Trajectory;
	public:
		const_iterator &operator++();
		const_iterator &operator++(int);
		const_iterator &operator--();
		const_iterator &operator--(int);		
		const KeyPoint &operator*();
		const KeyPoint *operator->();
		bool operator==(const const_iterator &it) const;
		bool operator!=(const const_iterator &it) const;

	private:
		const_iterator(list<TimeSignal<Vector3>::KeyPoint>::const_iterator position_iterator, list<TimeSignal<Quaternion>::KeyPoint>::const_iterator orientation_iterator);
		list<TimeSignal<Vector3>::KeyPoint>::const_iterator position_iterator_;
		list<TimeSignal<Quaternion>::KeyPoint>::const_iterator orientation_iterator_;
		KeyPoint pose_;
	};
	const_iterator cbegin();
	const_iterator cend();
	
	TimeSignal<Vector3> &positions() { return positions_; }
	TimeSignal<Quaternion> &orientations() { return orientations_; }
	
	void setPeriodic(float last_to_first_keypoint_time) { 
		positions_.setPeriodic(last_to_first_keypoint_time); 
		orientations_.setPeriodic(last_to_first_keypoint_time);
	}
	void setNonPeriodic() { positions_.setNonPeriodic(); orientations_.setNonPeriodic(); }
	
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