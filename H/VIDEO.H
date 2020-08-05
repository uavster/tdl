typedef struct
{
  int Magic;  // 'MGLC'
  int HeaderSize;
  int VideoX, VideoY;
  int MinBlock;
  int KeyFrame;
  int NumFrames;
  int Colors;  // 8, 15, 16, 24
  int CompressionType; // 0 = none (Variation only)
                       // 1 = 1 bit/sample
                       // 2 = 2 bits/sample
  int Increment1; //Increments for compression
  int Increment2;
  int Decrement1;
  int Decrement2;
} MGLCHeader;

typedef struct
{
  MGLCHeader *header;
  BYTE *buffer;
  int Frameptr;
  int actFrame;
  SLI *Frame;
  int Play;
} MGLC;

int MGLCTest(char *name);
MGLC *MGLCLoad(char *name);
void MGLCPlay(MGLC *re);
void MGLCStop(MGLC *re);
void MGLCRewind(MGLC *re);
int MGLCStatus(MGLC *re);
SLI *MGLCFrame(MGLC *re);
void MGLCDestroy(MGLC *re);

