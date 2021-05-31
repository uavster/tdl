#include "alloc.h"

void *operator new(unsigned int size) {
	return malloc(size);
}

void operator delete(void *ptr) {
	free(ptr);
}