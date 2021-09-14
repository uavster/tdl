#include "tdl.h"

TWave *LoadWaveOrDie(const char *file_name) {
	DWORD error_code;
	TWave *wave = WUFLoadWave(file_name, &error_code);
	if (wave == NULL) {
		printf("\n");
		printf("Error loading "); printf(file_name); printf("\n");
		printf("Error code: 0x%dhn", error_code); printf("\n");
		printf("\n");
		exit(1);
	}
	return wave;
}

void PlaySound(const TWave *sound) {
	WUFPlaySound(sound, kAnyChannelStartingAt|0, 1 << 24, 64, 0, NULL);
}

void MixerCallback(int num_channels, TChannel *channels) {
	const static char symbols[][3] = {"|\r", "/\r", "-\r", "\\\r"};
	static int symbol_index = 0;
	printf(symbols[symbol_index]);
	symbol_index = (symbol_index + 1) % (sizeof(symbols) / 3);
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
	
	WUFSetMixerCallback(0.25, &MixerCallback);
	
	bool do_loop = true;
	while(do_loop) {
		if (kbhit()) {
			switch(getch()) {
				case 27: do_loop = false; break;
				case '1': PlaySound(wave_8bit_mono); break;
				case '2': PlaySound(wave_8bit_stereo); break;
				case '3': PlaySound(wave_16bit_mono); break;
				case '4': PlaySound(wave_16bit_stereo); break;
			}
		}
	//	for (int i = 0; i < 100000; i++) {}
	}

	WUFClose();

	return 0;
}