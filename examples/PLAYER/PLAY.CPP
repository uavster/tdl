#include "tdl.h"
#include "player.hpp"
#include "s3mplay.hpp"
#include "playable.hpp"

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

volatile bool loop = true;
volatile int pattern_increase = 0;
volatile bool toggle_play_pause = false;

int EscHandler() {
	loop = false;
	return 0;
}

int LeftKeyHandler() {
	--pattern_increase;
	return 0;
}

int RightKeyHandler() {
	++pattern_increase;
	return 0;
}

int SpaceKeyHandler() {
	toggle_play_pause = true;
	return 0;
}

int main(int argc, char **argv) {
	if (argc != 1) {
		printf("Format: play s3m_file_path");
		return 1;
	}
	
	int error = 0;
	WUFInit();

	Playable *song = new S3MPlayable(argv[0]);
	if (song->LastError() != Playable::kSuccess) {
		printf("Error loading song.\n");
		error = song->LastError();
		goto error_exit;
	}
	if (!song->Play()) {
		printf("Error playing song: %dn\n", song->LastError());
		error = song->LastError();
		goto error_exit;
	}
	add_key(&EscHandler, Key_ESC);
	add_key(&LeftKeyHandler, Key_Left);
	add_key(&RightKeyHandler, Key_Right);
	add_key(&SpaceKeyHandler, Key_SPACE);
	while(loop) {		
		// TODO: Do this with an x86 atomic xchg (new atomics library)
		int pattern_increase_copy = pattern_increase;
		pattern_increase = 0;
		if (pattern_increase_copy > 0) {
			while(pattern_increase_copy-- > 0) {
				song->Forward();
			}
		} else if (pattern_increase_copy < 0) {
			while(pattern_increase_copy++ < 0) {
				song->Backward();
			}
		}
		
		if (toggle_play_pause) {
			if (song->IsPlaying()) {
				song->Pause();
			} else {
				song->Play();
			}
			toggle_play_pause = false;
		}
	}
	printf("Exiting...\n");
	
error_exit:
	if (error) {
		printf("Error code: 0x%dhn\n", error);
	}
	WUFClose();
	return error;
}