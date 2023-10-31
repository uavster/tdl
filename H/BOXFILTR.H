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
;         EBX = Multiplier
; Throws: 
;   Input SLI is not 8bpp
;�����������������������������������������������������������������������������
*/
int CreateIntegralImage(SLI *sli, DWORD multiplier);
#pragma aux CreateIntegralImage "*" parm   [eax] [ebx] \
									modify [eax ebx ecx edx esi edi ebp];

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
; Throws: 
;   Input SLI does not have an integral image
;�����������������������������������������������������������������������������
*/
void BoxFilter(const SLI *input_sli, int kernel_width, int kernel_height, SLI *output_sli);
#pragma aux BoxFilter "*" parm  [eax] [ebx] [ecx] [edi] \
									modify [eax ebx ecx edx esi edi ebp];
          

#ifdef __cplusplus
  }
#endif

#endif	// BOXFILTR_INCLUDED_