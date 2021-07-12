// S3M file loader

#include "stddef.h"

#ifndef __S3M_HEADER__
#define __S3M_HEADER__

#ifdef __cplusplus
  extern "C" {
#endif

#define kS3MMaxChannels 32
#define kS3MMaxRows 64

// Constant-size pieces of S3M file format.

#pragma pack(push, 1)

typedef WORD TS3MShortOffset;

typedef struct {
	BYTE		high;
	WORD		low;
} TS3MLongOffset;

typedef struct {
	BYTE	type:7;
	BYTE	is_disabled:1;
} TS3MChannel;

typedef enum {
	TypeUnknown = 0, Sampled = 1, AdlibMelody = 2, AdlibDrum = 3
} ES3MInstrumentType;

typedef enum {
	PackingUnknown = 0, Unpacked = 1, DP30ADPCM = 2
} ES3MInstrumentPacking;

typedef struct {
	BYTE	type;
	char	file_name[12];
	union {
		struct {
			TS3MLongOffset		offset;
			DWORD				length;
			DWORD				loop_start;
			DWORD				loop_end;
			BYTE				default_volume;
			BYTE				reserved;
			BYTE				packing;
			BYTE				flags;
		} sampled;
		struct {
			BYTE				reserved[3];
			BYTE				specs[16];
		} adlib;
	} spec;
	DWORD		c2_frequency;
	BYTE		reserved[12];
	char		name[28];
	DWORD		magic;
} TS3MInstrumentHeader;

typedef struct {
	WORD		size;
} TS3MPatternHeader;

typedef struct {
	BYTE		channel_number:5;
	BYTE		has_note_and_instrument:1;
	BYTE		has_volume:1;
	BYTE		has_effect:1;
	// Depending on the flags above, the following fields may follow:
	// BYTE		note;
	// BYTE		instrument;
	// BYTE		volume;
	// BYTE		fx_type;
	// BYTE		fx_value;
} TS3MPatternCellHeader;

typedef struct {
	BYTE		pan:4;
	BYTE		reserved2:1;
	BYTE		has_custom_pan:1;
	BYTE		reserved1:2;
} TS3MChannelPan;

typedef struct {
	TS3MChannelPan	channel_pans[32];
} TS3MChannelPans;

typedef enum {
	ScreamTracker = 1, 
	ImagoOrpheus = 2, 
	ImpulseTracker = 3, 
	SchismTracker = 4, 	// Up to v0.50; later versions encode a timestamp in the version value
	OpenMPT = 5, 
	BeRoTracker = 6, 
	CreamTracker = 7, 
	Camoto = 12			// Version value is 0xCA00
} ES3MTrackerID;

const char *TrackerNameFromID(ES3MTrackerID id);

typedef struct {
	WORD version_minor:8;
	WORD version_major:4;
	WORD id:4;
} TS3MTrackerVersion;

typedef enum {
	Signed = 1,
	Unsigned = 2
} ES3MSamplesFormat;

typedef struct {
	char 		module_name[28];
	BYTE 		magic1;
	BYTE 		file_type;
	WORD 		reserved;
	WORD 		num_orders;
	WORD 		num_instruments;
	WORD 		num_patterns;
	WORD 		flags;
	TS3MTrackerVersion tracker_version;
	WORD 		samples_format;
	DWORD		magic2;
	BYTE		global_volume;
	BYTE		initial_speed;
	BYTE		initial_tempo;
	BYTE		master_volume:7;
	BYTE		is_stereo:1;
	BYTE		ultra_click_removal;
	BYTE		has_custom_pan;
	BYTE		reserved2[8];
	WORD		offset_special;
	TS3MChannel	channels[kS3MMaxChannels];
} TS3MSongHeader;

#pragma pack(pop)

// Song structures in memory.

typedef struct {
	TS3MInstrumentHeader	header;
	void *data;
} TS3MInstrument;

typedef struct {
	TS3MPatternHeader header;
	BYTE *cells;	// Compact array of TS3MPatternCellHeader, each followed by a variable payload.
	BYTE num_rows;
	WORD row_indices[64];
} TS3MPattern;

typedef struct {
	TS3MSongHeader header;
	BYTE *orders;
	TS3MInstrument *instruments;
	TS3MPattern *patterns;
	TS3MChannelPans pans;
} TS3MSong;

// Loads an S3M file into memory.
// Returns a pointer to the song structure, or NULL if error.
TS3MSong *LoadS3M(const char *file_path);
void FreeS3M(TS3MSong *song);

#ifdef __cplusplus
  }
#endif

#endif