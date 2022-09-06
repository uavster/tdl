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

int StringLength(const char *);
#pragma aux StringLength "*" parm   [esi]\
                             value  [ecx];

#define strlen StringLength

void PushToString(char *,char);
#pragma aux PushToString "*" parm   [esi] [dl];

char *strcpy(const char *src, char *dst);
#pragma aux strcpy_ "*" parm	[esi] [edi] value [edi];

#ifdef __cplusplus
  };
#endif

#endif

