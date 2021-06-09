#include "tdl.h"
#include "s3m.hpp"
#include "except.hpp"

int main() {
	WUFInit();

	SoundProperties play_props;
	WUFGetProperties(&play_props, NULL);

	printf("\n");
	printf("Sampling rate: %dn", play_props.SPSamplingRate); printf(" Hz\n");
	printf("Bits per sample: %dn", play_props.SPBitsPerSample); printf("\n");
	printf("Number of channels: %dn", play_props.SPNumChannels); printf("\n");

	try {
		printf("A\n");
		S3MSong song("b.s3m");
		printf("B\n");
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
	} catch(const Exception &e) {
		printf("C\n");
//		printf(e.Description());
//		printf("\n");
	}
	printf("D\n");
	
	WUFClose();

	return 0;
}