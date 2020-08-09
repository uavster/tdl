;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Blitter for Nitro's SGL
;       Makes normal and scaled copies of 8 bits images to
;       8 bits video buffers
;
; Author: Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code
    INCLUDE blt8-8.inc
    INCLUDE clip.inc
    INCLUDE sli.inc

; Pseudo-c¢digo del bucle gen‚rico de blitting
comment #
        SOURCE_PTR = SOURCE_PTR_INIT
        TARGET_PTR = TARGET_PTR_INIT                    ; Por clipping

        do (TARGET_SIZE_Y) times {

                do (TARGET_SIZE_X) times {
                        [TARGET_PTR] = [SOURCE_PTR]
                        SOURCE_PTR += SOURCE_PTR_INC_X  ; Por escalado
                        TARGET_PTR++
                }

                SOURCE_PTR += SOURCE_PTR_INC_Y          ; Por escalado
                TARGET_PTR += TARGET_PTR_INC_Y          ; Por clipping
        }
#

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Makes a normal blit from an 8 bits SLI to an 8 bits one with clipping
;
; INPUT : ESI -> Source 8bit SLI
;         EDI -> Target 8bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitCopy_8_8   proc
        mov     eax,[esi.SLIFramePtr]
        add     eax,[esi.SOURCE_PTR_INIT]
        push    eax

        mov     ebp,[esi.TARGET_PTR_INC_Y]

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     eax,[esi.SOURCE_PTR_INC_Y]
        mov     ebx,[esi.SOURCE_SIZE_X]

        ; Need to copy palette, first
        push    edi esi
        mov     ecx,256
        lea     esi,[esi.SLIPalette]
        lea     edi,[edi.SLIPalette]
        rep     movsd           
        pop     esi edi

        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]

        pop     esi
        copy_8_8_y:
                mov     ecx,ebx
                shr     ecx,2
                ; (1 cycle!!)
                rep     movsd
                mov     ecx,ebx
                and     ecx,11b
                rep     movsb
                add     esi,eax
                add     edi,ebp
        dec     CopySourceSizeY
        jnz     copy_8_8_y
        ret
BlitCopy_8_8   endp

.data?
; ---Blit copy data---
CopySourceSizeY dd ?
; --------------------
end
