#include "s3mplay.hpp"
#include "wuf!.h"
#include "stdio.h"
#include "irq.h"

S3MPlayable::S3MPlayable(const char *file_name)
	: Playable(), song_(NULL), min_channel_index_(1), max_channel_index_(0), mixer_channels_(NULL), mixer_callback_(kHMixerCallbackInvalid), num_ticks_(0), row_index_(0), pattern_index_(0) {
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
	mixer_channels_ = new TChannel*[NumMixerChannels()];
	for (int i = 0; i < NumMixerChannels(); ++i) {
		mixer_channels_[i] = NULL;
	}
	Stop();
}

S3MPlayable::~S3MPlayable() {
	Destroy();
}

void S3MPlayable::Destroy() {
	Pause();
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
	num_ticks_ = 0;
	row_index_ = 0;
	pattern_index_ = 0;
}

void S3MPlayable::Volume(float volume) {	
}

float S3MPlayable::Volume() {
	return 0;
}

void S3MPlayable::Tick(HMixerCallback mixer_callback, void *user_pointer) {	
	S3MPlayable *self = static_cast<S3MPlayable *>(user_pointer);
	++self->num_ticks_;
	if (self->num_ticks_ >= self->ticks_per_row_) {
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
	
	// If DOS error mode flag, we cannot call any int 21h service, e.g. printf
	if (!(IRQDOSFlags() & 0xff)) {
		// Even if InDOS flag is set, services 1 thru 0ch can be called safely; printf() uses service 2.
		printf("Pattern: %dn", self->pattern_index_);
		printf(", row: %dn", self->row_index_);
		printf("\n");
	}
}