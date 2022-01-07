#include "s3m.h"
#include "alloc.h"
#include "filesys.h"
#include "stdio.h"

// The size is passed directly instead of deriving it with sizeof(field), 
// as the field instance may be not be in a tightly packed structure, even if
// its definition is.
#define read_field(field, size, file) \
	(ttl_read(field, size, file) == size)

#define INSTRUMENT_TYPE_NONE			0
#define INSTRUMENT_TYPE_SAMPLE			1
#define INSTRUMENT_TYPE_ADLIB_MELODY	2
#define INSTRUMENT_TYPE_ADLIB_DRUM		3

#define S3M_SONG_TYPE_ST3_MODULE	16
#define S3M_SONG_MAGIC1_VALUE 0x1A
#define S3M_SONG_MAGIC2_VALUE ((int)'S' | ((int)'C' << 8) | ((int)'R' << 16) | ((int)'M' << 24))
#define S3M_INSTRUMENT_MAGIC_VALUE ((int)'S' | ((int)'C' << 8) | ((int)'R' << 16) | ((int)'S' << 24))

static bool LoadS3MInstrument(int instrument_offset, TS3MInstrument &instrument, DWORD f) {
	if (ttl_seek(f, instrument_offset, SEEK_SET) != instrument_offset) {
		return false;
	}
	if (!read_field(&instrument.header, sizeof(TS3MInstrumentHeader), f)) {
		return false;
	}	
	if (instrument.header.type == INSTRUMENT_TYPE_NONE) {
		return true;
	}
	if (instrument.header.type != INSTRUMENT_TYPE_SAMPLE) {
		return false;
	}
	if (instrument.header.magic != S3M_INSTRUMENT_MAGIC_VALUE) {
		return false;
	}
	instrument.data = new BYTE[instrument.header.spec.sampled.length];
	if (instrument.data == NULL) {
		return false;
	}
	DWORD data_offset = 16 * (((DWORD)instrument.header.spec.sampled.offset.high << 16) | ((DWORD)instrument.header.spec.sampled.offset.low));
	if (ttl_seek(f, data_offset, SEEK_SET) != data_offset) {
		return false;
	}
	if (!read_field(instrument.data, instrument.header.spec.sampled.length, f)) {
		return false;
	}
	return true;
}

static bool LoadS3MPattern(int pattern_offset, TS3MPattern &pattern, DWORD f) {
	if (ttl_seek(f, pattern_offset, SEEK_SET) != pattern_offset) {
		return false;
	}
	if (!read_field(&pattern.header, sizeof(TS3MPatternHeader), f)) {
		return false;
	}
	int total_bytes = pattern.header.size - sizeof(pattern.header);
	pattern.cells = new BYTE[total_bytes];
	if (pattern.cells == NULL) {
		return false;
	}
	if (!read_field(pattern.cells, total_bytes, f)) {
		return false;
	}
	// Build row index.
	pattern.num_rows = 0;
	int i = 0;
	pattern.row_indices[pattern.num_rows] = i;
	while (i < total_bytes) {
		if (*(BYTE *)&pattern.cells[i] == 0) {
			++pattern.num_rows;
			if (pattern.num_rows > kS3MMaxRows) {
				printf("S3M pattern has more than %dn rows.\n", kS3MMaxRows);
				return false;
			}
			++i;
			if (i < total_bytes) {
				pattern.row_indices[pattern.num_rows] = i;
			}
		}
		else {
			TS3MPatternCellHeader cell_header = *(TS3MPatternCellHeader *)&pattern.cells[i];		
			++i;
			if (cell_header.has_effect) {
				i += 2;
			}
			if (cell_header.has_volume) {
				++i;
			}
			if (cell_header.has_note_and_instrument) {
				i += 2;
			}
		}
	}

	return true;
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
	if (!read_field(&song->header, sizeof(TS3MSongHeader), f)) {
		goto error;
	}

	// Check file type and magic numbers.
	if (song->header.magic1 != S3M_SONG_MAGIC1_VALUE ||
		song->header.magic2 != S3M_SONG_MAGIC2_VALUE ||
		song->header.file_type != S3M_SONG_TYPE_ST3_MODULE) {
		goto error;
	}
	
	// Load song orders.
	song->orders = new BYTE[song->header.num_orders];
	if (song->orders == NULL) {
		goto error;
	}
	if (!read_field(song->orders, song->header.num_orders, f)) {
		goto error;
	}

	// Load instrument offset table.
	num_instruments = song->header.num_instruments;
	instrument_offsets = new TS3MShortOffset[num_instruments];
	if (instrument_offsets == NULL) {
		goto error;
	}
	{
		const int instrument_offsets_size = num_instruments * sizeof(TS3MShortOffset);
		if (!read_field(instrument_offsets, instrument_offsets_size, f)) {
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
		if (!read_field(pattern_offsets, pattern_offsets_size, f)) {
			goto error;
		}
	}
	
	// Load S3M footer.
	if (song->header.has_custom_pan) {
		if (!read_field(&song->pans, sizeof(song->pans), f)) {
			goto error;
		}
	}
	
	// Load instruments.
	song->instruments = new TS3MInstrument[num_instruments];
	if (song->instruments == NULL) {
		goto error;
	}
	{
		for (int i = 0; i < num_instruments; ++i) {
			if (!LoadS3MInstrument(16 * instrument_offsets[i], song->instruments[i], f)) {
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
			if (!LoadS3MPattern(16 * pattern_offsets[j], song->patterns[j], f)) {
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

const char *TrackerNameFromID(ES3MTrackerID id) {
	static const char scream[] = "Scream Tracker";
	static const char imago[] = "Imago Orpheus";
	static const char impulse[] = "Impulse Tracker";
	static const char schism[] = "Schism Tracker";
	static const char openmpt[] = "OpenMPT";	
	static const char bero[] = "BeRO Tracker";
	static const char cream[] = "Cream Tracker";
	static const char camoto[] = "Camoto/libgamemusic";
	static const char unknown[] = "Unknown";
	
	switch(id) {
		case ScreamTracker: return scream;
		case ImagoOrpheus: return imago;
		case ImpulseTracker: return impulse;
		case SchismTracker: return schism;
		case OpenMPT: return openmpt;
		case BeRoTracker: return bero;
		case CreamTracker: return cream;
		case Camoto: return camoto;
		default: return unknown;
	}
}