#include "s3m.hpp"
#include "s3m.h"
#include "stdio.h"

S3MSong::S3MSong(const char *file_name) {
	song_ = LoadS3M(file_name);
	if (song_ == NULL) {
		return;
	}
	instruments_ = new S3MInstrument[NumInstruments()];
	for (int i = 0; i < NumInstruments(); ++i) {
		instruments_[i].song_ = song_;
		instruments_[i].index_ = i;
	}
}

bool S3MSong::IsLoaded() const {
	return song_ != NULL;
}

S3MSong::~S3MSong() {
	if (song_ == NULL) {
		return;
	}
	delete song_;
}

const char *S3MSong::Name() const {
	return song_->header.module_name;
}

int S3MSong::NumOrders() const {
	return song_->header.num_orders - 1;
}

int S3MSong::NumInstruments() const {
	return song_->header.num_instruments;
}

int S3MSong::NumPatterns() const {
	return song_->header.num_patterns;
}

const S3MInstrument *S3MSong::Instrument(const int instrument_index) const {
	if (instrument_index < 0 || instrument_index >= NumInstruments()) {
		return NULL;
	}
	return &instruments_[instrument_index];
}

const TS3MInstrument &S3MInstrument::Instrument() const {
	return song_->instruments[index_];
}
	
const char *S3MInstrument::Name() const {
	return Instrument().header.name;
}

const S3MInstrumentType S3MInstrument::Type() const {
	if (Instrument().header.type > 3) {
		return TypeUnknown;
	}
	return (S3MInstrumentType)Instrument().header.type;
}

int S3MInstrument::DefaultVolume() const {
	return Instrument().header.spec.sampled.default_volume;
}

bool S3MInstrument::HasLoop() const {
	return Instrument().header.spec.sampled.flags & 1;
}

DWORD S3MInstrument::LoopStart() const {
	return Instrument().header.spec.sampled.loop_start;
}

DWORD S3MInstrument::LoopEnd() const {
	return Instrument().header.spec.sampled.loop_end;
}

bool S3MInstrument::IsStereo() const {
	return Instrument().header.spec.sampled.flags & 2;
}

bool S3MInstrument::Is16Bit() const {
	return Instrument().header.spec.sampled.flags & 4;
}

S3MInstrumentPacking S3MInstrument::Packing() const {
	if (Instrument().header.spec.sampled.packing > 1) {
		return PackingUnknown;
	}
	return (S3MInstrumentPacking)(Instrument().header.spec.sampled.packing + 1);
}

DWORD S3MInstrument::C2Frequency() const {
	return Instrument().header.c2_frequency;
}

DWORD S3MInstrument::NumSamples() const {
	return Instrument().header.spec.sampled.length;
}

void *S3MInstrument::Samples() const {
	return Instrument().data;
}

const BYTE S3MSong::Order(const int order_index) const {
	if (order_index < 0 || order_index >= NumOrders()) {
		return -1;
	}
	return song_->orders[order_index];
}