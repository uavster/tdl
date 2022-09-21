#ifndef ROTMATRIX_H_
#define ROTMATRIX_H_

#include "matrix3.hpp"
#include "vector3.hpp"

class RotMatrix3 : public Matrix3 {
public:
	RotMatrix3() {}
	RotMatrix3(float a00, float a01, float a02, float a10, float a11, float a12, float a20, float a21, float a22)
			: Matrix3(a00, a01, a02, a10, a11, a12, a20, a21, a22) {}
	RotMatrix3(const Matrix3 &m) : Matrix3(m) {}
	RotMatrix3(const Vector3 &axis, float angle);
	virtual ~RotMatrix3() {}

	virtual Matrix3 inverse() const { return transpose(); }
	Vector3 getEulerAnglesZYX(bool thetaInQuadrants_I_IV = true) const;
};

#endif /* ROTMATRIX_H_ */