;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; SLI Blitter
;
; Author: Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.386p
.model flat
.code

        INCLUDE stderror.inc

; Number of posible bit distributions
BIT_TYPES       EQU 4   ; 8, 16, 24, 32

; Structure of blitting methodes ( 0 means NOT IMPLEMENTED )
BlitProc        STRUC
        ; Basic methodes
        BlitCopy                dd 0
        BlitAlpha               dd 0
        BlitAlphaMap            dd 0
        BlitAddSaturate         dd 0
        ; Basic methodes with mask
        BlitCopyMask            dd 0
        BlitAlphaMask           dd 0
        BlitAlphaMapMask        dd 0
        Reserved1               dd 0
        ; Basic methodes with scaling
        BlitCopyScaled          dd 0
        BlitAlphaScaled         dd 0
        BlitAlphaMapScaled      dd 0
        Reserved2               dd 0
        ; Basic methodes with scaling and mask
        BlitCopyMaskScaled      dd 0
        BlitAlphaMaskScaled     dd 0
        BlitAlphaMapMaskScaled  dd 0
        Reserved3               dd 0
ENDS

        INCLUDE blitter.inc
        INCLUDE clip.inc
        INCLUDE sli.inc

        INCLUDE blt8-8.inc
        INCLUDE blt8-16.inc
        INCLUDE blt8-24.inc
        INCLUDE blt8-32.inc

        INCLUDE blt24-32.inc

        INCLUDE blt32-16.inc
        INCLUDE blt32-24.inc
        INCLUDE blt32-32.inc

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Returns a pointer to a blitting procedure
;
; INPUT  : ESI -> Source SLI
;          EDI -> Target SLI
;
; OUTPUT : CF = 0 if procedure exists
;               EAX -> Blitting procedure
;          CF = 1 if procedure is NOT implemented
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetBlitProc     proc
        ; Input bits
        mov     eax,[esi.SLIColorBits]
        dec     eax
        imul    eax,BIT_TYPES*size BlitProc
        ; Output bits
        mov     ebx,[edi.SLIColorBits]
        dec     ebx
        imul    ebx,size BlitProc
        add     eax,ebx
        ; Basic methode
        mov     ebx,[esi.SLIBlitType]
        mov     eax,[Blits+eax+ebx*4]
        sub     eax,1   ; CF = 1 if EAX = 0
        inc     eax
        ret
GetBlitProc     endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Makes a blit of source SLI to target SLI
;
; INPUT : ESI -> Source SLI
;         EDI -> Target SLI
;
; OUTPUT : CF = 0 if procedure exists
;          CF = 1 if procedure is NOT implemented
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Blit    proc
        push    ebp
        call    Clip
        jc      no_blit_needed
        call    GetBlitProc
        jc      blit_error
        call    eax
        no_blit_needed:
        pop     ebp
        xor		eax, eax
        clc
        ret

        blit_error:
        pop     ebp
        mov     eax,UNIMPLEMENTED_PROC
        ret
Blit    endp

.data
; Table of blitting methodes
Blits   LABEL

        ; 8 bits -> 8 bits
        BlitProc <offset BlitCopy_8_8,0,0,0,  0,0,0,0, 0,0,0,0, 0,0,0,0>
        ; 8 bits -> 16 bits
        BlitProc <offset BlitCopy_8_16,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0>
        ; 8 bits -> 24 bits
        BlitProc <offset BlitCopy_8_24,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0>
        ; 8 bits -> 32 bits
        BlitProc <offset BlitCopy_8_32,offset BlitAlpha_8_32,offset BlitAlphaMap_8_32,offset BlitAddSaturate_8_32, offset BlitCopyMask_8_32,offset BlitAlphaMask_8_32,offset BlitAlphaMapMask_8_32,0, BlitCopyScaled_8_8,0,0,0, 0,0,0,0>

        ; 16 bits -> 8 bits
        BlitProc <0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0>
        ; 16 bits -> 16 bits
        BlitProc <0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0>
        ; 16 bits -> 24 bits
        BlitProc <0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0>
        ; 16 bits -> 32 bits
        BlitProc <0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0>

        ; 24 bits -> 8 bits
        BlitProc <0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0>
        ; 24 bits -> 16 bits
        BlitProc <0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0>
        ; 24 bits -> 24 bits
        BlitProc <0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0>
        ; 24 bits -> 32 bits
        BlitProc <offset BlitCopy_24_32,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0>

        ; 32 bits -> 8 bits
        BlitProc <0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0>
        ; 32 bits -> 16 bits
        BlitProc <offset BlitCopy_32_16,0,0,0, offset BlitCopyMask_32_16,0,0,0, 0,0,0,0, 0,0,0,0>
        ; 32 bits -> 24 bits
        BlitProc <offset BlitCopy_32_24,0,0,0, offset BlitCopyMask_32_24,0,0,0, 0,0,0,0, 0,0,0,0>
        ; 32 bits -> 32 bits
        BlitProc <offset BlitCopy_32_32,offset BlitAlpha_32_32,offset BlitAlphaMap_32_32,0, offset BlitCopyMask_32_32,offset BlitAlphaMask_32_32,offset BlitAlphaMapMask_32_32,0, 0,0,0,0, 0,0,0,0>

end
