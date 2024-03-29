;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; 3D object loader
;
; Author: Ignacio Mellado Bataller (a.k.a. B52 / The DarkRising)
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

UNILoadProcs    STRUC
        UNITestProc     dd ?
        UNILoadProc     dd ?
        UNIEndProc      dd ?
ENDS

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Loads a 3d world
;
; INPUT  : EAX -> File name
; OUTPUT : CF = 0 if ok
;               EAX -> RENDERWORLD structure
;          CF = 1 if error
;               EAX = NULL
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
global  LoadUniverse : NEAR

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Destroys a 3D world
;
; INPUT  : EAX -> RENDERWORLD
;
; OUTPUT : CF = 0 if success
;               EAX = 0
;          CF = 1 if error
;               EAX = Error code
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
global  DestroyUniverse : NEAR
