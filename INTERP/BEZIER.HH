template<class SampleT> Bezier<SampleT>::Bezier() {
}

template<class SampleT> Bezier<SampleT>::Bezier(const vector<SampleT> &points) {
	setControlPoints(points);
}

template<class SampleT> Bezier<SampleT>::Bezier(const list<SampleT> &points) {
	setControlPoints(points);
}

template<class SampleT> Bezier<SampleT>::Bezier(int numPoints, const SampleT *points) {
	setControlPoints(numPoints, points);
}

template<class SampleT> Bezier<SampleT>::Bezier(int numPoints, const SampleT **points) {
	setControlPoints(numPoints, points);
}

template<class SampleT> void Bezier<SampleT>::setControlPoints(const vector<SampleT> &points) {
	setControlPoints(points.size(), points.data());
}

template<class SampleT> void Bezier<SampleT>::setControlPoints(const list<SampleT> &points) {
	if (points.size() < 2) {
		throw Exception("[Bezier<>] At least 2 point must be passed.");
	}
	points_.resize(points.size());
	aux_.resize(points_.size());
	int i = 0;
	for (list<SampleT>::const_iterator it = points.cbegin(); it != points.cend(); ++it, ++i) points_[i] = *it;
}

template<class SampleT> void Bezier<SampleT>::setControlPoints(int numPoints, const SampleT *points) {
	if (numPoints < 2) {
		throw Exception("[Bezier<>] At least 2 point must be passed.");
	}
	points_.resize(numPoints);
	aux_.resize(points_.size());
	for (int i = 0; i < numPoints; i++) points_[i] = points[i];
}

template<class SampleT> void Bezier<SampleT>::setControlPoints(int numPoints, const SampleT **points) {
	if (numPoints < 2) {
		throw Exception("[Bezier<>] At least 2 point must be passed.");
	}
	points_.resize(numPoints);
	aux_.resize(points_.size());
	for (int i = 0; i < numPoints; i++) points_[i] = *points[i];
}

template<class SampleT> SampleT Bezier<SampleT>::getControlPoint(int index) {
	if (index < 0 || index >= points_.size()) throw Exception("[Bezier<>] getControlPoint()] Control point index out of bounds.");
	return points_[index];
}

template<class SampleT> SampleT Bezier<SampleT>::solve(float t) {
	num_aux_ = aux_.size();
	aux_ = points_;
	solveRecursive(t);
	return aux_[0];
}

template<class SampleT> void Bezier<SampleT>::solveRecursive(float t) {
	if (num_aux_ == 1) {
		return;
	}
	--num_aux_;
	for (int i = 0; i < num_aux_; i++)
		aux_[i] = (1 - t) * aux_[i] + t * aux_[i + 1];

	solveRecursive(t);
}
