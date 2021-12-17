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

	enum WaveformType { SINE = 0, SAWTOOTH = 1, SQUARE = 2, RANDOM = 3, NUM_WAVEFORMS = 4 };
	
protected:
	int NumMixerChannels() const;
	void Destroy();
	static void Tick(HMixerCallback mixer_callback, void *user_pointer);
	static DWORD FreqMultiplierForNote(BYTE note, BYTE octave, int period_increment, DWORD instrument_frequency, int vibrato);
	static DWORD MixerCallbackPeriod(DWORD ticks_per_second);
	int MixerChannelIndexForCellChannelIndex(int cell_channel_index) const;
	
private:
	S3MSong *song_;
	int min_channel_index_;
	int max_channel_index_;
	TChannel **mixer_channels_;
	HMixerCallback mixer_callback_;
	int num_ticks_;
	int row_index_;
	BYTE order_;
	int ticks_per_second_;
	int ticks_per_row_;
	TWave *instruments_;
	
	class SongChannel {
	public:
		SongChannel();
		void Reset();

		BYTE instrument;
		DWORD instrument_freq;
		BYTE volume;
		BYTE note;
		BYTE octave;
		int period_increment;
		DWORD freq_multiplier;
		char effect;
		BYTE effect_value;
		BYTE last_note;
		BYTE last_octave;
		bool is_playing;
		
		WaveformType tremolo_waveform;
		BYTE tremolo_index;
		int tremolo_volume;
		
		WaveformType vibrato_waveform;
		BYTE vibrato_index;
		int vibrato_depth;		
	};
	// One-to-one correspondence with mixer_channels_
	SongChannel *song_channels_;
	
	int waveform_tables_[NUM_WAVEFORMS][64];
	
protected:
	void TonePortamento(SongChannel &channel);
	int Tremolo(SongChannel &channel);
	int Vibrato(SongChannel &channel);
	DWORD PlayVolume(const SongChannel &channel) const;
};

#endif