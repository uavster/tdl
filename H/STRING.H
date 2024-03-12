/* ������������������������������������������������������������ 
   Include file for string handling functions
   ������������������������������������������������������������ */

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

char *strcpy(char *, const char *);
#pragma aux strcpy "strcpya" parm	[edi] [esi] \
                        value [edi];

int sprintf(const char *str, const char *format, ...);

#ifdef __cplusplus
  };
#endif

#endif

