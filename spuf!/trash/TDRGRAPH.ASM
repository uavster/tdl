;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Generic graphic routines for Nitro!'s SGL
;       by Ignacio Mellado Bataller ( a.k.a. B52 / the D@rkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code
        INCLUDE sgl.inc
        INCLUDE alloc.inc
        INCLUDE tdrgraph.inc

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Copies an 8bit image on a 16bit screen buffer
;
; INPUT -> EAX = X coordinate of the CENTER of the image
;          EBX = Y coordinate of the CENTER of the image
;          ECX = X size of the image
;          EDX = Y size of the image
;          DS:ESI -> source buffer
;          DS:EDI -> destiny buffer
;          DS:EBP -> light table for 8bit to 16bit color conversion
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CopyImage16Cntr  proc
        ; we calculate the X,Y of the upper left corner
        ; (perfect paired like this)
        or      ecx,ecx         ; is any value zero?
        jz      just_leave16_0  ; if so, don't draw anything...
        or      edx,edx
        jz      just_leave16_0
        mov     x_size,ecx
        mov     y_size,edx
        shr     edx,1
        shr     ecx,1   
        sub     ebx,edx
        sub     eax,ecx

        ; now, we need the pointer of the destiny buffer where to start to
        ; copy...
        mov     trash,ebx
        fild    trash           ; that's the Y
        fimul   VideoX          ; X size of a video buffer
        fistp   trash
        add     eax,trash       
        shl     eax,1           ; EAX = start pointer (*2 coz' it's 16 bits)

        ; need to know how to increment the pointer after each scanline
        mov     ebx,VideoX
        sub     ebx,x_size
        shl     ebx,1
        mov     scan_inc,ebx

        ; time to make the copy ;)
        add     edi,eax
        xor     eax,eax
        copy_y16_0:
                mov     ecx,x_size      
                copy_x16_0:
;-Better-for-Pentium---------------------------------------------
;                        xor     ebx,ebx                 ; U
;                        mov     al,[esi]                ; V
;                        mov     bx,ds:[ebp+eax*2]       ; U                        
;                        mov     al,[esi+1]              ; U
;                        add     esi,2                   ; V
;                        mov     dx,ds:[ebp+eax*2]       ; U
;                        shl     edx,16                  ; U
;                        or      edx,ebx                 ; U
;                        mov     [edi],edx               ; U
;                        add     edi,4                   ; V
;-Better-for-486-------------------------------------------------
                        mov     al,[esi]                ; U
                        mov     bx,ds:[ebp+eax*2]       ; U
                        mov     [edi],bx                ; U
                        add     edi,2                   ; U
                        inc     esi                     ; V
                dec     ecx                             ; U
                jnz     copy_x16_0                      ; V
                add     edi,scan_inc
        dec     y_size                 
        jnz     copy_y16_0
        just_leave16_0:
        ret
