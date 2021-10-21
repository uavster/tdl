/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
 WUF! C interface
 Author: Ignacio Mellado Bataller a.k.a. B52 / the DarkRising
컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴*/

#ifndef _WAVE_LOAD_INCLUDED_
#define _WAVE_LOAD_INCLUDED_

#include <stddef.h>

#ifdef __cplusplus
  extern "C" {
#endif

typedef struct {
        DWORD WaveType;	// bit 0 : 8/16 bits ,  bit 1 : Mono/Stereo
        void *WavePtr;	// -> Sound data
        DWORD WaveLen;	// Sound length in samples
        DWORD BaseRate;	// Base sample rate
		DWORD LoopStart;	// Sample index where loop starts (included); -1 and -2 are reserved values.
		DWORD LoopEnd;	// Sample index where loop ends (not included); no loop if LoopStart==LoopEnd==-1; -1 and -2 are reserved values.
} TWave;

/*
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Loads a wave file into memory (interfaces with C++)
;
; INPUT  : EAX -> ASCIIZ file name
;		   EBX = Output pointer to error code, or NULL if not needed
;
; OUTPUT : CF = 0 if format found
;               EAX = TWave structure
;				Input pointee contains NO_ERROR
;          CF = 1 otherwise
;               EAX = NULL
;				Input pointee contains error code
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
*/
TWave *WUFLoadWave(const char *file_name, DWORD *error_code);
#pragma aux WUFLoadWave "LoadWAVE_cpp" 	parm [eax] [ebx]\
										modify [eax ebx ecx edx esi edi ebp]\
										value [eax];
								
#ifdef __cplusplus
  };
#endif

#endif