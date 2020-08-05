;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; file: littable.asm
;
;  Creates a lighting table.
;
;       by C‚sar Guirao Robles, a.k.a. Nitro! / #Trouble# Team
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

        JUMPS
        .386p
        .model flat
        .code

    public  CreateLitTable16
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  CreateLitTable:     Crea una tabla de iluminacion en 16 bits de color
;³                      a partir de una paleta.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Entrada:            ESI : Paleta 256 colores
;³                      EDI : Buffer donde insertar la tabla
;³                      EAX : Tipo de tabla de iluminacion
;³                            00  0 - Original .... 31 - Blanco
;³                            01  0 - Negro    .... 31 - Original
;³                            02  0 - Negro ... 15 - Original ... 31 - Blanco
;³                            03  0 - Original
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Salida:             EDI : rellenado
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CreateLitTable16  proc
    push    ebp
    cmp     eax, 00
    je      Type00
    cmp     eax, 01
    je      Type01
    cmp     eax, 02
    je      Type02
    cmp     eax, 03
    jmp     Type03
type00:
    mov     ebp, 0
buclecolores:
    xor     ebx, ebx
    mov     bl, [esi]
    xor     ecx, ecx
    mov     cl, [esi+1]
    xor     edx, edx
    mov     dl, [esi+2]

    shl     ebx, 16
    shl     ecx, 16
    shl     edx, 16

    mov     eax, 64 shl 16
    sub     eax, ebx
    sar     eax, 5
    mov     Rincrement, eax

    mov     eax, 64 shl 16
    sub     eax, ecx
    sar     eax, 5
    mov     Gincrement, eax

    mov     eax, 64 shl 16
    sub     eax, edx
    sar     eax, 5
    mov     Bincrement, eax

    call    Bucle32

    add     esi, 3
    inc     ebp
    cmp     ebp, 256
    jne     short buclecolores
    pop     ebp
    ret

type01:
    mov     ebp, 0
buclecolores01:
    xor     ebx, ebx
    mov     bl, [esi]
    xor     ecx, ecx
    mov     cl, [esi+1]
    xor     edx, edx
    mov     dl, [esi+2]

    shl     ebx, 16
    shl     ecx, 16
    shl     edx, 16

    sar     ebx, 5
    mov     Rincrement, ebx

    sar     ecx, 5
    mov     Gincrement, ecx

    sar     edx, 5
    mov     Bincrement, edx

    xor     ebx, ebx
    xor     ecx, ecx
    xor     edx, edx

    call    Bucle32

    add     esi, 3
    inc     ebp
    cmp     ebp, 256
    jne     buclecolores01
    pop     ebp
    ret

type02:
    mov     ebp, 0
buclecolores02:
    xor     ebx, ebx
    mov     bl, [esi]
    xor     ecx, ecx
    mov     cl, [esi+1]
    xor     edx, edx
    mov     dl, [esi+2]

    shl     ebx, 16
    shl     ecx, 16
    shl     edx, 16

    sar     ebx, 4
    mov     Rincrement, ebx

    sar     ecx, 4
    mov     Gincrement, ecx

    sar     edx, 4
    mov     Bincrement, edx

    xor     ebx, ebx
    xor     ecx, ecx
    xor     edx, edx

        push    ebp
        mov     ebp, 0
        bucleblackfadeon:
        push    ebx ecx edx
        xor     eax, eax
        shr     ebx, 17
        shr     ecx, 16
        shr     edx, 17

        sal     ebx, 6+5
        sal     ecx, 5

        or      eax, ebx
        or      eax, ecx
        or      eax, edx

        mov     [edi], ax
        add     edi, 2
        pop     edx ecx ebx
        add     ebx, Rincrement
        add     ecx, Gincrement
        add     edx, Bincrement
        inc     ebp
        cmp     ebp, 16
        jnz     bucleblackfadeon
        pop     ebp

    xor     ebx, ebx
    mov     bl, [esi]
    xor     ecx, ecx
    mov     cl, [esi+1]
    xor     edx, edx
    mov     dl, [esi+2]

    shl     ebx, 16
    shl     ecx, 16
    shl     edx, 16

    mov     eax, 64 shl 16
    sub     eax, ebx
    sar     eax, 4
    mov     Rincrement, eax

    mov     eax, 64 shl 16
    sub     eax, ecx
    sar     eax, 4
    mov     Gincrement, eax

    mov     eax, 64 shl 16
    sub     eax, edx
    sar     eax, 4
    mov     Bincrement, eax

        push    ebp
        mov     ebp, 0
        buclewhitefadeoff:
        push    ebx ecx edx
        xor     eax, eax
        shr     ebx, 17
        shr     ecx, 16
        shr     edx, 17

        sal     ebx, 6+5
        sal     ecx, 5

        or      eax, ebx
        or      eax, ecx
        or      eax, edx

        mov     [edi], ax
        add     edi, 2
        pop     edx ecx ebx
        add     ebx, Rincrement
        add     ecx, Gincrement
        add     edx, Bincrement
        inc     ebp
        cmp     ebp, 16
        jnz     buclewhitefadeoff
        pop     ebp


    add     esi, 3
    inc     ebp
    cmp     ebp, 256
    jne     buclecolores02
    pop     ebp
    ret
type03:
    mov     ebp, 0
buclecolores03:
    xor     ebx, ebx
    mov     bl, [esi]
    xor     ecx, ecx
    mov     cl, [esi+1]
    xor     edx, edx
    mov     dl, [esi+2]

    shr     ebx, 1
    shr     edx, 1

    sal     ebx, 6+5
    sal     ecx, 5
    xor     eax, eax

    or      eax, ebx
    or      eax, ecx
    or      eax, edx

    mov     [edi], ax
    add     edi, 2

    add     esi, 3
    inc     ebp
    cmp     ebp, 256
    jne     buclecolores03
    pop     ebp
    ret

Bucle32:
        push    ebp
        mov     ebp, 0
        bucleilumina:
        push    ebx ecx edx
        xor     eax, eax
        shr     ebx, 17
        shr     ecx, 16
        shr     edx, 17

        sal     ebx, 6+5
        sal     ecx, 5

        or      eax, ebx
        or      eax, ecx
        or      eax, edx

        mov     [edi], ax
        add     edi, 2
        pop     edx ecx ebx
        add     ebx, Rincrement
        add     ecx, Gincrement
        add     edx, Bincrement
        inc     ebp
        cmp     ebp, 32
        jnz     bucleilumina
        pop     ebp
        ret

Rincrement  dd  ?
Gincrement  dd  ?
Bincrement  dd  ?
    endp

        end

