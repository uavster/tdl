/* 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
   Included file for all the stuff related to grids
   컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 */

#ifndef _GRID_INCLUDED_
#define _GRID_INCLUDED_

#include <sli.h>
#include <stddef.h>

#ifdef __cplusplus
  extern "C" {
#endif

typedef struct
{
  DWORD u;
  DWORD v;
  DWORD l;
} GRIDELEM;

typedef struct
{
  DWORD     GRIDXSize;
  DWORD     GRIDYSize;
  GRIDELEM  *GRIDPtr;
} GRID;

GRID *CreateGrid(DWORD dwXSize, DWORD dwYSize);
#pragma aux CreateGrid "*" parm   [eax] [ebx] \
                           value  [eax] \
                           modify [eax ebx ecx edx esi edi];

void Draw8x8Grid32Lit(SLI *output, GRID *Grid, SLI *texture);
#pragma aux Draw8x8Grid32Lit "*" parm   [edi] [esi] [edx] \
                            modify [eax ebx ecx edx esi edi ebp];

void Draw4x4Grid32Lit(SLI *output, GRID *Grid, SLI *texture);
#pragma aux Draw4x4Grid32Lit "*" parm   [edi] [esi] [edx] \
                            modify [eax ebx ecx edx esi edi];

#ifdef __cplusplus
  };
#endif

#endif
