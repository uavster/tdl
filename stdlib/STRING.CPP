#include "string.h"
#include "string.hpp"
#include "except.hpp"
#include "alloc.h"
#include "stdio.h"

namespace std {

string::string() : str_(NULL), len_(0) {}

string::string(const string &s) : str_(NULL), len_(0) {
  copy(s);
}

string::string(const char *s) : str_(NULL), len_(0) {
  copy(s);
}

string::string(char c) : str_(NULL), len_(0) {
  char str[2];
  str[0] = c;
  str[1] = '\0';
  copy(str);
}

std::string string::formatter(Radix radix, bool is_signed) const {
  std::string radix_str;
  if (radix != kDecimal) {
    radix_str = static_cast<char>(radix);
  }
  if (is_signed && radix == kDecimal) {
    return string("%d") + radix_str + "-n";
  } else {
    return string("%d") + radix_str + "n";
  }
}

string::string(int i, Radix radix) : str_(NULL), len_(0) {
  alloc(15);
  sprintf(str_, formatter(radix, /*is_signed=*/true).c_str(), i);
  len_ = strlen(str_);
}

string::string(DWORD d, Radix radix) : str_(NULL), len_(0) {
  alloc(15);
  sprintf(str_, formatter(radix, /*is_signed=*/false).c_str(), d);
  len_ = strlen(str_);
}

string::string(float f) : str_(NULL), len_(0) {
  alloc(31);
  sprintf(str_, "%dfn", f);
  len_ = strlen(str_);
}

string::string(double f) : str_(NULL), len_(0) {
  alloc(32);
  sprintf(str_, "%dfn", f);
  len_ = strlen(str_);
}

void string::alloc(int len) {
  destroy();
  if (len == 0) {
    return;
  }
  len_ = len;
  str_ = new char[len_ + 1];
  if (str_ == NULL) {
    throw MallocException();
  }
}

void string::destroy() {
  if (str_ == NULL) {
    return;
  }
  delete [] str_;
  str_ = NULL;
  len_ = 0;
}

string::~string() {
  destroy();
}

void string::copy(const char *s) {
  alloc(s != NULL ? strlen(s) : 0);
  if (str_ == NULL) {
    return;
  }
  strcpy(str_, s);
}

void string::copy(const string &s) {
  alloc(s.length());
  if (str_ == NULL) {
    return;
  }
  strcpy(str_, s.c_str());
}

string &string::operator=(const string &s) {
  if (this == &s) {
    return *this;
  }
  copy(s);
  return *this;
}

string string::operator+(char c) const {
  return *this + string(c);
}

string string::operator+(const string &s) const {
  string result;
  result.alloc(length() + s.length());
  strcpy(result.str_, c_str());
  strcpy(&result.str_[length()], s.c_str());
  result.str_[result.length()] = '\0';
  return result;
}

string string::operator+(int i) const {
  return *this + string(i, kDecimal);
}

string string::operator+(DWORD d) const {
  return *this + string(d, kDecimal);
}

string string::operator+(float f) const {
  return *this + string(f);
}

string string::operator+(double f) const {
  return *this + string(f);
}

} // namespace std