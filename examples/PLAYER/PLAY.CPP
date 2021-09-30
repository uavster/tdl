#include "tdl.h"
#include "player.hpp"

int main() {
	const Playable *song = Player::Load("a.s3m");
	if (song == NULL) {
		printf("Error loading song.\n");
		return 1;
	}
	getch();
	return 0;
}