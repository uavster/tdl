#include "s3m.hpp"
#include "s3m.h"
#include "stdio.h"

S3MSong::S3MSong(const char *file_name) {
	song_ = LoadS3M(file_name);
	if (song_ == NULL) {
		return;
	}
	instruments_ = new S3MInstrument[NumInstruments()];
	{
		for (int i = 0; i < NumInstruments(); ++i) {
			instruments_[i].song_ = song_;
			instruments_[i].index_ = i;
		}
	}
	
	{
		for (int i = 0; i < kS3MMaxChannels; ++i) {
			channels_[i].song_ = song_;
			channels_[i].index_ = i;
		}
	}

	patterns_ = new S3MPattern[NumPatterns()];
	{
		for (int i = 0; i < NumPatterns(); ++i) {
			patterns_[i].song_ = song_;
			patterns_[i].index_ = i;
			for (int j = 0; j < patterns_[i].NumRows(); ++j) {
				const TS3MPattern &pattern = patterns_[i].Pattern();
				patterns_[i].rows_[j].cells_ = &pattern.cells[pattern.row_indices[j]];
				if (j > 0) {
					patterns_[i].rows_[j - 1].num_bytes_ = patterns_[i].rows_[j].cells_ - patterns_[i].rows_[j - 1].cells_ - sizeof(TS3MPatternCellHeader);
				}
			}
			if (j > 0) {
				patterns_[i].rows_[j - 1].num_bytes_ = patterns_[i].Pattern().header.size - sizeof(patterns_[i].Pattern().header) - patterns_[i].Pattern().row_indices[j - 1] - sizeof(TS3MPatternCellHeader);
			}
		}
	}
}

bool S3MSong::IsLoaded() const {
	return song_ != NULL;
}

