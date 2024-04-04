#include "app.hpp"
#include "except.hpp"
#include "stdio.h"
#include "keyb.h"
#include "sli.h"
#include "debug.h"

volatile bool do_loop_ = true;

int EscHandler() {
	do_loop_ = false;
	return 0; // Do not run default handler.
}

int Application::Run() {
  do_loop_ = true;
	add_key(&EscHandler, Key_ESC);
  
  // Initialize the application.
  std::string init_error;
  try {    
    Init();
  } catch(...) {
    init_error = GetLastException().Description();
  }

  // Update the application in a loop until ESC is pressed.
  std::string update_error;
  if (init_error.length() == 0) {
    try {
      while(do_loop_) {
        Update();
      }
    } catch(...) {
      update_error = GetLastException().Description();
    }
  }

  remove_key(Key_ESC);

  // Clean up application resources.
  std::string cleanup_error;
  try {
    CleanUp();
  } catch(...) {      
    cleanup_error = GetLastException().Description();
  }

  // Clear any video mode that might have been set and not unset.
  DestroyVideoSLI(3);

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
