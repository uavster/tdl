#include "pose3int.hpp"

void Pose3Trajectory::addKeyPoint(float time, const Pose3 &pose) {
	positions_.addKeyPoint(time, pose.position());
	orientations_.addKeyPoint(time, pose.orientation());
}

void Pose3Trajectory::removeKeyPoint(float time) {
	positions_.removeKeyPoint(time);
	orientations_.removeKeyPoint(time);
}

void Pose3Interpolator::setTrajectory(Pose3Trajectory &trajectory) {
	positionInterpolator().setSignal(trajectory.positions());
	orientationInterpolator().setSignal(trajectory.orientations());
}

Pose3 Pose3Interpolator::getValue(float t) {
	return Pose3(positionInterpolator().getValue(t), orientationInterpolator().getValue(t));
}
