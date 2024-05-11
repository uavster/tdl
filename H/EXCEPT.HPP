#ifndef __EXCEPT_HEADER__
#define __EXCEPT_HEADER__

#include "string.hpp"

class ExceptionBase {
public:
  // ATTENTION: This function must be the first virtual declaration.
  virtual ~ExceptionBase() {}
  
  // Deep-copies itself in the heap and returns a pointer to the copy.
  // ATTENTION: This function must be the second virtual declaration.
  // It is called by "throw" to create, before unwinding the stack, a copy of the exception that can be later used safely.
  // The caller takes ownership of the created copy, and must delete it when no longer needed.
  virtual ExceptionBase *CreateDeepCopy() const;

  // Returns a string describing the exception.
	virtual const char *Description() const;
};

// Exception signaling a memory allocation error.
// This object must live entirely in the stack because the heap is likely full or corrupt.
class MallocException : public ExceptionBase {
public:
  // See documentation of base class for details.
  virtual ~MallocException() {}
  virtual ExceptionBase *CreateDeepCopy() const;
 	virtual const char *Description() const;
};

// Exception signaling there was no exception when GetLastException was called.
class NoExceptionThrown : public ExceptionBase {
public:
  // See documentation of base class for details.
  virtual ~NoExceptionThrown() {}
  virtual ExceptionBase *CreateDeepCopy() const;
 	virtual const char *Description() const;
};

class OutOfBoundsException : public ExceptionBase {
public:
  // See documentation of base class for details.
  virtual ~OutOfBoundsException() {}
  virtual ExceptionBase *CreateDeepCopy() const;
 	virtual const char *Description() const;
};

class Exception : public ExceptionBase {
public:
	Exception(const char *description);
  Exception(const std::string &description);

  // See documentation of base class for details.
  virtual ~Exception() {}
  virtual ExceptionBase *CreateDeepCopy() const;
	virtual const char *Description() const;

private:
	std::string description_;
};

// Returns a pointer to the last exception thrown, or NULL if none.
// ATTENTION: The pointee is only valid within the catch block. 
// After which, its memory is releases, and accessing the pointee will cause undefined behavior.
extern "C" const ExceptionBase *GetLastExceptionPtr();
#pragma aux GetLastExceptionPtr "*" modify [eax] \
                                    value [eax];

// Returns the last exception thrown, or throws NoExceptionThrown if none.
const ExceptionBase &GetLastException();


#endif  // __EXCEPT_HEADER__