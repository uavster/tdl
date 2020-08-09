; -------
; Assertions
; Author: B52
; -------
JUMPS
.386p
.model flat
.code
public AssertDwordProc

.data
AssertDwordMsg		db 13, 10
					db "AssertDword failed.", 13, 10
					db "Actual: %d"
AssertActualSigned	db "c"
					db "n"
					dd offset AssertDwordActual
					db 13, 10
					db "Expected: %s"
AssertDwordOpOffset	dd ?
					db " %d"
AssertExpectSigned	db "c"					
					db "n"
					dd offset AssertDwordExpected
					db 13, 10, 0
AssertDwordActual	dd ?
AssertDwordExpected	dd ?

AssertDwordOpEq		db "==", 0
AssertDwordOpNe		db "!=", 0
AssertDwordOpGt		db "signed >", 0
AssertDwordOpLt		db "signed <", 0
AssertDwordOpGe		db "signed >=", 0
AssertDwordOpLe		db "signed <=", 0
AssertDwordOpAt		db "unsigned >", 0
AssertDwordOpBt		db "unsigned <", 0
AssertDwordOpAe		db "unsigned >=", 0
AssertDwordOpBe		db "unsigned <=", 0

AssertDwordOpEqOffset dd offset AssertDwordOpEq
AssertDwordOpNeOffset dd offset AssertDwordOpNe
AssertDwordOpGtOffset dd offset AssertDwordOpGt
AssertDwordOpLtOffset dd offset AssertDwordOpLt
AssertDwordOpGeOffset dd offset AssertDwordOpGe
AssertDwordOpLeOffset dd offset AssertDwordOpLe
AssertDwordOpAtOffset dd offset AssertDwordOpAt
AssertDwordOpBtOffset dd offset AssertDwordOpBt
AssertDwordOpAeOffset dd offset AssertDwordOpAe
AssertDwordOpBeOffset dd offset AssertDwordOpBe

.code
INCLUDE utils.inc

AssertDwordExitProc	proc
		mov		esi, offset AssertDwordMsg
		call	printf
		ret
endp

AssertDwordProc	proc
		cmp		eax, ebx
		jmp		[eq_offset+ecx*4]
eq_test:		
		je		no_assert
		jmp		do_assert
ne_test:
		jne		no_assert
		jmp		do_assert
gt_test:
		jg		no_assert
		mov		AssertActualSigned, '-'
		mov		AssertExpectSigned, '-'
		jmp		do_assert
lt_test:
		jl		no_assert
		mov		AssertActualSigned, '-'
		mov		AssertExpectSigned, '-'
		jmp		do_assert
ge_test:
		jge		no_assert
		mov		AssertActualSigned, '-'
		mov		AssertExpectSigned, '-'
		jmp		do_assert
le_test:
		jle		no_assert
		mov		AssertActualSigned, '-'
		mov		AssertExpectSigned, '-'
		jmp		do_assert				
at_test:
		ja		no_assert
		jmp		do_assert
bt_test:
		jb		no_assert
		jmp		do_assert
ae_test:
		jae		no_assert
		jmp		do_assert
be_test:
		jbe		no_assert
		jmp		do_assert				
do_assert:		
				mov		AssertDwordActual, eax
				mov		AssertDwordExpected, ebx
				mov		ecx, ds:[AssertDwordOpEqOffset+4*ecx]
				mov		AssertDwordOpOffset, ecx
				ExitAfterCall AssertDwordExitProc		
		no_assert:
		ret		
eq_offset		dd offset eq_test
ne_offset		dd offset ne_test
; Signed comparisons
gt_offset		dd offset gt_test
lt_offset		dd offset lt_test
ge_offset		dd offset ge_test
le_offset		dd offset le_test
; Unsigned comparison
at_offset		dd offset at_test
bt_offset		dd offset bt_test
ae_offset		dd offset ae_test
be_offset		dd offset be_test
endp

end