CopyImage16Cntr  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Fastly mixes an 8bit image on a 16bit screen buffer (specially fast on
; Pentium processors)
;
; INPUT -> EAX = X coordinate of the CENTER of the image
;          EBX = Y coordinate of the CENTER of the image
;          ECX = X size of the image
;          EDX = Y size of the image
;          DS:ESI -> source buffer
;          DS:EDI -> destiny buffer
;          DS:EBP -> light table for 8bit to 16bit color conversion
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
FastMixImage16Cntr  proc
        ; real time code modification
        mov     dword ptr littab_pointer-4,ebp
        ; we calculate the X,Y of the upper left corner
        ; (perfect paired like this)
        or      ecx,ecx         ; is any value zero?
        jz      just_leave16_2  ; if so, don't draw anything...
        or      edx,edx
        jz      just_leave16_2
        mov     x_size,ecx
        mov     y_size,edx
        shr     edx,1
        shr     ecx,1   
        sub     ebx,edx
        sub     eax,ecx

        ; now, we need the pointer of the destiny buffer where to start to
        ; copy...
        mov     trash,ebx
        fild    trash           ; that's the Y
        fimul   VideoX          ; X size of a video buffer
        fistp   trash
        add     eax,trash       
        shl     eax,1           ; EAX = start pointer (*2 coz' it's 16 bits)

        ; need to know how to increment the pointer after each scanline
        mov     ebx,VideoX
        sub     ebx,x_size
        shl     ebx,1
        mov     dword ptr scan_line_increment-4,ebx

        ; time to make the fast mixing ;)
        add     edi,eax
        xor     ecx,ecx
        xor     eax,eax
        xor     edx,edx
        copy_y16_2:
                mov     ebp,x_size      
                copy_x16_2: 
                        mov     al,[esi]      
                        mov     cx,ds:[eax*2+12345678h]
                        littab_pointer:
                        mov     dx,[edi]
                        ; start of color mixing
                        mov     eax,ecx
                        mov     ebx,ecx
                        shr     eax,6+5
                        shr     ebx,5
                        and     eax,11111b      ; source RED
                        and     ebx,111111b     ; source GREEN
                        and     ecx,11111b      ; source BLUE
                        ; BLUE mixing
                        shl     edx,5+6
                        mov     dl,dh
                        shr     dl,3
                        add     cl,dl
                        shr     cl,1
                        ; GREEN mixing
                        shr     edx,6
                        mov     dl,dh
                        shr     dl,2
                        add     bl,dl
                        shr     bl,1
                        ; RED mixing
                        shr     edx,5+6+5
                        add     al,dl
                        shr     al,1
                        ; COLOR = RED<<(6+5) + GREEN<<5 + BLUE
                        shl     eax,6+5
                        shl     ebx,5
                        or      ecx,eax
                        or      ecx,ebx
                        mov     [edi],cx
                        add     edi,2            
                        inc     esi              
                        xor     eax,eax
                dec     ebp                      
                jnz     copy_x16_2                   
                add     edi,12345678h
                scan_line_increment:
        dec     y_size                 
        jnz     copy_y16_2
        just_leave16_2:
        ret
FastMixImage16Cntr  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initializes tables for routines with alpha calculation
;
; OUTPUT -> CF = 0 if succes
;           CF = 1 if not enough memory for tables
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
InitAlphaFX       proc
        ; We want 32Kb for multiplication tables
        mov     ecx,32*1024
        call    malloc
        or      ebx,ebx
        jz      alpha_init_error
        mov     alpha_table,ebx
        mov     dword ptr image_alpha_pointer-4,ebx
        add     ebx,16*1024
        mov     dword ptr back_alpha_pointer-4,ebx
        ; We calculate 2*256 multiplication tables of 64 bytes long for
        ; the front and back image alpha channels
        ; INTENSITY1 = INTENSITY*ALPHA
        ; INTENSITY2 = INTENSITY*(1.0-ALPHA)
        ; NEW_COMPONENT = [ offset ALPHA_TABLE + IMAGE_COMPONENT+64*ALPHA ] +
        ; + [ offset ALPHA_TABLE + 32*1024 + BACK_COMPONENT+64*ALPHA ]
        xor     eax,eax
        xor     edi,edi
        generate_alpha_tables:
                push    eax
                inc     eax
                shl     eax,8  ; 16-bits precision
                mov     ebx,eax
                mov     ecx,10000h
                sub     ecx,eax
                xor     ebp,ebp
                calc_alpha_tab:
                        mov     eax,ebp
                        mul     ebx
                        shr     eax,16
                        mov     [edi+12345678h],al
                        image_alpha_pointer:
                        mov     eax,ebp
                        mul     ecx
                        shr     eax,16
                        mov     [edi+12345678h],al
                        back_alpha_pointer:
                        inc     edi
                inc     ebp
                cmp     ebp,64
                jnz     calc_alpha_tab
                pop     eax
        inc     al
        jnz     generate_alpha_tables
        ; routine fix-ups
        mov     ebx,alpha_table
        mov     dword ptr image_alpha_pointerB-4,ebx
        mov     dword ptr image_alpha_pointerG-4,ebx
        mov     dword ptr image_alpha_pointerR-4,ebx
        add     ebx,16*1024
        mov     dword ptr back_alpha_pointerB-4,ebx
        mov     dword ptr back_alpha_pointerG-4,ebx
        mov     dword ptr back_alpha_pointerR-4,ebx
        clc
        ret

        alpha_init_error:
        stc
        ret
