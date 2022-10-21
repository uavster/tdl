#ifndef QUATERNION_H_
#define QUATERNION_H_

#include "vector3.hpp"
#include "vector4.hpp"
#include "rotmat3.hpp"

class Quaternion : public Vector4
{
public:
	Quaternion() {}
	Quaternion(const Vector3 &axis, float angle);
	Quaternion(const RotMatrix3 &rotm);
	Quaternion(float x, float y, float z, float w);
	Quaternion(const Quaternion &q);
	virtual ~Quaternion() {}

	void set(const Vector3 &axis, float angle);
	Vector3 getAxis() const;
	float getAngle() const;
	RotMatrix3 getRotMatrix() const;

	Quaternion normalize() const;
	Quaternion operator + (const Quaternion &q) const;
	Quaternion operator - (const Quaternion &q) const;
	Quaternion operator - () const;
	float dot(const Quaternion &q) const;
	Quaternion hProduct(const Quaternion &q) const;	// Hamilton product
	Quaternion exp() const;
	Quaternion log() const;
	Quaternion conj() const;
	Quaternion operator / (float f) const;
	Quaternion operator * (float f) const;
	float operator * (const Quaternion &q) const;
	Quaternion inverse() const;
	float norm() const;
};

Quaternion operator * (float left, const Quaternion &right);

#endif /* QUATERNION_H_ */