/*
;�����������������������������������������������������������������������������
; Basic graphic routines to draw on SLIs
;
; Author: Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;�����������������������������������������������������������������������������
*/

#ifndef GFX_INCLUDED_
#define GFX_INCLUDED_

#ifdef __cplusplus
  extern "C" {
#endif

/*
;�����������������������������������������������������������������������������
; Draws a 32 bit clipped line on a SLI
;
; INPUT : EAX = x0
;         EBX = y0
;         ECX = x1
;         EDX = y1
;         ESI = color in B:G:R:0 format
;         EDI -> destination SLI
;�����������������������������������������������������������������������������
*/
void DrawLine(SLI *sli, int x0, int y0, int x1, int y1, DWORD bgr);
#pragma aux DrawLine "Line" parm	[edi] [eax] [ebx] [ecx] [edx] [esi]\
							modify	[eax ebx ecx edx esi edi 8087];

#ifdef __cplusplus
  }
#endif

#endif	// GFX_INCLUDED_