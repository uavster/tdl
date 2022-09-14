#define SLERP_THRESHOLD			1e-6

template<class SampleT> SampleT LinearInterpolator<SampleT>::getValue(float t) {
	TimeSignal<SampleT>::KeyPoint keypoints[2];
	getSignal()->getNeighborKeyPoints(t, 2, keypoints);
	float normalizedTime = (t - keypoints[0].time) / (keypoints[1].time - keypoints[0].time);
	return lerp(normalizedTime, keypoints[0].value, keypoints[1].value);
}

template<class SampleT> SampleT LinearInterpolator<SampleT>::lerp(float normalizedT, const SampleT &kp0, const SampleT &kp1) {
	return kp0 + (kp1 - kp0) * normalizedT;
}

template<class SampleT> SampleT LinearSphericalInterpolator<SampleT>::getValue(float t) {
	if (!preprocessingDone) {
		preprocess(getSignal());
		preprocessingDone = true;
	}

	TimeSignal<SampleT>::KeyPoint keypoints[2];
	getSignal()->getNeighborKeyPoints(t, 2, keypoints);
	float normalizedTime = (t - keypoints[0].time) / (keypoints[1].time - keypoints[0].time);
	return slerp(normalizedTime, keypoints[0].value, keypoints[1].value);
}

template<class SampleT> SampleT LinearSphericalInterpolator<SampleT>::slerp(float normalizedT, const SampleT &kp0, const SampleT &kp1) {
	float a = acos(kp0 * kp1);

	float w0, w1;
	if (fabs(a) >= SLERP_THRESHOLD) {
		float invSinA = 1.0 / sin(a);
		w0 = sin((1.0 - normalizedT) * a) * invSinA;
		w1 = sin(normalizedT * a) * invSinA;
	}
	else {
		w0 = 1.0 - normalizedT;
		w1 = normalizedT;
	}

	return kp0 * w0 + kp1 * w1;
}

template<class SampleT> void LinearSphericalInterpolator<SampleT>::preprocess(TimeSignal<SampleT> *ts) {
	list<TimeSignal<SampleT>::KeyPoint> &keypoints = ts->getKeyPoints();
	for (list<TimeSignal<SampleT>::KeyPoint>::iterator it = keypoints.begin(); it != keypoints.rbegin(); it++) {
		list<TimeSignal<SampleT>::KeyPoint>::iterator nit = it;
		++nit;
		if (nit->value * it->value < 0.0)
			nit->value = -nit->value;
	}
}

#undef SLERP_THRESHOLD