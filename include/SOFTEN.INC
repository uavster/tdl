;ДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДД
; Various buffer interpolation routines
;       by Ignacio Mellado Bataller (a.k.a. B52 / the D@rkRising)
;ДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДД
;ДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДД
; Performs a buffer interpolation with the 8 rounding bytes of each point
;       
;       Interpolation: The center point is calculated as the average
;                      of 'x' points
;               
;                       x x x
;                       x ъ x
;                       x x x
;
; INPUT  -> DS:ESI -> buffer to soften
;           DS:EDI -> buffer where to store result
;           ECX = X size of buffer
;           EDX = Y size of buffer
;
; OUTPUT -> DS:EDI -> buffer softened
;ДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДД
global  soften8: NEAR

;ДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДД
; Performs a buffer interpolation with the 4 corner bytes of each point
;       
;       Interpolation: The center point is calculated as the average
;                      of 'x' points
;               
;                       x   x
;                         ъ  
;                       x   x
;
; INPUT  -> DS:ESI -> buffer to soften
;           DS:EDI -> buffer where to store result
;           ECX = X size of buffer
;           EDX = Y size of buffer
;
; OUTPUT -> DS:EDI -> buffer softened
;ДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДДД
global  soften4: NEAR
