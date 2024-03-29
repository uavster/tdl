;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Initialises fast coordinate conversion for typical modes which can be
; calculated as: Y SHL S1 + Y SHL S2 + ...
;
; INPUT -> VideoX = X size of screen buffer
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
global  FastCoordInit: NEAR

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Transforms the given screen coordinates to a linear pointer into video
; memory
;
; INPUT  -> EAX = X coordinate
;           EBX = Y coordinate
;           ECX = Reference system for coordinates transform
;
;               The number indicates the value of ECX and where the reference
;               system is centered:
;
;                           1컴컴컴8컴컴컴7
;                           �             �
;               SCREEN ->   2      0      6
;                           �             �
;                           3컴컴컴4컴컴컴5
;
; OUTPUT -> EAX = linear pointer into video memory
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
global  TransCoords: NEAR
