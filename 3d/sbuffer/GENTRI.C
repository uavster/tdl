#include <3d.h>
#include <sli.h>
#include <sbuffer.def>
#include <sbuffer.h>
#include <tinymath.h>

extern void GenericTriangleMapper(SLI *sbuffer, RENDERPOLY *p)
{
  RENDERPOINT *p1, *p2, *p3, *tmp;
  float p1_vars[SPAN_MAX_INTERPOLATE_VARS+1];
  float p2_vars[SPAN_MAX_INTERPOLATE_VARS+1];
  float p3_vars[SPAN_MAX_INTERPOLATE_VARS+1];
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
  if(p->P1->ImageProjection.y >= p->P2->ImageProjection.y)
  {
    p1=p->P2;
    p2=p->P1;
  } else
  {
    p1=p->P1;
    p2=p->P2;
  }
  if(p2->ImageProjection.y >= p3->ImageProjection.y)
  {
    tmp=p3;
    p3=p2;
    p2=tmp;
  }
  if(p1->ImageProjection.y >= p2->ImageProjection.y)
  {
    tmp=p2;
    p2=p1;
    p1=tmp;
  }
  p1y=ceil(p1->ImageProjection.y);
  p3y=ceil(p3->ImageProjection.y);
  if((p1y>sbuffer->SLIClip.SLRR2.SLPY)||
     (p3y<sbuffer->SLIClip.SLRR1.SLPY)||
     ((p3y - p1y)<=0)) return;

  p2y=ceil(p2->ImageProjection.y);

  p1x=ceil(p1->ImageProjection.x);
  p2x=ceil(p2->ImageProjection.x);
  p3x=ceil(p3->ImageProjection.x);
  
  // Calculamos la longitud de la linea mas ancha
  temp = (p2->ImageProjection.y - p1->ImageProjection.y ) / (p3->ImageProjection.y - p1->ImageProjection.y );

  if ((ancho1 = (temp * (p3->ImageProjection.x - p1->ImageProjection.x ) + (p1->ImageProjection.x - p2->ImageProjection.x))) == 0.0) return;

  if(ancho1<0) ancho1--;
  else ancho1++;
  ancho=65536.0/ancho1;

  // Extract interpolating variables
  if (p->N >= 0) {
	p1_vars[0] = p1->InverseZ;
	p2_vars[0] = p2->InverseZ;
	p3_vars[0] = p3->InverseZ;
  }
  if (p->N >= 1) {
	p1_vars[1] = p1->Properties.TextureCoordinates.x;
	p2_vars[1] = p2->Properties.TextureCoordinates.x;
	p3_vars[1] = p3->Properties.TextureCoordinates.x;
  }
  if (p->N >= 2) {
	p1_vars[2] = p1->Properties.TextureCoordinates.y;
	p2_vars[2] = p2->Properties.TextureCoordinates.y;
	p3_vars[2] = p3->Properties.TextureCoordinates.y;
  }
  if (p->N >= 3) {
	p1_vars[3] = p1->Properties.Light1;
	p2_vars[3] = p2->Properties.Light1;
	p3_vars[3] = p3->Properties.Light1;  
  }
  if (p->N >= 4) {
	p1_vars[4] = p1->Properties.Light2;
	p2_vars[4] = p2->Properties.Light2;
	p3_vars[4] = p3->Properties.Light2;  
  }

    // Calculamos las deltas de todas la variables
  
  for(i=0;i<=p->N;i++)
  {
    sp.SPVars[i*2+1]= ancho*(temp * (p3_vars[i] - p1_vars[i]) + (p1_vars[i] - p2_vars[i]));
    ks1[i]=   65536.0 * p1_vars[i];
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
      dx2=(p3->ImageProjection.x - p1->ImageProjection.x)/(p3->ImageProjection.y - p1->ImageProjection.y);
      x2=p1->ImageProjection.x;

      if((p2y - p1y)!=0)
      {
        temp=1.0/(p2->ImageProjection.y - p1->ImageProjection.y );
        dx1=temp * (p2->ImageProjection.x - p1->ImageProjection.x);
        temp*=65536.0;
        for(i=0;i<=p->N;i++)
        {
          deltas1[i]= temp * (p2_vars[i] - p1_vars[i]);
        }
        x1=p1->ImageProjection.x;
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

        x1+=((float)y-p1->ImageProjection.y)*dx1;
        x2+=((float)y-p1->ImageProjection.y)*dx2;
        for(i=0;i<=p->N;i++)
        {
          ks1[i]+=((float)y-p1->ImageProjection.y)*deltas1[i];
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
        x2+=((float)p1y-p1->ImageProjection.y)*dx2;
        for(i=0;i<=p->N;i++)
        {
          ks1[i]+=((float)p1y-p1->ImageProjection.y)*deltas1[i];
        }
      }

      /*else
      {
        for(i=0;i<=p->N;i++)
        {
          ks1[i]=   65536.0 * p2_vars[i];
        }
      } */
      if((p3y - p2y)==0) return;

      temp=1.0/(p3->ImageProjection.y - p2->ImageProjection.y);
      dx1=(p3->ImageProjection.x - p2->ImageProjection.x)*temp;
      temp*=65536.0;
      for(i=0;i<=p->N;i++)
      {
        deltas1[i]= temp * (p3_vars[i] - p2_vars[i]);
      }
      x1=p2->ImageProjection.x;
/*      for(i=0;i<=p->N;i++)
      {
        ks1[i]=   65536.0 * p2_vars[i]; pasado a abajo
      }*/

      y=(int)p2y;

      if(y<sbuffer->SLIClip.SLRR1.SLPY)
      {
        y=sbuffer->SLIClip.SLRR1.SLPY;
        x2+=((float)y-p2y)*dx2;
      }
      x1+=((float)y-p2->ImageProjection.y)*dx1;
      //x2+=((float)y-p2->ImageProjection.y)*dx2;
      for(i=0;i<=p->N;i++)
      {
        ks1[i]=65536.0 * p2_vars[i]+((float)y-p2->ImageProjection.y)*deltas1[i];
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
      temp=1.0/(p3->ImageProjection.y - p1->ImageProjection.y);
      dx1=temp * (p3->ImageProjection.x - p1->ImageProjection.x);
      temp*=65536.0;
      for(i=0;i<=p->N;i++)
      {
        deltas1[i]= temp * (p3_vars[i] - p1_vars[i]);
      }
      dx3=(p3->ImageProjection.x - p2->ImageProjection.x)/(p3->ImageProjection.y - p2->ImageProjection.y);

      x1=p1->ImageProjection.x;

      if((p2y - p1y)!=0)
      {
        x2=p1->ImageProjection.x;

        dx2=(p2->ImageProjection.x - p1->ImageProjection.x)/(p2->ImageProjection.y - p1->ImageProjection.y );

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

        x1+=((float)y-p1->ImageProjection.y)*dx1;
        x2+=((float)y-p1->ImageProjection.y)*dx2;

        for(i=0;i<=p->N;i++)
        {
          ks1[i]+=((float)y-p1->ImageProjection.y)*deltas1[i];
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
        x1+=((float)p1y-p1->ImageProjection.y)*dx1;
        for(i=0;i<=p->N;i++)
        {
          ks1[i]+=((float)p1y-p1->ImageProjection.y)*deltas1[i];
        }
      }

      if((p3y - p2y)==0) return;

      x2=p2->ImageProjection.x;

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
      //x1+=((float)y-p2->ImageProjection.y)*dx1;
      x2+=((float)y-p2->ImageProjection.y)*dx3;
      /*for(i=0;i<=p->N;i++)
      {
        ks1[i]+=((float)y-p2->ImageProjection.y)*deltas1[i];
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



