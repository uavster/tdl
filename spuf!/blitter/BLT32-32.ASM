;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Blitter for Nitro's SGL
;       Makes normal and scaled copies of 32bit images to
;       32 bits video buffers
;
; Author: Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code
    INCLUDE blt32-32.inc
    INCLUDE clip.inc
    INCLUDE sli.inc
    INCLUDE alpha.inc

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
; Makes a normal blit from a 32bit SLI to a 32bit one with clipping
;
; INPUT : ESI -> Source 32bit SLI
;         EDI -> Target 32bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitCopy_32_32   proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]

        mov     eax,[esi.SLIFramePtr]
        add     eax,[esi.SOURCE_PTR_INIT]
        push    eax

        mov     ebp,[esi.TARGET_PTR_INC_Y]

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     eax,[esi.SOURCE_PTR_INC_Y]
        mov     ebx,[esi.SOURCE_SIZE_X]

        pop     esi
        copy_32_32_y:
                mov     ecx,ebx
                ; (1 cycle!!)
                rep     movsd
                add     esi,eax
                add     edi,ebp
        dec     CopySourceSizeY
        jnz     copy_32_32_y
        ret
BlitCopy_32_32   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Makes a normal blit from a 32bit SLI to a 32bit one with clipping and
; color masking
;
; INPUT : ESI -> Source 32bit SLI
;         EDI -> Target 32bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitCopyMask_32_32   proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]

        mov     eax,[esi.SLIFramePtr]
        add     eax,[esi.SOURCE_PTR_INIT]
        push    eax

        mov     ebp,[esi.TARGET_PTR_INC_Y]
        mov     CopyTargetIncY,ebp

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     eax,[esi.SOURCE_PTR_INC_Y]
        mov     ebx,[esi.SOURCE_SIZE_X]

        mov     ebp,[esi.SLIMask]
        pop     esi
        copymask_32_32_y:
                mov     ecx,ebx
                copymask_32_32_x:
                        mov     edx,[esi]
                        cmp     edx,ebp
                        jz      dont_copymask
                                mov     [edi],edx
                        dont_copymask:
                        add     esi,4
                        add     edi,4
                dec     ecx
                jnz     copymask_32_32_x
                add     esi,eax
                add     edi,CopyTargetIncY
        dec     CopySourceSizeY
        jnz     copymask_32_32_y
        ret
BlitCopyMask_32_32   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Makes a blit with constant alpha from a 32bit SLI to a 32bit one with
; clipping
;
; INPUT : ESI -> Source 32bit SLI (pixel format 0:B:G:R)
;         EDI -> Target 32bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitAlpha_32_32 proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]

        mov     eax,[esi.SLIFramePtr]
        add     eax,[esi.SOURCE_PTR_INIT]
        push    eax

        mov     ebp,[esi.TARGET_PTR_INC_Y]
        mov     CopyTargetIncY,ebp

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     eax,[esi.SOURCE_PTR_INC_Y]
        mov     CopySourceIncY,eax
        mov     ebx,[esi.SOURCE_SIZE_X]
        mov     CopySourceSizeX,ebx

        mov     eax,ImgAlphaTable
        mov     ebx,BackAlphaTable
        xor     ecx,ecx
        mov     ch,byte ptr [esi.SLIAlpha]      ; Alpha level
        mov     edx,ecx
        add     ecx,eax
        add     edx,ebx
        mov     red_img_table-4,ecx
        mov     red_back_table-4,edx

        xor     ecx,ecx
        mov     ch,byte ptr [esi.SLIAlpha+1]      ; Alpha level
        mov     edx,ecx
        add     ecx,eax
        add     edx,ebx
        mov     green_img_table-4,ecx
        mov     green_back_table-4,edx

        xor     ecx,ecx
        mov     ch,byte ptr [esi.SLIAlpha+2]      ; Alpha level
        mov     edx,ecx
        add     ecx,eax
        add     edx,ebx
        mov     blue_img_table-4,ecx
        mov     blue_back_table-4,edx

        pop     esi
        alpha_32_32_y:
                mov     ebp,CopySourceSizeX
                alpha_32_32_x:
                        xor     ecx,ecx
                        xor     edx,edx
                        mov     eax,[esi]               ; image point
                        mov     ebx,[edi]               ; back point
                        ; mixing red...
                        mov     edx,eax
                        shr     edx,16                  ; image red
                        mov     cl,[edx+12345678h]
                        red_img_table   LABEL dword
                        mov     edx,ebx
                        shr     edx,16                  ; back red
                        add     cl,[edx+12345678h]      ; new image red + new back red
                        red_back_table  LABEL dword 
                        shl     ecx,16
                        ; mixing green...
                        mov     dl,ah                   ; image green
                        mov     ch,[edx+12345678h]
                        green_img_table  LABEL dword
                        mov     dl,bh                   ; back green
                        add     ch,[edx+12345678h]      ; new image green + new back green
                        green_back_table LABEL dword 
                        ; mixing blue...
                        mov     dl,al
                        mov     cl,[edx+12345678h]      ; image blue
                        blue_img_table  LABEL dword 
                        mov     dl,bl                   ; back blue
                        add     esi,4                   ; saving an AGI ;)
                        add     cl,[edx+12345678h]      ; new image blue + new back blue
                        blue_back_table LABEL dword 
                        ; we set the point
                        mov     [edi],ecx
                        add     edi,4
                dec     ebp
                jnz     alpha_32_32_x
                add     esi,CopySourceIncY
                add     edi,CopyTargetIncY
        dec     CopySourceSizeY
        jnz     alpha_32_32_y
        ret
