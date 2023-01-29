/*����������������������������������������������������������������������������
 Include file for box filter functions
����������������������������������������������������������������������������*/

#ifndef BOXFILTR_INCLUDED_
#define BOXFILTR_INCLUDED_

#include <stddef.h>

#ifdef __cplusplus
  extern "C" {
#endif

/*
;�����������������������������������������������������������������������������
; Computes the integral image of a SLI
;
; It allocates a buffer for the integral image and stores it in the SLI, if it
; had not been allocated already.
;
; Input:	EAX -> Input SLI
; Output:	CF = 0, if ok
;				EAX = 0 (NO_ERROR)
;			CF = 1, if error
; 				EAX = Error code
;�����������������������������������������������������������������������������
*/
int CreateIntegralImage(SLI *sli);
#pragma aux CreateIntegralImage "*" parm   [eax] \
									modify [eax ebx ecx edx esi edi ebp] \
									value  [eax];

#ifdef __cplusplus
  }
#endif

#endif	// BOXFILTR_INCLUDED_