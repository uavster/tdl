/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿

  Programa de ejemplo de usos de SLI's en C/C++

ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/

#include <tdl.h>
#include <tinymath.h>

#define SX  320
#define SY  400


void main(void)
{
  int Salir=0, x,y, bandera=0, luz=0;
  float phi=0, phi2=1,phi3=2, u, v, l, u1, v1, l1, a=1, d=0, d1, d2, d3, a1, a2, a3;
  float pi=2, pi2=0,pi3=1, z, zo=1, rot=0, tmp, p1x=SX/6, p2x=SX-SX/6, p3x=SX/2, p1y=SY/2, p2y=SY-SY/6, p3y=SY/6;
  float cte1=20000;
  int cte2=3;
  SLI *Imagen;
  SLI *Imagen2;
  SLI *Buffer;
  SLI *grid;
  int *p;

/*
  if (InitSGL() != SGL_OK)
  {
    puts("Error initializing new!SGL\r\n");
    return;
  }
*/

  if (CreateVideoSLI(SX, SY, 24) != SGL_OK)
  {
    puts("Error initializing videomode!\r\n");
    return;
  }

  Imagen=LoadGFX("dark.pcx", 8);
  Imagen2=LoadGFX("logo.pcx", 32);

  CreateLitTableSLI(Imagen, 2, 258);
  grid=CreateSLI(SX/8+1,SY/8+1,32*3,1);
  Buffer=CreateSLI(SX,SY, 32, 1);
  SetBlitType(Imagen2, SLIMaskedColor);
  Imagen2->SLIMask=0x0;

  p=(int *)grid->SLIFramePtr;

  while (!Salir)
  {
    if(kbhit()!=0)
      switch (getch())
      {
        case 27 : Salir = -1; break;
        case 'q': bandera=1;  break;
        case 'a': bandera=2;  break;
        case 'o': zo+=0.1;  break;
        case 'p': zo-=0.1;  break;
        case 'u': cte1+=100;  break;
        case 'i': cte1-=100;  break;

        case 't': cte2+=1;  break;
        case 'y': cte2-=1;  break;

        case 'l': luz=(luz+1)&1; break;
      }
    ClearCurrentFrame(GetVideoSLI(), 0);
    if(bandera==2)
    {
      a-=0.005;
      if ( a<0 )
      {
        a=0;
        bandera=0;
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
    //zo=z=1;
    for(y=0;y<SY/8+1;y++)
    {
      phi=phi2;
      pi=pi2;
      //zo+=0.01;
      z=1;
      for(x=0;x<SX/8+1;x++)
      {
          //u=sqrt((x*8-SX/2)*(x*8-SX/2)+(y*8-SY/2)*(y*8-SY/2))+10*cos(x/SX*M_PI*6+phi);
//          u=(x*8.0/SX*236.0)+10+10*cos(x*6.0/SX*M_PI+phi);
//          u=(x*8.0)-30+10*cos(x*6.0/SX*M_PI+phi);
          tmp=(x*8.0)*cos(rot)+(y*8.0)*sin(rot);
          //u=(x*8.0)-30+10*cos(x*6.0/SX*M_PI+phi);
          u=tmp-30+10*cos(x*6.0/SX*M_PI+phi);




          //u1=(x*8.0/SX*256.0);
          //u1=256.0/500.0*sqrt((x*8.0-SX/2)*(x*8.0-SX/2)+(y*8.0-SY/2)*(y*8.0-SY/2));
          //v=255.0*atan2((y*8-SY/2),(x*8-SX/2))/M_PI+10*sin(y/SY*M_PI*2+phi2);
//          v=(y*8.0/SY*256.0)+10*sin(y*5.0/SY*M_PI+phi2);
//          v=(y*8.0)-30+10*sin(y*5.0/SY*M_PI+phi2);
          tmp=(y*8.0)*cos(rot)-(x*8.0)*sin(rot);
          //v=(y*8.0)-30+10*sin(y*5.0/SY*M_PI+phi2);
          v=tmp-30+10*sin(y*5.0/SY*M_PI+phi2);




          //v1=(y*8.0/SY*256.0);
          //v1=256.0*4/M_PI*fabs(atan2((y*8.0-SY/2),(x*8.0-SX/2)));

//rota      u1=(x*8.0-SX/2*cos(rot))*cos(rot)/z+(y*8.0-SY/2)*sin(rot)/z-30;
//          v1=(y*8.0-SY/2*sin(rot))*cos(rot)/z-(x*8.0-SX/2)*sin(rot)/z-30;

/*plano
          u1=(x*8.0)/z+(y*8.0-SY/2)/z-30;
          v1=(y*8.0)/z-(x*8.0-SX/2)/z-30;*/
          d1=((x*8.0-p1x)*(x*8.0-p1x)+(y*8.0-p1y)*(y*8.0-p1y));
          d2=((x*8.0-p2x)*(x*8.0-p2x)+(y*8.0-p2y)*(y*8.0-p2y));
          d3=((x*8.0-p3x)*(x*8.0-p3x)+(y*8.0-p3y)*(y*8.0-p3y));

          a1=fabs(atan2((y*8.0-p1y),(x*8.0-p1x)))/M_PI*256.0*cte2;
          a2=fabs(atan2((y*8.0-p2y),(x*8.0-p2x)))/M_PI*256.0*cte2;
          a3=fabs(atan2((y*8.0-p3y),(x*8.0-p3x)))/M_PI*256.0*cte2;

          //u1=(5600/d1+5600/d2+5600/d3)/3.0;
          v1=(cte1/sqrt(d1)+cte1/sqrt(d2)+cte1/sqrt(d3))/3.0;
          u1=(a1+a2+a3)/3.0;

          p1x=SX/4+90*sin(pi3);
          p2x=SX/2+120*cos(pi3)*cos(rot);
          p3x=SX-SX/6+110*cos(phi3);

          p3y=SY/4+20+80*cos(phi3)*sin(pi3);
          p1y=SY/2+180*sin(pi3);
          p2y=SY-SY/4+120*sin(phi3);

          //l1=54.0+20.0*cos(rot);
          //l1=(1/(d1)+1/(d2)+1/(d3))*855000;

//          l1=u1*u1*u1/(35*35*35);
          l1=v1*v1/(15*15*zo);


          if(l1>255.0) l1=255.0;
          if(l1<0.0) l1=0.0;
          if(luz) l1=255-l1;


//          u1*=(cos(rot)+1.1)/2;
  //        v1*=(cos(rot)+1.1)/2;
          l=fabs(u-(128-40*sin(pi+pi2)))/3;


          //tmp=(u-SX/2*cos(rot)/4)*cos(-rot)+(v-SY/2*sin(rot)/4)*sin(-rot);
          //v=(v-SY/2*sin(rot)/4)*cos(-rot)-(u-SX/2*cos(rot)/4)*sin(-rot);
          //u=tmp;
          p[x*3+y*(SX/8+1)*3]=(int)((u1*a)+(u*(1-a)));
          p[x*3+y*(SX/8+1)*3+1]=((int)((v1+d)*a+(v+d)*(1-a)));
          p[x*3+y*(SX/8+1)*3+2]=((int)((l1*a)+(l*(1-a))));
          phi=fmod(phi+M_PI/20.0, 2*M_PI);
          pi=fmod(pi+M_PI/30.0, 2*M_PI);
          z+=zo;
      }
      phi2=fmod(phi2+M_PI/30.0, 2*M_PI);
      pi2=fmod(pi2+M_PI/(35.0+2*(sin(phi3+phi2)+1)), 2*M_PI);
      rot-=0.001;
    }
    phi3=fmod(phi3+M_PI/20.0, 2*M_PI);
    pi3=fmod(pi3-M_PI/(25.0+5*(cos(pi3-phi3)+1)), 2*M_PI);
 //     d+=3;
    rot=fmod(rot+M_PI/100.0, 2*M_PI);

    u=SX/2.0-Imagen2->SLIXSize/2.0 +SX/8.0*cos(phi3);
    v=SY/2.0-Imagen2->SLIYSize/2.0;
    Draw8x8Grid32Lit(Buffer, grid, Imagen);
    //SetPos(Imagen2,(int) ,(int) );
    //Blit(GetVideoSLI(), Imagen2);
    Blit(GetVideoSLI(), Buffer);

    ShowPage();
  }

  DestroyVideoSLI(3);
//  UnInitSGL();
}
