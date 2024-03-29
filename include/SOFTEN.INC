;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Various buffer interpolation routines
;       by Ignacio Mellado Bataller (a.k.a. B52 / the D@rkRising)
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Performs a buffer interpolation with the 8 rounding bytes of each point
;       
;       Interpolation: The center point is calculated as the average
;                      of 'x' points
;               
;                       x x x
;                       x � x
;                       x x x
;
; INPUT  -> DS:ESI -> buffer to soften
;           DS:EDI -> buffer where to store result
;           ECX = X size of buffer
;           EDX = Y size of buffer
;
; OUTPUT -> DS:EDI -> buffer softened
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
global  soften8: NEAR

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Performs a buffer interpolation with the 4 corner bytes of each point
;       
;       Interpolation: The center point is calculated as the average
;                      of 'x' points
;               
;                       x   x
;                         �  
;                       x   x
;
; INPUT  -> DS:ESI -> buffer to soften
;           DS:EDI -> buffer where to store result
;           ECX = X size of buffer
;           EDX = Y size of buffer
;
; OUTPUT -> DS:EDI -> buffer softened
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
global  soften4: NEAR
