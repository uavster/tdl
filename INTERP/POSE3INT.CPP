#include "pose3int.hpp"

void PoseTrajectory::addKeyPoint(float time, const Vector3 &position, const Quaternion &orientation) {
	positions_.addKeyPoint(time, position);
	orientations_.addKeyPoint(time, orientation);
}

void PoseTrajectory::removeKeyPoint(float time) {
	positions_.removeKeyPoint(time);
	orientations_.removeKeyPoint(time);
}

void Pose3Interpolator::setTrajectory(PoseTrajectory &trajectory) {
	positionInterpolator().setSignal(trajectory.positions());
	orientationInterpolator().setSignal(trajectory.orientations());
}

Pose3 Pose3Interpolator::getValue(float t) {
	return Pose3(positionInterpolator().getValue(t), orientationInterpolator().getValue(t));
}