InitAlphaFX       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the current alpha channel map
;
; INPUT -> DS:ESI -> 8bit alpha channel map
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetAlphaMap     proc
        mov     dword ptr alpha_map_pointer-4,esi
        ret
SetAlphaMap     endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Puts an 8bit image on a 16bit screen buffer with a transparency factor from
; the alpha channel map
;
; INPUT -> EAX = X coordinate of the CENTER of the image
;          EBX = Y coordinate of the CENTER of the image
;          ECX = X size of the image
;          EDX = Y size of the image
;          DS:ESI -> source buffer
;          DS:EDI -> destiny buffer
;          DS:EBP -> light table for 8bit to 16bit color conversion
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
PutAlphaMappedImage16Cntr  proc
        mov     dword ptr source_pointer-4,esi
        mov     dword ptr littab_alpha_pointer-4,ebp
        ; we calculate the X,Y of the upper left corner
        ; (perfect paired like this)
        or      ecx,ecx         ; is any value zero?
        jz      just_leave16_3  ; if so, don't draw anything...
        or      edx,edx      
        jz      just_leave16_3
        mov     x_size,ecx
        mov     y_size,edx
        shr     edx,1
        shr     ecx,1   
        sub     ebx,edx
        sub     eax,ecx

        ; now, we need the pointer of the destiny buffer where to start to
        ; copy...
        mov     trash,ebx
        fild    trash           ; that's the Y
        fimul   VideoX          ; X size of a video buffer
        fistp   trash
        add     eax,trash       
        shl     eax,1           ; EAX = start pointer (*2 coz' it's 16 bits)

        ; need to know how to increment the pointer after each scanline
        mov     ebx,VideoX
        sub     ebx,x_size
        shl     ebx,1
        mov     dword ptr scanline_alpha_inc-4,ebx

        ; time to make the copy ;)
        add     edi,eax
        xor     esi,esi
        xor     ecx,ecx
        xor     edx,edx
        ; NEW_COMPONENT = [ offset ALPHA_TABLE + IMAGE_COMPONENT+64*ALPHA ] +
        ; + [ offset ALPHA_TABLE + 32*1024 + BACK_COMPONENT+64*ALPHA ]
        copy_y16_3:
                mov     eax,x_size
                mov     temp_x,eax
                xor     eax,eax
                copy_x16_3: 
                        mov     al,[esi+12345678h]
                        source_pointer:
                        mov     dx,[edi]        ; to avoid AGI
                        mov     bx,[eax*2+12345678h]
                        littab_alpha_pointer:
                        mov     al,[esi+12345678h]      ; AL = ALPHA
                        alpha_map_pointer:
                        shl     eax,6
                        mov     ebp,eax                 ; EBP = ALPHA*64
                        ; image BLUE
                        mov     eax,ebx
                        and     eax,11111b
                        mov     cl,ds:[eax+ebp+12345678h]          
                        image_alpha_pointerB:
                        ; back BLUE
                        mov     eax,edx
                        and     eax,11111b
                        add     cl,ds:[eax+ebp+12345678h]
                        back_alpha_pointerB:
                        ; image GREEN
                        mov     eax,ebx
                        shr     eax,5
                        and     eax,111111b
                        shl     ecx,16          ; to avoid AGI
                        mov     ch,ds:[eax+ebp+12345678h]
                        image_alpha_pointerG:
                        ; back GREEN
                        mov     eax,edx
                        shr     eax,5
                        and     eax,111111b
                        add     ch,ds:[eax+ebp+12345678h]
                        back_alpha_pointerG:
                        ; image RED
                        shr     ebx,6+5
                        shr     edx,6+5         ; to avoid AGI
                        mov     cl,ds:[ebx+ebp+12345678h]
                        image_alpha_pointerR:
                        ; back RED
                        add     cl,ds:[edx+ebp+12345678h]
                        back_alpha_pointerR:
                        ; we have ECX = 0:B:G:R       
                        mov     eax,ecx
                        mov     edx,ecx
                        shr     ecx,16
                        and     ecx,11111b
                        shr     eax,3
                        and     eax,11111100000b
                        or      ecx,eax
                        shl     edx,6+5
                        and     edx,1111100000000000b
                        or      ecx,edx
                        mov     [edi],cx
                        xor     eax,eax
                        add     edi,2            
                        inc     esi              
                dec     temp_x
                jnz     copy_x16_3               
                add     edi,12345678h
                scanline_alpha_inc:
        dec     y_size                 
        jnz     copy_y16_3
        just_leave16_3:
        ret
