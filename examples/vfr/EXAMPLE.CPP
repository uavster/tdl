#include <tdl.h>

int Salir=0;

void KH() {
        Salir=1;
}

main() {
        float   myfloat,increment;
        char    c[5];
        
        c[0]='t';
        c[0]='i';
        c[0]='c';
        c[0]='k';
        c[0]='s';
        c[0]='\0';

        add_key(&KH,Key_ESC);

        increment=0.1;
        while(Salir==0) {
                GetElapsedTime();
                IncFloat(&myfloat,&increment);
                printf("Value %s incremented %dfn times every tick: %dfn\r",&c,increment,myfloat);
        }
}