BlitAlpha_32_32 endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Makes a blit with 8 bit alpha map from a 32bit SLI to a 32bit one with
; clipping
;
; INPUT : ESI -> Source 32bit SLI
;         EDI -> Target 32bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitAlphaMap_32_32 proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]

        mov     ebp,[esi.SOURCE_PTR_INIT]

        mov     eax,[esi.TARGET_PTR_INC_Y]
        mov     CopyTargetIncY,eax

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     eax,[esi.SOURCE_PTR_INC_Y]
        shr     eax,2
        mov     CopySourceIncY,eax
        mov     ebx,[esi.SOURCE_SIZE_X]
        mov     CopySourceSizeX,ebx

        mov     ebx,ImgAlphaTable
        mov     red_img_table_map-4,ebx
        mov     green_img_table_map-4,ebx
        mov     blue_img_table_map-4,ebx

        mov     eax,BackAlphaTable
        mov     red_back_table_map-4,eax
        mov     green_back_table_map-4,eax
        mov     blue_back_table_map-4,eax

        mov     eax,[esi.SLIAlpha]
        mov     alpha_ptr-4,eax

        mov     eax,[esi.SLIFramePtr]
        mov     sourcemap_ptr-4,eax
        mov     esi,ebp
        shr     esi,2
        alphamap_32_32_y:
                mov     eax,CopySourceSizeX
                mov     x_iter,eax
                alphamap_32_32_x:
                        xor     ecx,ecx
                        xor     edx,edx
                        xor     ebx,ebx
                        mov     bh,[esi+12345678h]
                        alpha_ptr       LABEL dword
                        mov     eax,[esi*4+12345678h]   ; image point
                        sourcemap_ptr   LABEL dword
                        mov     ebp,[edi]               ; back point
                        ; mixing red...
                        mov     edx,eax
                        shr     edx,16                  ; image red
                        mov     cl,[edx+ebx+12345678h]
                        red_img_table_map   LABEL dword
                        mov     edx,ebp
                        shr     edx,16                  ; back red
                        add     cl,[edx+ebx+12345678h]  ; new image red + new back red
                        red_back_table_map  LABEL dword 
                        shl     ecx,16
                        ; mixing green...
                        mov     dl,ah                   ; image green
                        mov     ch,[edx+ebx+12345678h]
                        green_img_table_map  LABEL dword
                        mov     edx,ebp
                        shr     edx,8
                        xor     dh,dh                   ; back green
                        add     ch,[edx+ebx+12345678h]  ; new image green + new back green
                        green_back_table_map LABEL dword 
                        ; mixing blue...
                        mov     dl,al
                        mov     cl,[edx+ebx+12345678h]  ; image blue
                        blue_img_table_map  LABEL dword 
                        and     ebp,0ffh                ; back blue
                        inc     esi                     ; saving an AGI ;)
                        add     cl,ds:[ebp+ebx+12345678h] ; new image blue + new back blue
                        blue_back_table_map LABEL dword 
                        ; we set the point
                        mov     [edi],ecx
                        add     edi,4
                dec     x_iter
                jnz     alphamap_32_32_x
                add     esi,CopySourceIncY
                add     edi,CopyTargetIncY
        dec     CopySourceSizeY
        jnz     alphamap_32_32_y
        ret