S3MSong::~S3MSong() {
	if (song_ == NULL) {
		return;
	}
	delete [] patterns_;
	delete [] instruments_;
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

const S3MPattern *S3MSong::Pattern(const int pattern_index) const {
	if (pattern_index < 0 || pattern_index >= NumPatterns()) {
		return NULL;
	}
	return &patterns_[pattern_index];
}

const S3MChannel *S3MSong::Channel(const int channel_index) const {
	if (channel_index < 0 || channel_index >= kS3MMaxChannels) {
		return NULL;
	}
	return &channels_[channel_index];
}

const TS3MPattern &S3MPattern::Pattern() const {
	return song_->patterns[index_];
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

bool S3MSong::HasVolumeOptimization() const {
	return song_->header.flags & 0x8;
}

bool S3MSong::HasAmigaLimits() const {
	return song_->header.flags & 0x10;
}

S3MTrackerID S3MSong::TrackerID() const {
	return (S3MTrackerID)song_->header.tracker_version.id;
}

S3MTrackerVersion S3MSong::TrackerVersion() const {
	S3MTrackerVersion version;
	version.parts.major = song_->header.tracker_version.version_major;
	version.parts.minor = song_->header.tracker_version.version_minor;
	return version;
}

const char *S3MSong::TrackerName() const {
	return TrackerNameFromID(TrackerID());
}

S3MSamplesFormat S3MSong::SamplesFormat() const {
	return (S3MSamplesFormat)song_->header.samples_format;
}

bool S3MSong::AreSamplesSigned() const {
	return SamplesFormat() == Signed;
}

BYTE S3MSong::GlobalVolume() const {
	return song_->header.global_volume;
}

BYTE S3MSong::MasterVolume() const {
	return song_->header.master_volume;
}

BYTE S3MSong::InitialSpeed() const {
	return song_->header.initial_speed;
}

BYTE S3MSong::InitialTempo() const {
	return song_->header.initial_tempo;
}

bool S3MSong::IsStereo() const {
	return song_->header.is_stereo != 0;
}

bool S3MSong::HasCustomPan() const {
	return song_->header.has_custom_pan != 0;
}

// S3MPatternRowIterator S3MPattern::begin() const {
	// return S3MPatternRowIterator(this, 0);
// }

// S3MPatternRowIterator S3MPattern::end() const {
	// return S3MPatternRowIterator(this, kEndRowIndex);
// }

int S3MPattern::NumRows() const {
	return Pattern().num_rows;
}

const S3MRow *S3MPattern::Row(int row_index) const {
	if (row_index < 0 || row_index >= NumRows()) {
		return NULL;
	}
	return &rows_[row_index];
}

S3MCellIterator S3MRow::begin() const {
	return S3MCellIterator(num_bytes_, cells_, 0);
}

S3MCellIterator S3MRow::end() const {
	return S3MCellIterator(num_bytes_, cells_, num_bytes_);
}

S3MCellIterator::S3MCellIterator(int num_bytes, const BYTE *cells, int byte_index) : byte_index_(byte_index), num_bytes_(num_bytes), cells_(cells) {}

S3MCellIterator S3MCellIterator::operator++(int) {
	S3MCellIterator it = *this;
	if (byte_index_ >= num_bytes_) {
		return it;
	}
	const TS3MPatternCellHeader &cell_header = *(TS3MPatternCellHeader *)&cells_[byte_index_];
	byte_index_++;	// Skip header
	if (cell_header.has_effect) {
		byte_index_ += 2;
	}
	if (cell_header.has_volume) {
		byte_index_++;
	}
	if (cell_header.has_note_and_instrument) {
		byte_index_ += 2;
	}
	return it;
}

void S3MCellIterator::operator+=(int increment) {
	for (int i = 0; i < increment && byte_index_ < num_bytes_; ++i) {
		(*this)++;
	}
}

bool S3MCellIterator::operator==(const S3MCellIterator &it) const {
	return byte_index_ == it.byte_index_;
}

bool S3MCellIterator::operator!=(const S3MCellIterator &it) const {
	return byte_index_ != it.byte_index_;
}

S3MCell S3MCellIterator::Cell() const {
	return S3MCell(&cells_[byte_index_]);
}

S3MCell::S3MCell(const BYTE *cell) : cell_(cell) {}

BYTE S3MCell::ChannelNumber() const {
	return ((TS3MPatternCellHeader *)cell_)->channel_number;
}

bool S3MCell::HasNoteAndInstrument() const {
	return ((TS3MPatternCellHeader *)cell_)->has_note_and_instrument;
}

BYTE S3MCell::Note() const {
	return cell_[1] & 0xf;
}

char S3MCell::NoteLetter() const {
	const static char letters[] = {'C', 'C', 'D', 'D', 'E', 'F', 'F', 'G', 'G', 'A', 'A', 'B'};
	return letters[Note() % 12];
}

bool S3MCell::IsSemitone() const {
	const static bool is_semitone[] = {false, true, false, true, false, false, true, false, true, false, true, false};
	return is_semitone[Note() % 12];
}

BYTE S3MCell::Octave() const {
	return ((cell_[1] >> 4) & 0xf) + 1;
}

void S3MCell::GetNoteName(char *name) const {
	if (HasNoteAndInstrument()) {
		name[0] = NoteLetter();
		name[1] = IsSemitone() ? '#' : '-';
		name[2] = Octave() + '0';
	} else {
		name[0] = '.';
		name[1] = '.';
		name[2] = '.';
	}
	name[3] = '\0';
}

BYTE S3MCell::Instrument() const {
	return cell_[2];
}

bool S3MCell::HasVolume() const {
	return ((TS3MPatternCellHeader *)cell_)->has_volume;
}

BYTE S3MCell::Volume() const {
	if (HasNoteAndInstrument()) {
		return cell_[3];
	} else {
		return cell_[1];
	}
}

bool S3MCell::HasEffect() const {
	return ((TS3MPatternCellHeader *)cell_)->has_effect;
}

char S3MCell::Effect() const {
	int index = 1;
	if (HasNoteAndInstrument()) {
		index += 2;
	}
	if (HasVolume()) {
		index++;
	}
	return cell_[index] - 1 + 'A';
}

BYTE S3MCell::EffectValue() const {
	int index = 2;
	if (HasNoteAndInstrument()) {
		index += 2;
	}
	if (HasVolume()) {
		index++;
	}
	return cell_[index];
}

bool S3MChannel::IsEnabled() const {
	return !song_->header.channels[index_].is_disabled;
}

BYTE S3MChannel::Pan() const {
	if (song_->pans.channel_pans[index_].has_custom_pan) {
		return song_->pans.channel_pans[index_].pan;
	} else {
		return song_->header.channels[index_].type < 8 ? 0 : 15;
	}
}

// S3MPatternRowIterator::S3MPatternRowIterator(const S3MPattern *pattern, int row) : pattern_(pattern), current_row_(row) {
// }

// S3MPatternRowIterator S3MPatternRowIterator::operator++() {
	// return S3MPatternRowIterator(current_row_++);
// }

// void S3MPatternRowIterator::operator+=(int offset) {
	// current_row += offset;
// }

// void S3MPatternRowIterator::operator-=(int offset) {
	// current_row -= offset;
// }

	// S3MPatternRowIterator &S3MPatternRowIterator::operator=(int row) {
	// current_row = row;
	// return *this;
// }

