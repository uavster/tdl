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
LoadWAVE        proc
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
LoadWAVE        endp

.data
WAVELoaders     dd offset WAVFileLoader

end 
