#include "except.hpp"
#include "string.hpp"
#include "stdio.h"

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

const char *OutOfBoundsException::Description() const {
	const static char oob_error[] = "Out of bounds access";
  return oob_error;
}

ExceptionBase *ExceptionBase::CreateDeepCopy() const {
  return new ExceptionBase;
}

ExceptionBase *MallocException::CreateDeepCopy() const {
  return new MallocException;
}

ExceptionBase *NoExceptionThrown::CreateDeepCopy() const {
  return new NoExceptionThrown;
}

ExceptionBase *OutOfBoundsException::CreateDeepCopy() const {
  return new OutOfBoundsException;
}

Exception::Exception(const char *description) : description_(description) {}
Exception::Exception(const std::string &description) : description_(description) {}

const char *Exception::Description() const {
	return description_.c_str();
}

ExceptionBase *Exception::CreateDeepCopy() const {
  return new Exception(Description());
}

const ExceptionBase &GetLastException() { 
  const ExceptionBase *exc = GetLastExceptionPtr();
  if (exc == NULL) {
    throw NoExceptionThrown();
  }
  return *exc; 
}