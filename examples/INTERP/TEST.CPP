#include "tdl.h"
#include "vector3.hpp"
#include "interp.hpp"
#include "quatnion.hpp"
#include "htmat4.hpp"
#include "gfx.h"

#define SCREEN_WIDTH		320
#define SCREEN_HEIGHT		200
#define SCREEN_BIT_DEPTH	32

volatile bool do_loop = true;

int KeyESCHandler() {
	do_loop = false;
	return 0;
}

class RefFrame {
public:
	RefFrame(const Vector3 &position, const Quaternion &rotation) : position_(position), rotation_(rotation) {}
	
	const Vector3 &position() const { return position_; }
	const Quaternion &rotation() const { return rotation_; }
	
	void Draw(SLI *sli, const Matrix4 &cam_model, const DWORD *axis_colors) const {
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
		Matrix4 projections = cam_model * points;

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
			DrawLine(sli, center_x, center_y, projections.value[0][axis_index[i]] / z, projections.value[1][axis_index[i]] / z, colors);
		}
	}
	
private:
	Quaternion rotation_;
	Vector3 position_;
	int axis_colors_[3];
};

class PoseKeyPoint {
public:
	PoseKeyPoint(float time, const RefFrame &frame) : time_(time), frame_(frame) {}
	float time() const { return time_; }
	const RefFrame &frame() const  { return frame_; }

private:
	float		time_;
	RefFrame	frame_;
};

int main() {
	const PoseKeyPoint key_points[] = {
		PoseKeyPoint(0.0f, RefFrame(Vector3(0, 0, 5), Quaternion(Vector3(1, 0, 0), 0))),
		PoseKeyPoint(1.5f, RefFrame(Vector3(-4, 0, 7), Quaternion(Vector3(1, 0, 0), M_PI/4))),
		PoseKeyPoint(3.0f, RefFrame(Vector3(-1, -3.5, 12), Quaternion(Vector3(0, 1, 0), M_PI/2))),
		PoseKeyPoint(4.5f, RefFrame(Vector3(3, 0.5, 5), Quaternion(Vector3(0, 1, 1), M_PI))),
		PoseKeyPoint(6.0f, RefFrame(Vector3(1, 3, 12), Quaternion(Vector3(1, 1, 0), M_PI))),
	};

	if (CreateVideoSLI(SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_BIT_DEPTH) != SGL_OK) {
		printf("Error initializing video mode (%dn, %dn, %dn)\n", SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_BIT_DEPTH);
		return -1;
	}
	SLI *buffer = CreateSLI(SCREEN_WIDTH, SCREEN_HEIGHT, 32, 1);
	if (buffer == NULL) {
		printf("Unable to create SLI\n");
		return -2;
	}

	add_key(&KeyESCHandler, Key_ESC);
	
	// Trajectory in camera frame.
	TimeSignal<Vector3> pos_trajectory;
	TimeSignal<Quaternion> rot_trajectory;
	const int num_points = sizeof(key_points) / sizeof(PoseKeyPoint);
	for (int i = 0; i < num_points; ++i) {
		pos_trajectory.addKeyPoint(key_points[i].time(), key_points[i].frame().position());
		rot_trajectory.addKeyPoint(key_points[i].time(), key_points[i].frame().rotation());
	}
	
	CubicCatmullRomInterpolator<Vector3> pos_interpolator(pos_trajectory);
	CubicCatmullRomSphericalInterpolator<Quaternion> rot_interpolator(rot_trajectory);

	const DWORD axis_colors[] = { 0xff0000, 0x00ff00, 0x0000ff };
	const DWORD key_point_colors[] = { 0xff00ff, 0xffff00, 0x00ffff };
	const float kFocalDistance = 3 * SCREEN_WIDTH / 4;
	const Matrix4 cam_model(kFocalDistance, 0, 0, SCREEN_WIDTH / 2, 
							0, kFocalDistance, 0, SCREEN_HEIGHT / 2, 
							0, 0, kFocalDistance, 0,
							0, 0, 0, 1);
	float t = 0;
	float t_inc = 1.0f / 100.0f;
	while(do_loop) {
		ClearCurrentFrame(buffer, 0);
		
		// Draw key point frames.
		for (int i = 0; i < num_points; ++i) {
			key_points[i].frame().Draw(buffer, cam_model, key_point_colors);
		}
		
		// Draw interpolating frame.
		RefFrame(pos_interpolator.getValue(t), rot_interpolator.getValue(t)).Draw(buffer, cam_model, axis_colors);
		
		GetElapsedTime();
		IncFloat(&t, &t_inc);
		
		Blit(GetVideoSLI(), buffer);
		ShowPage();
	}
	
	DestroySLI(buffer);

	return 0;
}