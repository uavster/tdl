/* 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 
   Include file for string handling functions
   컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 */

#ifndef _STRING_INCLUDED_
#define _STRING_INCLUDED_

#define strlen StringLength

#include <stddef.h>

#ifdef __cplusplus
  extern "C" {
#endif

DWORD StringLength(char *);
#pragma aux StringLength "*" parm   [esi]\
                             modify [eax ebx ecx edx esi edi ebp]\
                             value  [ecx];

void PushToString(char *,char);
#pragma aux PushToString "*" parm   [esi] [dl];

#ifdef __cplusplus
  };
#endif

#endif

