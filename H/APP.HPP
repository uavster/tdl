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

  // Override if needed. Called once right after the application is run.
  virtual void Init() {}
  // Override if needed. Called continuously in a loop while IsRunning() is true.
  virtual void Update() {}
  // Override if needed. Called once after the 
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

#endif  // __APP_HEADER__