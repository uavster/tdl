;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Blitter for Nitro's SGL
;       Makes normal and scaled copies of 32 bits images to
;       24 bits video buffers
;
; Author: Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code
    INCLUDE blt32-24.inc
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
; Makes a normal blit from an 32 bits SLI to a 24 bits one with
; clipping
;
; INPUT : ESI -> Source 32bit SLI
;         EDI -> Target 24bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitCopy_32_24   proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]
        sub     edi,3

        mov     ebx,[esi.SLIFramePtr]
        add     ebx,[esi.SOURCE_PTR_INIT]

        mov     ecx,[esi.SOURCE_PTR_INC_Y]
        mov     ebp,[esi.TARGET_PTR_INC_Y]

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     esi,[esi.SOURCE_SIZE_X]
        neg     esi
        copy_32_24_y:
                mov     edx,esi
                sal     edx,2
                sub     ebx,edx
                sar     edx,2
                copy_32_24_x:
                        ; All copies are byte-size for aligning
                        ; This is PERFECT paired like this!!
                        ; (4 cycles)
                        mov     eax,[ebx+edx*4]         ; u
                        add     edi,3                   ; v
                        mov     [edi],al                ; u
                        mov     [edi+1],ah              ; v
                        shr     eax,8                   ; u
                        inc     edx                     ; v
                        mov     [edi+2],ah              ; u
                jnz     copy_32_24_x                    ; v
                add     ebx,ecx
                add     edi,ebp
        dec     CopySourceSizeY
        jnz     copy_32_24_y
        ret
BlitCopy_32_24   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Makes a normal blit from an 32 bits SLI to a 24 bits one with
; clipping and color mask
;
; INPUT : ESI -> Source 32bit SLI
;         EDI -> Target 24bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitCopyMask_32_24      proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]

        mov     ebx,[esi.SLIFramePtr]
        add     ebx,[esi.SOURCE_PTR_INIT]

        mov     ecx,[esi.SOURCE_PTR_INC_Y]
        mov     ebp,[esi.TARGET_PTR_INC_Y]

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     eax,[esi.SOURCE_SIZE_X]
        neg     eax
        mov     CopySourceSizeX,eax

        mov     esi,[esi.SLIMask]
        copymask_32_24_y:
                mov     edx,CopySourceSizeX
                sal     edx,2
                sub     ebx,edx
                sar     edx,2
                copymask_32_24_x:
                        ; All copies are byte-size for aligning
                        ; This is PERFECT paired like this!!
                        ; ( Supposing jump is predicted)
                        ; (non-masked : 6 cycles , masked : 6 cycles)
                        mov     eax,[ebx+edx*4]         ; u
                        cmp     eax,esi                 ; u
                        jz      copymask_avoid          ; v
                        mov     [edi],al                ; u
                        mov     [edi+1],ah              ; v
                        shr     eax,8                   ; u
                        mov     [edi+2],ah              ; u
                        copymask_avoid:
                        add     edi,3                   ; v
                        inc     edx                     ; u
                jnz     copymask_32_24_x                ; v
                add     ebx,ecx
                add     edi,ebp
        dec     CopySourceSizeY
        jnz     copymask_32_24_y
        ret
BlitCopyMask_32_24      endp


.data?
; ---Blit copy data---
CopySourceSizeY dd ?
; --------------------
; ---Blit copy data---
CopySourceSizeX dd ?
; --------------------
end
