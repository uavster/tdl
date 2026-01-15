#ifndef __APP_HEADER__
#define __APP_HEADER__

class AppOptions {
public:
  AppOptions() : does_terminate_with_esc_key_(true) {}

  bool does_terminate_with_esc_key() { return does_terminate_with_esc_key_; }
  bool does_terminate_with_esc_key(bool s) { does_terminate_with_esc_key_ = s; return does_terminate_with_esc_key_; }

private:
  bool does_terminate_with_esc_key_;
};

class Application {
public:
  Application() : status_(kInstantiated) {}
  Application(const AppOptions &options) : status_(kInstantiated), options_(options) {}

  AppOptions &options() { return options_; }

  // Note: if a constructor is defined, Watcom does not compile virtuals without implementation,
  // so we cannot force compilation to fail uf one of the functions is not overriden.

  // Override if needed. Called once when Run() is called.
  virtual void Init() {}
  // Override if needed. Called after Init(), continuously in a loop while status is kInitialized or kUpdating.
  virtual void Update() {}
  // Override if needed. Called once before Run() returns.
  virtual void CleanUp() {}

  enum Status {
    kInstantiated,  // Object created.
    kStarted, // Run() called by program.
    kInitialized, // Init() successful.
    kUpdating, // Update() is running in a loop.
    kFailed,  // An error occurred.
    kTerminating, // The application asked for termination.
    kTerminated // CleanUp() successful.
  };

  // Runs the application.
  // It blocks the program until the application calls Terminate().
  // Returns 0 if no error or an error code.
  int Run();

  Status status() const { return status_; }

protected:
  // Returns from Run() after the caller returns. Always calls CleanUp() before.
  void Terminate() { status_ = kTerminating; }

private:
  Status status_;
  AppOptions options_;
};

class VideoAppOptions : public AppOptions {
public:
  VideoAppOptions() : resolution_x_(320), resolution_y_(200), bits_per_pixel_(32), do_print_fps_at_end_(false) {}

  int resolution_x() const { return resolution_x_; }
  int resolution_y() const { return resolution_y_; }
  int bits_per_pixel() const { return bits_per_pixel_; }
  void SetVideoMode(int resolution_x, int resolution_y, int bits_per_pixel) { resolution_x_ = resolution_x; resolution_y_ = resolution_y; bits_per_pixel_ = bits_per_pixel; }
  
  bool do_print_fps_at_end() const { return do_print_fps_at_end_; }
  bool do_print_fps_at_end(bool s) { do_print_fps_at_end_ = s; return do_print_fps_at_end_; }

private:
  int resolution_x_;
  int resolution_y_;
  int bits_per_pixel_;
  bool do_print_fps_at_end_;
};
  
class VideoApplication : public Application {
public:
  VideoApplication() : Application() {}
  VideoApplication(const VideoAppOptions &options) : Application(options), video_options_(options) {}
  
  virtual void Init();
  virtual void Update();
  virtual void CleanUp();

  // Override if needed. Called once after the video mode is set.
  virtual void InitBeforeVideo() {}
  // Override if needed. Called after the video mode is set, continuously in a loop while status is kInitialized or kUpdating.
  virtual void UpdateFrame(float time) {}
  // Override if needed. Called once before Run() returns. Text mode is already set.
  virtual void CleanUpAfterVideo() {}

private:
  VideoAppOptions video_options_;
  float time_;
};

#endif  // __APP_HEADER__