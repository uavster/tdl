#include "tdl.h"
#include "s3m.hpp"
#include "except.hpp"

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
		
			++i;
			if (i >= song.NumPatterns()) {
				break;
			}
		}
	}
	
	return 0;
}