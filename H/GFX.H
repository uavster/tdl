/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Basic graphic routines to draw on SLIs
;
; Author: Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

#ifndef GFX_INCLUDED_
#define GFX_INCLUDED_

#ifdef __cplusplus
  extern "C" {
#endif

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Draws a 32 bit clipped line on a SLI
;
; INPUT : EAX = x0
;         EBX = y0
;         ECX = x1
;         EDX = y1
;         ESI = color in B:G:R:0 format
;         EDI -> destination SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void DrawLine(SLI *sli, int x0, int y0, int x1, int y1, DWORD bgr);
#pragma aux DrawLine "Line" parm	[edi] [eax] [ebx] [ecx] [edx] [esi]\
							modify	[eax ebx ecx edx esi edi 8087];

void Soften4(BYTE *in_pixels, int width, int height, BYTE *out_pixels);
#pragma aux Soften4 "soften4" 	parm	[esi] [ecx] [edx] [edi]\
								modify	[eax ebx ecx edx esi edi];

void Soften8(BYTE *in_pixels, int width, int height, BYTE *out_pixels);
#pragma aux Soften8 "soften8" 	parm	[esi] [ecx] [edx] [edi]\
								modify	[eax ebx ecx edx esi edi];
								
#ifdef __cplusplus
  }
#endif

#endif	// GFX_INCLUDED_