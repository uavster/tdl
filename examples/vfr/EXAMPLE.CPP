#include "tdl.h"

volatile int do_loop = 1;

int key_handler() {
	do_loop = 0;
	return 0;	// Do not chain with default ISR.
}

int main() {
	float myfloat, increment;
	double increment_double, mydouble;
	
	add_key(&key_handler, Key_ESC);

	increment = 1.0 / 30.0;
	myfloat = 0.0f;
	while(do_loop) {
		IncFloat(&myfloat, &increment);
		mydouble = myfloat;
		increment_double = increment;
		printf("Incrementing %dfn", increment_double);
		printf(" times every tick: %dfn", mydouble);
		printf("       \r");
		GetElapsedTime();
	}
	return 0;
}
