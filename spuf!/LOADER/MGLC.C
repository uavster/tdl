#include <tdl.h>
int loadcount;

int MGLCTest(char *name)
{
  DWORD handle;
  MGLCHeader VideoHeader;
    handle=ttl_open(name,0);
    ttl_seek(handle, 0, SEEK_SET);
    ttl_read((BYTE *)&VideoHeader, sizeof(VideoHeader), handle);
    ttl_close(handle);
    if(VideoHeader.Magic=='MGLC') return 1;
    else return 0;
}
MGLC *MGLCLoad(char *name)
{
  DWORD handle;
  MGLCHeader *VideoHeader;
  MGLC *re;
  int size, i;

    handle=ttl_open(name,0);
    re=malloc(sizeof(MGLC)+10);
    VideoHeader=malloc(sizeof(MGLCHeader)+10);
    re->header=VideoHeader;
    size=ttl_seek(handle, 0, SEEK_END)-sizeof(MGLCHeader);
    ttl_seek(handle, 0, SEEK_SET);
    ttl_read(VideoHeader, sizeof(MGLCHeader), handle);
    re->buffer=malloc(size+10);
    ttl_read(re->buffer, size, handle);
    ttl_close(handle);
    re->Play=0;
    re->Frameptr=0;
    re->Frame=CreateSLI(VideoHeader->VideoX, VideoHeader->VideoY,VideoHeader->Colors, 1);
    if ( VideoHeader->Colors ==8 )
    {
      for (i=0; i<256; i++ )
      {
        re->Frame->SLIPalette[i]=i+(i<<8)+(i<<16);
      }
    }
    return re;
}

void MGLCDestroy(MGLC *re)
{
    free(re->header);
    free(re->buffer);
    DestroySLI(re->Frame);
    free(re);
}

int LoadBit(BYTE *l)
{
    DWORD i=0, r=0, c=0;
    i=loadcount>>3;
    c=(7-(loadcount&7));
    r=l[i]>>c;
    r=r&1;
    loadcount++;
    return r;
}
void MGLCPlay(MGLC *re)
{
  re->Frameptr=0;
  re->actFrame=0;
  ClearCurrentFrame(re->Frame, 0);
  re->Play=1;
}
void MGLCStop(MGLC *re)
{
  re->Play=2;
}
void MGLCRewind(MGLC *re)
{
  re->Play=0;
  re->Frameptr=0;
  re->actFrame=0;
}
int MGLCStatus(MGLC *re)
{
  return re->Play;
}


