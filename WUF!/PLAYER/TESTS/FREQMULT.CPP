#include <tdl.h>
#include <tinymath.h>

// Notes: C, C#, D, D#, E, F, F#, G, G#, A, A#, B
const DWORD period_by_note[] = { 1712, 1616, 1524, 1440, 1356, 1280, 1208, 1140, 1076, 1016, 960, 907 };

DWORD FreqMultiplierForNote_fixedpoint(BYTE note, BYTE octave) {
	return ((14317056u << 8) / ((8363u * 16u * period_by_note[note]) >> (octave - 1))) << 16;
}

DWORD FreqMultiplierForNote_double(BYTE note, BYTE octave) {
	double freq_mult_double = 14317056.0 / (double)((8363u * 16u * period_by_note[note]) >> (octave - 1));
	return (DWORD)(freq_mult_double * (1 << 24));
}

int main() {
	int octave, note;
	DWORD fm_double, fm_fixed;
	int avg_error = 0;
	int num_sums = 0;
	int worst_error = 0;
	int error;
	const int test_freqs[] = { 8363, 11025, 22050, 44100 };
	int freq_index;
	
	for (octave = 1; octave <= 9; ++octave) {
		for (note = 0; note < sizeof(period_by_note) / sizeof(DWORD); ++note) {
			fm_double = FreqMultiplierForNote_double(note, octave);
			fm_fixed = FreqMultiplierForNote_fixedpoint(note, octave);
			error = fm_double - fm_fixed;
			printf("Note:%dn octave:%dn -> expected:%dn actual:%dn error:%dn\n", note, octave, fm_double, fm_fixed, error);
			avg_error += error;
			if (fabs(error) > worst_error) {
				worst_error = fabs(error);
			}
			++num_sums;
		}
	}
	printf("[Rel. freq.] Avg. error:%dfn ; worst |error|:%dfn\n", (avg_error / (double)num_sums) / (1 << 24), (double)worst_error / (1 << 24));
	for (freq_index = 0; freq_index < sizeof(test_freqs) / sizeof(int); ++freq_index) {
		printf("[@%dn Hz] Avg. error:%dfn ; worst |error|:%dfn\n", test_freqs[freq_index], test_freqs[freq_index] * ((avg_error / (double)num_sums) / (1 << 24)), test_freqs[freq_index] * ((double)worst_error / (1 << 24)));
	}
	
	return 0;
}