BlitAlphaMap_32_32 endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Makes a blit with constant alpha from a 32bit SLI to a 32bit one with
; clipping and color masking
;
; INPUT : ESI -> Source 32bit SLI
;         EDI -> Target 32bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitAlphaMask_32_32 proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]

        mov     eax,[esi.SLIFramePtr]
        add     eax,[esi.SOURCE_PTR_INIT]
        push    eax

        mov     ebp,[esi.TARGET_PTR_INC_Y]
        mov     CopyTargetIncY,ebp

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     eax,[esi.SOURCE_PTR_INC_Y]
        mov     CopySourceIncY,eax
        mov     ebx,[esi.SOURCE_SIZE_X]
        mov     CopySourceSizeX,ebx

        mov     eax,ImgAlphaTable
        mov     ebx,BackAlphaTable
        xor     ecx,ecx
        mov     ch,byte ptr [esi.SLIAlpha]      ; Alpha level
        mov     edx,ecx
        add     ecx,eax
        add     edx,ebx
        mov     red_img_table_mask-4,ecx
        mov     red_back_table_mask-4,edx

        xor     ecx,ecx
        mov     ch,byte ptr [esi.SLIAlpha+1]      ; Alpha level
        mov     edx,ecx
        add     ecx,eax
        add     edx,ebx
        mov     green_img_table_mask-4,ecx
        mov     green_back_table_mask-4,edx

        xor     ecx,ecx
        mov     ch,byte ptr [esi.SLIAlpha+2]      ; Alpha level
        mov     edx,ecx
        add     ecx,eax
        add     edx,ebx
        mov     blue_img_table_mask-4,ecx
        mov     blue_back_table_mask-4,edx

        mov     eax,[esi.SLIMask]
        mov     color_mask,eax

        pop     esi
        alphamask_32_32_y:
                mov     ebp,CopySourceSizeX
                alphamask_32_32_x:
                        mov     eax,[esi]               ; image point
                        cmp     eax,color_mask
                        jz      skip_color_alpha
                        xor     ecx,ecx
                        xor     edx,edx
                        mov     ebx,[edi]               ; back point
                        ; mixing red...
                        mov     edx,eax
                        shr     edx,16                  ; image red
                        mov     cl,[edx+12345678h]
                        red_img_table_mask   LABEL dword
                        mov     edx,ebx
                        shr     edx,16                  ; back red
                        add     cl,[edx+12345678h]      ; new image red + new back red
                        red_back_table_mask  LABEL dword 
                        shl     ecx,16
                        ; mixing green...
                        mov     dl,ah                   ; image green
                        mov     ch,[edx+12345678h]
                        green_img_table_mask  LABEL dword
                        mov     dl,bh                   ; back green
                        add     ch,[edx+12345678h]      ; new image green + new back green
                        green_back_table_mask LABEL dword 
                        ; mixing blue...
                        mov     dl,al
                        mov     cl,[edx+12345678h]      ; image blue
                        blue_img_table_mask  LABEL dword 
                        mov     dl,bl                   ; back blue
                        add     cl,[edx+12345678h]      ; new image blue + new back blue
                        blue_back_table_mask LABEL dword 
                        ; we set the point
                        mov     [edi],ecx
                        skip_color_alpha:
                        add     edi,4
                        add     esi,4
                dec     ebp
                jnz     alphamask_32_32_x
                add     esi,CopySourceIncY
                add     edi,CopyTargetIncY
        dec     CopySourceSizeY
        jnz     alphamask_32_32_y
        ret
