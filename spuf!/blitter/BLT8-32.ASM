;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Blitter for Nitro's SGL
;       Makes normal and scaled copies of 8bit images to
;       32 bits video buffers
;
; Author: Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code
    INCLUDE blt8-32.inc
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
; Makes a normal blit from an 8bit palettized SLI to a 32bit one with
; clipping
;
; INPUT : ESI -> Source 8bit SLI
;         EDI -> Target 32bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitCopy_8_32   proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]
        sub     edi,4

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
        copy_8_32_y:
                mov     edx,esi
                sub     ebx,edx
                copy_8_32_x:
                        ; All copies are byte-size for aligning
                        ; PERFECT paired like this!!
                        ; (3 cycles)
                        mov     cl,[ebx+edx]            ; u
                        add     edi,4                   ; v (avoids AGI)
                        mov     eax,ds:[ebp+ecx*4]      ; u
                        inc     edx                     ; v
                        mov     [edi],eax               ; u
                jnz     copy_8_32_x                     ; v
                add     ebx,CopySourceIncY
                add     edi,CopyTargetIncY
        dec     CopySourceSizeY
        jnz     copy_8_32_y
        ret
BlitCopy_8_32   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Makes a normal blit from an 8bit palettized SLI to a 32bit one with
; clipping and color masking
;
; INPUT : ESI -> Source 8bit SLI
;         EDI -> Target 32bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitCopyMask_8_32       proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]
        sub     edi,4

        mov     ebx,[esi.SLIFramePtr]
        add     ebx,[esi.SOURCE_PTR_INIT]

        mov     eax,[esi.SOURCE_PTR_INC_Y]
        mov     CopySourceIncY,eax
        mov     eax,[esi.TARGET_PTR_INC_Y]
        mov     CopyTargetIncY,eax

        lea     ebp,[esi.SLIPalette]

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     eax,[esi.SOURCE_SIZE_X]
        neg     eax
        mov     CopySourcePtrX,eax
        mov     esi,[esi.SLIMask]
        xor     ecx,ecx
        copymask_8_32_y:
                mov     edx,CopySourcePtrX
                sub     ebx,edx
                copymask_8_32_x:
                        ; All copies are byte-size for aligning
                        ; PERFECT paired like this!!
                        ; (3 cycles)
                        mov     cl,[ebx+edx]
                        add     edi,4                   ; (avoids AGI)
                        mov     eax,ds:[ebp+ecx*4]
                        cmp     eax,esi
                        jz      dont_copymask
                        mov     [edi],eax 
                        dont_copymask:
                        inc     edx
                jnz     copymask_8_32_x
                add     ebx,CopySourceIncY
                add     edi,CopyTargetIncY
        dec     CopySourceSizeY
        jnz     copymask_8_32_y
        ret
BlitCopyMask_8_32       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Makes a blit with constant alpha from an 8bit SLI to a 32bit one with
; clipping
;
; INPUT : ESI -> Source 8bit SLI
;         EDI -> Target 32bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitAlpha_8_32 proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]

        lea     eax,[esi.SLIPalette]
        mov     dword ptr alpha_pal_ptr-4,eax

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
        alpha_8_32_y:
                mov     ebp,CopySourceSizeX
                alpha_8_32_x:
                        xor     ecx,ecx
                        xor     edx,edx
                        mov     dl,[esi]               ; image point
                        mov     eax,[edx*4+12345678h]
                        alpha_pal_ptr   LABEL dword
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
                        inc     esi                     ; saving an AGI ;)
                        add     cl,[edx+12345678h]      ; new image blue + new back blue
                        blue_back_table LABEL dword 
                        ; we set the point
                        mov     [edi],ecx
                        add     edi,4
                dec     ebp
                jnz     alpha_8_32_x
                add     esi,CopySourceIncY
                add     edi,CopyTargetIncY
        dec     CopySourceSizeY
        jnz     alpha_8_32_y
        ret
