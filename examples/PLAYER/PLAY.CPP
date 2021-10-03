#include "tdl.h"
#include "player.hpp"
#include "s3mplay.hpp"
#include "playable.hpp"

int main() {
	WUFInit();
	
	// Playable *song = Player::Load("a.s3m");
	S3MPlayable *song = new S3MPlayable("a.s3m");
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
	// while(!kbhit()) {}
	printf("Exiting...\n");
	
	WUFClose();
	return 0;
}