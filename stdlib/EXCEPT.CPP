#include "except.hpp"
#include "string.hpp"

const char *ExceptionWithoutContext::Description() const {
	const static char unknown_error[] = "Unknown exception";
  return unknown_error;
}

const char *MallocException::Description() const {
	const static char malloc_error[] = "Unable to allocate memory";
  return malloc_error;
}

Exception::Exception(const char *description) : description_(description) {}
Exception::Exception(const std::string &description) : description_(description) {}

const char *Exception::Description() const {
	return description_.c_str();
}

ExceptionWithoutContext &GetLastException() { return *GetLastExceptionPtr(); }