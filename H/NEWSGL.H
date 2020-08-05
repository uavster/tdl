/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
 Include file for newSGL! graphic library
 Author: C굎ar Guirao Robles a.k.a. Nitro! / the DarkRising
컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*/

#ifndef _NEWSGL_INCLUDED_
#define _NEWSGL_INCLUDED_

#include <stddef.h>

#ifdef __cplusplus
  extern "C" {
#endif

#define    SGL_OK       0
#define    SGL_DRIVER   1
#define    SGL_NOMEM    2
#define    SGL_FILE     3
#define    SGL_REINIT   4
#define    SGL_NOINIT   5
#define    SGL_ERROR   -1

#define    SGL_MemoryBuffer 0x80000000
int InitSGL(void);
#pragma aux InitSGL "*" modify [eax ebx ecx edx esi edi ebp] \
                        value  [eax];

int SetVideoMode(int xRes, int yRes, int nBits);
#pragma aux SetVideoMode "*" parm   [eax] [ebx] [ecx] \
                             modify [eax ebx ecx edx esi edi ebp] \
                             value  [eax];
int UnSetVideoMode(int nMode);
#pragma aux UnSetVideoMode "*" parm   [eax] \
                               modify [eax ebx ecx edx esi edi ebp] \
                               value  [eax];
void UnInitSGL(void);
#pragma aux UnInitSGL "*" modify [eax ebx ecx edx esi edi ebp];

#define DONTCHANGE  0

BYTE *GetAvailPage(void);
#pragma aux GetAvailPage "*" value [eax];

BYTE *GetMemoryPtr(void);
#pragma aux GetMemoryPtr "*" value [eax];

void ShowPage(void);
#pragma aux ShowPage "*" modify [eax ebx ecx edx esi edi];

void WaitRetrace(void);
#pragma aux WaitRetrace "*" modify [eax ebx ecx edx esi edi];

int InitGraph(int *modelist);

void ShowFrame(void);

#ifdef __cplusplus
  };
#endif

#endif
