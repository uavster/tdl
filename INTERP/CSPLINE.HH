template<class SampleT> CSpline<SampleT>::CSpline(const SampleT &p0, const SampleT &v0, const SampleT &p1, const SampleT &v1) {
	setControlPoints(p0, v0, p1, v1);
}

template<class SampleT> void CSpline<SampleT>::setControlPoints(const SampleT &p0, const SampleT &v0, const SampleT &p1, const SampleT &v1) {
	const SampleT points[] = {p0, p0 + v0 * (1.0 / 3.0), p1 - v1 * (1.0 / 3.0), p1};
	bezier_.setControlPoints(4, points);
}
