;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Generical graphic routines for Nitro!'s SGL
;       by Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

global  InitAlphaFX: NEAR
global  SetAlphaMap: NEAR
global  PutAlphaMappedImage16Cntr: NEAR

global  AddImage8Cntr: NEAR

global  CopyImage16Cntr: NEAR
global  FastMixImage16Cntr: NEAR
global  ORImage16Cntr: NEAR

global  PutImage8Cntr: NEAR
global  PutImage16Cntr: NEAR

global  MixImage16: NEAR
global  SetMixingFactor: NEAR

global  scale_factor: DWORD
global  fixpointfactor: DWORD
global  increment: DWORD
global  mantisa: DWORD
global  zero: DWORD

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Changes the scale factor applied to the other functions
; 
; INPUT -> ST(0) = floating point scale factor
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetScaleFactor  MACRO
LOCAL   invalid_scale
        fstp    scale_factor
        fld     zero
        fcomp   scale_factor
        fstsw   ax
        sahf
        jae     invalid_scale
        fld1
        fdiv    scale_factor
        fimul   fixpointfactor  ; we have fixed point with 16bit precission
        fist    increment
        shr     increment,16
        fistp   mantisa
        shl     mantisa,16
        invalid_scale:
ENDM

