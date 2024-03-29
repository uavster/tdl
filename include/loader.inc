;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Graphics loader
;
; Author: Ignacio Mellado Bataller (a.k.a. B52 / The DarkRising)
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
        
Loader  STRUC
        TestProc        dd ?
        InitProc        dd ?
        LoadProc        dd ?
        EndProc         dd ?
ENDS

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Parameters for Loader structure procedures
;
;               INPUT                   OUTPUT
;
; TestProc      EDX -> File name        CF = 0 if ok
;                                               EAX = X size of frame
;                                               EBX = Y size of frame
;                                               ECX = Bytes per pixel
;                                               EDX = Number of frames
;                                       CF = 1 if error
;                                               EAX = Error code
;
; InitProc      EDX -> File name        CF = 0 if ok
;                                       CF = 1 if error
;                                               EAX = Error code
;
; LoadProc      ECX = Frame number      CF = 0 if ok
;                     to decompress     CF = 1 if error
;                                               EAX = Error code
;
; EndProc       Nothing                 CF = 0 if ok
;                                       CF = 1 if error
;                                               EAX = Error code
;
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Loads a graphic file into a memory SLI
;
; INPUT  : EAX -> GFX file name
;          EBX = Output SLI color depth (number of bits)
;
; OUTPUT : CF = 0 if success
;               EAX = NULL
;               EBX -> Memory SLI
;          CF = 1 if error
;               EAX = Error code
;               EBX = NULL
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
global  LoadGFX: NEAR