BlitAlpha_8_32 endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Makes a blit with 8 bit alpha map from an 8bit SLI to a 32bit one with
; clipping
;
; INPUT : ESI -> Source 8bit SLI
;         EDI -> Target 32bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitAlphaMap_8_32 proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]

        lea     eax,[esi.SLIPalette]
        mov     dword ptr alphamap_pal_ptr-4,eax

        mov     eax,[esi.TARGET_PTR_INC_Y]
        mov     CopyTargetIncY,eax

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     eax,[esi.SOURCE_PTR_INC_Y]
        mov     CopySourceIncY,eax
        mov     ebx,[esi.SOURCE_SIZE_X]
        mov     CopySourceSizeX,ebx

        mov     eax,[esi.SLIAlpha]
        mov     alpha_ptr-4,eax

        mov     ebx,ImgAlphaTable
        mov     red_img_table_map-4,ebx
        mov     green_img_table_map-4,ebx
        mov     blue_img_table_map-4,ebx

        mov     eax,BackAlphaTable
        mov     red_back_table_map-4,eax
        mov     green_back_table_map-4,eax
        mov     blue_back_table_map-4,eax

        mov     eax,[esi.SLIFramePtr]
        mov     sourcemap_ptr-4,eax

        mov     esi,[esi.SOURCE_PTR_INIT]
        alphamap_8_32_y:
                mov     eax,CopySourceSizeX
                mov     x_iter,eax
                alphamap_8_32_x:
                        xor     edx,edx
                        xor     ebx,ebx
                        mov     bh,[esi+12345678h]
                        alpha_ptr       LABEL dword
                        mov     dl,[esi+12345678h]     ; image point
                        sourcemap_ptr   LABEL dword
                        xor     ecx,ecx
                        mov     eax,[edx*4+12345678h]
                        alphamap_pal_ptr LABEL dword 
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
                jnz     alphamap_8_32_x
                add     esi,CopySourceIncY
                add     edi,CopyTargetIncY
        dec     CopySourceSizeY
        jnz     alphamap_8_32_y
        ret
BlitAlphaMap_8_32 endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Makes a blit with constant alpha from an 8bit SLI to a 32bit one with
; clipping and color masking
;
; INPUT : ESI -> Source 8bit SLI
;         EDI -> Target 32bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitAlphaMask_8_32 proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]

        lea     eax,[esi.SLIPalette]
        mov     dword ptr alpha_pal_ptr_mask-4,eax

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
        alphamask_8_32_y:
                mov     ebp,CopySourceSizeX
                alphamask_8_32_x:
                        xor     edx,edx
                        mov     dl,[esi]               ; image point
                        mov     eax,[edx*4+12345678h]
                        alpha_pal_ptr_mask   LABEL dword
                        cmp     eax,color_mask
                        jz      skip_alphamask
                        xor     ecx,ecx
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
                        skip_alphamask:
                        inc     esi
                        add     edi,4
                dec     ebp
                jnz     alphamask_8_32_x
                add     esi,CopySourceIncY
                add     edi,CopyTargetIncY
        dec     CopySourceSizeY
        jnz     alphamask_8_32_y
        ret
BlitAlphaMask_8_32 endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Makes a blit with 8 bit alpha map from an 8bit SLI to a 32bit one with
; clipping and color masking
;
; INPUT : ESI -> Source 8bit SLI
;         EDI -> Target 32bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitAlphaMapMask_8_32 proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]

        lea     eax,[esi.SLIPalette]
        mov     dword ptr alphamap_pal_ptr_mask-4,eax

        mov     eax,[esi.TARGET_PTR_INC_Y]
        mov     CopyTargetIncY,eax

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     eax,[esi.SOURCE_PTR_INC_Y]
        mov     CopySourceIncY,eax
        mov     ebx,[esi.SOURCE_SIZE_X]
        mov     CopySourceSizeX,ebx

        mov     eax,[esi.SLIAlpha]
        mov     alpha_ptr_mask-4,eax

        mov     ebx,ImgAlphaTable
        mov     red_img_table_map_mask-4,ebx
        mov     green_img_table_map_mask-4,ebx
        mov     blue_img_table_map_mask-4,ebx

        mov     eax,BackAlphaTable
        mov     red_back_table_map_mask-4,eax
        mov     green_back_table_map_mask-4,eax
        mov     blue_back_table_map_mask-4,eax

        mov     eax,[esi.SLIFramePtr]
        mov     sourcemap_ptr_mask-4,eax

        mov     eax,[esi.SLIMask]
        mov     color_mask,eax

        mov     esi,[esi.SOURCE_PTR_INIT]
        alphamapmask_8_32_y:
                mov     eax,CopySourceSizeX
                mov     x_iter,eax
                alphamapmask_8_32_x:
                        xor     edx,edx
                        mov     dl,[esi+12345678h]     ; image point
                        sourcemap_ptr_mask   LABEL dword
                        mov     eax,[edx*4+12345678h]
                        alphamap_pal_ptr_mask LABEL dword
                        cmp     eax,color_mask
                        jz      skip_color_alphamap
                        xor     ecx,ecx
                        xor     ebx,ebx
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
                jnz     alphamapmask_8_32_x
                add     esi,CopySourceIncY
                add     edi,CopyTargetIncY
        dec     CopySourceSizeY
        jnz     alphamapmask_8_32_y
        ret
