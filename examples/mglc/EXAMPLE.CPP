/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿

  Programa de ejemplo de usos de SLI's en C/C++

ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/

#include <tdl.h>
#include <tinymath.h>

#define SX 640
#define SY 480

int modelist[]={ SX, SY, 32,
                 SX, SY, 24,
                 SX, SY, 16,
                 320, 400, 32,
                 320, 400, 24,
                 320, 400, 16,
                 0};

void main(void)
{
  int Salir=0;
  float phi=0;
  MGLC *video1,*video2,*video3;
  SLI *Imagen;

/*
  if (InitSGL() != SGL_OK)
  {
    puts("Error initializing new!SGL\r\n");
    return;
  }
*/
  if (InitGraph(modelist) != SGL_OK)
  {
    puts("Error initializing videomode!\r\n");
    return;
  }

  video2=MGLCLoad("video2.mgl");
  video1=MGLCLoad("video.mgl");
  video3=MGLCLoad("video3.mgl");
  MGLCPlay(video1);
  MGLCPlay(video2);
  MGLCPlay(video3);

  while (!Salir)
  {
    if(kbhit()!=0)
      switch (getch())
      {
        case 27 : Salir = -1; break;
        case 'z': if(MGLCStatus(video1)==2)  MGLCPlay(video1); break;
        case 'x': if(MGLCStatus(video2)==2)  MGLCPlay(video2); break;
        case 'c': if(MGLCStatus(video3)==2)  MGLCPlay(video3); break;

      }
    ClearCurrentFrame(OS,0);
    Imagen=MGLCFrame(video2);
    SetPos(Imagen, SX/2-96+SX/4.0*cos(phi), SY/2-72+SY/4.0*sin(phi));
    Blit(OS, Imagen);

    Imagen=MGLCFrame(video3);
    SetPos(Imagen, SX/2-96-SX/2.0*cos(phi),145);
    Blit(OS, Imagen);

    phi=fmod(phi+M_PI/50, 2.0*M_PI);

    Imagen=MGLCFrame(video1);
    SetPos(Imagen, SX/2-96+SX/2.0*cos(phi),0);
    Blit(OS, Imagen);

     if(MGLCStatus(video1)==2)  MGLCPlay(video1);
     if(MGLCStatus(video2)==2)  MGLCPlay(video2);
     if(MGLCStatus(video3)==2)  MGLCPlay(video3);

    ShowFrame();
    //ShowVideoSLI();
  }

  DestroyVideoSLI(3);
//  UnInitSGL();
}
