#include "stddef.h"

typedef WORD S3MShortOffset;

typedef struct {
	BYTE		high;
	WORD		low;
} S3MLongOffset;

typedef struct {
	BYTE	is_disabled:1;
	BYTE	type:7;
} S3MChannel;

typedef struct {
	BYTE	type;
	BYTE	file_name[12];
} S3MInstrumentHeader;

typedef struct {
	S3MLongOffset		offset;
	DWORD				length;
	DWORD				loop_start;
	DWORD				loop_end;
	BYTE				default_volume;
	BYTE				reserved;
	BYTE				is_packed;
	BYTE				flags;
} S3MInstrumentSampled;

typedef struct {
	BYTE				reserved[3];
	BYTE				unnamed[16];
} S3MInstrumentAdlib;

typedef struct {
	DWORD		tuning_hz;
	BYTE		reserved[12];
	BYTE		name[28];
	DWORD		magic;
} S3MInstrumentFooter;

typedef struct {
	WORD		size;
} S3MPatternHeader;

typedef struct {
	BYTE		has_fx:1;
	BYTE		has_volume:1;
	BYTE		has_note_and_instrument:1;
	BYTE		channel_number:5;
	BYTE		note;
	BYTE		instrument;
	BYTE		volume;
	BYTE		fx_type;
	BYTE		fx_value;
} S3MPatternCell;

typedef struct {
	BYTE		reserved1:2;
	BYTE		has_custom_pan:1;
	BYTE		reserved2:1;
	BYTE		pan:4;
} S3MChannelPan;

typedef struct {
	S3MChannelPan	channel_pans[32];
} S3MChannelPans;

typedef struct {
	BYTE 		module_name[28];
	BYTE 		magic1;
	BYTE 		file_type;
	WORD 		reserved;
	WORD 		num_orders;
	WORD 		num_instrumens;
	WORD 		num_patterns;
	WORD 		flags;
	WORD 		tracker_version;
	WORD 		samples_format;
	DWORD		magic2;
	BYTE		global_volume;
	BYTE		initial_speed;
	BYTE		initial_tempo;
	BYTE		is_stereo:1;
	BYTE		master_volume:7;
	BYTE		ultra_click_removal;
	BYTE		has_custom_pan;
	BYTE		reserved2[8];
	WORD		offset_special;
	S3MChannel	channels[32];
} S3MSongHeader;