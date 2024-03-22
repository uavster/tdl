#ifndef __DEBUG_INCLUDED__
#define __DEBUG_INCLUDED__

#ifdef __cplusplus
  extern "C" {
#endif

#include "stddef.h"

/*
; --------------
; Writes the bytecodes around the call to this function to a file.
; Assumes a near call and ds having the same base address as cs.
; 
; Input:
; eax -> number of bytes before the call site
; ebx -> number of bytes after the call site
; edx -> file path
;
; Output:
; cf = 0 if success
;   eax = 0
; cf = 1 if error
;   eax = error code
; --------------
*/
int DumpCodeToFile(const char *file_name, DWORD bytes_before_call, DWORD bytes_after_call);
#pragma aux DumpCodeToFile "*" parm   [edx] [eax] [ebx] \
									modify [eax ebx ecx edx esi edi] \
                  value [eax];

#ifdef __cplusplus
  }
#endif

#endif  // __DEBUG_INCLUDED__