.386p
.model flat
.stack 1000h
.code
        INCLUDE utils.inc
        INCLUDE blitter.inc
        INCLUDE sli.inc
        INCLUDE alloc.inc
        INCLUDE newsgl.inc
        INCLUDE coolpal.inc
        INCLUDE loader.inc
        INCLUDE clip.inc
        INCLUDE assert.inc

SCREENX EQU 320
SCREENY EQU 200
CBITS   EQU 32

start:
        InitDPMI
                
        xor     eax,eax
        int     33h
        sub     eax,1
        ErrorExit "This program needs a mouse!"
	
        mov     eax,offset file_name
        mov     ebx,8
        call    LoadGFX
        ErrorExit "Error loading graphics in 8 bits!"
        mov     dword ptr imagenes,ebx

        mov     eax,ebx
        mov     bl,SLIAnimForwardLoop
        call	SetAnimMode        

        mov     ebx,CAlpha
        call    SetAlpha
        
        mov     eax,offset file_name        
        mov     ebx,32
        call    LoadGFX
        ErrorExit "Error loading graphics in 32 bits!"
        mov     dword ptr imagenes+4,ebx

        mov     eax,dword ptr imagenes+4
        mov     bl,SLIAnimForwardLoop
        call	SetAnimMode
        
        ; TODO: Handle loop end < loop start
;        mov		ebx,3
;        call	SetAnimLoopStartFrame
                
;        mov		eax,dword ptr imagenes
;        mov		ebx,10
;        call	SetAnimLoopEndFrame
        
;        mov		eax,dword ptr imagenes+4
;        mov		ebx,10
;        call	SetAnimLoopEndFrame
        
        mov     ebx,CAlpha
        call    SetAlpha

        mov     eax,[imagenes+4]
        mov		ebx,[eax.SLIYSize]
        mov		eax,[eax.SLIXSize]
        mov     ecx,32
        mov     edx,1
        call    CreateSLI
        ErrorExit "Error creating dummy SLI"
        mov     dummy_sli,ebx

        mov     eax,im_bits
        mov     eax,[imagenes+eax*4]
        mov     source,eax

        mov     ebx,current_blit
        mov     ebx,[ebx*4+tipos_de_blit]
        call    SetBlitType
        
        mov     eax,SCREENX
        mov     ebx,SCREENY
        mov     ecx,CBITS
        call    CreateVideoSLI
        ErrorExit "Error creating video SLI"
                
        mov     ecx,SCREENX
        mov     edx,SCREENY/2
        mov     eax,4
        int     33h
		
        bucle:
                mov     eax,current_blit
                mov     eax,[eax*4+tipos_de_blit]
                and     eax,3
                cmp     eax,SLIBlitAlphaMap
                je      par
                        inc     byte ptr CAlpha
                        inc     byte ptr CAlpha+1
                        inc     byte ptr CAlpha+2
                        mov     ebx,CAlpha
                        jmp     set_alpha
                par:
                        mov     eax,dword ptr imagenes
                        call    GetCurrentFramePtr
                        mov     ebx,eax
                set_alpha:
                mov     eax,dword ptr imagenes+4
                push    ebx
                call    SetAlpha
                pop     ebx
                mov     eax,dword ptr imagenes
                call    SetAlpha

                call    GetVideoSLI
                push    eax
                
                mov     eax,dummy_sli
                mov		ebx, back_color
                call    ClearCurrentFrame
                
                mov     esi,source
                mov     edi,dummy_sli
                call    Blit
                jnc     dont_draw
                        xor     back_color,0ffffffh
                dont_draw:                
				call	GetSyncTimerTicks
                push	eax
                mov		esi,dword ptr imagenes+4
                call	AnimateSLIWithTicks                
                pop		eax
                mov		esi,dword ptr imagenes
                call	AnimateSLIWithTicks                

                pop     edi
                mov     esi,dummy_sli
                call    Blit
                ErrorExit "Error blitting"

                call    ShowVideoSLI

                mov     eax,3
                int     33h
                movzx   ecx,cx
                movzx   edx,dx
                mov     edi,source
                shr     ecx,1
                push    ecx edx edi
                mov     eax,source
                call    GetDimensions
                pop     edi edx ecx
                shr     eax,1
                shr     ebx,1
                sub     eax,ecx
                sub     ebx,edx
                neg     eax
                neg     ebx
                call    SetPos

        mov     ah,1
        int     16h
        jz      bucle
        xor     ah,ah
        int     16h
        cmp     al,' '
        jnz     no_space
                inc     current_blit
                cmp     current_blit,3*4
                jnz     no_es_doce
                        mov     current_blit,0
                        inc     im_bits
                        and     im_bits,1
                        mov     ebx,im_bits
                        mov     ebx,[imagenes+ebx*4]
                        mov     source,ebx
                        call    GetVideoSLI
                        mov     ebx,808080h
                        push    eax
                        call    ClearCurrentFrame
                        call    ShowPage
                        xor     ah,ah
                        int     16h
                        mov     ebx,0
                        pop     eax
                        call    ClearCurrentFrame
                no_es_doce:
                mov     eax,source
                mov     ebx,current_blit
                mov     ebx,[ebx*4+tipos_de_blit]
                call    SetBlitType
                mov     back_color,0ffffffh
                jmp     bucle
        no_space:
        cmp		al,'+'
        jnz		no_plus
				mov     eax,source
				call	GetFrame
				mov		ebx,eax
				inc		ebx
				mov		eax,source
				call	SetFrame
				ErrorExit "Error setting frame"
				jmp bucle
        no_plus:
        cmp		al,'-'
        jnz		no_minus
				mov     eax,source
				call	GetFrame
				mov		ebx,eax
				dec		ebx
				mov		eax,source
				call	SetFrame
				ErrorExit "Error setting frame"
				jmp bucle
        no_minus:
        dec     ah
        jnz     bucle

        mov     eax,3
        call    DestroyVideoSLI
        ErrorExit "Error destroying video SLI"

        ExitAfterCall mem_statistix

.data
file_name       db "bball.fli",0
;file_name       db "carr03.pcx",0

CAlpha          dd 0ffffffh

back_color      dd 0ffffffh

im_bits         dd 1
imagenes        dd ?,?

current_blit    dd 0
tipos_de_blit   dd SLIBlitCopy,SLIBlitAlpha,SLIBlitAlphaMap
                dd SLIBlitCopy+SLIMaskedColor,SLIBlitAlpha+SLIMaskedColor,SLIBlitAlphaMap+SLIMaskedColor
                dd SLIBlitCopy+SLIScaled,SLIBlitAlpha+SLIScaled,SLIBlitAlphaMap+SLIScaled
                dd SLIBlitCopy+SLIScaled+SLIMaskedColor,SLIBlitAlpha+SLIScaled+SLIMaskedColor,SLIBlitAlphaMap+SLIScaled+SLIMaskedColor

.data?
im_list         dd ?

dummy_sli       dd ?

back            dd ?

source  dd ?
target  dd ?
kk_de_vak       dd ?

end start
