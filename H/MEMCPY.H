// ------------------------
//   Memory copy routines
// ------------------------

#ifndef _MEMCPY_INCLUDED_
#define _MEMCPY_INCLUDED_

#include <stddef.h>

#ifdef __cplusplus
  extern "C" {
#endif

void memcpy(void *dest, void *src, DWORD len);
#pragma aux memcpy =      \
  "   push    ecx"        \
  "   shr     ecx, 2"     \
  "   cld"                \
  "   rep     movsd"      \
  "   pop     ecx"        \
  "   and     ecx, 3"     \
  "   rep     movsb"      \
  parm [edi] [esi] [ecx] modify [edi esi ecx];

// Aligned memory copy.
// Guarantees that the atomic copies are aligned to the size of their operands.
void amemcpy(void *dest, const void *src, DWORD len);
#pragma aux amemcpy "Memcopy" parm   [edi] [esi] [ecx] \
                        modify [eax ecx edx esi edi];

#ifdef __cplusplus
  };
#endif

#endif
