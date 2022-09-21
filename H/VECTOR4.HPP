#ifndef VECTOR4_H_
#define VECTOR4_H_

#include "vector3.hpp"

class Matrix4;

class Vector4
{
public:
	float x, y, z, w;

	Vector4(float x = 0.0, float y = 0.0, float z = 0.0, float w = 0.0) { Vector4::x = x; Vector4::y = y; Vector4::z = z; Vector4::w = w; }
	Vector4(const float *a) { x = a[0]; y = a[1]; z = a[2]; w = a[3]; }
	Vector4(const Vector3 &v, float w = 0.0) { x = v.x; y = v.y; z = v.z; Vector4::w = w; }
	virtual ~Vector4() {}

	Vector4 operator - (const Vector4 &v) const { return Vector4(x - v.x, y - v.y, z - v.z, w - v.w); }
	Vector4 normalize() const;
	Vector4 operator + (const Vector4 &v) const { return Vector4(x + v.x, y + v.y, z + v.z, w + v.w); }
	float operator * (const Vector4 &v) const { return x * v.x + y * v.y + z * v.z + w * v.w; }
	Vector4 operator * (const Matrix4 &m) const;
	Vector4 operator * (float f) const;
	Vector4 operator / (float d) const;
};

inline Vector4 operator * (float left, const Vector4 &right) { return right * left; }

#endif