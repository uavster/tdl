/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿

  Programa de ejemplo de usos de SLI's en C/C++

ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/

#include <tdl.h>
#include <tinymath.h>

#define SX  320
#define SY  200


void main(void)
{
  int Salir=0, x,y, bandera=0;
  float phi=0, phi2=1,phi3=2, u, v, l, u1, v1, l1, a=1, d=0;
  float pi=2, pi2=0,pi3=1;
  SLI *Imagen;
  SLI *Imagen2;
  SLI *Buffer;
  SLI *grid;
  int *p;

  int currimg = 0;

  if (InitSGL() != SGL_OK)
  {
    puts("Error initializing new!SGL\r\n");
    return;
  }

  if (CreateVideoSLI(SX, SY, 16) != SGL_OK)
  {
    puts("Error initializing videomode!\r\n");
    return;
  }

  Imagen=LoadGFX("amber.pcx", 8);
  Imagen2=LoadGFX("t.pcx", 8);
//  Imagen2=LoadGFX("logo.pcx", 32);

  CreateLitTableSLI(Imagen, 2, 128);
  CreateLitTableSLI(Imagen2, 2, 128);
  grid=CreateSLI(SX/8+1,SY/8+1,32*3,1);
  Buffer=CreateSLI(SX,SY, 32, 1);
//  SetBlitType(Imagen2, SLIBlitCopy);

  p=(int *)grid->SLIFramePtr;

  while (!Salir)
  {
    if(kbhit()!=0)
      switch (getch())
      {
        case 27 : Salir = -1; break;
        case 'q': bandera=1;  break;
        case 'a': bandera=2;  break;
      }
//    ClearCurrentFrame(GetVideoSLI(), 0);
    if(bandera==2)
    {
      a-=0.005;
      if ( a<0 )
      {
        a=0;
//        bandera=0;
        bandera=1;
        currimg = 1;
      }
    }
    if(bandera==1)
    {
      a+=0.005;
      if ( a>1 )
      {
        a=1;
        bandera=0;
      }

    }
    phi2=phi3;
    pi2=pi3;
    for(y=0;y<SY/8+1;y++)
    {
      phi=phi2;
      pi=pi2;
      for(x=0;x<SX/8+1;x++)
      {
          //u=sqrt((x*8-SX/2)*(x*8-SX/2)+(y*8-SY/2)*(y*8-SY/2))+10*cos(x/SX*M_PI*6+phi);
//          u=(x*8.0/SX*236.0)+10+10*cos(x*6.0/SX*M_PI+phi);
          u=(x*8.0)-30+10*cos(x*6.0/SX*M_PI+phi);
          //u1=(x*8.0/SX*256.0);
          //u1=256.0/500.0*sqrt((x*8.0-SX/2)*(x*8.0-SX/2)+(y*8.0-SY/2)*(y*8.0-SY/2));
          //v=255.0*atan2((y*8-SY/2),(x*8-SX/2))/M_PI+10*sin(y/SY*M_PI*2+phi2);
//          v=(y*8.0/SY*256.0)+10*sin(y*5.0/SY*M_PI+phi2);
          v=(y*8.0)-30+10*sin(y*5.0/SY*M_PI+phi2);
          //v1=(y*8.0/SY*256.0);
          //v1=256.0*4/M_PI*fabs(atan2((y*8.0-SY/2),(x*8.0-SX/2)));

          u1=x*8-30;
          v1=y*8-30;
          l=fabs(u-(128-40*sin(pi+pi2)))/3;
          l1=64.0;
          p[x*3+y*(SX/8+1)*3]=(int)((u1*a)+(u*(1-a)));
          p[x*3+y*(SX/8+1)*3+1]=((int)((v1+d)*a+(v+d)*(1-a)));
          p[x*3+y*(SX/8+1)*3+2]=((int)((l1*a)+(l*(1-a))));
          phi=fmod(phi+M_PI/20.0, 2*M_PI);
          pi=fmod(pi+M_PI/30.0, 2*M_PI);
      }
      phi2=fmod(phi2+M_PI/30.0, 2*M_PI);
      pi2=fmod(pi2+M_PI/(35.0+2*(sin(phi3+phi2)+1)), 2*M_PI);
    }
    phi3=fmod(phi3+M_PI/20.0, 2*M_PI);
    pi3=fmod(pi3-M_PI/(25.0+5*(cos(pi3-phi3)+1)), 2*M_PI);
      d+=1;


//    u=SX/2.0-Imagen2->SLIXSize/2.0 +SX/8.0*cos(phi3);
//    v=SY/2.0-Imagen2->SLIYSize/2.0;
    if (currimg == 0)
      Draw8x8Grid32Lit(Buffer, grid, Imagen);
    else
      Draw8x8Grid32Lit(Buffer, grid, Imagen2);
//    SetPos(Imagen2,(int)u ,(int)v );
    Blit(GetVideoSLI(), Buffer);

    ShowPage();
  }

  DestroyVideoSLI(3);
  UnInitSGL();
}
