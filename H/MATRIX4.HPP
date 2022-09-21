#ifndef MATRIX4_H_
#define MATRIX4_H_

#include "vector4.hpp"
#include "vector3.hpp"
#include "except.hpp"
#include "memcpy.h"

class Matrix4
{
public:
	float value[4][4];

	Matrix4() { }
	Matrix4(float *a) { memcpy(value, a, sizeof(value)); }
	Matrix4(float a00, float a01, float a02, float a03, float a10, float a11, float a12, float  a13, float a20, float  a21, float a22, float a23, float a30, float a31, float a32, float a33);
	Matrix4(const Vector4 &row1, const Vector4 &row2, const Vector4 &row3, const Vector4 &row4) { setRows(row1, row2, row3, row4); }
	virtual ~Matrix4() { }

	Matrix4 &operator = (const Matrix4 &m);
	Matrix4 &setRows(const Vector4 &row1, const Vector4 &row2, const Vector4 &row3, const Vector4 &row4);
	Matrix4 &setCols(const Vector4 &col1, const Vector4 &col2, const Vector4 &col3, const Vector4 &col4);
	static Matrix4 identity() { return Matrix4(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0); }
	static Matrix4 zero() { return Matrix4(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0); }

	// Operations are defined as virtual, so subtypes of 4x4 matrices may override them with faster algorithms
	virtual Matrix4 inverse() const;
	virtual float det() const;
	virtual bool operator != (const Matrix4 &m) const;
	virtual float trace() const;
	virtual Matrix4 transpose() const;
	virtual Matrix4 operator + (const Matrix4 &m) const;
	virtual Matrix4 operator - (const Matrix4 &m) const;
	virtual Vector4 operator * (const Vector3 &v) const;
	virtual Vector4 operator * (const Vector4 &v) const;
	virtual Matrix4 operator * (const Matrix4 &m) const;
	virtual Matrix4 operator * (float f) const;
	virtual Matrix4 operator / (float d) const;
	virtual Matrix4 operator < (const Matrix4 &m) const;
	virtual Matrix4 operator < (float t) const;
	virtual Matrix4 operator > (const Matrix4 &m) const;
	virtual Matrix4 operator > (float t) const;
	virtual Matrix4 scalarPow(float e) const;
	virtual Matrix4 scalarSqrt() const;
	virtual int countValues(float v) const;

private:
	Vector4 res_vector;
};

Matrix4 operator * (float left, const Matrix4 &right) { return right * left; }

#endif