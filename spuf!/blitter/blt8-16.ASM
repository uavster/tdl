;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Blitter for Nitro's SGL
;       Makes normal and scaled copies of 8 bits images to
;       16 bits video buffers
;
; Author: Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code
    INCLUDE blt8-16.inc
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
; Makes a normal blit from an 8bit palettized SLI to a 16bit one with
; clipping
;
; INPUT : ESI -> Source 8bit SLI
;         EDI -> Target 16bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitCopy_8_16   proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]

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
        copy_8_16_y:
                mov     edx,esi
                sub     ebx,edx
                sal     edx,1
                sub     edi,edx
                sar     edx,1
                copy_8_16_x:
                        ; (12 cycles)
                        xor     eax,eax                 ; u
                        mov     al,[ebx+edx]            ; u
                        mov     ecx,ds:[ebp+eax*4]      ; u (AGI!!)
                        mov     eax,ecx                 ; u
                        shl     ecx,8                   ; u (to delete highest byte)
                        shr     al,8-5                  ; u
                        shr     ecx,8+8                 ; v
                        and     ch,11111000b            ; u
                        mov     cl,al                   ; v
                        shr     eax,8-5 + 8-6           ; u
                        and     eax,11111100000b        ; u
                        or      ecx,eax                 ; u
                        mov     [edi+edx*2],cx          ; u (prefix!!)
                inc     edx                             ; u
                jnz     copy_8_16_x                     ; v
                add     ebx,CopySourceIncY
                add     edi,CopyTargetIncY
        dec     CopySourceSizeY
        jnz     copy_8_16_y
        ret
BlitCopy_8_16   endp

.data?
; ---Blit copy data---
CopyTargetIncY  dd ?
CopySourceIncY  dd ?
CopySourceSizeY dd ?
; --------------------
end
