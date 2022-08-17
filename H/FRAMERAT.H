#ifndef _FRAMERATE_INCLUDED_
#define _FRAMERATE_INCLUDED_

#include <stddef.h>

#ifdef __cplusplus
  extern "C" {
#endif

/*
;�����������������������������������������������������������������������������
; Starts the frame rate measure (to be called just before the loop)
;�����������������������������������������������������������������������������
*/
void StartFrameRate();
#pragma aux StartFrameRate "*" modify [eax ebx ecx edx ebp esi edi];

/*
;�����������������������������������������������������������������������������
; Increments frame counter (to be called each frame)
;�����������������������������������������������������������������������������
*/
void IncFrameCounter();
#pragma aux IncFrameCounter "*" modify [eax ebx ecx edx ebp esi edi];

/*
;�����������������������������������������������������������������������������
; Stops the frame rate measure (to be called just at the end of the loop)
;�����������������������������������������������������������������������������
*/
void StopFrameRate();
#pragma aux StopFrameRate "*" modify [eax ebx ecx edx ebp esi edi];

/*
;�����������������������������������������������������������������������������
; Shows the frame rate measurement results
;�����������������������������������������������������������������������������
*/
void ShowFrameRateResult();
#pragma aux ShowFrameRateResult "*" modify [eax ebx ecx edx ebp esi edi];

#ifdef __cplusplus
  };
#endif

#endif