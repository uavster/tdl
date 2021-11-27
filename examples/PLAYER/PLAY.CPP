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


int main() {
	WUFInit();

	Playable *song = new S3MPlayable("test.s3m");
	if (song->LastError() != Playable::kSuccess) {
		printf("Error loading song.\n");
		return song->LastError();
	}
	if (!song->Play()) {
		printf("Error playing song: %dn", song->LastError());
		printf("\n");
		return song->LastError();
	}
	getch();
	printf("Exiting...\n");
	
	WUFClose();
	return 0;
}