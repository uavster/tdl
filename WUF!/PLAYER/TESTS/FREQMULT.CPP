#include <tdl.h>
#include <tinymath.h>

// Notes: C, C#, D, D#, E, F, F#, G, G#, A, A#, B
const DWORD period_by_note[] = { 1712, 1616, 1524, 1440, 1356, 1280, 1208, 1140, 1076, 1016, 960, 907 };

DWORD FreqMultiplierForNote_fixedpoint(BYTE note, BYTE octave) {
	return ((14317456u << 8) / ((8363u * 16u * period_by_note[note]) >> (octave - 1))) << 16;
}

DWORD FreqMultiplierForNote_fixedpoint_new(BYTE note, BYTE octave) {
	return ((894841u << 12) / ((8363u * period_by_note[note]) >> (octave - 1))) << 12;
}

DWORD FreqMultiplierForNote_double(BYTE note, BYTE octave) {
	double freq_mult_double = 14317456.0 / (double)((8363u * 16u * period_by_note[note]) >> (octave - 1));
	return (DWORD)(freq_mult_double * (1 << 24));
}

int main() {
	int octave, note;
	DWORD fm_double, fm_fixed, fm_fixed_new;
	int avg_error = 0, avg_error_new = 0;
	int num_sums = 0;
	int worst_error = 0, worst_error_new = 0;
	int worst_note, worst_octave, worst_note_new, worst_octave_new;
	int error, error_new;
	
	for (octave = 1; octave <= 9; ++octave) {
		for (note = 0; note < sizeof(period_by_note) / sizeof(DWORD); ++note) {
			fm_double = FreqMultiplierForNote_double(note, octave);
			fm_fixed = FreqMultiplierForNote_fixedpoint(note, octave);
			fm_fixed_new = FreqMultiplierForNote_fixedpoint_new(note, octave);
			error = fm_double - fm_fixed;
			error_new = fm_double - fm_fixed_new;
			printf("Note:%dn octave:%dn -> expected:%dn actual:%dn error:%dn new:%dn err_new:%dn\n", note, octave, fm_double, fm_fixed, error, fm_fixed_new, error_new);
			avg_error += error;
			if (fabs(error) > worst_error) {
				worst_error = fabs(error);
				worst_note = note;
				worst_octave = octave;
			}
			avg_error_new += error_new;
			if (fabs(error_new) > worst_error_new) {
				worst_error_new = fabs(error_new);
				worst_note_new = note;
				worst_octave_new = octave;
			}
			++num_sums;
		}
	}
	printf("[Rel.freq.] Avg.error:%dfn; worst |error|:%dfn (note:%dn, oct:%dn); avg.err_new:%dfn; worst |err_new|:%dfn (note:%dn, oct:%dn)\n", (avg_error / (double)num_sums) / (1 << 24), (double)worst_error / (1 << 24), worst_note, worst_octave, (avg_error_new / (double)num_sums) / (1 << 24), (double)worst_error_new / (1 << 24), worst_note_new, worst_octave_new);

	return 0;
}