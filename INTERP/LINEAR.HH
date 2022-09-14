#define SLERP_THRESHOLD			1e-6

template<class _T> _T LinearInterpolator<_T>::getValue(float t) {
	TimeSignal<_T>::KeyPoint keypoints[2];
	getSignal()->getNeighborKeyPoints(t, 2, keypoints);
	float normalizedTime = (t - keypoints[0].time) / (keypoints[1].time - keypoints[0].time);
	return lerp(normalizedTime, keypoints[0].value, keypoints[1].value);
}

template<class _T> _T LinearInterpolator<_T>::lerp(float normalizedT, const _T &kp0, const _T &kp1) {
	return kp0 + (kp1 - kp0) * normalizedT;
}

template<class _T> _T LinearSphericalInterpolator<_T>::getValue(float t) {
	if (!preprocessingDone) {
		preprocess(getSignal());
		preprocessingDone = true;
	}

	TimeSignal<_T>::KeyPoint keypoints[2];
	getSignal()->getNeighborKeyPoints(t, 2, keypoints);
	float normalizedTime = (t - keypoints[0].time) / (keypoints[1].time - keypoints[0].time);
	return slerp(normalizedTime, keypoints[0].value, keypoints[1].value);
}

template<class _T> _T LinearSphericalInterpolator<_T>::slerp(float normalizedT, const _T &kp0, const _T &kp1) {
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

template<class _T> void LinearSphericalInterpolator<_T>::preprocess(TimeSignal<_T> *ts) {
	list<TimeSignal<_T>::KeyPoint> &keypoints = ts->getKeyPoints();
	for (list<TimeSignal<_T>::KeyPoint>::iterator it = keypoints.begin(); it != keypoints.rbegin(); it++) {
		list<TimeSignal<_T>::KeyPoint>::iterator nit = it;
		++nit;
		if (nit->value * it->value < 0.0)
			nit->value = -nit->value;
	}
}

#undef SLERP_THRESHOLD