#ifndef __S3MPLAY_INCLUDED__
#define __S3MPLAY_INCLUDED__

#include "playable.hpp"
#include "s3m.hpp"
#include "wuf!.h"
#include "waveload.h"

class S3MPlayable : public Playable {
public:
	S3MPlayable(const char *file_name);
	virtual ~S3MPlayable();
	
	// Playable interface
	bool Play();
	void Pause();
	void Stop();
	void Volume(float volume);
	float Volume();

protected:
	int NumMixerChannels() const;
	void Destroy();
	static void Tick(HMixerCallback mixer_callback, void *user_pointer);
	static DWORD FreqMultiplierForNote(BYTE note, BYTE octave);
	
private:
	S3MSong *song_;
	int min_channel_index_;
	int max_channel_index_;
	TChannel **mixer_channels_;
	HMixerCallback mixer_callback_;
	int num_ticks_;
	int row_index_;
	int pattern_index_;
	int ticks_per_second_;
	int ticks_per_row_;
	TWave *instruments_;
};

#endif