temp_x  dd ?
PutAlphaMappedImage16Cntr  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Adds an 8bit image to an 8bit screen buffer
;
; INPUT -> EAX = X coordinate of the CENTER of the image
;          EBX = Y coordinate of the CENTER of the image
;          ECX = X size of the image
;          EDX = Y size of the image
;          DS:ESI -> source buffer
;          DS:EDI -> destiny buffer
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
AddImage8Cntr  proc
        ; we calculate the X,Y of the upper left corner
        ; (perfect paired like this)
        or      ecx,ecx         ; is any value zero?
        jz      just_leave16_8  ; if so, don't draw anything...
        or      edx,edx
        jz      just_leave16_8
        mov     x_size,ecx
        mov     y_size,edx
        shr     edx,1
        shr     ecx,1   
        sub     ebx,edx
        sub     eax,ecx

        ; Clipping into a video buffer
        mov     esi_inc,0
        mov     esi_start,0
        mov     ecx,eax
        add     ecx,x_size
        mov     edx,ebx
        add     edx,y_size
        cmp     eax,VideoX
        jb      X0_ok
                or      eax,eax
                jns     just_leave16_8
                sub     esi_start,eax
                xor     eax,eax
        X0_ok:
        cmp     ecx,VideoX
        jb      X1_ok
                or      ecx,ecx
                js      just_leave16_8
                add     esi_inc,ecx                
                mov     ecx,VideoX
                sub     esi_inc,ecx
        X1_ok:
        cmp     ebx,VideoY
        jb      Y0_ok
                or      ebx,ebx
                jns     just_leave16_8
                imul    ebx,x_size  
                sub     esi,ebx
                xor     ebx,ebx
        Y0_ok:
        cmp     edx,VideoY
        jb      Y1_ok
                or      edx,edx
                js      just_leave16_8
                mov     edx,VideoY
        Y1_ok:
        sub     ecx,eax
        jz      just_leave16_8
        mov     x_size,ecx
        sub     edx,ebx
        jz      just_leave16_8
        mov     y_size,edx

        ; now, we need the pointer of the destiny buffer where to start to
        ; copy...
        mov     trash,ebx
        fild    trash           ; that's the Y
        fimul   VideoX          ; X size of a video buffer
        fistp   trash
        add     eax,trash       

        ; need to know how to increment the pointer after each scanline
        mov     ebp,VideoX
        sub     ebp,x_size

        ; time to make the copy ;)
        add     edi,eax
        neg     x_size
        copy_y16_8:
                mov     ecx,x_size
                sub     esi,ecx
                sub     edi,ecx
                add     esi,esi_start
                copy_x16_8: 
                        mov     al,[esi+ecx]
                        mov     dl,[edi+ecx]
                        add     dl,al
                        mov     bl,0
                        sbb     bl,0
                        or      dl,bl
                        mov     [edi+ecx],dl
                inc     ecx             
                jnz     copy_x16_8      
                add     edi,ebp
                add     esi,esi_inc
        dec     y_size
        jnz     copy_y16_8
        just_leave16_8:
        ret
