#include <tdl.h>

volatile int Salir=0;

int KH() {
        Salir=1;
		return 0;	// Do not chain with default ISR.
}

main() {
        float myfloat,increment;
		double increment_double,mydouble;
		
        add_key(&KH,Key_ESC);

        increment=1.0/30.0;
		myfloat=0.0f;
        while(Salir==0) {
                IncFloat(&myfloat,&increment);
				mydouble=myfloat;
				increment_double=increment;
                printf("Incrementing %dfn", increment_double);
				printf(" times every tick: %dfn", mydouble);
				printf("\r");
                GetElapsedTime();
        }
}
