
#include <tdl.h>

int Converting=0;
int Centering=0;
SLI *OS;

int InitGraph(int *modelist)
{
  int i=0;
  while ( modelist[i]!=0 )
  {
    if (CreateVideoSLI(modelist[i], modelist[i+1], modelist[i+2]) == SGL_OK)
    {
        if( (modelist[i]==modelist[0]) &&
            (modelist[i+1]==modelist[1]) &&
            (modelist[i+2]==modelist[2]) )
        {
            Converting=0;
            Centering=0;
            OS=GetVideoSLI();
            return SGL_OK;
        }
        if (modelist[i+2]==modelist[2])
        {
            OS=GetVideoSLI();
            OS->SLIYSize=modelist[1];
            SetClip(OS, 0, 0 , modelist[0]-1,modelist[1]-1);
            Centering=((modelist[i+1]/2-modelist[1]/2)*modelist[i]+modelist[i]/2-modelist[0]/2)*modelist[i+2]/8;
            OS->SLIFramePtr+=Centering;
            Converting=0;
            return SGL_OK;
        }
        else
        {
            OS=CreateSLI(modelist[0],modelist[1],modelist[2],1);
            Centering=((modelist[i+1]/2-modelist[1]/2)*modelist[i]+modelist[i]/2-modelist[0]/2)*modelist[i+2]/8;
            Converting=1;
            return SGL_OK;
        }
    }
    i+=3;
  }
  puts("Error initializing videomode!\r\n");
  return SGL_ERROR;
}

void ShowFrame(void)
{
    SLI *out;
    if(Converting)
    {
      out=GetVideoSLI();
      if(Centering!=0)
        out->SLIFramePtr+=Centering;
      Blit(out, OS);
    }
    ShowVideoSLI();
    if((Converting==0)&&(Centering!=0))
      OS->SLIFramePtr+=Centering;
}
