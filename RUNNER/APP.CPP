#include "app.hpp"
#include "except.hpp"
#include "stdio.h"
#include "keyb.h"
#include "sli.h"
#include "debug.h"
#include "sync.h"
#include "framerat.h"

volatile bool esc_pressed_ = false;

int EscHandler() {
	esc_pressed_ = true;
	return 0; // Do not run default handler.
}

int Application::Run() {
  status_ = kStarted;

	add_key(&EscHandler, Key_ESC);
  
  // Initialize the application.
  std::string init_error;
  try {    
    Init();
    status_ = kInitialized;
  } catch(...) {
    init_error = GetLastException().Description();
    status_ = kFailed;
  }

  // Update the application in a loop until ESC is pressed.
  std::string update_error;
  try {
    while(status_ == kUpdating || status_ == kInitialized) {
      Update();
      status_ = kUpdating;
      if (options_.does_terminate_with_esc_key() && esc_pressed_) {
        status_ = kTerminating;
      }
    }
  } catch(...) {
    update_error = GetLastException().Description();
    status_ = kFailed;
  }

  remove_key(Key_ESC);

  // Clean up application resources.
  std::string cleanup_error;
  try {
    CleanUp();
  } catch(...) {      
    cleanup_error = GetLastException().Description();
    status_ = kFailed;
  }
  if (status_ == kTerminating) { status_ = kTerminated; }

  if (init_error.length() != 0) {
    printf("[INIT] ");
    printf(init_error.c_str());
    printf("\n");
  }
  if (update_error.length() != 0) {
    printf("[UPDATE] ");
    printf(update_error.c_str());
    printf("\n");
  }
  if (cleanup_error.length() != 0) {
    printf("[CLEANUP] ");
    printf(cleanup_error.c_str());
    printf("\n");
  }
  return (init_error.length() || update_error.length() || cleanup_error.length()) ? 1 : 0;
}

void VideoApplication::Init() {
  // Initialize in text mode to print errors.
  InitBeforeVideo();
  // Set video mode.
  if (CreateVideoSLI(video_options_.resolution_x(), video_options_.resolution_y(), video_options_.bits_per_pixel())) {
    throw Exception("Can't create video SLI");
  }
  time_ = 0;
  StartFrameRate();
}

void VideoApplication::Update() {
  UpdateFrame(time_);
  ShowVideoSLI();
  GetElapsedTime();
  float t_inc = 1.0f / *GetSyncTimerBaseFreqPtr();
  IncFloat(&time_, &t_inc);
  IncFrameCounter();
}

void VideoApplication::CleanUp() {  
  StopFrameRate();
  DestroyVideoSLI(3);
  CleanUpAfterVideo();
  if (video_options_.do_print_fps_at_end()) {
    ShowFrameRateResult();
  }
}