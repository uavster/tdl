#include "s3m.h"
#include "alloc.h"
#include "filesys.h"

S3MSong *LoadS3M(const char *file_path) {
	// Open module file.
	DWORD f = ttl_open(file_path, READ_ONLY);
	if (f == NULL) {
		return NULL;
	}
	// Load S3M header.
	S3MSong *song = new S3MSong; //(S3MSong *)malloc(sizeof(S3MSong));
	if (song == NULL) {
		goto error;
	}
	if (ttl_read(&song->header, sizeof(song->header), f) != sizeof(song->header)) {
		goto error;
	}
	
	// TODO: load instruments and patterns.
	
	// Load S3M footer.
	if (ttl_read(&song->pans, sizeof(song->pans), f) != sizeof(song->pans)) {
		goto error;
	}
	ttl_close(f);
	
error:
	FreeS3M(song);
	if (f != NULL) {
		ttl_close(f);
	}
	return NULL;
}

void FreeS3M(const S3MSong *song) {
	if (song != NULL) {
		if (song->instruments != NULL) {
			for (int i = 0; i < song->header.num_instruments; ++i) {
				if (song->instruments[i].body.sampled != NULL) {
					free(song->instruments[i].body.sampled);
				}
				if (song->instruments[i].data != NULL) {
					free(song->instruments[i].data);
				}
			}
			free(song->instruments);
		}
		if (song->patterns != NULL) {
			for (int i = 0; i < song->header.num_patterns; ++i) {
				if (song->patterns[i].cells != NULL) {
					free(song->patterns[i].cells);
				}
			}
			free(song->patterns);
		}
		free(song);
	}
}
