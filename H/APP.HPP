#ifndef __APP_HEADER__
#define __APP_HEADER__

class Application {
public:
  virtual void Init();
  virtual void Update();
  virtual void CleanUp();

  int Run();
};

#endif  // __APP_HEADER__