;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Polynomial interpolation routines
;
; Author: Ignacio Mellado Bataller (a.k.a. B52 / the DarkRising)
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

POLYDEBUG       EQU 1

CONDITION       STRUC
        Order           dd ?    ; Derivation order
        Value           dd ?    ; f(x0) in Floating point
ENDS

POINTCONDITION  STRUC
        XPoint          dd ?    ; x0
        NumConditions   dd ?    ; Number of conditions for this point
        Conditions      dd ?    ; -> Array of ordered CONDITIONS

        NumEntries      dd ?    ; Filled internally
ENDS

COEFICIENT      STRUC
        PointValue      dd ?
        CoefValue       dd ?
ENDS

POLYNOME        STRUC
        NumCoefs        dd ?
        CoefData        dd ?    ; This is the array of COEFICIENTs that
                                ; is NumCoefs length (it's NOT a pointer)
ENDS

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Finds the coeficients for the minimum order interpolator polynome with
; the given conditions
;
; INPUT  : EAX -> POINTCONDITION array
;          EBX = Number of POINTCONDITIONS
;
; OUTPUT : CF = 0 if ok
;               EAX -> POLYNOME structure
;          CF = 1 if error
;               EAX = NULL
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
global  FindInterPoly : NEAR

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Evaluates an interpolator polynome at a given point
;
; INPUT : EAX = Point (float)
;         EBX -> POLYNOME structure
;
; OUTPUT : EAX = Polynome value (float)
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
global  EvalPoly : NEAR

