#include "tdl.h"
#include "vector3.hpp"
#include "interp.hpp"

#define SCREEN_WIDTH		320
#define SCREEN_HEIGHT		200
#define SCREEN_BIT_DEPTH	32

volatile bool do_loop = true;

int KeyESCHandler() {
	do_loop = false;
	return 0;
}

int main() {
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
	
	TimeSignal<Vector3> trajectory;
	trajectory.addKeyPoint(0, Vector3(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, 0));
	trajectory.addKeyPoint(5, Vector3(SCREEN_WIDTH / 4, SCREEN_HEIGHT / 2, 0));
	trajectory.addKeyPoint(10, Vector3(3 * SCREEN_WIDTH / 4, SCREEN_HEIGHT / 4, 0));
	trajectory.addKeyPoint(15, Vector3(SCREEN_WIDTH / 2, 3 * SCREEN_HEIGHT / 4, 0));
	CubicFiniteDiffInterpolator<Vector3> interpolator_fd(trajectory);
	CubicCatmullRomInterpolator<Vector3> interpolator_cr(trajectory);
	LinearInterpolator<Vector3> interpolator_lin(trajectory);
	float t = 0;
	float t_inc = 1.0f / 100.0f;
	while(do_loop) {
		// ClearCurrentFrame(buffer, 0);
		DWORD *ptr = static_cast<DWORD *>(GetCurrentFramePtr(buffer));
				
		for (list<TimeSignal<Vector3>::KeyPoint>::const_iterator it = trajectory.getKeyPoints().cbegin(); it != trajectory.getKeyPoints().cend(); ++it) {
			ptr[static_cast<int>(it->value.y) * buffer->SLIXSize + static_cast<int>(it->value.x)] = 0xff00ff00;
		}
		
		Vector3 position = interpolator_cr.getValue(t);
		ptr[static_cast<int>(position.y) * buffer->SLIXSize + static_cast<int>(position.x)] = 0xff0000ff;

		position = interpolator_fd.getValue(t);
		ptr[static_cast<int>(position.y) * buffer->SLIXSize + static_cast<int>(position.x)] = 0xffff0000;

		position = interpolator_lin.getValue(t);
		ptr[static_cast<int>(position.y) * buffer->SLIXSize + static_cast<int>(position.x)] = 0xffffffff;
		
		GetElapsedTime();
		IncFloat(&t, &t_inc);
		
		Blit(GetVideoSLI(), buffer);
		ShowPage();		
	}
	
	DestroySLI(buffer);

	return 0;
}