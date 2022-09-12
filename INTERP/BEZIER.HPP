/*
 *  Bezier curve solution with the De Casteljau method.
 *
 *  Notes: The template parameter SampleT defines the sample type.
 *  Sample types are required to provide + and * operators.
 *  A faster specialization is provided for 4-point curves.
 *  The free parameter, i.e. time, is in normalized units: [0, 1]
 */

#ifndef BEZIER_H_
#define BEZIER_H_

#include "vector.hpp"
#include "list.hpp"

using namespace std;

template<class SampleT> class Bezier {
public:
	// Control points are passed later
	Bezier();

	// Control points are passed in a vector
	Bezier(const vector<SampleT> &points);
	void setControlPoints(const vector<SampleT> &points);
	// Control points are passed in a list
	Bezier(const list<SampleT> &points);
	void setControlPoints(const list<SampleT> &points);
	// Control points are passed as an array
	Bezier(int numPoints, const SampleT *points);
	void setControlPoints(int numPoints, const SampleT *points);
	// Control points are passed as an array of pointers to the points
	Bezier(int numPoints, const SampleT **points);
	void setControlPoints(int numPoints, const SampleT **points);

	SampleT getControlPoint(int index);

	SampleT solve(float time);

protected:
	void solveRecursive(float t);
private:
	vector<SampleT> points_;
	int num_aux_;
	vector<SampleT> aux_;
};

#include "bezier.hh"

#endif /* BEZIER_H_ */