/* 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 
   Include file for TDL standard definitions and functions
   컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 */

#ifndef _STDDEF_INCLUDED_
#define _STDDEF_INCLUDED_

#ifdef __cplusplus
  extern "C" {
#endif

typedef unsigned char   BYTE;
typedef unsigned short  WORD;
typedef unsigned long   DWORD;
typedef double          QWORD;
#ifndef __cplusplus
typedef int             bool;
#endif
typedef DWORD			size_t;

#define NULL        	0

void puts(char *sz);
#pragma aux puts =        \
  "   mov     ecx, 0ffffh"\
  "   mov     edi, edx"   \
  "   xor     al, al"     \
  "   cld"                \
  "   repne   scasb"      \
  "   dec     edi"        \
  "   mov     [edi], '$'" \
  "   mov     ah, 9"      \
  "   int     21h"        \
  "   mov     [edi], al"  \
  parm [edx] modify [eax ecx edi];

int getch(void);
#pragma aux getch =   \
  "   mov     ah, 8"  \
  "   int     21h"    \
  "   movzx   eax, al"\
  value [eax];

int kbhit(void);
#pragma aux kbhit =   \
  "   mov     ah, 0bh"\
  "   int     21h"    \
  "   movsx   eax, al"\
  value [eax];

void memset(void *ptr, BYTE c, DWORD len);
#pragma aux memset =      \
  "   mov     ah, al"     \
  "   mov     edx, eax"   \
  "   shl     eax, 16"    \
  "   mov     ax, dx"     \
  "   push    ecx"        \
  "   shr     ecx, 2"     \
  "   cld"                \
  "   rep     stosd"      \
  "   pop     ecx"        \
  "   and     ecx, 3"     \
  "   rep     stosb"      \
  parm [edi] [al] [ecx] modify [eax edi ecx edx];

#define exit _exit_
void _exit_(BYTE);
#pragma aux _exit_ "*" parm [al]\
                       modify [eax ebx ecx edx esi edi ebp];

#ifdef __cplusplus
  };
#endif

#endif

