#include "s3mplay.hpp"
#include "wuf!.h"
#include "stdio.h"
#include "irq.h"

S3MPlayable::S3MPlayable(const char *file_name)
	: Playable(), song_(NULL), min_channel_index_(1), max_channel_index_(0), mixer_channels_(NULL), mixer_callback_(kHMixerCallbackInvalid), num_ticks_(0), row_index_(0), pattern_index_(0), instruments_(NULL) {
	song_ = new S3MSong(file_name);
	if (!song_->IsLoaded()) {
		Destroy();
		LastError(kCantLoad);
		return;
	}
	ticks_per_row_ = song_->InitialSpeed();
	ticks_per_second_ = song_->InitialTempo();
	// Get the min and max channels used.
	min_channel_index_ = 1000000;
	max_channel_index_ = -1;
	for (int pattern_index = 0; pattern_index < song_->NumPatterns(); ++pattern_index) {
		for (int row_index = 0; row_index < song_->Pattern(pattern_index)->NumRows(); ++row_index) {
			const S3MRow *row = song_->Pattern(pattern_index)->Row(row_index);
			for (S3MCellIterator it = row->begin(); it != row->end(); it++) {
				int channel_number = it.Cell().ChannelNumber();
				if (channel_number < min_channel_index_) {
					min_channel_index_ = channel_number;
				}
				if (channel_number > max_channel_index_) {
					max_channel_index_ = channel_number;
				}
			}
		}
	}
	// Create mixer channels.
	if (NumMixerChannels()) {
		mixer_channels_ = new TChannel*[NumMixerChannels()];
		for (int i = 0; i < NumMixerChannels(); ++i) {
			mixer_channels_[i] = NULL;
		}
	}
	// Create TWave for each instrument.
	if (song_->NumInstruments() > 0) {
		instruments_ = new TWave[song_->NumInstruments()];
		for (int j = 0; j < song_->NumInstruments(); ++j) {
			const S3MInstrument *instrument = song_->Instrument(j);
			instruments_[j].WaveType = instrument->IsStereo() ? 1 : 0;
			instruments_[j].WaveType |= instrument->Is16Bit() ? 2 : 0;
			instruments_[j].WavePtr = instrument->Samples();
			instruments_[j].WaveLen = instrument->NumSamples();
			instruments_[j].BaseRate = instrument->C2Frequency();
		}
	}
	Stop();
}

S3MPlayable::~S3MPlayable() {
	Destroy();
}

void S3MPlayable::Destroy() {
	Pause();
	// TODO: Wait for IRQ to actually pause before freeing samples
	if (instruments_ != NULL) {
		delete [] instruments_;
		instruments_ = NULL;
	}
	if (mixer_channels_ != NULL) {
		delete [] mixer_channels_;
		mixer_channels_ = NULL;
	}
	if (song_ != NULL) {
		delete song_;
		song_ = NULL;
	}
}

int S3MPlayable::NumMixerChannels() const {
	return max_channel_index_ - min_channel_index_ + 1;
}

bool S3MPlayable::Play() {
	if (LastError() != kSuccess) {
		return false;
	}
	// Limited audio resources are allocated before playing, 
	// so that multiple playables can stay in memory without
	// consuming resources.
	if (WUFAllocateChannels(0, NumMixerChannels(), mixer_channels_) != 0) {
		LastError(kCantAllocateMixerChannels);
		return false;
	}
	printf("Ticks per second: %dn", ticks_per_second_);
	printf("\n");
	mixer_callback_ = WUFAddMixerCallback(5.0f / ticks_per_second_, &Tick, this);
	if (mixer_callback_ == kHMixerCallbackInvalid) {
		WUFFreeChannels(NumMixerChannels(), mixer_channels_);
		LastError(kCantAddMixerCallback);
		return false;
	}
	return true;
}

void S3MPlayable::Pause() {
	if (LastError() != kSuccess) {
		return;
	}
	if (mixer_callback_ != kHMixerCallbackInvalid) {
		WUFDeleteMixerCallback(mixer_callback_);
		mixer_callback_ = kHMixerCallbackInvalid;
	}
	if (mixer_channels_ != NULL) {
		WUFFreeChannels(NumMixerChannels(), mixer_channels_);
	}
}

