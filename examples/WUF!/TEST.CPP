#include "tdl.h"

const TWave *LoadWaveOrDie(const char *file_name) {
	int error_code;
	const TWave *wave = WUFLoadWave(file_name, &error_code);
	if (wave == NULL) {
		printf("\n");
		printf("Error loading "); printf(file_name); printf("\n");
		printf("Error code: 0x%dhn", error_code); printf("\n");
		printf("\n");
		exit(1);
	}
	return wave;
}

int main() {
	WUFInit();

	SoundProperties play_props;
	WUFGetProperties(&play_props, NULL);
	printf("\n");
	printf("Sampling rate: %dn", play_props.SPSamplingRate); printf(" Hz\n");
	printf("Bits per sample: %dn", play_props.SPBitsPerSample); printf("\n");
	printf("Number of channels: %dn", play_props.SPNumChannels); printf("\n");

	const TWave *wave_8bit_mono = LoadWaveOrDie("w8m22k.wav");
	const TWave *wave_8bit_stereo = LoadWaveOrDie("w8s8k.wav");
	const TWave *wave_16bit_mono = LoadWaveOrDie("w16m8k.wav");
	const TWave *wave_16bit_stereo = LoadWaveOrDie("w16s44k.wav");
	
	bool do_loop = true;
	while(do_loop) {
		if (kbhit()) {
			switch(getch()) {
				case 27: do_loop = false; break;
				case '1': printf("1\n"); WUFPlaySound(wave_8bit_mono); break;
				case '2': printf("2\n"); WUFPlaySound(wave_8bit_stereo); break;
				case '3': printf("3\n"); WUFPlaySound(wave_16bit_mono); break;
				case '4': printf("4\n"); WUFPlaySound(wave_16bit_stereo); break;
			}
		}
	//	for (int i = 0; i < 100000; i++) {}
	}

	WUFClose();

	return 0;
}