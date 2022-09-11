template<class _SampleT> _SampleT NearestNeighborInterpolator<_SampleT>::getValue(float time) {
	TimeSignal<_SampleT>::KeyPoint keypoints[2];
	Interpolator<_SampleT>::getSignal()->getNeighborKeyPoints(time, 2, keypoints);
	if (time - keypoints[0].time < keypoints[1].time - time) return keypoints[0].value;
	else return keypoints[1].value;
}
