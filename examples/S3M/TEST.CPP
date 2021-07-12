#include "tdl.h"
#include "s3m.hpp"
#include "except.hpp"

#define kMaxRowsPerPage		23

int main() {
	S3MSong song("a.s3m");
	if (!song.IsLoaded()) {
		printf("Unable to load song.\n");
		return 1;
	}
	
	printf("\n");
	printf("Song name: ");
	printf(song.Name());
	printf("\n");
	printf("Num. instruments: %dn\n", song.NumInstruments());
	printf("Num. patterns: %dn\n", song.NumPatterns());
	printf("Orders:");
	for (int i = 0; i < song.NumOrders(); ++i) {
		printf(" %dn", song.Order(i));
	}
	printf("\n");
	printf("Created with ");
	printf(song.TrackerName());
	printf(" %dn.%dhn\n", song.TrackerVersion().parts.major, song.TrackerVersion().parts.minor);
	
	printf("Samples format: ");
	if (song.AreSamplesSigned()) {
		printf("signed");
	} else {
		printf("unsigned");
	}
	printf("\n");
	
	printf("Global volume: %dn\n", song.GlobalVolume());
	printf("Master volume: %dn\n", song.MasterVolume());
	printf("Initial speed: %dn\n", song.InitialSpeed());
	printf("Initial tempo: %dn\n", song.InitialTempo());
	printf("Stereo: ");
	printf(song.IsStereo() ? "yes" : "no");
	printf("\n");
	printf("Custom pan: ");
	printf(song.HasCustomPan() ? "yes" : "no");
	printf("\n");
	printf("Volume optimization: ");
	printf(song.HasVolumeOptimization() ? "yes" : "no");
	printf("\n");
	printf("Amiga limits: ");
	printf(song.HasAmigaLimits() ? "yes" : "no");
	printf("\n");
	printf("Channels: ");
	for (i = 0; i < kS3MMaxChannels; ++i) {
		printf("%dn:", i + 1);
		if (song.Channel(i) == NULL) {
			continue;
		}
		if (!song.Channel(i)->IsEnabled()) {
			printf("OFF");
		} else {
			printf("%dn", song.Channel(i)->Pan()); 
		}
		printf(" ");
	}
	printf("\n");
	printf("\nPress ENTER to see instruments, or ESC to leave.\n", i);
	int k = 0;
	while(k != 13 && k != 27) {
		k = getch();
	}
	if (k == 27) {
		return 0;
	}
	printf("\n");
	
	for (i = 0; i < song.NumInstruments(); ++i) {
		if (song.Instrument(i) == NULL) {
			printf("Error retrieving instrument %dn\n", i);
			return 2;
		}
		const S3MInstrument &instrument = *song.Instrument(i);
		printf("Instrument %dn: ", i);
		printf(instrument.Name());
		printf("\n");
		switch(instrument.Type()) {
			case Sampled:
				printf("Sampled"); break;
			case AdlibMelody:
				printf("Adlib melody"); break;
			case AdlibDrum:
				printf("Adlib drum"); break;
			case TypeUnknown:
				printf("Unknown"); break;
		}
		printf(" vol:%dn", instrument.DefaultVolume());
		if (instrument.HasLoop()) {
			printf(" loop:%dn,%dn", instrument.LoopStart(), instrument.LoopEnd());
		}
		if (instrument.IsStereo()) {
			printf(" stereo");
		} else {
			printf(" mono");
		}
		if (instrument.Is16Bit()) {
			printf(" 16bit");
		} else {
			printf(" 8bit");
		}
		printf(" pack:%dn", instrument.Packing());
		printf(" C2freq:%dn", instrument.C2Frequency());
		printf(" Num.samples:%dn", instrument.NumSamples());
		printf("\n");
	}
	printf("\n");
	
	k = 13;
	i = 0;
	while(true) {
		if (k == 13) {
			printf("Press ENTER to see pattern %dn, or ESC to leave.\n", i);
		}
		k = getch();
		if (k == 27) {
			break;
		}
		if (k == 13) {
			int kk = -1;
			for (int row_index = 0; row_index < song.Pattern(i)->NumRows(); ++row_index) {
				if (row_index > 0 && (row_index % kMaxRowsPerPage == 0)) {
					printf("Press ENTER to continue showing pattern %dn, or ESC to leave.\n", i);
					kk = -1;
					while(kk != 27 && kk != 13) {
						kk = getch();
					}
					if (kk == 27) {
						i = song.NumPatterns(); 
						break;
					}
				}
				int channel_number = 0;
				const S3MRow *row = song.Pattern(i)->Row(row_index);
				printf("%dn: ", row_index);
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
					if (it.Cell().HasNoteAndInstrument()) {
						char note_name[4];
						it.Cell().GetNoteName(note_name);
						printf(note_name);
						printf(" %dn ", it.Cell().Instrument());
					} else {
						printf("... .. ");
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
			++i;
			if (i >= song.NumPatterns()) {
				if (kk != 27) {
					printf("Press any key to leave.\n");
					getch();
				}
				break;
			}
		}
	}
	
	return 0;
}