esi_start       dd ?
esi_inc         dd ?
AddImage8Cntr  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; ORs an 8bit image on a 16bit screen buffer
;
; INPUT -> EAX = X coordinate of the CENTER of the image
;          EBX = Y coordinate of the CENTER of the image
;          ECX = X size of the image
;          EDX = Y size of the image
;          DS:ESI -> source buffer
;          DS:EDI -> destiny buffer
;          DS:EBP -> light table for 8bit to 16bit color conversion
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ORImage16Cntr  proc
        ; we calculate the X,Y of the upper left corner
        ; (perfect paired like this)
        or      ecx,ecx         ; is any value zero?
        jz      just_leave16_1  ; if so, don't draw anything...
        or      edx,edx
        jz      just_leave16_1
        mov     x_size,ecx
        mov     y_size,edx
        shr     edx,1
        shr     ecx,1   
        sub     ebx,edx
        sub     eax,ecx

        ; now, we need the pointer of the destiny buffer where to start to
        ; copy...
        mov     trash,ebx
        fild    trash           ; that's the Y
        fimul   VideoX          ; X size of a video buffer
        fistp   trash
        add     eax,trash       
        shl     eax,1           ; EAX = start pointer (*2 coz' it's 16 bits)

        ; need to know how to increment the pointer after each scanline
        mov     ebx,VideoX
        sub     ebx,x_size
        shl     ebx,1
        mov     edx,ebx

        ; time to make the copy ;)
        add     edi,eax
        xor     eax,eax
        copy_y16_1:
                mov     ecx,x_size      
                copy_x16_1: 
                        mov     al,[esi]                ; U
                        mov     bx,ds:[ebp+eax*2]       ; U
                        or      [edi],bx                ; U
                        add     edi,2                   ; U
                        inc     esi                     ; V
                dec     ecx                             ; U
                jnz     copy_x16_1                      ; V
                add     edi,edx
        dec     y_size                 
        jnz     copy_y16_1
        just_leave16_1:
        ret
ORImage16Cntr  endp


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Puts an 8bit image on an 8bit screen buffer with a scale factor
; taking coordinates from the center of the image
;
; INPUT -> EAX = X coordinate of the CENTER of the image
;          EBX = Y coordinate of the CENTER of the image
;          ECX = X size of the image
;          EDX = Y size of the image
;          DS:ESI -> source buffer
;          DS:EDI -> destiny buffer
;
; NOTE: Scale factor is changed with the macro 'SetScaleFactor'
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
PutImage8Cntr   proc
        ; first, we calculate the new dimensions of the image
        mov     x_size,ecx
        mov     x_size0,ecx
        mov     y_size,edx
        fild    x_size
        fmul    scale_factor
        fistp   x_size
        fild    y_size
        fmul    scale_factor
        fistp   y_size

        ; we calculate the X,Y of the upper left corner
        ; (perfect paired like this)
        mov     edx,y_size
        mov     ecx,x_size
        or      ecx,ecx         ; is any value zero?
        jz      just_leave      ; if so, don't draw anything...
        or      edx,edx
        jz      just_leave
        shr     edx,1
        shr     ecx,1   
        sub     ebx,edx
        sub     eax,ecx

        ; now, we need the pointer of the destiny buffer where to start to
        ; copy...
        mov     trash,ebx
        fild    trash           ; that's the Y
        fimul   VideoX          ; X size of a video buffer
        fistp   trash
        add     eax,trash       ; EAX = start pointer

        ; need to know how to increment the pointer after each scanline
        mov     ebx,VideoX
        sub     ebx,x_size
        mov     scan_inc,ebx

        ; time to make the copy ;)
        add     edi,eax
        xor     ebp,ebp
        xor     ebx,ebx
        copy_y:
                push    ebx             
                mov     ecx,x_size      
                mov     trash,ebx
                fild    trash
                fimul   x_size0
                xor     edx,edx         ; FIMUL has 6 cycles of shadow         
                fistp   trash
                mov     ebx,trash
                copy_x:                        
                        mov     al,[esi+ebx]    ; U-pipe
                        add     edx,mantisa     ; V-pipe
                        mov     [edi],al        ; U-pipe
                        adc     ebx,increment   ; V-pipe
                        inc     edi             ; U-pipe
                dec     ecx                     ; V-pipe
                jnz     copy_x                  ; V-pipe - executes after DEC
                pop     ebx             ; U-pipe
                add     ebp,mantisa     ; V-pipe
                adc     ebx,increment   ; U-pipe
                add     edi,scan_inc    ; V-pipe
        dec     y_size                  ; U-pipe 
        jnz     copy_y                  ; V-pipe - executes after DEC
        just_leave:
        ret
