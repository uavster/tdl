#ifndef __EXCEPT_HEADER__
#define __EXCEPT_HEADER__

#include "string.hpp"

class ExceptionBase {
public:
	virtual const char *Description() const;
};

// Exception signaling a memory allocation error.
// This object must live entirely in the stack because the heap is likely full or corrupt.
class MallocException : public ExceptionBase {
public:
 	virtual const char *Description() const;
};

// Exception signaling there was no exception when GetLastException was called.
class NoExceptionThrown : public ExceptionBase {
public:
 	virtual const char *Description() const;
};

class Exception : public ExceptionBase {
public:
	Exception(const char *description);
  Exception(const std::string &description);

	virtual const char *Description() const;
	
private:
	std::string description_;
};

// Returns a pointer to the last exception thrown, or NULL if none.
extern "C" const ExceptionBase *GetLastExceptionPtr();
#pragma aux GetLastExceptionPtr "*" modify [eax] \
                                    value [eax];

// Returns the last exception thrown, or throws NoExceptionThrown if none.
const ExceptionBase &GetLastException();


#endif  // __EXCEPT_HEADER__