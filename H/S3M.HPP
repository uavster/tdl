#ifndef __S3M_CPP_HEADER__
#define __S3M_CPP_HEADER__

#include "s3m.h"

class S3MSong {
public:
	S3MSong(const char *file_path);
	virtual ~S3MSong();
	
	const char *Name();
	
private:
	TS3MSong *song_;
};

#endif