#include "except.hpp"
#include "s3m.hpp"
#include "s3m.h"
#include "stdio.h"

S3MSong::S3MSong(const char *file_name) {
	song_ = LoadS3M(file_name);
	if (song_ == NULL) {
		printf("1\n");
		throw Exception("Unable to load song.");
		printf("2\n");
	}
}

S3MSong::~S3MSong() {
	if (song_ == NULL) {
		return;
	}
	delete song_;
}

const char *S3MSong::Name() {
	return NULL;
}