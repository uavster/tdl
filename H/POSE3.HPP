#ifndef POSE3_INCLUDED_
#define POSE3_INCLUDED_

#include "sli.h"
#include "vector3.hpp"
#include "quatnion.hpp"
#include "matrix4.hpp"

class Pose3 {
public:
	Pose3(const Vector3 &position, const Quaternion &rotation);
	
	const Vector3 &position() const;
	const Quaternion &rotation() const;
	
	// Draws a stick representation of the pose in a 32-bit SLI, with the passed projection matrix and axis colors.
	void Draw(SLI *sli32, const Matrix4 &projection, const DWORD *axis_colors) const;
	
private:
	Quaternion rotation_;
	Vector3 position_;
};

#endif	// #ifndef POSE3_INCLUDED_