SLI *MGLCFrame(MGLC *re)
{
  DWORD x, y, x1;
  DWORD *p;
  BYTE  *p8;
  int   oldar, oldag, oldab;
  int   aR, bR, cR;
  int   aG, bG, cG;
  int   aB, bB, cB;
  int   inR, inG, inB;

    if( (re->header->Colors==8)&& (re->header->CompressionType==1) && (re->Play==1))
    {
        oldar=0;
        p8=(BYTE *)re->Frame->SLIFramePtr;
        loadcount=re->Frameptr;
        for(y=0; y<re->header->VideoY ; y++)
          for(x=0; x<(re->header->VideoX/re->header->MinBlock) ; x++)
          {
              if(LoadBit(re->buffer))
              {
                  if(x!=0)
                    oldar=p8[y*re->header->VideoX+x*re->header->MinBlock-1];
                  else
                    oldar=0;
                  aR=0;
                  if(LoadBit(re->buffer)) aR+=8<<4;
                  if(LoadBit(re->buffer)) aR+=4<<4;
                  if(LoadBit(re->buffer)) aR+=2<<4;
                  if(LoadBit(re->buffer)) aR+=1<<4;
                  bR=0;
                  cR=0;
                  for(x1=0; x1<re->header->MinBlock; x1++)
                  {
                      if(LoadBit(re->buffer))
                      {
                        if(bR==0) cR=0;
                        else     cR++;
                        aR-=re->header->Increment1+re->header->Increment2*cR*cR;
                        if ( aR<0 ) aR=0;
                        bR=1;
                      }
                      else
                      {
                        if(bR==1) cR=0;
                        else     cR++;
                        aR+=re->header->Decrement1+re->header->Decrement2*cR*cR;
                        if ( aR>255 ) aR=255;
                        bR=0;
                      }
                      inR=(aR+oldar)/2;

                      oldar=aR;
                      p8[y*re->header->VideoX+x*re->header->MinBlock+x1]=inR;
                  }
              }

          }
          re->Frameptr=loadcount;
          re->actFrame++;
    }

    if( (re->header->Colors==32)&& (re->header->CompressionType==1) && (re->Play==1))
    {
        p=(DWORD *)re->Frame->SLIFramePtr;
        loadcount=re->Frameptr;
        oldar=0;
        oldag=0;
        oldab=0;
        for(y=0; y<re->header->VideoY ; y++)
          for(x=0; x<(re->header->VideoX/re->header->MinBlock) ; x++)
          {
            if(LoadBit(re->buffer))
            {
                if(x!=0)
                {
                  oldar=(p[y*re->header->VideoX+x*re->header->MinBlock-1]>>16)&255;
                  oldag=(p[y*re->header->VideoX+x*re->header->MinBlock-1]>>8)&255;
                  oldab=p[y*re->header->VideoX+x*re->header->MinBlock-1]&255;
                }
                else
                {
                  oldar=0;
                  oldag=0;
                  oldab=0;
                }
                aB=0;
                if(LoadBit(re->buffer)) aB+=8<<4;
                if(LoadBit(re->buffer)) aB+=4<<4;
                if(LoadBit(re->buffer)) aB+=2<<4;
                if(LoadBit(re->buffer)) aB+=1<<4;
                aG=0;
                if(LoadBit(re->buffer)) aG+=8<<4;
                if(LoadBit(re->buffer)) aG+=4<<4;
                if(LoadBit(re->buffer)) aG+=2<<4;
                if(LoadBit(re->buffer)) aG+=1<<4;
                aR=0;
                if(LoadBit(re->buffer)) aR+=8<<4;
                if(LoadBit(re->buffer)) aR+=4<<4;
                if(LoadBit(re->buffer)) aR+=2<<4;
                if(LoadBit(re->buffer)) aR+=1<<4;

                bB=0;
                cB=0;
                bG=0;
                cG=0;
                bR=0;
                cR=0;

                for(x1=0;x1<re->header->MinBlock;x1++)
                {
                  if(LoadBit(re->buffer))
                  {
                    if(bB==0) cB=0;
                    else     cB++;
                    aB-=re->header->Increment1+re->header->Increment2*cB*cB;
                    if ( aB<0 ) aB=0;
                    bB=1;
                  }
                  else
                  {
                    if(bB==1) cB=0;
                    else     cB++;
                    aB+=re->header->Decrement1+re->header->Decrement2*cB*cB;
                    if ( aB>255 ) aB=255;
                    bB=0;
                  }

                  if(LoadBit(re->buffer))
                  {
                    if(bG==0) cG=0;
                    else     cG++;
                    aG-=re->header->Increment1+re->header->Increment2*cG*cG;
                    if ( aG<0 ) aG=0;
                    bG=1;
                  }
                  else
                  {
                    if(bG==1) cG=0;
                    else     cG++;
                    aG+=re->header->Decrement1+re->header->Decrement2*cG*cG;
                    if ( aG>255 ) aG=255;
                    bG=0;
                  }

                  if(LoadBit(re->buffer))
                  {
                    if(bR==0) cR=0;
                    else     cR++;
                    aR-=re->header->Increment1+re->header->Increment2*cR*cR;
                    if ( aR<0 ) aR=0;
                    bR=1;
                  }
                  else
                  {
                    if(bR==1) cR=0;
                    else     cR++;
                    aR+=re->header->Decrement1+re->header->Decrement2*cR*cR;
                    if ( aR>255 ) aR=255;
                    bR=0;
                  }

                  inR=(aR+oldar)/2;
                  inG=(aG+oldag)/2;
                  inB=(aB+oldab)/2;

                  oldar=aR;
                  oldag=aG;
                  oldab=aB;

                  p[y*re->header->VideoX+x*re->header->MinBlock+x1]=inB+(inG<<8)+(inR<<16);
                }
            }

          }
        re->Frameptr=loadcount;
        re->actFrame++;
    }
    if(re->actFrame>=re->header->NumFrames)
    {
      re->Frameptr=0;
      re->actFrame=0;
      re->Play=2;
    }
    return re->Frame;
}


