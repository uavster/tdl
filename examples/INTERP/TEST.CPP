#include "tdl.h"
#include "pose3.hpp"
#include "interp.hpp"
#include "gfx.h"

#define SCREEN_WIDTH		320
#define SCREEN_HEIGHT		200
#define SCREEN_BIT_DEPTH	32

using namespace std;

volatile bool do_loop = true;

int KeyESCHandler() {
	do_loop = false;
	return 0;
}

class PoseKeyPoint {
public:
	PoseKeyPoint(float time, const Pose3 &pose) : time_(time), pose_(pose) {}
	float time() const { return time_; }
	const Pose3 &pose() const  { return pose_; }

private:
	float		time_;
	Pose3		pose_;
};

int main() {
	// Trajectory in camera pose.
	Pose3Trajectory pose_trajectory;
	pose_trajectory.addKeyPoint(0.0f, Pose3(Vector3(0, 0, 6), Quaternion(Vector3(1, 0, 0), 0)));
	pose_trajectory.addKeyPoint(1.5f, Pose3(Vector3(-4, 0, 7), Quaternion(Vector3(1, 0, 0), M_PI/4)));
	pose_trajectory.addKeyPoint(3.0f, Pose3(Vector3(-1, -3.5, 12), Quaternion(Vector3(0, 1, 0), M_PI/2)));
	pose_trajectory.addKeyPoint(4.5f, Pose3(Vector3(3, 0.5, 5.5), Quaternion(Vector3(0, 1, 1), M_PI)));
	pose_trajectory.addKeyPoint(6.0f, Pose3(Vector3(1, 3, 12), Quaternion(Vector3(1, 1, 0), M_PI)));
	pose_trajectory.setPeriodic(1);
	Pose3CubicCatmullRomInterpolator pose_interpolator;
	pose_interpolator.setTrajectory(pose_trajectory);

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
		
		// Draw key point poses.
		for (Pose3Trajectory::const_iterator it = pose_trajectory.cbegin(); it != pose_trajectory.cend(); ++it) {
			it->pose().Draw(buffer, cam_model, key_point_colors);
		}
		
		// Draw interpolating pose.
		pose_interpolator.getValue(t).Draw(buffer, cam_model, axis_colors);
		
		GetElapsedTime();
		IncFloat(&t, &t_inc);
		
		Blit(GetVideoSLI(), buffer);
		ShowPage();
	}
	
	DestroySLI(buffer);

	return 0;
}