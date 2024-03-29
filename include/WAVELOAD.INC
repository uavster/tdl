;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Wave file loader
;       Ignacio Mellado Bataller ( B52 / the DarkRising )
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

WAVELoader      STRUC
        WLTestProc      dd 0
        WLLoadProc      dd 0
ENDS

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Loads a wave file into memory
;
; INPUT  : EAX -> ASCIIZ file name
;
; OUTPUT : CF = 0 if format found
;               EAX = TWave structure
;          CF = 1 otherwise
;               EAX = Error code
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
global  WUFLoadWAVE : NEAR

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Loads a wave file into memory (interfaces with C++)
;
; INPUT  : EAX -> ASCIIZ file name
;		   EBX = Pointer to output error code, or NULL if not needed
;
; OUTPUT : CF = 0 if format found
;               EAX = TWave structure
;				Input pointee contains NO_ERROR
;          CF = 1 otherwise
;               EAX = NULL
;				Input pointee contains error code
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
global 	LoadWAVE_cpp : NEAR
