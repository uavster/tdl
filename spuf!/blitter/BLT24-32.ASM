;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Blitter for Nitro's SGL
;       Makes normal and scaled copies of 24 bits images to
;       32 bits video buffers
;
; Author: Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code
    INCLUDE blt24-32.inc
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
; Makes a normal blit from an 24 bits SLI to a 32 bits one with
; clipping
;
; INPUT : ESI -> Source 24bit SLI
;         EDI -> Target 32bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitCopy_24_32   proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]
        sub     edi,4

        mov     ebx,[esi.SLIFramePtr]
        add     ebx,[esi.SOURCE_PTR_INIT]

        mov     eax,[esi.SOURCE_PTR_INC_Y]
        mov     CopySourcePtrIncY,eax

        mov     ebp,[esi.TARGET_PTR_INC_Y]

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     esi,[esi.SOURCE_SIZE_X]
        lea     esi,[esi*2+esi]
        neg     esi
        xor     ecx,ecx
        copy_24_32_y:
                mov     edx,esi
                sub     ebx,edx
                copy_24_32_x:
                        ; (6 cycles)
                        xor     ecx,ecx                 ; u
                        mov     cl,[ebx+edx]            ; u
                        mov     ch,[ebx+edx+1]          ; v
                        mov     al,[ebx+edx+2]          ; u
                        add     edi,4                   ; v
                        shl     eax,16                  ; u
                        or      eax,ecx                 ; u
                        add     edx,3                   ; v
                        mov     [edi],eax               ; u
                jnz     copy_24_32_x                    ; v
                add     ebx,CopySourcePtrIncY
                add     edi,ebp
        dec     CopySourceSizeY
        jnz     copy_24_32_y
        ret
BlitCopy_24_32   endp

.data?
; ---Blit copy data---
CopySourceSizeY         dd ?
CopySourcePtrIncY       dd ?
; --------------------
end
