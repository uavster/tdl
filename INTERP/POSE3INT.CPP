#include "pose3int.hpp"

void Pose3Trajectory::addKeyPoint(float time, const Pose3 &pose) {
	positions_.addKeyPoint(time, pose.position());
	orientations_.addKeyPoint(time, pose.orientation());
}

void Pose3Trajectory::addKeyPoint(const KeyPoint &key_point) {
	addKeyPoint(key_point.time(), key_point.pose());
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

Pose3Trajectory::const_iterator::const_iterator(
	list<TimeSignal<Vector3>::KeyPoint>::const_iterator position_iterator, 
	list<TimeSignal<Quaternion>::KeyPoint>::const_iterator orientation_iterator) 
	: position_iterator_(position_iterator), orientation_iterator_(orientation_iterator), pose_(0, Pose3(Vector3(), Quaternion())) {}

Pose3Trajectory::const_iterator &Pose3Trajectory::const_iterator::operator++() {
	++position_iterator_;
	++orientation_iterator_;
	return *this;
}

Pose3Trajectory::const_iterator &Pose3Trajectory::const_iterator::operator++(int) {
	const_iterator it = *this;
	++(*this);
	return it;
}

Pose3Trajectory::const_iterator &Pose3Trajectory::const_iterator::operator--() {
	--position_iterator_;
	--orientation_iterator_;
	return *this;
}

Pose3Trajectory::const_iterator &Pose3Trajectory::const_iterator::operator--(int) {
	const_iterator it = *this;
	--(*this);
	return it;
}

const Pose3Trajectory::KeyPoint &Pose3Trajectory::const_iterator::operator*()  {
	pose_ = KeyPoint(position_iterator_->time, Pose3(position_iterator_->value, orientation_iterator_->value));
	return pose_;
}

const Pose3Trajectory::KeyPoint *Pose3Trajectory::const_iterator::operator->() {
	return &**this;
}

bool Pose3Trajectory::const_iterator::operator==(const const_iterator &it) const {
	return position_iterator_ == it.position_iterator_;
}

bool Pose3Trajectory::const_iterator::operator!=(const const_iterator &it) const {
	return !(operator==(it));
}

Pose3Trajectory::const_iterator Pose3Trajectory::cbegin() {
	return const_iterator(positions_.getKeyPoints().cbegin(), orientations_.getKeyPoints().cbegin());
}

Pose3Trajectory::const_iterator Pose3Trajectory::cend() {
	return const_iterator(positions_.getKeyPoints().cend(), orientations_.getKeyPoints().cend());
}
