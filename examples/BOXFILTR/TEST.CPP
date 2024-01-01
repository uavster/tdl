#include "tdl.h"
#include "boxfiltr.h"
#include "except.hpp"

volatile bool do_loop = true;
volatile int kernel_width = 1;
volatile int kernel_height = 1;

int KeyESCHandler() {
	do_loop = false;
	return 0;
}

int KeyLeftHandler() {
  kernel_width -= 2;
  if (kernel_width <= 0) {
    kernel_width = 1;
  }
	return 0;
}

int KeyRightHandler() {
  kernel_width += 2;
	return 0;
}

int KeyUpHandler() {
  kernel_height += 2;
	return 0;
}

int KeyDownHandler() {
  kernel_height -= 2;
  if (kernel_height <= 0) {
    kernel_height = 1;
  }
	return 0;
}

int main() {
	add_key(&KeyESCHandler, Key_ESC);
	add_key(&KeyLeftHandler, Key_Left);
	add_key(&KeyRightHandler, Key_Right);
	add_key(&KeyUpHandler, Key_Up);
	add_key(&KeyDownHandler, Key_Down);

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

  SLI *filtered = CreateSLI(image->SLIXSize, image->SLIYSize, image->SLIColorBits * 8, /*nframes=*/1);
  if (filtered == NULL) {
    DestroyVideoSLI(3);
    printf("ERROR: Unable to create output SLI.");
    return 3;
  }

  SetAnimMode(image, SLIAnimForwardLoop);
  while(do_loop) {
    BoxFilter(image, kernel_width, kernel_height, filtered);
    SetPalette(filtered, image->SLIPalette);
    Blit(GetVideoSLI(), filtered);
    AnimateSLI(image);
    ShowVideoSLI();
  }  
	return 0;
}