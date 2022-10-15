#ifndef HTMATRIX_H_
#define HTMATRIX_H_

#include "matrix4.hpp"
#include "rotmat3.hpp"
#include <string.h>

class HTMatrix4 : public Matrix4 {
public:
	HTMatrix4() {}
	virtual ~HTMatrix4() {}
	HTMatrix4(const RotMatrix3 &rotation, const Vector3 &translation);
	HTMatrix4(const Matrix4 &m) : Matrix4(m) {}

	RotMatrix3 getRotationMatrix() const {
		return RotMatrix3(value[0][0], value[0][1], value[0][2], value[1][0], value[1][1], value[1][2], value[2][0], value[2][1], value[2][2]);
	}
	Vector3 getTranslation() const {
		return Vector3(value[0][3], value[1][3], value[2][3]);
	}
	virtual Matrix4 inverse() const;
};

#endif /* HTMATRIX_H_ */