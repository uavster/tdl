template<class SampleT> SampleT SampleHoldInterpolator<SampleT>::getValue(float time) {
	TimeSignal<SampleT>::KeyPoint keypoints[2];
	Interpolator<SampleT>::getSignal()->getNeighborKeyPoints(time, 2, keypoints);
	return keypoints[0].value;
}
