/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿

  Programa de ejemplo de usos de SLI's en C/C++

ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/

#include <tdl.h>
#include <tinymath.h>
#include <render.h>
#include <uniload.h>

#define SX  640
#define SY  480

  RENDERWORLD *world;

void main(void)
{
  int Salir=0;
  SLI *buffer;




  if (CreateVideoSLI(SX, SY, 16) != SGL_OK)
  {
    puts("Error initializing videomode!\r\n");
    return;
  }

  buffer=CreateSLI(SX,SY, 32, 1);
  world=LoadUniverse("prueba.3ds");
  if (world==0)
  {
    puts("Error loading 3D universe");
    return;
  }
  
  while (Salir!=-1)
  {
    if(kbhit()) {
      switch (getch())
      {
        case 27 : Salir = -1; break;
      }
    }
    ClearCurrentFrame(buffer, 0);
    RenderUniverse(world, buffer);
    Blit(GetVideoSLI(), buffer);
    ShowPage();
  }
}
