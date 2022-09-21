#include "quatnion.hpp"
#include "tinymath.h"

#define ACCURACY_THRESHOLD		1e-6

Quaternion::Quaternion(const Vector3 &axis, float angle) {
	set(axis, angle);
}

float Quaternion::getAngle() const {
	return acos(w) * 2.0 * 180.0 / M_PI;
}

Vector3 Quaternion::getAxis() const {
	float sinA = sqrt(1.0 - w * w);
	if (fabs(sinA) < ACCURACY_THRESHOLD) sinA = 1.0;
	float invSinA = 1.0 / sinA;
	return Vector3(x * invSinA, y * invSinA, z * invSinA);
}

RotMatrix3 Quaternion::getRotMatrix() const {
	RotMatrix3 matrix;
	Quaternion q = normalize();

	matrix.value[0][0] = 1 - 2 * (q.y * q.y + q.z * q.z);
	matrix.value[0][1] = 2 * (q.x * q.y - q.z * q.w);
	matrix.value[0][2] = 2 * (q.x * q.z + q.y * q.w);

	matrix.value[1][0] = 2 * (q.x * q.y + q.z * q.w);
	matrix.value[1][1] = 1 - 2 * (q.x * q.x + q.z * q.z);
	matrix.value[1][2] = 2 * (q.y * q.z - q.x * q.w);

	matrix.value[2][0] = 2 * (q.x * q.z - q.y * q.w);
	matrix.value[2][1] = 2 * (q.y * q.z + q.x * q.w);
	matrix.value[2][2] = 1 - 2 * (q.x * q.x + q.y * q.y);

	return matrix;
}

void Quaternion::set(const Vector3 &axis, float angle) {
	// q = cos(angle) + axis * sin(angle)
	float sinA = sin(angle * 0.5);

	x = axis.x * sinA;
	y = axis.y * sinA;
	z = axis.z * sinA;
	w = cos(angle * 0.5);
}

float Quaternion::norm() const {
	return sqrt(x * x + y * y + z * z + w * w);
}

Quaternion Quaternion::inverse() const {
	float n = norm();
	float nn = n * n;
	if (nn > 0)
		return conj() / nn;
	else
		return Quaternion(0, 0, 0, 0);
}

Quaternion Quaternion::hProduct(const Quaternion &q) const {
	return Quaternion(	w * q.x + x * q.w + y * q.z - z * q.y,
						w * q.y - x * q.z + y * q.w + z * q.x,
						w * q.z + x * q.y - y * q.x + z * q.w,
						w * q.w - x * q.x - y * q.y - z * q.z
						);
}

float Quaternion::operator * (const Quaternion &q) const {
	return dot(q);
}

Quaternion Quaternion::operator / (float d) const {
	return (*this) * (1.0 / d);
}

Quaternion Quaternion::conj() const {
	return Quaternion(-x, -y, -z, w);
}

Quaternion Quaternion::operator * (float f) const {
	return Quaternion(x * f, y * f, z * f, w * f);
}

Quaternion::Quaternion(const Quaternion &q) {
	*this =	q;
}

Quaternion Quaternion::log() const {
    // If q = cos(A)+sin(A)*(x*i+y*j+z*k) where (x,y,z) is unit length, then
    // log(q) = A*(x*i+y*j+z*k). If sin(A) is near zero, use log(q) =
    // sin(A)*(x*i+y*j+z*k), since sin(A)/A has limit 1.

	Quaternion q;
	q.w = 0;

    if (fabs(w) < 1.0)
    {
		float a = acos(w);
		float sinA = sin(a); // sqrt(1 - w * w);
        if (fabs(sinA) >= ACCURACY_THRESHOLD) {
        	float k = a / sinA;
            q.x = k * x;
            q.y = k * y;
            q.z = k * z;
			return q;
        }
    }

	q.x = x; q.y = y; q.z = z;

    return q;
}

Quaternion Quaternion::exp() const {
    // If q = A*(x*i+y*j+z*k) where (x,y,z) is unit length, then
    // exp(q) = cos(A)+sin(A)*(x*i+y*j+z*k).  If sin(A) is near zero,
    // use exp(q) = cos(A)+A*(x*i+y*j+z*k), since A/sin(A) has limit 1.

	Quaternion q;
	float a = sqrt(x * x + y * y + z * z);

    q.w = cos(a);

    if (fabs(a) >= ACCURACY_THRESHOLD)
    {
    	float k = sin(a) / a;
        q.x = k * x;
        q.y = k * y;
        q.z = k * z;
    }
	else {
		q.x = x; q.y = y; q.z = z;
	}

    return q;
}

float Quaternion::dot(const Quaternion &q) const {
	return (*(Vector4 *)this) * (*(Vector4 *)&q);
}

Quaternion Quaternion::operator + (const Quaternion &q) const {
	return Quaternion(x + q.x, y + q.y, z + q.z, w + q.w);
}

Quaternion::Quaternion(float x, float y, float z, float w) {
	Quaternion::x = x;
	Quaternion::y = y;
	Quaternion::z = z;
	Quaternion::w = w;
}

Quaternion Quaternion::operator -() const {
	return Quaternion(-x, -y, -z, -w);
}

Quaternion Quaternion::operator -(const Quaternion &q) const {
	return Quaternion(x - q.x, y - q.y, z - q.z, w - q.w);
}

Quaternion::Quaternion(const RotMatrix3 &rotm) {
	// Quaternion from rotation matrix
	float trace = rotm.trace() + 1.0;	// The algorithm expects an HT matrix
	if (trace > ACCURACY_THRESHOLD) {
		float s = 0.5 / sqrt(trace);
		w = 0.25 / s;
		x = (rotm.value[2][1] - rotm.value[1][2]) * s;
		y = (rotm.value[0][2] - rotm.value[2][0]) * s;
		z = (rotm.value[1][0] - rotm.value[0][1]) * s;
	}
	else {
		float s;
		if (rotm.value[0][0] > rotm.value[1][1] && rotm.value[0][0] > rotm.value[2][2]) {
			s = 1.0 / (2 * sqrt(1.0 + rotm.value[0][0] - rotm.value[1][1] - rotm.value[2][2]));
			x = 0.25 / s;
			y = (rotm.value[0][1] + rotm.value[1][0]) * s;
			z = (rotm.value[0][2] + rotm.value[2][0]) * s;
			w = (rotm.value[1][2] - rotm.value[2][1]) * s;
		}
		else if (rotm.value[1][1] > rotm.value[2][2]) {
			s = 1.0 / (2.0 * sqrt(1.0 + rotm.value[1][1] - rotm.value[0][0] - rotm.value[2][2]));
			y = 0.25 / s;
			x = (rotm.value[0][1] + rotm.value[1][0]) * s;
			w = (rotm.value[0][2] - rotm.value[2][0]) * s;
			z = (rotm.value[1][2] + rotm.value[2][1]) * s;
		}
		else {
			s = 1.0 / (2.0 * sqrt(1.0 + rotm.value[2][2] - rotm.value[0][0] - rotm.value[1][1]));
			z = 0.25 / s;
			w = (rotm.value[0][1] - rotm.value[1][0]) * s;
			x = (rotm.value[0][2] + rotm.value[2][0]) * s;
			y = (rotm.value[1][2] + rotm.value[2][1]) * s;
		}
	}
}

Quaternion Quaternion::normalize() const {
	float k = 1.0 / norm();
	return Quaternion(x * k, y * k, z * k, w * k);
}