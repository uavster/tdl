#ifndef VECTOR3_H_
#define VECTOR3_H_

class Matrix3;

class Vector3
{
public:
	float x, y, z;

	Vector3(float x = 0.0, float y = 0.0, float z = 0.0) { Vector3::x = x; Vector3::y = y; Vector3::z = z; }
	Vector3(float *a) { x = a[0]; y = a[1]; z = a[2]; }
	virtual ~Vector3();

	Vector3 operator - () const;
	Vector3 rotate(const Vector3 &point, const Vector3 &axis, float angle) const;
	float modulus() const;
	Vector3 normalize() const;
	Vector3 &operator = (const Vector3 &v);
	Vector3 operator + (const Vector3 &v) const;
	Vector3 operator - (const Vector3 &v) const;
	Vector3 operator * (float f) const;
	float operator * (const Vector3 &v) const;
	Vector3 operator * (const Matrix3 &m) const;
	Vector3 operator / (float d) const;
	Vector3 operator % (const Vector3 &v) const;
	Vector3 &operator += (const Vector3 &v);
	Vector3 &operator -= (const Vector3 &v);
	bool operator != (const Vector3 &v) const;
	bool operator == (const Vector3 &v) const;
	Vector3 operator > (const Vector3 &v) const;
	Vector3 operator > (float t) const;
	Vector3 operator < (const Vector3 &v) const;
	Vector3 operator < (float t) const;
	int countValues(float v) const;
	bool operator<(const Vector3 &v) { return false;}
};

Vector3 operator * (float left, const Vector3 &right);

#endif