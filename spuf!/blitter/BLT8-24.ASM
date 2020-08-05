;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Blitter for Nitro's SGL
;       Makes normal and scaled copies of 8 bits images to
;       24 bits video buffers
;
; Author: Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code
    INCLUDE blt8-24.inc
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
; Makes a normal blit from an 8bit palettized SLI to a 24bit one with
; clipping
;
; INPUT : ESI -> Source 8bit SLI
;         EDI -> Target 24bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitCopy_8_24   proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]
        sub     edi,3

        mov     ebx,[esi.SLIFramePtr]
        add     ebx,[esi.SOURCE_PTR_INIT]

        mov     eax,[esi.SOURCE_PTR_INC_Y]
        mov     CopySourceIncY,eax
        mov     eax,[esi.TARGET_PTR_INC_Y]
        mov     CopyTargetIncY,eax

        lea     ebp,[esi.SLIPalette]

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     esi,[esi.SOURCE_SIZE_X]
        neg     esi
        xor     ecx,ecx
        copy_8_24_y:
                mov     edx,esi
                sub     ebx,edx
                copy_8_24_x:
                        ; All copies are byte-size for aligning
                        ; (6 cycles)
                        mov     cl,[ebx+edx]            ; u
                        add     edi,3                   ; v (avoids AGI)
                        mov     eax,ds:[ebp+ecx*4]      ; u
                        mov     [edi],al                ; u
                        shr     eax,8                   ; u
                        inc     edx                     ; v
                        mov     [edi+1],al              ; u
                        mov     [edi+2],ah              ; v
                jnz     copy_8_24_x                     ; v
                add     ebx,CopySourceIncY
                add     edi,CopyTargetIncY
        dec     CopySourceSizeY
        jnz     copy_8_24_y
        ret
BlitCopy_8_24   endp

.data?
; ---Blit copy data---
CopySourceIncY  dd ?
CopyTargetIncY  dd ?
CopySourceSizeY dd ?
; --------------------
end
