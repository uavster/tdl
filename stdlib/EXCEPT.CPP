#include "except.hpp"
#include "string.h"

Exception::Exception(const char *description) {
	int len = strlen(description);
	if (len == 0) {
		description_ = NULL;
		return;
	}
	description_ = new char[len + 1];
	strcpy(description, description_);
}

Exception::~Exception() {
	if (description_ == NULL) {
		return;
	}
	delete [] description_;
}

const char *Exception::Description() const {
	return description_;
}