;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Clipping between SLIs for normal and scaled images in 8,16,24 & 32 bits
;
; Author: Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

; Öndices a variables locales del bucle gen‚rico 
SOURCE_PTR_INIT         EQU SLITemp.tmp1
TARGET_PTR_INIT         EQU SLITemp.tmp2
SOURCE_SIZE_Y           EQU SLITemp.tmp3
SOURCE_SIZE_X           EQU SLITemp.tmp4
SOURCE_PTR_INC_X        EQU SLITemp.tmp5	; Fixed point 16.16 coordinate increment, if scaled; integer pointer increment, otherwise.
SOURCE_PTR_INC_Y        EQU SLITemp.tmp6	; Fixed point 16.16 coordinate increment, if scaled; integer pointer increment, otherwise.
TARGET_PTR_INC_Y        EQU SLITemp.tmp7
;TARGET_PTR_INC_Y1       EQU SLITemp.tmp8        ; X size in bytes


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Performs clipping of input buffer into output buffer
;
; INPUT  -> ESI -> Input SLI header
;           EDI -> Output SLI header
;
; OUTPUT -> CF = 0 if some part of image is drawn
;                Input SLI temporary variables filled
;           CF = 1 if image is hidden
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global Clip: NEAR
