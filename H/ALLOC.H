/* 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
   Include file for general memory handling routines
   컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 */

#ifndef _ALLOC_INCLUDED_
#define _ALLOC_INCLUDED_

#include <stddef.h>

#ifdef __cplusplus
  extern "C" {
#endif

void init_c_heap(void);
#pragma aux init_c_heap "*"  modify [ecx eax ebx edx];


void *malloc(DWORD dwSize);
#pragma aux malloc "*" parm   [ecx] \
                       modify [eax ecx] \
                       value  [ebx];

void free(void *pv);
#pragma aux free "*" parm   [ebx] \
                     modify [eax ebx ecx];

void *realloc(void *pv, DWORD dwSize);
#pragma aux realloc "*" parm   [ebx] [ecx] \
                        modify [eax ecx edx esi edi] \
                        value  [ebx];

int checkheap(void);
#pragma aux checkheap "*" modify [eax ebx edx] \
                          value  [eax];

#define CH_ERROR    -1
#define CH_OK       0

DWORD getmeminfo(void);
#pragma aux getmeminfo "*" modify [eax ebx ecx] \
                           value  [eax];

#ifdef __cplusplus
  };
#endif

#endif