BlitAlphaMapMask_8_32 endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Makes a blit with 8 bit alpha map from an 8bit SLI to a 32bit one with
; clipping
;
; INPUT : ESI -> Source 8bit SLI
;         EDI -> Target 32bit SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BlitAddSaturate_8_32 proc
        mov     edi,[edi.SLIFramePtr]
        add     edi,[esi.TARGET_PTR_INIT]

        lea     eax,[esi.SLIPalette]
        mov     dword ptr sourceimg8_pal_ptr-4,eax

        mov     eax,[esi.TARGET_PTR_INC_Y]
        mov     CopyTargetIncY,eax

        mov     eax,[esi.SOURCE_SIZE_Y]
        mov     CopySourceSizeY,eax

        mov     eax,[esi.SOURCE_PTR_INC_Y]
        mov     CopySourceIncY,eax
        mov     ebx,[esi.SOURCE_SIZE_X]
        mov     CopySourceSizeX,ebx

        mov     eax,[esi.SLIFramePtr]
        mov     sourceimg8_ptr-4,eax

        mov     esi,[esi.SOURCE_PTR_INIT]
        addsaturate_8_32_y:
                mov     ecx,CopySourceSizeX
				; Inner loop total cycles: 97+m (386), 45 (486)
                addsaturate_8_32_x:
                        xor     eax,eax	; 2 (386), 1 (486)
                        mov     al,[esi+12345678h]		; 4, 1
                        sourceimg8_ptr   LABEL dword	; eax = source image pixel
                        mov     ebx,[edi]               ; ebp = ARGB of destination image ; 4, 1
                        mov     eax,[eax*4+12345678h]	; 4, 1
                        sourceimg8_pal_ptr LABEL dword	; eax = ARGB of source image
                        
						; Blue channel.
						add 	al,bl	; 2, 1
						rcr 	dh,1	; 9, 3
						sar 	dh,7	; 3, 2
						or		al,dh	; 2, 1
						ror		eax,8	; 3, 2
						
						; Green channel.
						shr		ebx,8	; 3, 2
						add 	al,bl	; 2, 1
						rcr 	dh,1	; 9, 3
						sar 	dh,7	; 3, 2
						or		al,dh	; 2, 1
						ror		eax,8	; 3, 2
						
						; Red channel.
						shr		ebx,8	; 3, 2
						add 	al,bl	; 2, 1
						rcr 	dh,1	; 9, 3
						sar 	dh,7	; 3, 2
						or		al,dh	; 2, 1
						ror		eax,16	; 3, 2
						
						; Alpha channel.
						; mov		al,0ffh	; 2, 1
						; ror		eax,8	; 3, 2
						
                        mov     [edi],eax	; 2, 1
						
                        inc     esi		; 2, 1
                        add     edi,4	; 2, 1
                dec     ecx				; 2, 1
                jnz     addsaturate_8_32_x	; 7+m, 3
				
                add     esi,CopySourceIncY
                add     edi,CopyTargetIncY
        dec     CopySourceSizeY
        jnz     addsaturate_8_32_y
        ret
BlitAddSaturate_8_32 endp

.data?
; ---Blit copy data---
CopySourceIncY  dd ?
CopyTargetIncY  dd ?
CopySourceSizeY dd ?
CopySourceSizeX dd ?
x_iter          dd ?
color_mask      dd ?
; --------------------
CopySourcePtrX  dd ?
end
