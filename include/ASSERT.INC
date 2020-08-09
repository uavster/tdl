; -------
; Assertions
; Author: B52
; -------

extrn	AssertDwordProc: near

_EQ		EQU 0
_NE		EQU 1
; Signed comparisons
_GTS	EQU 2
_LTS	EQU 3
_GES	EQU 4
_LES	EQU 5
; Unsigned comparisons
_GTU	EQU 6
_LTU	EQU 7
_GEU	EQU 8
_LEU	EQU 9

AssertDword	MACRO actual, operation, expected
		pushf
		pushad
		mov		eax, actual
		mov		ebx, expected
		mov		ecx, operation
		call	AssertDwordProc
		popad
		popfd
ENDM

AssertD EQU AssertDword