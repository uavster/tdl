#include "tdl.h"
#include "tinymath.h"
#include "boxfiltr.h"
#include "except.hpp"

volatile bool do_loop = true;

int KeyESCHandler() {
	do_loop = false;
	return 0;
}

int main() {
	add_key(&KeyESCHandler, Key_ESC);

  if (CreateVideoSLI(320, 200, 32) != SGL_OK) {
    printf("Error initializing videomode!\r\n");
    return 1;
  }

  SLI *image = LoadGFX("mercury.fli", 32);
  if (image == NULL) {
    DestroyVideoSLI(3);
    printf("ERROR: Unable to load image.");
    return 2;
  }

  SetAnimMode(image, SLIAnimForwardLoop);
  float t = 0.0f;
  float t_inc = 0.01f;
	StartFrameRate();
  while(do_loop) {
    const int kernel_size = static_cast<int>(32.0f * (cos(3.14159f * (0.35f * t + 1.0f)) + 1.0f) / 2.0f);
    const int odd_kernel_size = 2 * kernel_size + 1;
    BoxFilter(image, odd_kernel_size, odd_kernel_size, GetVideoSLI());
    AnimateSLI(image);
    ShowVideoSLI();
		IncFloat(&t, &t_inc);
		GetElapsedTime();
		IncFrameCounter();
  }  
	StopFrameRate();
  DestroyVideoSLI(3);
	ShowFrameRateResult();
	return 0;
}