PutImage8Cntr   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Puts an 8bit image on a 16bit screen buffer with a scale factor
; taking coordinates from the center of the image
;
; INPUT -> EAX = X coordinate of the CENTER of the image
;          EBX = Y coordinate of the CENTER of the image
;          ECX = X size of the image
;          EDX = Y size of the image
;          DS:ESI -> source buffer
;          DS:EDI -> destiny buffer
;          DS:EBP -> light table for 8bit to 16bit color conversion
;
; NOTE: Scale factor is changed with the macro 'SetScaleFactor'
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
PutImage16Cntr  proc
        ; first, we calculate the new dimensions of the image
        mov     x_size,ecx
        mov     x_size0,ecx
        mov     y_size,edx
        fild    x_size
        fmul    scale_factor
        fistp   x_size
        fild    y_size
        fmul    scale_factor
        fistp   y_size

        ; we calculate the X,Y of the upper left corner
        ; (perfect paired like this)
        mov     edx,y_size
        mov     ecx,x_size
        or      ecx,ecx         ; is any value zero?
        jz      just_leave16    ; if so, don't draw anything...
        or      edx,edx
        jz      just_leave16
        shr     edx,1
        shr     ecx,1   
        sub     ebx,edx
        sub     eax,ecx

        ; now, we need the pointer of the destiny buffer where to start to
        ; copy...
        mov     trash,ebx
        fild    trash           ; that's the Y
        fimul   VideoX          ; X size of a video buffer
        fistp   trash
        add     eax,trash       
        shl     eax,1           ; EAX = start pointer (*2 coz' it's 16 bits)

        ; need to know how to increment the pointer after each scanline
        mov     ebx,VideoX
        sub     ebx,x_size
        shl     ebx,1
        mov     scan_inc,ebx

        ; time to make the copy ;)
        add     edi,eax
        xor     ebx,ebx
        xor     eax,eax
        mov     acumulator,eax
        copy_y16:
                push    ebx             
                mov     ecx,x_size      
                mov     trash,ebx
                fild    trash
                fimul   x_size0
                xor     edx,edx         ; FIMUL has 6 cycles of shadow         
                fistp   trash
                mov     ebx,trash
                copy_x16:                        
                        mov     al,[esi+ebx]     ; U-pipe 
                        add     edx,mantisa      ; V-pipe 
                        mov     ax,ds:[ebp+eax*2]; U-pipe maybe doesn't pair :(
                        adc     ebx,increment    ; V-pipe 
                        mov     [edi],ax         ; U-pipe 
                        add     edi,2            ; V-pipe
                        xor     eax,eax
                dec     ecx                      ; U-pipe 
                jnz     copy_x16                 ; V-pipe - executes after DEC
                mov     ecx,mantisa     ; U-pipe
                pop     ebx             ; V-pipe
                add     acumulator,ecx  ; U-pipe
                adc     ebx,increment   ; U-pipe - depends on previous result
                add     edi,scan_inc    ; V-pipe
        dec     y_size                  ; U-pipe 
        jnz     copy_y16                ; V-pipe - executes after DEC
        just_leave16:
        ret
