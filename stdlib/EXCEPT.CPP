#include "except.hpp"
#include "string.hpp"

const char *ExceptionBase::Description() const {
	const static char unknown_error[] = "Unknown exception";
  return unknown_error;
}

const char *MallocException::Description() const {
	const static char malloc_error[] = "Unable to allocate memory";
  return malloc_error;
}

const char *NoExceptionThrown::Description() const {
	const static char no_exc_error[] = "No exception was thrown";
  return no_exc_error;
}

Exception::Exception(const char *description) : description_(description) {}
Exception::Exception(const std::string &description) : description_(description) {}

const char *Exception::Description() const {
	return description_.c_str();
}

const ExceptionBase &GetLastException() { 
  const ExceptionBase *exc = GetLastExceptionPtr();
  if (exc == NULL) {
    throw NoExceptionThrown();
  }
  return *exc; 
}