JUMPS
.486P
.MODEL  FLAT

getxy           macro
        push    dx
        xor     eax, eax
        mov     dx, 3d4h
        mov     al, 0eh
        out     dx, al
        inc     dx
        in      al, dx
        mov     ah, al
        dec     dx
        mov     al, 0fh
        out     dx, al
        inc     dx
        in      al, dx
        shl     eax, 1
        pop     dx
        endm

setxy           macro
        push    bx dx 
        shr     ebx, 1
        xor     eax, eax
        mov     dx, 3d4h
        mov     al, 0eh
        out     dx, al
        inc     dx
        mov     al, bh
        out     dx, al
        mov     ah, al
        dec     dx
        mov     al, 0fh
        out     dx, al
        inc     dx
        mov     al, bl
        out     dx, al

        push    ax bx dx edi

        mov     edi, 450h

        mov     ax, 80
        xchg    bx, ax
        xor     dx, dx
        div     bx
        mov     byte ptr [edi+1], al
        imul    dx, 80
        mov     byte ptr [edi], dl

        pop     edi dx bx ax

        pop     dx bx
        endm


.CODE
        PUBLIC  xprint

xprint          PROC
        push    ax
        getxy
        mov     edi, eax
        mov     ebx, edi
        add     edi, 0b8000h
        pop     ax
poner:
        lodsb
        or      al, al
        jz      endprint
        cmp     al, 13
        je      intro
        cmp     al, 1
        je      cambiarcolor
        stosb
        or      ah, ah
        jz      nocolor
        mov     byte ptr [edi], ah
nocolor:
        inc     edi
        jmp     poner

cambiarcolor:
        lodsb
        mov     ah, al
        jmp     poner

intro:
        add     ebx, 160
        cmp     ebx, 4000
        jae     scroll
finscroll:
        mov     edi, ebx
        add     edi, 0b8000h
        jmp     poner

scroll:
        push    eax esi edi
        mov     ecx, 1000-40
        mov     edi, 0b8000h
        mov     esi, edi
        add     esi, 160
        cld
        rep     movsd
        sub     ebx, 160
        mov     ecx, 40
        mov     eax, 07200720h
        rep     stosd
        pop     edi esi eax
        jmp     finscroll

endprint:

        setxy
        ret
xprint          ENDP

END
