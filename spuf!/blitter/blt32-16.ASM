;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Blitter for Nitro's SGL
;       Makes normal and scaled copies of 32 bits images to
;       16 bits video buffers
;
; Author: Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code
    INCLUDE blt32-16.inc
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
; Makes a normal blit from a 32 bits SLI to a 16bit one with
; clipping
;
; INPUT : ESI -> Source 32bit SLI
;         EDI -> Target 16bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitCopy_32_16   proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]
        sub     edi,2

        mov     ebx,[esi.SLIFramePtr]
        add     ebx,[esi.SOURCE_PTR_INIT]

        mov     eax,[esi.SOURCE_PTR_INC_Y]
        mov     CopySourceIncY,eax
        mov     eax,[esi.TARGET_PTR_INC_Y]
        mov     CopyTargetIncY,eax

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     esi,[esi.SOURCE_SIZE_X]
        neg     esi
        copy_32_16_y:
                mov     edx,esi
                sal     edx,1
                sub     edi,edx
                sal     edx,1
                sub     ebx,edx
                sar     edx,2
                copy_32_16_x:
                        ; (10 cycles) <:( -> hate 16 bits
                        mov     eax,[ebx+edx*4]         ; u
                        mov     ecx,eax                 ; u
                        shl     ecx,8                   ; u (to delete highest byte)
                        shr     al,8-5                  ; v
                        shr     ecx,8+8                 ; u
                        and     ch,11111000b            ; u
                        mov     cl,al                   ; v
                        shr     eax,8-5 + 8-6           ; u
                        and     eax,11111100000b        ; u
                        or      ecx,eax                 ; u
                        inc     edx                     ; v
                        mov     [edi+edx*2],cx          ; u ($%& prefix!!)
                jnz     copy_32_16_x                    ; v
                add     ebx,CopySourceIncY
                add     edi,CopyTargetIncY
        dec     CopySourceSizeY
        jnz     copy_32_16_y
        ret
BlitCopy_32_16   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Makes a normal blit from a 32 bits SLI to a 16bit one with
; clipping and color masking
;
; INPUT : ESI -> Source 32bit SLI
;         EDI -> Target 16bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitCopyMask_32_16      proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]
        sub     edi,2

        mov     ebx,[esi.SLIFramePtr]
        add     ebx,[esi.SOURCE_PTR_INIT]

        mov     eax,[esi.SOURCE_PTR_INC_Y]
        mov     CopySourceIncY,eax
        mov     eax,[esi.TARGET_PTR_INC_Y]
        mov     CopyTargetIncY,eax

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     eax,[esi.SOURCE_SIZE_X]
        neg     eax
        mov     CopySourceSizeX,eax

        mov     esi,[esi.SLIMask]
        copymask_32_16_y:
                mov     edx,CopySourceSizeX
                sal     edx,1
                sub     edi,edx
                sal     edx,1
                sub     ebx,edx
                sar     edx,2
                copymask_32_16_x:
                        ; Supposing jump is predicted...
                        ; (non-masked : 12 cycles) <:( -> hate 16 bits
                        ; (masked : 5 cycles)
                        mov     eax,[ebx+edx*4]         ; u
                        cmp     eax,esi                 ; u
                        jz      copymask_avoid          ; v
                        mov     ecx,eax                 ; u
                        shl     ecx,8                   ; u (to delete highest byte)
                        shr     al,8-5                  ; v
                        shr     ecx,8+8                 ; u
                        and     ch,11111000b            ; u
                        mov     cl,al                   ; v
                        shr     eax,8-5 + 8-6           ; u
                        and     eax,11111100000b        ; u
                        or      ecx,eax                 ; u
                        mov     [edi+edx*2],cx          ; u ($%& prefix!!)
                        copymask_avoid:
                        inc     edx                     ; u
                jnz     copymask_32_16_x                ; v
                add     ebx,CopySourceIncY
                add     edi,CopyTargetIncY
        dec     CopySourceSizeY
        jnz     copymask_32_16_y
        ret
BlitCopyMask_32_16      endp


.data?
; ---Blit copy data---
CopyTargetIncY  dd ?
CopySourceIncY  dd ?
CopySourceSizeY dd ?
; --------------------
; ---Blit copy masked data---
CopySourceSizeX dd ?
; --------------------
end
