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

void PlaySound(const TWave *sound) {
	TChannel *channel = WUFAllocateChannel(kWUFChannelAutoFree);
	if (channel == NULL) {
		printf("Unable to allocate channel.\n");
		return;
	}
	WUFPlaySound(sound, channel, 1 << 24, 64, 0);
}

bool loop = true;

int EscHandler() {
	loop = false;
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
	while(loop) {}
	printf("Exiting...\n");
	
error_exit:
	if (error) {
		printf("Error code: 0x%dhn\n", error);
	}
	WUFClose();
	return error;
}