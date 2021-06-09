#include "s3m.h"
#include "alloc.h"
#include "filesys.h"
#include "stdio.h"

#define read_field(field, file) \
	(ttl_read(&field, sizeof(field), file) == sizeof(field))

#define INSTRUMENT_TYPE_SAMPLE			1
#define INSTRUMENT_TYPE_ADLIB_MELODY	2
#define INSTRUMENT_TYPE_ADLIB_DRUM		3

static bool LoadS3MInstrument(int instrument_offset, TS3MInstrument &instrument, DWORD f) {
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

static bool LoadS3MPattern(int pattern_offset, TS3MPattern &pattern, DWORD f) {
	if (ttl_seek(f, pattern_offset, SEEK_SET) != pattern_offset) {
		return false;
	}
	if (!read_field(pattern.header, f)) {
		return false;
	}
	pattern.cells = (TS3MPatternCell *)new BYTE[pattern.header.size];
	if (pattern.cells == NULL) {
		return false;
	}
	return ttl_read(pattern.cells, pattern.header.size, f) == pattern.header.size;
}

static void SafeDeleteBuffer(void **p) {
	if (*p == NULL) {
		return;
	}
	delete [] *p;
	*p = NULL;
}

#define SAFE_DELETE_BUFFER(p)	SafeDeleteBuffer((void **)&p)

TS3MSong *LoadS3M(const char *file_path) {
	TS3MShortOffset *pattern_offsets = NULL;
	int num_patterns;
	TS3MShortOffset *instrument_offsets = NULL;
	int num_instruments;

	// Open module file.
	DWORD f = ttl_open(file_path, READ_ONLY);
	if (f == NULL) {
		return NULL;
	}

	// Load S3M header.
	TS3MSong *song = new TS3MSong;
	if (song == NULL) {
		goto error;
	}
	if (!read_field(song->header, f)) {
		goto error;
	}

	// Load song orders.
	song->orders = new BYTE[song->header.num_orders];
	if (song->orders == NULL) {
		goto error;
	}
	{
		int bytes_read = ttl_read(song->orders, song->header.num_orders, f);
		if (bytes_read != song->header.num_orders) {
			goto error;
		}
	}

	// Load instrument offset table.
	num_instruments = song->header.num_instruments;
	instrument_offsets = new TS3MShortOffset[num_instruments];
	if (instrument_offsets == NULL) {
		goto error;
	}
	{
		int instrument_offsets_size = num_instruments * sizeof(TS3MShortOffset);
		int bytes_read = ttl_read(instrument_offsets, instrument_offsets_size, f);
		if (bytes_read != instrument_offsets_size) {
			goto error;
		}
	}

	// Load pattern offset table.
	num_patterns = song->header.num_patterns;
	pattern_offsets = new TS3MShortOffset[num_patterns];
	if (pattern_offsets == NULL) {
		goto error;
	}
	{
		int pattern_offsets_size = num_patterns * sizeof(TS3MShortOffset);
		if (ttl_read(pattern_offsets, pattern_offsets_size, f) != pattern_offsets_size) {
			goto error;
		}
	}
	
	// Load S3M footer.
	if (ttl_read(&song->pans, sizeof(song->pans), f) != sizeof(song->pans)) {
		goto error;
	}
	
	// Load instruments.
	song->instruments = new TS3MInstrument[num_instruments];
	if (song->instruments == NULL) {
		goto error;
	}
	{
		for (int i = 0; i < num_instruments; ++i) {
			if (!LoadS3MInstrument(instrument_offsets[i], song->instruments[i], f)) {
				goto error;
			}
		}
	}
	SAFE_DELETE_BUFFER(instrument_offsets);

	// Load patterns.
	song->patterns = new TS3MPattern[num_patterns];
	if (song->patterns == NULL) {
		goto error;
	}
	{
		for (int j = 0; j < num_patterns; ++j) {
			if (!LoadS3MPattern(pattern_offsets[j], song->patterns[j], f)) {
				goto error;
			}
		}
	}
	SAFE_DELETE_BUFFER(pattern_offsets);
	
	ttl_close(f);
	
	return song;
	
error:
	SAFE_DELETE_BUFFER(instrument_offsets);
	SAFE_DELETE_BUFFER(pattern_offsets);
	FreeS3M(song);
	if (f != NULL) {
		ttl_close(f);
	}
	return NULL;
}

void FreeS3M(TS3MSong *song) {
	if (song != NULL) {
		SAFE_DELETE_BUFFER(song->orders);
		if (song->instruments != NULL) {
			for (int i = 0; i < song->header.num_instruments; ++i) {
				SAFE_DELETE_BUFFER(song->instruments[i].data);
			}
			SAFE_DELETE_BUFFER(song->instruments);
		}
		if (song->patterns != NULL) {
			for (int i = 0; i < song->header.num_patterns; ++i) {
				SAFE_DELETE_BUFFER(song->patterns[i].cells);
			}
			SAFE_DELETE_BUFFER(song->patterns);
		}
		delete song;
	}
}
