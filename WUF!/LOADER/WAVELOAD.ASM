;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Wave file loader
;       Ignacio Mellado Bataller ( B52 / the DarkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code

        NUM_WAVE_FORMATS        EQU 1

        INCLUDE waveload.inc
        INCLUDE wav.inc
        INCLUDE stderror.inc

        INCLUDE utils.inc

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Loads a wave file into memory
;
; INPUT  : EAX -> ASCIIZ file name
;
; OUTPUT : CF = 0 if format found
;               EAX = TWave structure
;          CF = 1 otherwise
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFLoadWAVE        proc
        mov     ecx,NUM_WAVE_FORMATS
        mov     esi,offset WAVELoaders
        find_format:
                mov     ebx,[esi]
                push    eax ebx ecx
                call    [ebx.WLTestProc]
                pop     ecx ebx eax
                jnc     found_loader
                add     esi,4
        loop    find_format
        mov     eax,INVALID_FORMAT
        stc
        ret

        found_loader:
        call    [ebx.WLLoadProc]
        ret
WUFLoadWAVE        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Loads a wave file into memory (interfaces with C++)
;
; INPUT  : EAX -> ASCIIZ file name
;		   EBX = Pointer to output error code, or NULL if not needed
;
; OUTPUT : If no error,
;               EAX = TWave structure
;				Input pointee contains NO_ERROR
;          If error,
;               EAX = NULL
;				Input pointee contains error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
LoadWAVE_cpp	proc
	push	ebx
	call	WUFLoadWAVE
	pop		ebx
	jc		load_wave_error
	test	ebx,ebx
	jz		error_code_skipped
	mov		dword ptr [ebx],NO_ERROR
	ret
	
	load_wave_error:
	test	ebx,ebx
	jz		error_code_skipped
	mov		[ebx],eax
	xor		eax,eax
	error_code_skipped:
	ret
LoadWAVE_cpp	endp

.data
WAVELoaders     dd offset WAVFileLoader

end 
