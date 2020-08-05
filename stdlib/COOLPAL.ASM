;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Palette routines for generic purposes
;       by Ignacio Mellado Bataller (a.k.a. B52 / the D@rkRising)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

JUMPS
.386p
.model flat
.code

INCLUDE coolpal.inc
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the specified 768-byte palette as the current 8bit one
;
; INPUT -> DS:ESI -> 768-byte source palette buffer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetPal  proc
        xor     al,al
        mov     dx,3C8h
        out     dx,al
        inc     edx
        mov     ecx,256*3
        cld
        rep     outsb
        ret
SetPal  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Stores the current 8bit palette in the specified 768-byte buffer
;
; INPUT -> ES:EDI -> 768-byte destination buffer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetPal  proc
        mov     dx,3C7h
        xor     al,al
        out     dx,al
        inc     edx
        inc     edx
        mov     ecx,256*3
        cld
        rep     insb
        ret
GetPal  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Makes the calculations needed to perform a fade between to palettes
; with 8bit modes
;
; INPUT -> ECX = number of frames that the fade will take
;          if EAX <> -1
;             DS:EAX -> destination palette to fade current to (768 bytes)
;          if EAX = -1
;             EBX = destination color to fade current palette to
;                   ( | XX | red | green | blue |  8 bits each component,
;                     only values between 0-63 are valid for each component )
;                    
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CalcFade8       proc
        mov     only_color,0
        cmp     eax,-1
        jnz     one_color
                mov     byte ptr only_color+2,bl        ; need ordered 
                mov     byte ptr only_color+1,bh        ; components... ;)
                shr     ebx,8
                mov     byte ptr only_color,bh
                or      only_color,1 SHL 31             ; one-color bit ON
        one_color:
        mov     frames,ecx
        mov     edi,offset current_pal
        push    eax
        call    GetPal
        pop     eax
        mov     ecx,256
        xor     esi,esi
        calc_incs:                        
                test    only_color,1 SHL 31     ; is there one-color bit?
                jnz     we_need_one
                        mov     ebx,[eax]
                        add     eax,3
                        mov     only_color,ebx
                        and     only_color,NOT(1 SHL 31)   ; not only one
                we_need_one:                
                mov     bl,byte ptr only_color ; we get destiny red component
                mov     byte ptr trash,bl
                fild    trash                   
                mov     bl,byte ptr [esi+current_pal.red]
                mov     byte ptr trash,bl
                fisub   trash
                fidiv   frames
                fstp    dword ptr [esi*4+color_incs.red_inc]
                mov     bl,byte ptr only_color+1        ; now, green
                mov     byte ptr trash,bl
                fild    trash
                mov     bl,byte ptr [esi+current_pal.green]
                mov     byte ptr trash,bl
                fisub   trash
                fidiv   frames
                fstp    dword ptr [esi*4+color_incs.green_inc]
                mov     bl,byte ptr only_color+2        ; and blue
                mov     byte ptr trash,bl
                fild    trash
                mov     bl,byte ptr [esi+current_pal.blue]
                mov     byte ptr trash,bl
                fisub   trash
                fidiv   frames
                fstp    dword ptr [esi*4+color_incs.blue_inc]
                add     esi,3
        loop    calc_incs

        ; we need a float palette
        mov     ecx,256*3
        xor     esi,esi
        make_them_floats:
                mov     bl,byte ptr [esi+current_pal]
                mov     byte ptr trash,bl
                fild    trash
                fstp    [esi*4+float_pal]
                inc     esi
        loop    make_them_floats
        ret
CalcFade8       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; fades current 8bit palette to the specified one
;
; OUTPUT -> CF = 0 if fade is being performed
;           CF = 1 if fade terminated
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Fade8           proc
        cmp     frames,0
        stc
        jz      no_more_frames
        dec     frames
        xor     esi,esi
        mov     ecx,256*3
        add_incs:
                fld     [esi*4+float_pal]
                fadd    dword ptr [esi*4+color_incs]
                fst     trash1
                fcomp   zero
                fstsw   ax
                sahf
                jbe     no_more_inc
                        mov     eax,trash1
                        mov     [esi*4+float_pal],eax
                        fld     trash1
                        fistp   trash1
                        mov     bl,byte ptr trash1
                        mov     byte ptr [esi+current_pal],bl
                no_more_inc:
                inc     esi
        loop    add_incs
        ; we put modified palette
        mov     esi,offset current_pal
        call    SetPal
        clc
        no_more_frames:
        ret
Fade8   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Builds a cool palette in the specified buffer with given parameters
;
; INPUT -> EAX = | Unused | Initial Red | Initial Green | Initial Blue |
;          EBX = | Unused | Red Counter | Green Counter | Blue Counter |
;          ECX = | Unused | Red Trigger | Green Trigger | Blue Trigger |
;          DS:ESI -> buffer to write palette in
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BuildCoolPal    proc
        and     eax,0FFFFFFh
        mov     edx,ebx
        xor     edi,edi
        Gen:
                push    eax
                mov     [esi+2],al
                mov     [esi+1],ah
                shr     eax,16
                mov     [esi],al
                pop     eax
                
                mov     ebp,ecx
                shr     ecx,16
                cmp     edi,ecx
                jb      green_color
                        sub     ebx,00010000h
                        push    ebx
                        and     ebx,00FF0000h
                        pop     ebx
                jnz     Green_color
                mov     ecx,edx
                and     ecx,00FF0000h
                or      ebx,ecx
                push    eax
                and     eax,00FF0000h
                cmp     eax,003F0000h
                pop     eax
                je      Green_color
                        add     eax,00010000h ; it's < 63 -> won't overflow ;)
                Green_color:
                mov     ecx,ebp
                shr     cx,8
                cmp     di,cx
                jb      blue_color
                        sub     bx,0100h
                        push    ebx
                        and     bx,0FF00h
                        pop     ebx
                jnz     Blue_color
                mov     bh,dh
                cmp     ah,63
                je      Blue_color
                        inc     ah
                mov     ecx,ebp                
                Blue_color:
                and     cx,0FFh
                cmp     di,cx
                jb      pasa
                        dec     bl
                jnz     Pasa
                mov     bl,dl
                cmp     al,63
                je      Pasa
                        inc     al
        Pasa:
        add     esi,3
        inc     edi
        cmp     di,100h
        jnz     Gen
        ret
BuildCoolPal    endp
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.data
trash           dd 0
zero            dd 0

.data?
TInc            STRUC
    red_inc     dd ?
    green_inc   dd ?
    blue_inc    dd ?
ENDS

TColor          STRUC
        red     db ?
        green   db ?
        blue    db ?
ENDS

color_incs      TInc   256 dup(<>)
current_pal     TColor 256 dup(<>)
float_pal       dd   256*3 dup(?)
frames          dd ?
only_color      dd ?
trash1          dd ?

end
