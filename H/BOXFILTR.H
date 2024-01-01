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
; Supports 8 bpp and 32 bpp SLIs. It allocates a buffer for the integral image 
; and stores it in the SLI, if it had not been allocated already.
;
; Input:	EAX -> Input SLI
;         EBX = Multiplier
; Asserts: 
;   Input SLI is 8 bpp
;�����������������������������������������������������������������������������
*/
void CreateIntegralImage(SLI *sli, DWORD multiplier);
#pragma aux CreateIntegralImage "*" parm   [eax] [ebx] \
									modify [eax ebx ecx edx esi edi ebp];

/*
;�����������������������������������������������������������������������������
; For each pixel, computes the integral in a neighborhood and scales it with
; a divider
;
; It supports 8 bpp and 32 bpp SLIs. The integral image must have been generated 
; first for the SLI contents with CreateIntegralImage. The time complexity does 
; not depend on the kernel size, only on the image dimensions. 
;
; Input and output SLIs must be the same size.
;
; Input:	EAX -> Input SLI (CreateIntegralImage must have been called first)
;			EBX = Kernel width (rounded up to odd number)
;     ECX = Kernel height (rounded up to odd number)
;     EDX = log2 of divider; the result for each pixel is divided by this value
;			EDI -> Output SLI
; Asserts: 
;   Input SLI does not have an integral image
;�����������������������������������������������������������������������������
*/
void ScaledBoxIntegral(const SLI *input_sli, DWORD kernel_width, DWORD kernel_height, DWORD log2_divider, SLI *output_sli);
#pragma aux ScaledBoxIntegral "*" parm  [eax] [ebx] [ecx] [edx] [edi] \
									modify [eax ebx ecx edx esi edi ebp];

/*
;�����������������������������������������������������������������������������
; Applies a box filter of the given size on the SLI contents
;
; It supports 8 bpp and 32 bpp SLIs. Input and output SLIs must be the same
; size and type.
;
; The time complexity does not depend on the kernel size, only on the image
; dimensions. 
;
; There's no need to create the integral image before calling this function.
; It will be created internally if needed.
;
; Input:	EAX -> Input SLI
;			EBX = Kernel width (rounded up to odd number)
;     ECX = Kernel height (rounded up to odd number)
;			EDI -> Output SLI
;�����������������������������������������������������������������������������
*/
void BoxFilter(const SLI *input_sli, DWORD kernel_width, DWORD kernel_height, SLI *output_sli);
#pragma aux BoxFilter "*" parm  [eax] [ebx] [ecx] [edi] \
									modify [eax ebx ecx edx esi edi ebp];

#ifdef __cplusplus
  }
#endif

#endif	// BOXFILTR_INCLUDED_