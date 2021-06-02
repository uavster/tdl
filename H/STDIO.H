/* 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
   Include file for standard input/output functions
   컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 */

#ifndef _STDIO_INCLUDED_
#define _STDIO_INCLUDED_

#ifdef __cplusplus
  extern "C" {
#endif

void printf(const char *,...);
#pragma aux PrintFormatted "*" 	parm   [esi] \
								modify [eax ebx ecx edx esi edi ebp 8087];

#ifdef __cplusplus
  };
#endif

#endif




