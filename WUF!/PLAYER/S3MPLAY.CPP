#include "s3mplay.hpp"
#include "wuf!.h"
#include "stdio.h"

S3MPlayable::S3MPlayable(const char *file_name)
	: Playable(), mixer_channels_(NULL), mixer_callback_(kHMixerCallbackInvalid), num_ticks_(0), row_index_(0), pattern_index_(0) {
	song_ = new S3MSong(file_name);
	if (!song_->IsLoaded()) {
		Destroy();
		LastError(kCantLoad);
		return;
	}
	ticks_per_row_ = song_->InitialSpeed();
	ticks_per_second_ = song_->InitialTempo();
	// Get the min and max channels used.
	int min_channel_index_ = 1000000;
	int max_channel_index_ = -1;
	for (int pattern_index = 0; pattern_index < song_->NumPatterns(); ++pattern_index) {
		for (int row_index = 0; row_index < song_->Pattern(pattern_index)->NumRows(); ++row_index) {
			const S3MRow *row = song_->Pattern(pattern_index)->Row(row_index);
			for (S3MCellIterator it = row->begin(); it != row->end(); it++) {
				int channel_number = it.Cell().ChannelNumber();
				if (channel_number < min_channel_index_) {
					min_channel_index_ = channel_number;
				}
				if (channel_number < max_channel_index_) {
					max_channel_index_ = channel_number;
				}
			}
		}
	}
	mixer_channels_ = new TChannel*[NumMixerChannels()];
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
	if (!WUFAllocateChannels(0, NumMixerChannels(), mixer_channels_)) {
		LastError(kCantAllocateMixerChannels);
		return false;
	}
	mixer_callback_ = WUFAddMixerCallback((5000 / ticks_per_second_) / 1000.0f, &Tick, this);
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
	WUFFreeChannels(NumMixerChannels(), mixer_channels_);
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
			++self->pattern_index_;
		}
	}
	printf("Pattern: %dn", self->pattern_index_);
	printf(", row: %dn", self->row_index_);
	printf("\n");
}