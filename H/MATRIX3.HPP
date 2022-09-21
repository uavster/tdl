#ifndef MATRIX3_H_
#define MATRIX3_H_

#include "memcpy.h"

class Vector3;

class Matrix3
{
public:
	float value[3][3];

	Matrix3() { }
	Matrix3(const Matrix3 &m);
	Matrix3(float *a) { memcpy(value, a, sizeof(value)); }
	Matrix3(float a00, float a01, float a02, float a10, float a11, float a12, float a20, float a21, float a22);
	Matrix3(const Vector3 &row1, const Vector3 &row2, const Vector3 &row3) { setRows(row1, row2, row3); }
	virtual ~Matrix3() { }

	Matrix3 &operator = (const Matrix3 &m);
	Matrix3 &setRows(const Vector3 &row1, const Vector3 &row2, const Vector3 &row3);
	Matrix3 &setCols(const Vector3 &col1, const Vector3 &col2, const Vector3 &col3);
	static Matrix3 identity() { return Matrix3(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0); }
	static Matrix3 zero() { return Matrix3(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0); }

	// Operations are defined as virtual, so subtypes of 3x3 matrices may override them with faster algorithms
	virtual float det() const;
	virtual Matrix3 transpose() const;
	virtual Matrix3 inverse() const;
	virtual float trace() const;
	virtual Matrix3 operator * (float f) const;
	virtual Vector3 operator * (const Vector3 &v) const; 
	virtual Matrix3 operator * (const Matrix3 &m) const;
	virtual Matrix3 operator / (float d) const;
	virtual Matrix3 operator < (const Matrix3 &m) const;
	virtual Matrix3 operator < (float t) const;
	virtual Matrix3 operator > (const Matrix3 &m) const;
	virtual Matrix3 operator > (float t) const;
	virtual int countValues(float v) const;
};

Matrix3 operator * (float left, const Matrix3 &right) { return right * left; }

#endif