;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initialises fast coordinate conversion for typical modes which can be
; calculated as: Y SHL S1 + Y SHL S2 + ...
;
; INPUT -> VideoX = X size of screen buffer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global  FastCoordInit: NEAR

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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
;                           1ÄÄÄÄÄÄ8ÄÄÄÄÄÄ7
;                           ³             ³
;               SCREEN ->   2      0      6
;                           ³             ³
;                           3ÄÄÄÄÄÄ4ÄÄÄÄÄÄ5
;
; OUTPUT -> EAX = linear pointer into video memory
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global  TransCoords: NEAR
