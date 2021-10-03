#include "player.hpp"
#include "s3mplay.hpp"
#include "stdio.h"

PointerList<Playable> Player::playables;

Player::Player() {
}

Player::~Player() {
	playables.Restart();
	Playable *playable = playables.Next();
	while(playable != NULL) {
		Playable *playable_back = playable;
		// Seek to next element before erasing to avoid undefined behavior.
		playable = playables.Next();
		playables.Erase(playable_back);
	}
}

Playable *Player::Load(const char *file) {
	S3MPlayable *s3m = new S3MPlayable(file);
	if (s3m->LastError() == Playable::kSuccess) {
		playables.Insert(s3m);
		return s3m;
	}
	delete s3m;
	return NULL;
}

void Player::Unload(Playable *playable) {
	playables.Erase(playable);
	delete playable;
}