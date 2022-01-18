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
	bool IsPlaying();
	void Stop();
	// TODO: implement volume interface.
	void Volume(float volume);
	float Volume();
	
	// This functions should not be called from an IRQ with higher priority than that of the sound card.
	void Forward();
	void Backward();
	
	enum WaveformType { SINE = 0, SAWTOOTH = 1, SQUARE = 2, RANDOM = 3, NUM_WAVEFORMS = 4 };
	
protected:
	int NumMixerChannels() const;
	void Destroy();
	static void Tick(HMixerCallback mixer_callback, void *user_pointer);
	static DWORD FreqMultiplierForNote(BYTE note, BYTE octave, int period_increment, DWORD instrument_frequency, int vibrato);
	static DWORD MixerCallbackPeriod(DWORD ticks_per_second);
	int MixerChannelIndexForCellChannelIndex(int cell_channel_index) const;
	int SongChannelIndexForMixerChannelIndex(int mixer_channel_index) const;
	void PrintRow();
	
private:
	S3MSong *song_;
	int min_channel_index_;
	int max_channel_index_;
	TChannel **mixer_channels_;
	HMixerCallback mixer_callback_;
	int num_ticks_;
	int row_index_;
	BYTE order_;
	int next_order_;
	int ticks_per_second_;
	int ticks_per_row_;
	TWave *instruments_;
	BYTE repeat_row_times_;
	
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
		BYTE vibrato_data;
		BYTE vibrato_index;
		int vibrato_depth;
		
		BYTE remaining_delay_ticks;
		S3MCell delayed_cell;
		
		BYTE remaining_retrigger_ticks;
		
		BYTE tremor_remaining_ticks;
		
		BYTE panning;	// 0 = left, 64 = right
	};
	// One-to-one correspondence with mixer_channels_
	SongChannel *song_channels_;
	
	int waveform_tables_[NUM_WAVEFORMS][64];
	bool is_playing_;
	
protected:
	void TonePortamento(SongChannel &channel);
	int Tremolo(SongChannel &channel);
	int Vibrato(SongChannel &channel);
	void VibratoTick(SongChannel &channel);
	DWORD PlayVolume(const SongChannel &channel) const;
	static bool EffectsShareMemory(char fx1, char fx2);
	void VolumeSlideRow(SongChannel &channel);
	void VolumeSlideTick(SongChannel &channel);
	void HandleNewNote(const S3MCell &cell, SongChannel &channel, TWave **instrument, DWORD *sample_offset);
	bool NeedsRetrigger(SongChannel &channel);
	void AdvanceRow(int next_row);
	void TremorRow(SongChannel &channel);
	void TremorTick(SongChannel &channel);
};

#endif