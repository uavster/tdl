#include "s3m.h"
#include "alloc.h"
#include "filesys.h"

#define read_field(field, file) \
	(ttl_read(&field, sizeof(field), file) == sizeof(field))

#define INSTRUMENT_TYPE_SAMPLE			1
#define INSTRUMENT_TYPE_ADLIB_MELODY	2
#define INSTRUMENT_TYPE_ADLIB_DRUM		3

bool LoadS3MInstrument(int instrument_offset, S3MInstrument &instrument, DWORD f) {
	if (ttl_seek(f, instrument_offset, SEEK_SET) != instrument_offset) {
		return false;
	}
	if (!read_field(instrument.header, f)) {
		return false;
	}	
	if (instrument.header.type == INSTRUMENT_TYPE_SAMPLE) {
		instrument.data = new BYTE[instrument.header.spec.sampled.length];
		if (instrument.data == NULL) {
			return false;
		}
		DWORD data_offset = ((DWORD)instrument.header.spec.sampled.offset.high << 16) | ((DWORD)instrument.header.spec.sampled.offset.low);
		if (ttl_seek(f, data_offset, SEEK_SET) != data_offset) {
			return false;
		}
		if (ttl_read(instrument.data, instrument.header.spec.sampled.length, f) != instrument.header.spec.sampled.length) {
			return false;
		}
	}
	return true;
}

bool LoadS3MPattern(int pattern_offset, S3MPattern &pattern, DWORD f) {
	if (ttl_seek(f, pattern_offset, SEEK_SET) != pattern_offset) {
		return false;
	}
	if (!read_field(pattern.header, f)) {
		return false;
	}
	pattern.cells = (S3MPatternCell *)new BYTE[pattern.header.size];
	if (pattern.cells == NULL) {
		return false;
	}
	return ttl_read(pattern.cells, pattern.header.size, f) == pattern.header.size;
}

S3MSong *LoadS3M(const char *file_path) {
	S3MShortOffset *pattern_offsets;
	int num_patterns;
	S3MShortOffset *instrument_offsets;
	int num_instruments;
	
	// Open module file.
	DWORD f = ttl_open(file_path, READ_ONLY);
	if (f == NULL) {
		return NULL;
	}
	// Load S3M header.
	S3MSong *song = new S3MSong;
	if (song == NULL) {
		goto error;
	}
	if (!read_field(song->header, f)) {
		goto error;
	}
	
	// Load instrument offset table.
	num_instruments = song->header.num_instruments;
	song->instruments = new S3MInstrument[num_instruments];
	if (song->instruments == NULL) {
		goto error;
	}
	instrument_offsets = new S3MShortOffset[num_instruments];
	{
		int instrument_offsets_size = num_instruments * sizeof(S3MShortOffset);
		if (ttl_read(&instrument_offsets, instrument_offsets_size, f) != instrument_offsets_size) {
			goto error;
		}
	}
	
	// Load pattern offset table.
	num_patterns = song->header.num_patterns;
	song->patterns = new S3MPattern[num_patterns];
	if (song->patterns == NULL) {
		goto error;
	}
	pattern_offsets = new S3MShortOffset[num_patterns];
	{
		int pattern_offsets_size = num_patterns * sizeof(S3MShortOffset);
		if (ttl_read(&pattern_offsets, pattern_offsets_size, f) != pattern_offsets_size) {
			goto error;
		}
	}
	
	// Load S3M footer.
	if (ttl_read(&song->pans, sizeof(song->pans), f) != sizeof(song->pans)) {
		goto error;
	}
	
	// Load instruments.
	{
	for (int i = 0; i < num_instruments; ++i) {
		if (!LoadS3MInstrument(instrument_offsets[i], song->instruments[i], f)) {
			delete [] instrument_offsets;
			delete [] pattern_offsets;
			goto error;
		}
	}
	}
	delete [] instrument_offsets;

	// Load patterns.
	{
		for (int j = 0; j < num_patterns; ++j) {
			if (!LoadS3MPattern(pattern_offsets[j], song->patterns[j], f)) {
				delete [] pattern_offsets;
				goto error;
			}
		}
	}
	delete [] pattern_offsets;
	
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