BlitAlphaMask_32_32 endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Makes a blit with 8 bit alpha map from a 32bit SLI to a 32bit one with
; clipping and color masking
;
; INPUT : ESI -> Source 32bit SLI
;         EDI -> Target 32bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitAlphaMapMask_32_32 proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]

        mov     ebp,[esi.SOURCE_PTR_INIT]

        mov     eax,[esi.TARGET_PTR_INC_Y]
        mov     CopyTargetIncY,eax

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     eax,[esi.SOURCE_PTR_INC_Y]
        shr     eax,2
        mov     CopySourceIncY,eax
        mov     ebx,[esi.SOURCE_SIZE_X]
        mov     CopySourceSizeX,ebx

        mov     ebx,ImgAlphaTable
        mov     red_img_table_map_mask-4,ebx
        mov     green_img_table_map_mask-4,ebx
        mov     blue_img_table_map_mask-4,ebx

        mov     eax,BackAlphaTable
        mov     red_back_table_map_mask-4,eax
        mov     green_back_table_map_mask-4,eax
        mov     blue_back_table_map_mask-4,eax

        mov     eax,[esi.SLIAlpha]
        mov     alpha_ptr_mask-4,eax

        mov     eax,[esi.SLIMask]
        mov     color_mask,eax

        mov     eax,[esi.SLIFramePtr]
        mov     sourcemap_ptr_mask-4,eax
        mov     esi,ebp
        shr     esi,2
        jmp alphamapmask_32_32_y
        alphamapmask_32_32_y:
                mov     eax,CopySourceSizeX
                mov     x_iter,eax
                alphamapmask_32_32_x:
                        mov     eax,[esi*4+12345678h]   ; image point
                        sourcemap_ptr_mask   LABEL dword
                        cmp     eax,color_mask
                        jz      skip_color_alphamap
                        xor     ebx,ebx
                        xor     ecx,ecx
                        xor     edx,edx
                        mov     bh,[esi+12345678h]
                        alpha_ptr_mask       LABEL dword
                        mov     ebp,[edi]               ; back point
                        ; mixing red...
                        mov     edx,eax
                        shr     edx,16                  ; image red
                        mov     cl,[edx+ebx+12345678h]
                        red_img_table_map_mask   LABEL dword
                        mov     edx,ebp
                        shr     edx,16                  ; back red
                        add     cl,[edx+ebx+12345678h]  ; new image red + new back red
                        red_back_table_map_mask  LABEL dword 
                        shl     ecx,16
                        ; mixing green...
                        mov     dl,ah                   ; image green
                        mov     ch,[edx+ebx+12345678h]
                        green_img_table_map_mask  LABEL dword
                        mov     edx,ebp
                        shr     edx,8
                        xor     dh,dh                   ; back green
                        add     ch,[edx+ebx+12345678h]  ; new image green + new back green
                        green_back_table_map_mask LABEL dword 
                        ; mixing blue...
                        mov     dl,al
                        mov     cl,[edx+ebx+12345678h]  ; image blue
                        blue_img_table_map_mask  LABEL dword 
                        and     ebp,0ffh                ; back blue
                        add     cl,ds:[ebp+ebx+12345678h] ; new image blue + new back blue
                        blue_back_table_map_mask LABEL dword 
                        ; we set the point
                        mov     [edi],ecx
                        skip_color_alphamap:
                        inc     esi
                        add     edi,4
                dec     x_iter
                jnz     alphamapmask_32_32_x
                add     esi,CopySourceIncY
                add     edi,CopyTargetIncY
        dec     CopySourceSizeY
        jnz     alphamapmask_32_32_y
        ret
BlitAlphaMapMask_32_32 endp

.data?
; ---Blit copy data---
CopySourceSizeX dd ?
CopySourceSizeY dd ?
x_iter          dd ?
CopySourceIncY  dd ?
CopyTargetIncY  dd ?
color_mask      dd ?
; --------------------
end
