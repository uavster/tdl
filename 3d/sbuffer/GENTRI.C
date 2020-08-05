#include <3d.h>
#include <sli.h>
#include <sbuffer.def>
#include <sbuffer.h>
#include <tinymath.h>

extern void GenericTriangleMapper(SLI *sbuffer, RENDERPOLY *p)
{
  RENDERPOINT *p1, *p2, *p3, *tmp;
  float deltas1[SPAN_MAX_INTERPOLATE_VARS+1];
  float ks1[SPAN_MAX_INTERPOLATE_VARS+1];
  float dx1, dx2, dx3, x1, x2;
  float temp, ancho, ancho1;
  SPAN sp;
  int i, y, y2;
  int p1y, p2y, p3y;
  int p1x, p2x, p3x;

  // Ordenamos los puntos en altura
  p3=p->P3;
  if(p->P1->Y >= p->P2->Y)
  {
    p1=p->P2;
    p2=p->P1;
  } else
  {
    p1=p->P1;
    p2=p->P2;
  }
  if(p2->Y >= p3->Y)
  {
    tmp=p3;
    p3=p2;
    p2=tmp;
  }
  if(p1->Y >= p2->Y)
  {
    tmp=p2;
    p2=p1;
    p1=tmp;
  }
  p1y=ceil(p1->Y);
  p3y=ceil(p3->Y);
  if((p1y>sbuffer->SLIClip.SLRR2.SLPY)||
     (p3y<sbuffer->SLIClip.SLRR1.SLPY)||
     ((p3y - p1y)<=0)) return;

  p2y=ceil(p2->Y);

  p1x=ceil(p1->X);
  p2x=ceil(p2->X);
  p3x=ceil(p3->X);

  // Calculamos la longitud de la linea mas ancha
  temp = (p2->Y - p1->Y ) / (p3->Y - p1->Y );

  if ((ancho1 = (temp * (p3->X - p1->X ) + (p1->X - p2->X))) == 0.0) return;

  if(ancho1<0) ancho1--;
  else ancho1++;
  ancho=65536.0/ancho1;

    // Calculamos las deltas de todas la variables
  for(i=0;i<=p->N;i++)
  {
    sp.SPVars[i*2+1]= ancho*(temp * (p3->k[i] - p1->k[i]) + (p1->k[i] - p2->k[i]));
    ks1[i]=   65536.0 * p1->k[i];
  }
  sp.SPN=p->N+1;
  sp.SPType=p->Type;
  switch(p->Type)
  {
    case 1:
    case 12:
            sp.SPTexture=(BYTE *)p->Texture1;
            break;
    case 2:
            sp.SPTexture=p->Texture1->SLIFramePtr;
            sp.SPLightMap=(BYTE *)p->Texture1->SLIPalette;
            break;
    case 3:
            sp.SPTexture=p->Texture1->SLIFramePtr;
            sp.SPLightMap=p->Texture1->SLILitTable;
            break;
    case 4:
            sp.SPTexture=p->Texture1->SLIFramePtr;
            sp.SPLightMap=p->Texture1->SLILitTable;
            sp.SPAlpha=p->Texture2->SLIFramePtr;
            break;

  }
  /*
    sp.SPTexture=p->Texture1->SLIFramePtr;
    sp.SPLightMap=p->Texture1->SLILitTable;
    sp.SPAlpha=p->Texture2->SLIFramePtr;
  */
  if( ancho1 > 0)
  {
      dx2=(p3->X - p1->X)/(p3->Y - p1->Y);
      x2=p1->X;

      if((p2y - p1y)!=0)
      {
        temp=1.0/(p2->Y - p1->Y );
        dx1=temp * (p2->X - p1->X);
        temp*=65536.0;
        for(i=0;i<=p->N;i++)
        {
          deltas1[i]= temp * (p2->k[i] - p1->k[i]);
        }
        x1=p1->X;
        y=(int)p1y;
        if(y<sbuffer->SLIClip.SLRR1.SLPY)
        {
          if(((int)p2y)<sbuffer->SLIClip.SLRR1.SLPY)
          {
            y=(int)p2y;
          }
          else
            y=sbuffer->SLIClip.SLRR1.SLPY;
        }

        x1+=((float)y-p1->Y)*dx1;
        x2+=((float)y-p1->Y)*dx2;
        for(i=0;i<=p->N;i++)
        {
          ks1[i]+=((float)y-p1->Y)*deltas1[i];
        }

        y2=(int)p2y;
        if(y2>sbuffer->SLIClip.SLRR2.SLPY) y2=sbuffer->SLIClip.SLRR2.SLPY;

        for (; y<y2; y++)
        {
          sp.SPX1=(int)ceil(x1);
          sp.SPX2=(int)ceil(x2);
          if((sp.SPX1<=sbuffer->SLIClip.SLRR2.SLPX)&&(sp.SPX2>=sbuffer->SLIClip.SLRR1.SLPX))
          {
            if(sp.SPX1<sbuffer->SLIClip.SLRR1.SLPX) sp.SPX1=sbuffer->SLIClip.SLRR1.SLPX;
            sp.SPX2--;
            if(sp.SPX2>sbuffer->SLIClip.SLRR2.SLPX) sp.SPX2=sbuffer->SLIClip.SLRR2.SLPX;
            for(i=0;i<=p->N;i++)
            {
              sp.SPVars[i*2]=ks1[i]+((float)sp.SPX1-x1)*sp.SPVars[i*2+1];
            }
            if(sp.SPX1<=sp.SPX2)
            InsertSpan(sbuffer, (SPAN *)&sp,y);
          }
          x1+=dx1;
          x2+=dx2;
          for(i=0;i<=p->N;i++)
          {
            ks1[i]+=deltas1[i];
          }
        }
      }
      else
      {
        x2+=((float)p1y-p1->Y)*dx2;
        for(i=0;i<=p->N;i++)
        {
          ks1[i]+=((float)p1y-p1->Y)*deltas1[i];
        }
      }

      /*else
      {
        for(i=0;i<=p->N;i++)
        {
          ks1[i]=   65536.0 * p2->k[i];
        }
      } */
      if((p3y - p2y)==0) return;

      temp=1.0/(p3->Y - p2->Y);
      dx1=(p3->X - p2->X)*temp;
      temp*=65536.0;
      for(i=0;i<=p->N;i++)
      {
        deltas1[i]= temp * (p3->k[i] - p2->k[i]);
      }
      x1=p2->X;
/*      for(i=0;i<=p->N;i++)
      {
        ks1[i]=   65536.0 * p2->k[i]; pasado a abajo
      }*/

      y=(int)p2y;

      if(y<sbuffer->SLIClip.SLRR1.SLPY)
      {
        y=sbuffer->SLIClip.SLRR1.SLPY;
        x2+=((float)y-p2y)*dx2;
      }
      x1+=((float)y-p2->Y)*dx1;
      //x2+=((float)y-p2->Y)*dx2;
      for(i=0;i<=p->N;i++)
      {
        ks1[i]=65536.0 * p2->k[i]+((float)y-p2->Y)*deltas1[i];
      }
      y2=(int)p3y;
      if(y2>sbuffer->SLIClip.SLRR2.SLPY) y2=sbuffer->SLIClip.SLRR2.SLPY;

      for (; y<=y2; y++)
      {
        sp.SPX1=(int)ceil(x1);
        sp.SPX2=(int)ceil(x2);
        if((sp.SPX1<=sbuffer->SLIClip.SLRR2.SLPX)&&(sp.SPX2>=sbuffer->SLIClip.SLRR1.SLPX))
        {
          if(sp.SPX1<sbuffer->SLIClip.SLRR1.SLPX) sp.SPX1=sbuffer->SLIClip.SLRR1.SLPX;
          sp.SPX2--;
          if(sp.SPX2>sbuffer->SLIClip.SLRR2.SLPX) sp.SPX2=sbuffer->SLIClip.SLRR2.SLPX;
          for(i=0;i<=p->N;i++)
          {
            sp.SPVars[i*2]=ks1[i]+((float)sp.SPX1-x1)*sp.SPVars[i*2+1];
          }
          if(sp.SPX1<=sp.SPX2)
          InsertSpan(sbuffer, (SPAN *)&sp ,y);
        }
        x1+=dx1;
        x2+=dx2;
        for(i=0;i<=p->N;i++)
        {
          ks1[i]+=deltas1[i];
        }
      }

  }
  else
  {
      temp=1.0/(p3->Y - p1->Y);
      dx1=temp * (p3->X - p1->X);
      temp*=65536.0;
      for(i=0;i<=p->N;i++)
      {
        deltas1[i]= temp * (p3->k[i] - p1->k[i]);
      }
      dx3=(p3->X - p2->X)/(p3->Y - p2->Y);

      x1=p1->X;

      if((p2y - p1y)!=0)
      {
        x2=p1->X;

        dx2=(p2->X - p1->X)/(p2->Y - p1->Y );

        y=(int)p1y;

        if(y<sbuffer->SLIClip.SLRR1.SLPY)
        {
          if(((int)p2y)<sbuffer->SLIClip.SLRR1.SLPY)
          {
            y=(int)p2y;
          }
          else
          {
            y=sbuffer->SLIClip.SLRR1.SLPY;
          }
        }

        x1+=((float)y-p1->Y)*dx1;
        x2+=((float)y-p1->Y)*dx2;

        for(i=0;i<=p->N;i++)
        {
          ks1[i]+=((float)y-p1->Y)*deltas1[i];
        }
        y2=(int)p2y;
        if(y2>sbuffer->SLIClip.SLRR2.SLPY) y2=sbuffer->SLIClip.SLRR2.SLPY;

        for (; y<y2; y++)
        {
          sp.SPX1=(int)ceil(x1);
          sp.SPX2=(int)ceil(x2);
          if((sp.SPX1<=sbuffer->SLIClip.SLRR2.SLPX)&&(sp.SPX2>=sbuffer->SLIClip.SLRR1.SLPX))
          {
            if(sp.SPX1<sbuffer->SLIClip.SLRR1.SLPX) sp.SPX1=sbuffer->SLIClip.SLRR1.SLPX;
            sp.SPX2--;
            if(sp.SPX2>sbuffer->SLIClip.SLRR2.SLPX) sp.SPX2=sbuffer->SLIClip.SLRR2.SLPX;
            for(i=0;i<=p->N;i++)
            {
              sp.SPVars[i*2]=ks1[i]+((float)sp.SPX1-x1)*sp.SPVars[i*2+1];
            }
            if(sp.SPX1<=sp.SPX2)
            InsertSpan(sbuffer, (SPAN *)&sp,y);
          }
          x1+=dx1;
          x2+=dx2;
          for(i=0;i<=p->N;i++)
          {
            ks1[i]+=deltas1[i];
          }
        }
      }
      else
      {
        x1+=((float)p1y-p1->Y)*dx1;
        for(i=0;i<=p->N;i++)
        {
          ks1[i]+=((float)p1y-p1->Y)*deltas1[i];
        }
      }

      if((p3y - p2y)==0) return;

      x2=p2->X;

      y=(int)p2y;

      if(y<sbuffer->SLIClip.SLRR1.SLPY)
      {
        y=sbuffer->SLIClip.SLRR1.SLPY;
        x1+=((float)y-p2y)*dx1;
        for(i=0;i<=p->N;i++)
        {
          ks1[i]+=((float)y-p2y)*deltas1[i];
        }
      }
      //x1+=((float)y-p2->Y)*dx1;
      x2+=((float)y-p2->Y)*dx3;
      /*for(i=0;i<=p->N;i++)
      {
        ks1[i]+=((float)y-p2->Y)*deltas1[i];
      }*/
      y2=(int)p3y;
      if(y2>sbuffer->SLIClip.SLRR2.SLPY) y2=sbuffer->SLIClip.SLRR2.SLPY;

      for (; y<=y2; y++)
      {
        sp.SPX1=(int)ceil(x1);
        sp.SPX2=(int)ceil(x2);
        if((sp.SPX1<=sbuffer->SLIClip.SLRR2.SLPX)&&(sp.SPX2>=sbuffer->SLIClip.SLRR1.SLPX))
        {
          if(sp.SPX1<sbuffer->SLIClip.SLRR1.SLPX) sp.SPX1=sbuffer->SLIClip.SLRR1.SLPX;
          sp.SPX2--;
          if(sp.SPX2>sbuffer->SLIClip.SLRR2.SLPX) sp.SPX2=sbuffer->SLIClip.SLRR2.SLPX;
          for(i=0;i<=p->N;i++)
          {
            sp.SPVars[i*2]=ks1[i]+((float)sp.SPX1-x1)*sp.SPVars[i*2+1];
          }
          if(sp.SPX1<=sp.SPX2)
          InsertSpan(sbuffer, (SPAN *)&sp,y);
        }
        x1+=dx1;
        x2+=dx3;
        for(i=0;i<=p->N;i++)
        {
          ks1[i]+=deltas1[i];
        }
      }
  }
  return;
}



