/*
зддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©

  Programa de ejemplo de usos de SLI's en C/C++

юддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды
*/

#include <tdl.h>
#include <tinymath.h>

#define SX  640
#define SY  480

void changedir(float *x, int minx, int maxx, int *dir)
{
    if(*x>maxx)
    {
       *x=maxx;
       *dir=0;
    }
    if(*x<minx)
    {
       *x=minx;
       *dir=!0;
    }
}

void main(void)
{
  int Salir=0, bandera=!0;
  SLI *Textura;
  SLI *Textura2;
  SLI *Imagen;
  RENDERPOLY p;
  RENDERPOLY k;
  RENDERPOLY k1;
  RENDERPOINT p1, p2 ,p3, p4, p5;
  int dir1=!0, dir2=0;
  int dir3=0, dir4=!0;
  int dir5=!0, dir6=!0;

  p.P1=&p1;
  p.P2=&p2;
  p.P3=&p3;
  p.N=4;
  p.Type=4;

  k.P1=&p1;
  k.P2=&p2;
  k.P3=&p5;
  k.N=3;
  k.Type=3;

  k1.P1=&p1;
  k1.P2=&p3;
  k1.P3=&p4;
  k1.N=3;
  k1.Type=3;


  p4.X=0;
  p4.Y=SY-1;
  p4.k[0]=10;
  p4.k[1]=55.0;
  p4.k[2]=123.0;
  p4.k[3]=0.0;

  p5.X=SX-1;
  p5.Y=0;
  p5.k[0]=20;
  p5.k[1]=255.0;
  p5.k[2]=255.0;
  p5.k[3]=25.0;

  p1.X=40;
  p1.Y=50;
  p1.k[0]=2;
  p1.k[1]=255.0;
  p1.k[2]=0.0;
  p1.k[3]=128.0;
  p1.k[4]=0.0;

  p2.X=SX-71;
  p2.Y=70;
  p2.k[0]=2;
  p2.k[1]=0.0;
  p2.k[2]=255.0;
  p2.k[3]=64.0;
  p2.k[4]=255.0;

  p3.X=20;
  p3.Y=SY-71;
  p3.k[0]=50;
  p3.k[1]=0.0;
  p3.k[2]=0.0;
  p3.k[3]=192.0;
  p3.k[4]=255.0;


  Textura=LoadGFX("ca.pcx", 8);
  if (Textura==NULL)
  {
    puts("Error loading ca.pcx\n\r");
    return;
  }


  Textura2=LoadGFX("tr.pcx", 8);
  if (Textura2==NULL)
  {
    puts("Error loading tr.pcx\n\r");
    return;
  }

  p.Texture1=Textura;
  p.Texture2=Textura2;


  Imagen=CreateSLI(SX,SY,32, 1);
  if (Imagen==NULL)
  {
    puts("Error creating SLI\n\r");
    return;
  }

  if (CreateVideoSLI(SX, SY, 16) != SGL_OK)
  {
    puts("Error initializing videomode!\r\n");
    return;
  }

  k.Texture1=Textura;
  k1.Texture1=Textura;
  CreateLitTableSLI(Textura, 2, 129);

  SLI2SBuffer(Imagen);
  InitSBufferSLI(Imagen);
  SetClip(Imagen, 100, 0, SX-100, SY-1);
  while (!Salir)
  {
    InitSBufferSLI(Imagen);
    ClearCurrentFrame(Imagen, 0x505050);

    //for(i=0; i<500; i++)
    {
    //p1.k[3]=(float)((int)((int)p1.X)&127u);
    //p2.k[3]=(float)((int)((int)p2.Y)&127u);
    //p3.k[3]=127.0*sqrt(p3.X*p3.X+p3.Y*p3.Y)/sqrt((SX*SX+SY*SY));
    //p2.k[3]=127.0*sqrt(p2.X*p2.X+p2.Y*p2.Y)/sqrt((SX*SX+SY*SY));
    //p1.k[3]=127.0*sqrt(p1.X*p1.X+p1.Y*p1.Y)/sqrt((SX*SX+SY*SY));
    //p.Texture1=(SLI *)((int)(p1.X+p1.Y-p2.X*256*256+p2.Y*256-p3.X-p3.Y*256));


    GenericTriangleMapper(Imagen,&p);
//    GenericTriangleMapper(GetVideoSLI(),&k);
//    GenericTriangleMapper(GetVideoSLI(),&k1);

    if(dir1) p1.X+=3.8768532*cos(p2.Y/800.0*M_PI); else p1.X-=4.8768532*sin(p3.Y/800.0*M_PI);
    changedir(&p1.X, 1, SX-1, &dir1);
    if(dir2) p1.Y+=4.4567452*sin(p3.X/800.0*M_PI); else p1.Y-=3.4567452*cos(p2.X/800.0*M_PI);
    changedir(&p1.Y, 1, SY-1, &dir2);

    if(dir3) p2.X+=3.7654762*cos(p3.Y/800.0*M_PI); else p2.X-=2.7654762*sin(p1.Y/800.0*M_PI);
    changedir(&p2.X, 1, SX-1, &dir3);
    if(dir4) p2.Y+=2.5463542*sin(p1.X/800.0*M_PI); else p2.Y-=4.5463542*cos(p3.X/800.0*M_PI);
    changedir(&p2.Y, 1, SY-1, &dir4);

    if(dir5) p3.X+=3.3545252; else p3.X-=3.3545252;
    changedir(&p3.X, 1, SX-1, &dir5);
    if(dir6) p3.Y+=4.1231232; else p3.Y-=2.1231232;
    changedir(&p3.Y, 1, SY-1, &dir6);
    }
    RenderSBufferSLI(Imagen);
    Blit(GetVideoSLI(),Imagen);
    ShowPage();
    if(bandera)
    {
      p1.k[3]=p1.X*256.0/SX;
      p1.k[4]=p1.Y*256.0/SY;
      p2.k[3]=p2.X*256.0/SX;
      p2.k[4]=p2.Y*256.0/SY;
      p3.k[3]=p3.X*256.0/SX;
      p3.k[4]=p3.Y*256.0/SY;
    }

    if(kbhit()!=0)
      switch (getch())
      {
        case 27 : Salir = -1; break;
        case 'x' : bandera =!bandera; break;
        case ' ': dir1=!dir1;
                  dir2=!dir2;
                  dir3=!dir3;
                  dir4=!dir4;
                  dir5=!dir5;
                  dir6=!dir6;
                  break;
        case 'c':
                  switch(p.Type)
                  {
                      case 1:
                            p.Type=2;
                            p.N=2;
                            break;
                      case 2:
                            p.Type=3;
                            p.N=3;
                            break;
                      case 3:
                            p.Type=4;
                            p.N=4;
                            break;
                      case 4:
                            p.Type=12;
                            p.N=3;
                            break;
                      case 12:
                            p.Type=1;
                            p.N=0;
                            break;
                  }
                  break;
        default : getch();break;
      }
  }
  DestroyVideoSLI(3);
}
