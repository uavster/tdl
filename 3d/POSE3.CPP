#include "pose3.hpp"
#include "htmat4.hpp"
#include "gfx.h"

Pose3::Pose3(const Vector3 &position, const Quaternion &rotation) : position_(position), rotation_(rotation) {}

const Vector3 &Pose3::position() const { return position_; }

const Quaternion &Pose3::rotation() const { return rotation_; }
	
void Pose3::Draw(SLI *sli32, const Matrix4 &projection, const DWORD *axis_colors) const {
	HTMatrix4 pose(rotation_.getRotMatrix(), position_);
	// 'points' columns are: x_tip, y_tip, z_tip, center.
	Matrix4 points = pose * Matrix4(1, 0, 0, 0, 
									0, 1, 0, 0, 
									0, 0, 1, 0,
									1, 1, 1, 1);
	// Project on the image plane. Columns are: x_tip_projection, y_tip_projection, z_tip_projection, center_projection.
	// Component 3 of each axis is the point's depth.
	points.value[3][0] = points.value[2][0];
	points.value[3][1] = points.value[2][1];
	points.value[3][2] = points.value[2][2];
	points.value[3][3] = points.value[2][3];
	Matrix4 projections = projection * points;

	// Order axes by depth for drawing order.
	int axis_index[] = {0, 1, 2};
	if (projections.value[3][axis_index[0]] < projections.value[3][axis_index[1]]) {
		int tmp = axis_index[1];
		axis_index[1] = axis_index[0];
		axis_index[0] = tmp;
	}
	if (projections.value[3][axis_index[1]] < projections.value[3][axis_index[2]]) {
		int tmp = axis_index[2];
		axis_index[2] = axis_index[1];
		axis_index[1] = tmp;
	}
	if (projections.value[3][axis_index[0]] < projections.value[3][axis_index[1]]) {
		int tmp = axis_index[1];
		axis_index[1] = axis_index[0];
		axis_index[0] = tmp;
	}
	// Draw axes.
	float center_x = projections.value[0][3] / projections.value[3][3];
	float center_y = projections.value[1][3] / projections.value[3][3];
	for (int i = 0; i < 3; ++i) {
		const float z = projections.value[3][axis_index[i]];
		DWORD r = ((axis_colors[axis_index[i]] >> 16) & 0xff);
		DWORD g = ((axis_colors[axis_index[i]] >> 8) & 0xff);
		DWORD b = (axis_colors[axis_index[i]] & 0xff);
		const float z_factor = (15 - z) / 10;
		r = static_cast<DWORD>(r * z_factor);
		g = static_cast<DWORD>(g * z_factor);
		b = static_cast<DWORD>(b * z_factor);
		DWORD colors = (r << 16) | (g << 8) | b;
		DrawLine(sli32, center_x, center_y, projections.value[0][axis_index[i]] / z, projections.value[1][axis_index[i]] / z, colors);
	}
}