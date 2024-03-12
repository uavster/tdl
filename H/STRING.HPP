#ifndef SLI_HPP_
#define SLI_HPP_

#include "stddef.h"

namespace std {

enum Radix { kDecimal = 'd', kHexadecimal = 'h', kOctal = 'o', kBinary = 'i' };

class string {
public:
  string();
  string(const string &s);
  string(const char *s);
  string(char c);
  string(int i, Radix radix);
  string(DWORD d, Radix radix);
  string(float f);
  string(double f);
  virtual ~string();

  string &operator=(const string &s);

  string operator+(const string &s) const;
  string operator+(char c) const;
  string operator+(DWORD d) const;
  string operator+(int i) const;
  string operator+(float f) const;
  string operator+(double f) const;

  int length() const { return len_; }
  const char *c_str() const { return str_; }

private:
  void alloc(int len);
  void destroy();
  void copy(const char *s);
  void copy(const string &s);
  string formatter(Radix radix, bool is_signed) const;
  
  char *str_;
  int len_;
};

} // namespace std

#endif  // SLI_HPP_