template<class _SampleT> _SampleT SampleHoldInterpolator<_SampleT>::getValue(float time) {
	TimeSignal<_SampleT>::KeyPoint keypoints[2];
	Interpolator<_SampleT>::getSignal()->getNeighborKeyPoints(time, 2, keypoints);
	return keypoints[0].value;
}
