#include "tdl.h"
#include "s3m.hpp"
#include "except.hpp"

int main() {
	WUFInit();
/*
	SoundProperties play_props;
	WUFGetProperties(&play_props, NULL);

	printf("\n");
	printf("Sampling rate: %dn", play_props.SPSamplingRate); printf(" Hz\n");
	printf("Bits per sample: %dn", play_props.SPBitsPerSample); printf("\n");
	printf("Number of channels: %dn", play_props.SPNumChannels); printf("\n");
*/
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
	printf("Num. instruments: %dn\n", song.NumInstruments());
	printf("Num. orders: %dn\n", song.NumOrders());
	printf("\n");
	
	for (int i = 0; i < song.NumInstruments(); ++i) {
		printf("Instrument %dn: ", i);
		printf(song.Instrument(i)->Name());
		printf(" [");
		switch(song.Instrument(i)->Type()) {
			case Sampled:
				printf("Sampled"); break;
			case AdlibMelody:
				printf("Adlib melody"); break;
			case AdlibDrum:
				printf("Adlib drum"); break;
			case TypeUnknown:
				printf("Unknown"); break;
		}
		printf("]\n");
	}
	printf("\n");
	
/*	try {
		S3MSong song("b.s3m");
	} catch(const Exception &e) {
		printf(e.Description());
	}
*/

/*
	bool do_loop = true;
	while(do_loop) {
		if (kbhit()) {
			switch(getch()) {
				case 27: do_loop = false; break;
			}
		}
	}
*/
	
	WUFClose();

	return 0;
}