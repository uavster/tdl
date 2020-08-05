;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; file: vga.asm
;
;  Some routines for VGA coding.
;
;       by C굎ar Guirao Robles, a.k.a. Nitro! / #Trouble# Team
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

        JUMPS
        .386p
        .model flat
        .code

        Public  CharSize

        ;       BL      Altura del caracter

CharSize        proc
        mov     dx,3d4h
        mov     al,09h
        out     dx,al
        inc     dx
        in      al,dx
        and     al,11110000b
        add     al,bl
        mov     ah,al
        mov     dx,3d4h
        mov     al,09
        out     dx,ax
        ret
        endp


        Public  ScreenStart
        ;       BX      Direccion de inicio de la CRTC
ScreenStart     proc
        mov     dx,3d4h
        mov     al,0dh
        mov     ah,bl
        out     dx,ax
        mov     dx,3d4h
        mov     al,0ch
        mov     ah,bh
        out     dx,ax
        ret
        endp

; 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
;       Prepara la VGA para el SplitScreen
; 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
        Public  SetSplit
        ;   BX      Scanline donde hacer el Splitscreen

SetSplit        proc
        mov     dx,3d4h
        mov     al,18h
        mov     ah,bl
        out     dx,ax

        mov     al,7h
        out     dx,al
        inc     dx
        in      al,dx
        dec     dx
        and     al,11101111b
        mov     bl,bh
        and     bl,1
        shl     bl,4
        or      al,bl
        mov     ah,al
        mov     al,7h
        out     dx,ax

        mov     dx,3d4h
        mov     al,9h
        out     dx,al
        inc     dx
        in      al,dx
        dec     dx
        and     al,10111111b
        mov     bl,bh
        and     bl,10b
        shl     bl,5
        or      al,bl
        mov     ah,al
        mov     al,9h
        out     dx,ax

        ret
        endp

        public  SetCurPos

SetCurPos       proc
        mov     dx,3d4h
        mov     al,0eh
        mov     ah,bh
        out     dx,ax
        mov     dx,3d4h
        mov     al,0fh
        mov     ah,bl
        out     dx,ax
        ret
        endp

        public  GetCurPos

GetCurPos       proc
        mov     dx,3d4h
        mov     al,0eh
        out     dx,al
        inc     dx
        in      al,dx
        mov     bh,al
        mov     dx,3d4h
        mov     al,0fh
        out     dx,al
        inc     dx
        in      al,dx
        mov     bl,al
        ret
        endp

        end