PutImage16Cntr  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Mixes an 8bit image on a 16bit screen buffer with a transparency factor
; taking coordinates from the upper left corner of the image
;
; INPUT -> EAX = X coordinate of the UPPER LEFT corner of the image
;          EBX = Y coordinate of the UPPER LEFT corner the image
;          ECX = X size of the image
;          EDX = Y size of the image
;          DS:ESI -> source buffer
;          DS:EDI -> destiny buffer
;          DS:EBP -> 8bit palette of the image
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MixImage16      proc
        mov     [pal_ptr-4],ebp
        mov     y_iter,edx
        mov     x_iter0,ecx
        shl     eax,1
        shl     ebx,1
        add     edi,eax
        mov     eax,ebx
        mov     ebx,VideoX
        mul     ebx
        add     edi,eax
        mov     scan_inc,ebx
        sub     scan_inc,ecx
        shl     scan_inc,1
        xor     ebp,ebp
        mix_y:
                mov     eax,x_iter0
                mov     x_iter,eax
                mix_x:
                        xor     eax,eax
                        xor     edx,edx
                        mov     al,[esi]                ; image point
                        mov     bp,[edi]
                        xor     ecx,ecx
                        mov     eax,[eax*4+12345678h]   ; EAX = 0:B:G:R
                        pal_ptr LABEL dword
                        ; mixing red...
                        mov     dl,al                   ; BL = image red (aligned)
                        shr     dl,1
                        mov     ebx,ebp                 ; back point
                        shr     ebx,5+6                 ; EBX = back red
                        shl     ebx,6
                        mov     cl,[edx+ebx+mixing_table]
                        shl     ecx,5+6
                        ; mixing green...
                        xor     bh,bh
                        mov     bl,ah                   ; BL = image green (aligned)
                        mov     edx,ebp                 ; back point
                        and     edx,11111100000b        ; EBX = back green
                        shl     edx,6-5
                        shr     eax,16+1                ; to save an AGI
                        mov     bl,[ebx+edx+mixing_table]; EDX = new image green + new back green
                        shl     ebx,5
                        or      ecx,ebx
                        ; mixing blue...
                        mov     ebx,ebp                  ; back point
                        and     ebx,11111b               ; EBX = back blue
                        shl     ebx,6
                        inc     esi                      ; saving an AGI ;)
                        or      cl,[ebx+eax+mixing_table]; EDX = new image blue + new back blue
                        ; we set the point
                        mov     [edi],cx
                        add     edi,2
                dec     x_iter
                jnz     mix_x
                add     edi,scan_inc
        dec     y_iter
        jnz     mix_y
        ret
MixImage16      endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Modifies the mixing color tables with the specified transparency factor
;
; INPUT -> EAX = fixed point transparency factor with 16bit precission
;                (0 = transparent [0.0] ; 10000h = opaque [1.0])
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetMixingFactor proc
        ; We calculate two 64 bytes multiplication tables
        ; INTENSITY1 = INTENSITY*MIX_FACTOR
        ; INTENSITY2 = INTENSITY*(1.0-MIX_FACTOR)
        mov     ebx,eax
        mov     ecx,10000h
        sub     ecx,eax
        mov     ebp,64
        xor     edi,edi
        calc_mult_tab:
                mov     eax,edi
                mul     ebx
                mov     [edi*4+mult_table1],eax
                mov     eax,edi
                mul     ecx
                mov     [edi*4+mult_table2],eax
                inc     edi
        dec     ebp
        jnz     calc_mult_tab

        ; Now, we need this 4Kb table that will save our cycles
        ; INTENSITY = INTENSITY1+INTENSITY2
        mov     ch,64
        xor     edx,edx
        mov     edi,-1  ; just to optimize inner loop ;)
        calc_mix_tab_v:
                mov     cl,64
                xor     ebx,ebx
                mov     esi,[edx*4+mult_table2]
                calc_mix_tab_u:
                        mov     eax,esi ; calculating next address while doing this
                        inc     edi
                        add     eax,[ebx*4+mult_table1]
                        inc     ebx
                        shr     eax,16
                        mov     [edi+mixing_table],al
                dec     cl
                jnz     calc_mix_tab_u
                inc     edx
        dec     ch
        jnz     calc_mix_tab_v

        ret
SetMixingFactor endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.data
; data together means only one cache line load
mantisa         dd 0
acumulator      dd 0
increment       dd 1
scan_inc        dd 0
y_size          dd 0
x_size          dd 0
trash           dd 0
x_size0         dd 0

scale_factor    dd 1.0
fixpointfactor  dd 10000h
zero            dd 0

.data?

x_iter          dd ?
x_iter0         dd ?
y_iter          dd ?

alpha_table     dd ?    ; address of multiplication table for alpha channels

; multiplication table for image color (16bit precission fixed point)
mult_table1     dd 64 dup(?)
; multiplication table for back color (16bit precission fixed point)
mult_table2     dd 64 dup(?)

; table for component mixing
mixing_table    db 64*64 dup(?)

end