void S3MPlayable::Stop() {
	Pause();
	num_ticks_ = ticks_per_row_ - 1;
	row_index_ = 0;
	pattern_index_ = 0;
}

void S3MPlayable::Volume(float volume) {	
}

float S3MPlayable::Volume() {
	return 0;
}

DWORD S3MPlayable::FreqMultiplierForNote(BYTE note, BYTE octave) {
	static const DWORD period_by_note[] = { 1712, 1616, 1524, 1440, 1356, 1280, 1208, 1140, 1076, 1016, 960, 907 };
	return ((14317056u << 8) / ((8363u * 16u * period_by_note[note]) >> octave)) << 16;
}

void S3MPlayable::Tick(HMixerCallback mixer_callback, void *user_pointer) {	
	S3MPlayable *self = static_cast<S3MPlayable *>(user_pointer);
	
	++self->num_ticks_;
	if (self->num_ticks_ >= self->ticks_per_row_) {
		const S3MRow *row = self->song_->Pattern(self->pattern_index_)->Row(self->row_index_);
		for (S3MCellIterator it = row->begin(); it != row->end(); it++) {
			S3MCell cell = it.Cell();
			DWORD volume;
			TWave *instrument;
			if (cell.HasInstrument()) {
				volume = cell.HasVolume() ? cell.Volume() : 64;
				instrument = &self->instruments_[cell.Instrument() - 1];
			} else {
				volume = cell.HasVolume() ? cell.Volume() : -1;		// -1 = keep channel volume
				instrument = NULL;
			}
			DWORD freq_multiplier = cell.HasNote() ? FreqMultiplierForNote(cell.Note(), cell.Octave()) : -1;	// -1 = keep channel freq
			DWORD channel_number = static_cast<DWORD>(cell.ChannelNumber()) - static_cast<DWORD>(self->min_channel_index_);
			WUFPlaySound(instrument, WUFChannelInCallback(self->mixer_channels_[channel_number]), freq_multiplier, volume, 0); 
		}
		
		// If DOS error mode flag, we cannot call any int 21h service, e.g. printf
		if (!(IRQDOSFlags() & 0xff)) {
			// Even if InDOS flag is set, services 1 thru 0ch can be called safely; printf() uses service 2.
			printf("p:%dn", self->pattern_index_);
			printf(" r:%dn|", self->row_index_);
			const S3MRow *row = self->song_->Pattern(self->pattern_index_)->Row(self->row_index_);
			int channel_number = 0;
			for (S3MCellIterator it = row->begin(); it != row->end(); it++) {
				// Unused previous channels.
				for (; channel_number < it.Cell().ChannelNumber(); ++channel_number) {
					printf("... .. .. ...");
					if (channel_number < 31) {
						printf("|");
					}
				}
				++channel_number;
				// Print cell data.
				if (it.Cell().HasNote()) {
					char note_name[4];
					it.Cell().GetNoteName(note_name);
					printf(note_name);
				} else {
					printf("... ");
				}
				if (it.Cell().HasInstrument()) {
					printf(" %dn ", it.Cell().Instrument());
				} else {
					printf(".. ");
				}
				if (it.Cell().HasVolume()) {
					printf("%dn ", it.Cell().Volume());
				} else {
					printf(".. ");
				}
				if (it.Cell().HasEffect()) {
					char effect_name[2];
					effect_name[0] = it.Cell().Effect();
					effect_name[1] = '\0';
					printf(effect_name);
					printf("%dhn", it.Cell().EffectValue());
				} else {
					printf("...");
				}
				if (channel_number < 31) {
					printf("|");
				}
			}
			printf("\n");
		}
		
		self->num_ticks_ = 0;
		++self->row_index_;
		if (self->row_index_ >= self->song_->Pattern(self->pattern_index_)->NumRows()) {
			self->row_index_ = 0;
			++self->pattern_index_;
			if (self->pattern_index_ >= self->song_->NumPatterns()) {
				self->pattern_index_ = 0;
			}
		}
	}
}