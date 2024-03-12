#ifndef __EXCEPT_HEADER__
#define __EXCEPT_HEADER__

#include "string.hpp"

class ExceptionWithoutContext {
public:
	virtual const char *Description() const;
};

// Exception signaling a memory allocation error.
// This object must live entirely in the stack because the heap is likely full or corrupt.
class MallocException : public ExceptionWithoutContext {
public:
 	virtual const char *Description() const;
};

class Exception : public ExceptionWithoutContext {
public:
	Exception(const char *description);
  Exception(const std::string &description);

	virtual const char *Description() const;
	
private:
	std::string description_;
};

#endif  // __EXCEPT_HEADER__