#include "tdl.h"

// Setting this to non-zero polls the default key buffers in real mode.
// It works on DOSBox as the overhead of switching between real and protected modes is low.
// However, it halts in PCem with actual DOS, probably because the overhead of mode switching
// is much higher.
// Setting this to zero, installs protected mode keyboard handlers. It works on both DOSBox and PCem, 
// as everything happens in protected mode.
#define HANDLE_KEYS_POLLING_DOS	0

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
	TChannel *channel = WUFAllocateChannel(kWUFChannelAutoFree);
	if (channel == NULL) {
		printf("Unable to allocate channel.\n");
		return;
	}
	WUFPlaySound(sound, channel, 1 << 24, 64, 0);
}

void MixerCallback(HMixerCallback callback_handler, void *user_pointer) {
	const static char symbols[][3] = {"|\r", "/\r", "-\r", "\\\r"};
	static int symbol_index = 0;
	if (!(IRQDOSFlags() & 0xff)) {
		printf(symbols[symbol_index]);
		symbol_index = (symbol_index + 1) % (sizeof(symbols) / 3);
	}
}

volatile bool do_loop = true;
TWave *wave_8bit_mono, *wave_8bit_stereo, *wave_16bit_mono, *wave_16bit_stereo;

#if !(HANDLE_KEYS_POLLING_DOS)
int KeyESCHandler() {
	do_loop = false;
	return 0;
}

int Key1Handler() {
	PlaySound(wave_8bit_mono);
	return 0;
}

int Key2Handler() {
	PlaySound(wave_8bit_stereo);
	return 0;
}

int Key3Handler() {
	PlaySound(wave_16bit_mono);
	return 0;
}

int Key4Handler() {
	PlaySound(wave_16bit_stereo);
	return 0;
}
#endif

int main() {	
	WUFInit();

	SoundProperties play_props;
	WUFGetProperties(&play_props, NULL);
	printf("\n");
	printf("Sampling rate: %dn", play_props.SPSamplingRate); printf(" Hz\n");
	printf("Bits per sample: %dn", play_props.SPBitsPerSample); printf("\n");
	printf("Number of channels: %dn", play_props.SPNumChannels); printf("\n");

	wave_8bit_mono = LoadWaveOrDie("w8m22k.wav");
	wave_8bit_stereo = LoadWaveOrDie("w8s8k.wav");
	wave_16bit_mono = LoadWaveOrDie("w16m8k.wav");
	wave_16bit_stereo = LoadWaveOrDie("w16s44k.wav");
	
	WUFAddMixerCallback(static_cast<DWORD>(0.25 * 65536), &MixerCallback, NULL);

#if !(HANDLE_KEYS_POLLING_DOS)	
	add_key(&Key1Handler, Key_1);
	add_key(&Key2Handler, Key_2);
	add_key(&Key3Handler, Key_3);
	add_key(&Key4Handler, Key_4);
	add_key(&KeyESCHandler, Key_ESC);
#endif

	while(do_loop) {
#if (HANDLE_KEYS_POLLING_DOS)
		if (kbhit()) {
			switch(getch()) {
				case 27: do_loop = false; break;
				case '1': PlaySound(wave_8bit_mono); break;
				case '2': PlaySound(wave_8bit_stereo); break;
				case '3': PlaySound(wave_16bit_mono); break;
				case '4': PlaySound(wave_16bit_stereo); break;
			}
		}
#endif
	}
	WUFClose();

	return 0;
}