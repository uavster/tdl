#ifndef __PLAYER_INCLUDED__
#define __PLAYER_INCLUDED__

#include "playable.hpp"
#include "list.hpp"

/*
Objects of this class can manage the current playables.
Playables are owned statically by the class, so Player
objects can be created and destroyed without affecting
the audio output.
*/
class Player {
public:
	Player();
	~Player();
	static Playable *Load(const char *file);
	static void Unload(Playable *playable);

private:
	static PointerList<Playable> playables;
};

#endif