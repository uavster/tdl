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

SCREENX EQU 320
SCREENY EQU 200
CBITS   EQU 16

start:
        InitDPMI
        
        xor     eax,eax
        int     33h
        sub     eax,1
        ErrorExit "This program needs a mouse!"

;        call    InitSGL
;        ErrorExit "Error!"

        mov     eax,SCREENX
        mov     ebx,SCREENY
        mov     ecx,CBITS
        call    CreateVideoSLI
        ErrorExit "Error creating video SLI"
        
        call    InitAlphaFX
        ErrorExit "Error initializing alpha tables"

        mov     eax,offset file_name
        mov     ebx,8
        call    LoadGFX
        ErrorExit "Error loading graphics in 8 bits!"
        mov     dword ptr imagenes,ebx

        mov     eax,ebx
        mov     ebx,CAlpha
        call    SetAlpha

        mov     eax,offset file_name
        mov     ebx,32
        call    LoadGFX
        ErrorExit "Error loading graphics in 32 bits!"
        mov     dword ptr imagenes+4,ebx

        mov     eax,ebx
        mov     ebx,CAlpha
        call    SetAlpha

        mov     eax,320
        mov     ebx,200
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

        mov     ecx,SCREENX
        mov     edx,SCREENY/2
        mov     eax,4
        int     33h

        bucle:
                mov     eax,current_blit
                mov     eax,[eax*4+tipos_de_blit]
                and     eax,3
                cmp     eax,SLIBlitAlphaMap
                jz      par
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
                mov     ebx,back_color
                call    ClearCurrentFrame

                mov     edi,dummy_sli
                mov     esi,source
                call    Blit
                jnc     dont_draw
                        xor     back_color,0ffffffh
                dont_draw:

                pop     edi
                mov     esi,dummy_sli
                call    Blit
                ErrorExit "Error blitting"
                call    ShowPage

                mov     eax,3
                int     33h
                movzx   ecx,cx
                movzx   edx,dx
                mov     esi,source
                shr     ecx,1
                sub     ecx,512/2
                sub     edx,512/2
;                push ecx edx
;                mov eax,source
;                call GetDimensions
;                pop edx ecx
;                shr eax,1
;                shr ebx,1
;                sub ecx,eax
;                sub edx,ebx
                mov     [esi.SLIPos.SLPX],ecx
                mov     [esi.SLIPos.SLPY],edx

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
                        call    ClearCurrentFrame
                        call    ShowPage
                        xor     ah,ah
                        int     16h
                no_es_doce:
                mov     eax,source
                mov     ebx,current_blit
                mov     ebx,[ebx*4+tipos_de_blit]
                call    SetBlitType
                mov     back_color,0ffffffh
                jmp     bucle
        no_space:
        dec     ah
        jnz     bucle

        mov     eax,3
        call    DestroyVideoSLI
        ErrorExit "Error destroying video SLI"

;        call    UnInitSGL

        call    mem_statistix

        Exit

.data
file_name       db "carr03.pcx",0

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
