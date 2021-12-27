#include "s3mplay.hpp"
#include "wuf!.h"
#include "stdio.h"
#include "irq.h"
#include "tinymath.h"
#include "random.h"

S3MPlayable::S3MPlayable(const char *file_name)
	: Playable(), song_(NULL), min_channel_index_(1), max_channel_index_(0), mixer_channels_(NULL), mixer_callback_(kHMixerCallbackInvalid), num_ticks_(0), row_index_(0), order_(0), instruments_(NULL), song_channels_(NULL) {
	song_ = new S3MSong(file_name);
	if (!song_->IsLoaded()) {
		Destroy();
		LastError(kCantLoad);
		return;
	}
	ticks_per_row_ = song_->InitialSpeed();
	ticks_per_second_ = song_->InitialTempo();
	// Get the min and max channels used.
	min_channel_index_ = 0;
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
	// Create mixer channels and corresponding song channels.
	if (NumMixerChannels()) {
		mixer_channels_ = new TChannel*[NumMixerChannels()];
		for (int i = 0; i < NumMixerChannels(); ++i) {
			mixer_channels_[i] = NULL;
		}
		song_channels_ = new SongChannel[NumMixerChannels()];
	}
	// Create TWave for each instrument.
	if (song_->NumInstruments() > 0) {
		instruments_ = new TWave[song_->NumInstruments()];
		for (int j = 0; j < song_->NumInstruments(); ++j) {		
			const S3MInstrument *instrument = song_->Instrument(j);
			if (instrument->Type() == TypeUnknown) {
				instruments_[j].WavePtr = NULL;
				instruments_[j].WaveLen = 0;
				continue;
			}
			// Check instrument type and packing
			instruments_[j].WaveType = instrument->IsStereo() ? 1 : 0;
			instruments_[j].WaveType |= instrument->Is16Bit() ? 2 : 0;
			instruments_[j].WavePtr = instrument->Samples();
			instruments_[j].WaveLen = instrument->NumSamples();
			instruments_[j].BaseRate = instrument->C2Frequency();
			if (instrument->HasLoop()) {
				instruments_[j].LoopStart = instrument->LoopStart();
				instruments_[j].LoopEnd = instrument->LoopEnd();
			} else {
				instruments_[j].LoopStart = -1;
				instruments_[j].LoopEnd = -1;
			}
		}
	}
	
	// Create waveform tables.
	const int kWaveformTableLength = sizeof(waveform_tables_[SINE]) / sizeof(int);
	for (int i = 0; i < kWaveformTableLength; ++i) { 
		waveform_tables_[SINE][i] = (int)(256.0 * sin(2.0 * M_PI * (i / static_cast<float>(kWaveformTableLength))));
		waveform_tables_[SAWTOOTH][i] = (int)(256.0 * (1.0 - i / (float)kWaveformTableLength));
		waveform_tables_[SQUARE][i] = i < kWaveformTableLength / 2 ? 256 : 0;
		waveform_tables_[RANDOM][i] = (BYTE)random(256);
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
	if (song_channels_ != NULL) {
		delete [] song_channels_;
		song_channels_ = NULL;
	}
	if (song_ != NULL) {
		delete song_;
		song_ = NULL;
	}
}

int S3MPlayable::NumMixerChannels() const {
	return max_channel_index_ - min_channel_index_ + 1;
}

int S3MPlayable::MixerChannelIndexForCellChannelIndex(int cell_channel_index) const {
	return cell_channel_index - min_channel_index_;
}

static DWORD S3MPlayable::MixerCallbackPeriod(DWORD ticks_per_second) {
	return ((2500 * 65536) / 1000) / ticks_per_second;
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
	printf("Ticks per second: %dn\n", ticks_per_second_);
	mixer_callback_ = WUFAddMixerCallback(MixerCallbackPeriod(ticks_per_second_), &Tick, this);
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
	order_ = 0;
	for (int i = 0; i < NumMixerChannels(); ++i) {
		song_channels_[i].Reset();
	}	
}

void S3MPlayable::Volume(float volume) {	
}

float S3MPlayable::Volume() {
	return 0;
}

DWORD S3MPlayable::FreqMultiplierForNote(BYTE note, BYTE octave, int period_increment, DWORD instrument_frequency, int vibrato) {
	// Notes: C, C#, D, D#, E, F, F#, G, G#, A, A#, B
	static const DWORD period_by_note[] = { 1712, 1616, 1524, 1440, 1356, 1280, 1208, 1140, 1076, 1016, 960, 907 };
	// This limit is not imposed by Impulse Tracker. In IT, instruments going above 
	// the max frequency with Fxx go mute, and are no longer recoverable with Fxx.
	// However, we choose to go with stability rather than fidelity to the original behavior.
	// period = 1;		
	const DWORD numerator = 894841u << 12;
	int denominator = ((8363u * period_by_note[note]) >> (octave - 1)) + (((static_cast<int>(instrument_frequency) * (period_increment * 256 + vibrato))) / (256 * 16));
	if (denominator < 4096) {
		return numerator;
	} else if (denominator > numerator) {
		return 1 << 12;
	}
	return (numerator / static_cast<DWORD>(denominator)) << 12;
}

void S3MPlayable::TonePortamento(SongChannel &channel) {
	DWORD new_freq_mult = FreqMultiplierForNote(channel.note, channel.octave, 0, channel.instrument_freq, channel.vibrato_depth);
//printf("note:%dn, octave:%dn, last_note:%dn, last_octave:%dn, period_inc: %dn, nfm:%dn, fm:%dn, fxv:%dn\n", channel.note, channel.octave, channel.last_note, channel.last_octave, channel.period_increment, new_freq_mult, channel.freq_multiplier, channel.effect_value);
	if (new_freq_mult > channel.freq_multiplier) {
		channel.period_increment -= 4 * channel.effect_value;
		channel.freq_multiplier = FreqMultiplierForNote(channel.last_note, channel.last_octave, channel.period_increment, channel.instrument_freq, channel.vibrato_depth);
		if (new_freq_mult < channel.freq_multiplier) {
			channel.freq_multiplier = new_freq_mult;
			channel.period_increment = 0;
		}
	} else if (new_freq_mult < channel.freq_multiplier) {
		channel.period_increment += 4 * channel.effect_value;
		channel.freq_multiplier = FreqMultiplierForNote(channel.last_note, channel.last_octave, channel.period_increment, channel.instrument_freq, channel.vibrato_depth);
		if (new_freq_mult > channel.freq_multiplier) {
			channel.freq_multiplier = new_freq_mult;
			channel.period_increment = 0;
		}
	}	
}

int S3MPlayable::Tremolo(SongChannel &channel) {
	const DWORD kWaveformTableLength = sizeof(waveform_tables_[SINE]) / sizeof(int);
	DWORD tremolo_speed = channel.effect_value >> 4;
	DWORD tremolo_depth = channel.effect_value & 0xf;
	channel.tremolo_index = (channel.tremolo_index + tremolo_speed) % kWaveformTableLength;
	return 2 * tremolo_depth * waveform_tables_[channel.tremolo_waveform][channel.tremolo_index];
}

int S3MPlayable::Vibrato(SongChannel &channel) {
	const DWORD kWaveformTableLength = sizeof(waveform_tables_[SINE]) / sizeof(int);
	DWORD vibrato_speed = channel.vibrato_data >> 4;
	DWORD vibrato_amplitude = channel.vibrato_data & 0xf;
	channel.vibrato_index = (channel.vibrato_index + vibrato_speed) % kWaveformTableLength;
	return vibrato_amplitude * waveform_tables_[channel.vibrato_waveform][channel.vibrato_index];
}

bool S3MPlayable::EffectsShareMemory(char fx1, char fx2) {
	if ((fx1 == 'H' && fx2 == 'U') || (fx1 == 'U' && fx2 == 'H')) {
		return true;
	}
	if ((fx1 == 'E' && fx2 == 'F') || (fx1 == 'F' && fx2 == 'E')) {
		return true;
	}
	if ((fx1 == 'E' && fx2 == 'H') || (fx1 == 'H' && fx2 == 'E')) {
		return true;
	}
	if ((fx1 == 'F' && fx2 == 'H') || (fx1 == 'H' && fx2 == 'F')) {
		return true;
	}
	if ((fx1 == 'E' && fx2 == 'U') || (fx1 == 'U' && fx2 == 'E')) {
		return true;
	}
	if ((fx1 == 'F' && fx2 == 'U') || (fx1 == 'U' && fx2 == 'F')) {
		return true;
	}
	return fx1 == fx2;
}

void S3MPlayable::Tick(HMixerCallback mixer_callback, void *user_pointer) {
	S3MPlayable *self = static_cast<S3MPlayable *>(user_pointer);
	++self->num_ticks_;
	if (self->num_ticks_ < self->ticks_per_row_) {
		// Update channel states with effects.
		for (int i = 0; i < self->NumMixerChannels(); ++i) {
			SongChannel &channel = self->song_channels_[i];
			switch(channel.effect) {
				case 'F':
					if (channel.effect_value < 0xE0) {
						channel.period_increment -= 4 * channel.effect_value;
						channel.freq_multiplier = FreqMultiplierForNote(channel.note, channel.octave, channel.period_increment, channel.instrument_freq, channel.vibrato_depth);
					}
					break;
				case 'E':
					if (channel.effect_value < 0xE0) {
						channel.period_increment += 4 * channel.effect_value;
						channel.freq_multiplier = FreqMultiplierForNote(channel.note, channel.octave, channel.period_increment, channel.instrument_freq, channel.vibrato_depth);
					}
					break;
				case 'D':
					BYTE slide_up = channel.effect_value >> 4;
					BYTE slide_down = channel.effect_value & 0xf;
					if (!slide_up && slide_down) {
						// Slide down.
						if (slide_down < channel.volume) {
							channel.volume -= slide_down;
						} else {
							channel.volume = 0;
						}
					}
					if (slide_up && !slide_down) {
						// Slide up.
						if (slide_up < 64 - channel.volume) {
							channel.volume += slide_up;
						} else {
							channel.volume = 64;
						}
					}
					break;
				case 'G':
					self->TonePortamento(channel);
					break;
				case 'R':
					channel.tremolo_volume = self->Tremolo(channel);
					break;
				case 'H':
					channel.vibrato_depth = 8 * self->Vibrato(channel);
					channel.freq_multiplier = FreqMultiplierForNote(channel.note, channel.octave, channel.period_increment, channel.instrument_freq, channel.vibrato_depth);
					break;
				case 'U':
					channel.vibrato_depth = 2 * self->Vibrato(channel);
					channel.freq_multiplier = FreqMultiplierForNote(channel.note, channel.octave, channel.period_increment, channel.instrument_freq, channel.vibrato_depth);
					break;
			}
			if (channel.is_playing) {
				WUFPlaySound(NULL, WUFChannelInCallback(self->mixer_channels_[i]), channel.freq_multiplier, self->PlayVolume(channel), -1);
			}
		}
	} else {
		// New pattern row.
		int next_order = -1;
		int last_read_channel_index = 0;
		// Interpret song cells.
		const S3MRow *row = self->song_->Pattern(self->song_->Order(self->order_))->Row(self->row_index_);
		bool processed_channels[64];
		for (int i = 0; i < self->NumMixerChannels(); ++i) {
			processed_channels[i] = false;
		}		
		for (S3MCellIterator it = row->begin(); it != row->end(); it++) {
			S3MCell cell = it.Cell();
			int mixer_channel_index = self->MixerChannelIndexForCellChannelIndex(cell.ChannelNumber());
			processed_channels[mixer_channel_index] = true;
			SongChannel &channel = self->song_channels_[mixer_channel_index];
			TWave *instrument = NULL;
			bool is_invalid_instrument = cell.HasInstrument() &&
				(cell.Instrument() == 0 || 
				cell.Instrument() > self->song_->NumInstruments() || 
				self->instruments_[cell.Instrument() - 1].WavePtr == NULL);
			if (cell.HasStop() || is_invalid_instrument) {
				channel.is_playing = false;
				WUFPauseSound(WUFChannelInCallback(self->mixer_channels_[mixer_channel_index]));
			} else {
				DWORD sample_offset = -1;
				if (cell.HasInstrument()) {
					channel.volume = cell.HasVolume() ? cell.Volume() : 64;
					if (!cell.HasEffect() || cell.Effect() != 'G' || channel.instrument != cell.Instrument() - 1 || channel.note == 0xff) {
						instrument = &self->instruments_[cell.Instrument() - 1];
						channel.period_increment = 0;
						sample_offset = 0;
					}
					channel.instrument = cell.Instrument() - 1;
					channel.instrument_freq = self->instruments_[channel.instrument].BaseRate;
				} else {
					if (cell.HasVolume()) {
						channel.volume = cell.Volume();
					}
					// channel.instrument = 0xff;
				}
				if (cell.HasNote()) {
					channel.is_playing = true;
					channel.last_note = channel.note;
					channel.last_octave = channel.octave;
					channel.note = cell.Note();
					channel.octave = cell.Octave();
					channel.tremolo_index = 0;
					channel.vibrato_index = 0;
					if (channel.last_note == 0xff) {
						channel.last_note = channel.note;
						channel.last_octave = channel.octave;
						channel.freq_multiplier = self->FreqMultiplierForNote(channel.note, channel.octave, 0, channel.instrument_freq, channel.vibrato_depth);
					}
				}
				if (channel.note != 0xff && channel.octave != 0xff) {
					// Update frequency multiplier if the current note and octave are valid for the channel.
					if (!cell.HasEffect() || cell.Effect() != 'G') {	// Tone Portamento adjusts the multiplier progressively to the current note.
						channel.freq_multiplier = FreqMultiplierForNote(channel.note, channel.octave, channel.period_increment, channel.instrument_freq, channel.vibrato_depth);
					}
				}
				
				if (cell.HasEffect()) {
					if (cell.EffectValue() > 0 || (channel.effect != 0xff && !EffectsShareMemory(cell.Effect(), channel.effect))) {
						// If the effect did not change and the value is 0, leave value as is. Otherwise, update.
						channel.effect_value = cell.EffectValue();
					}
					channel.effect = cell.Effect();
					if (channel.effect != 'R') {
						channel.tremolo_volume = 0;					
					}
					if (channel.effect != 'H' && channel.effect != 'U') {
						channel.vibrato_depth = 0;
					}
					switch(cell.Effect()) {
						case 'A':
							self->ticks_per_row_ = cell.EffectValue();
							break;
						case 'B':
							next_order = cell.EffectValue();
							break;
						case 'T':
							self->ticks_per_second_ = cell.EffectValue();
							WUFSetMixerCallbackPeriod(self->mixer_callback_, MixerCallbackPeriod(self->ticks_per_second_));
							break;
						case 'F':
							if (channel.effect_value >= 0xE0) {
								channel.period_increment -= (channel.effect_value >= 0xF0 ? 4 : 1) * (channel.effect_value & 0xf);
								channel.freq_multiplier = FreqMultiplierForNote(channel.note, channel.octave, channel.period_increment, channel.instrument_freq, channel.vibrato_depth);
							}
							break;
						case 'E':
							if (channel.effect_value >= 0xE0) {
								channel.period_increment += (channel.effect_value >= 0xF0 ? 4 : 1) * (channel.effect_value & 0xf);
								channel.freq_multiplier = FreqMultiplierForNote(channel.note, channel.octave, channel.period_increment, channel.instrument_freq, channel.vibrato_depth);
							}
							break;
						case 'D':
							if ((channel.effect_value & 0xf0) == 0xf0) {
								// Fine slide down.
								BYTE slide_down = channel.effect_value & 0xf;
								if (slide_down < channel.volume) {
									channel.volume -= slide_down;
								} else {
									channel.volume = 0;
								}
							}
							if ((channel.effect_value & 0xf) == 0xf) {
								// Slide up.
								BYTE slide_up = channel.effect_value >> 4;
								if (slide_up == 0) {
									if (0xf < channel.volume) {
										channel.volume -= 0xf;
									} else {
										channel.volume = 0;
									}
								} else {
									if (slide_up < 64 - channel.volume) {
										channel.volume += slide_up;
									} else {
										channel.volume = 64;
									}
								}
							}
							break;
						case 'G':
							self->TonePortamento(channel);
							break;
						case 'O':
							sample_offset = cell.EffectValue() << 8;
							if (instrument != NULL && instrument->LoopStart != -1 && instrument->LoopEnd != -1 && sample_offset >= instrument->LoopEnd) {
								// Set loop at start, if offset if beyond the loop end.
								sample_offset = instrument->LoopStart;
							}
							sample_offset <<= 8;	// Format is fixed point 24.8.
							break;
						case 'V':
							WUFSetGlobalVolume(cell.EffectValue());
							break;
						case 'S':
							switch(cell.EffectValue() >> 4) {
								case 4:
									channel.tremolo_waveform = cell.EffectValue() & 0xf;
									break;
								case 3:
									channel.vibrato_waveform = cell.EffectValue() & 0xf;
									break;
							}
							break;
						case 'H':
						case 'U':
							if (cell.EffectValue() != 0) {
								channel.vibrato_data = cell.EffectValue();
							}
							break;
					}
				} else {
					channel.effect = 0xff;
	//				channel.effect_value = 0;
					channel.tremolo_volume = 0;
					channel.vibrato_depth = 0;
				}
				if (channel.is_playing) {
					WUFPlaySound(instrument, WUFChannelInCallback(self->mixer_channels_[mixer_channel_index]), channel.freq_multiplier, self->PlayVolume(channel), sample_offset);	
				}
			}			
		}
		
		// Clear effects on all channels with empty cells.
		for (int j = 0; j < self->NumMixerChannels(); ++j) {
			if (!processed_channels[j]) {
				SongChannel &channel = self->song_channels_[j];
				channel.effect = 0xff;
			}
		}
		
		// If DOS error mode flag, we cannot call any int 21h service, e.g. printf
		if (!(IRQDOSFlags() & 0xff)) {
			// Even if InDOS flag is set, services 1 thru 0ch can be called safely; printf() uses service 2.
			printf("p:%d02n r:%d02n|", self->song_->Order(self->order_), self->row_index_);
			const S3MRow *row = self->song_->Pattern(self->song_->Order(self->order_))->Row(self->row_index_);
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
					printf(" ");
				} else {
					if (it.Cell().HasStop()) {
						printf("^^^ ");
					} else {
						printf("... ");
					}
				}
				if (it.Cell().HasInstrument()) {
					printf("%d02n ", it.Cell().Instrument());
				} else {
					printf(".. ");
				}
				if (it.Cell().HasVolume()) {
					printf("%d02n ", it.Cell().Volume());
				} else {
					printf(".. ");
				}
				if (it.Cell().HasEffect()) {
					char effect_name[2];
					effect_name[0] = it.Cell().Effect();
					effect_name[1] = '\0';
					printf(effect_name);
					printf("%d02hn", it.Cell().EffectValue());
				} else {
					printf("...");
				}
				if (channel_number < 31) {
					printf("|");
				}
			}
			for (; channel_number < self->NumMixerChannels(); ++channel_number) {
				printf("... .. .. ...");
				if (channel_number < 31) {
					printf("|");
				}
			}
			printf("\n");
		}

		self->num_ticks_ = 0;
		if (next_order >= 0) {
			self->order_ = next_order;
			self->row_index_ = 0;
		} else {
			++self->row_index_;
			if (self->row_index_ >= self->song_->Pattern(self->song_->Order(self->order_))->NumRows()) {
				self->row_index_ = 0;
				++self->order_;
				if (self->order_ >= self->song_->NumOrders() || self->song_->Order(self->order_) == 0xff) {
					self->order_ = 0;
				}
			}
		}
	}
}

S3MPlayable::SongChannel::SongChannel() {
	Reset();
}

void S3MPlayable::SongChannel::Reset() {
	note = 0xff;
	octave = 0xff;
	period_increment = 0;
	volume = 0xff;
	freq_multiplier = 1 << 24;
	effect = -1;
	effect_value = 0;
	instrument = 0xff;
	last_note = 0xff;
	last_octave = 0xff;
	is_playing = false;

	tremolo_waveform = SINE;
	tremolo_index = 0;
	tremolo_volume = 0;

	vibrato_waveform = SINE;
	vibrato_data = 0;
	vibrato_index = 0;
	vibrato_depth = 0;
}

DWORD S3MPlayable::PlayVolume(const SongChannel &channel) const {
	int volume = static_cast<int>(static_cast<DWORD>(channel.volume) << 8) + channel.tremolo_volume;
	if (volume <= 0) {
		return 0;
	}
	else if (volume >= 64 * 256) {
		return 64;
	}
	return static_cast<DWORD>(volume) >> 8;
}