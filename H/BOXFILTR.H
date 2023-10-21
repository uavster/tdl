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

/*
;�����������������������������������������������������������������������������
; Applies a box filter of the given size on the SLI contents
;
; The integral image must have been generated first for the SLI contents
; with CreateIntegralImage. The time complexity only depends on the image 
; dimensions, and it does not depend on the filter size.
;
; Input:	EAX -> Input SLI (CreateIntegralImage must have been called first)
;			EBX = Kernel width (rounded up to odd number)
;     ECX = Kernel height (rounded up to odd number)
;			EDI -> Output SLI
; Output:	
;     CF = 0
;				EAX = 0 (NO_ERROR)
;			CF = 1, if error
; 			EAX = Error code
;				INVALID_PARAMETER: the SLI has no integral image allocated
;�����������������������������������������������������������������������������
*/
void BoxFilter(const SLI *input_sli, int kernel_width, int kernel_height, SLI *output_sli);
#pragma aux BoxFilter "*" parm  [eax] [ebx] [ecx] [edi] \
									modify [eax ebx ecx edx esi edi ebp];
          

#ifdef __cplusplus
  }
#endif

#endif	// BOXFILTR_INCLUDED_