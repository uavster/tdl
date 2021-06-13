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
	printf("Num. patterns: %dn\n", song.NumPatterns());
	
	printf("Orders:");
	for (int i = 0; i < song.NumOrders(); ++i) {
		printf(" %dn", song.Order(i));
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
	
	return 0;
}