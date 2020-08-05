;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; file: tblmap.inc
;
;  Mapeja una textura utilitzant una taula i en blocs de 8x8.
;
;       by Xavier Rubio Jansana, a.k.a. Teknik / #Trouble# Team, July 1998
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

        .386
        .model flat

        .code

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Mapeja una textura en blocs de 8x8. Versi� paletitzada de 8 bits.
;
;  parameters:
;    edi - punter a la mem븈ia de video
;
;  modifies:
;    all
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

Text8x8Blocs8bit macro   BLOCSX, BLOCSY, TABLE, TEXTURE
        local   loop_y_block, loop_x_block, visiona, cnt_x, cnt_y

    SX  equ     BLOCSX * 8
    SY  equ     BLOCSY * 8

        xor     esi, esi
        mov     [cnt_y], BLOCSY
loop_y_block:
        mov     [cnt_x], BLOCSX
loop_x_block:
        mov     ecx, -8 * SX
        add     edi,  8 * SX

        align   16

visiona:

        mov     ebx, TABLE[esi + ecx*4 + 8  + SX*8*4]
        mov     edx, TABLE[esi + ecx*4 + 12 + SX*8*4]
        mov     ebp, TABLE[esi + ecx*4 +      SX*8*4]
        mov     al,  TEXTURE[ebx]
        mov     ah,  TEXTURE[edx]
        mov     ebx, TABLE[esi + ecx*4 + 4  + SX*8*4]
        shl     eax, 16
        add     ecx, 4
        mov     al,  TEXTURE[ebp]
        mov     ah,  TEXTURE[ebx]
        mov     [edi + ecx - 4], eax

        mov     ebx, TABLE[esi + ecx*4 + 8  + SX*8*4]
        mov     edx, TABLE[esi + ecx*4 + 12 + SX*8*4]
        mov     ebp, TABLE[esi + ecx*4 +      SX*8*4]
        mov     al,  TEXTURE[ebx]
        mov     ah,  TEXTURE[edx]
        mov     ebx, TABLE[esi + ecx*4 + 4  + SX*8*4]
        shl     eax, 16
        add     ecx, SX - 4
        mov     al,  TEXTURE[ebp]
        mov     ah,  TEXTURE[ebx]
        mov     [edi + ecx - SX + 4], eax

        jnz     visiona

        sub     edi, 8 * SX - 8
        add     esi, 8 * 4

        dec     [cnt_x]
        jnz     loop_x_block

        add     edi, (8 - 1) * SX
        add     esi, (8 - 1) * SX * 4

        dec     [cnt_y]
        jnz     loop_y_block

        .data

    ; -----------------

        align   16

cnt_x   dd      ?
cnt_y   dd      ?

    ; -----------------

        .code

        endm

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Mapeja una textura en blocs de 8x8. Versi� de 16 bits hicolor.
;
;  parameters:
;    edi - punter a la mem븈ia de video
;
;  modifies:
;    all
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

Text8x8Blocs16bit macro   BLOCSX16, BLOCSY16, TABLE16, TEXTURE16, CLUT16
        local   loop_y_block16, loop_x_block16, visiona16, cnt_x16, cnt_y16

    SX16 equ    BLOCSX16 * 8
    SY16 equ    BLOCSY16 * 8

        xor     esi, esi
        mov     [cnt_y16], BLOCSY16
loop_y_block16:
        mov     [cnt_x16], BLOCSX16
loop_x_block16:
        mov     ecx, -8 * SX16
        add     edi,  8 * SX16 * 2

        align   16

visiona16:

        mov     edx, TABLE16[esi + ecx*4 + 4 + SX16*8*4]; 1
        xor     ebx, ebx                                ; 0
        mov     ebp, TABLE16[esi + ecx*4 +     SX16*8*4]; 1
        mov     bl,  TEXTURE16[edx]                     ; 1
        xor     edx, edx                                ; 1
        mov     dl,  TEXTURE16[ebp]                     ; 1
        add     ecx, 2                                  ; 0
        mov     ax,  CLUT16[ebx * 2]                    ; 1
        shl     eax, 16                                 ; 1
        mov     ax,  CLUT16[edx * 2]                    ; 1

        mov     edx, TABLE16[esi + ecx*4 + 4 + SX16*8*4]; 0
        mov     [edi + ecx * 2 - 4], eax                ; 1
        xor     ebx, ebx                                ; 0
        mov     ebp, TABLE16[esi + ecx*4 +     SX16*8*4]; 1
        mov     bl,  TEXTURE16[edx]                     ; 0
        xor     edx, edx                                ; 1
        mov     ax,  CLUT16[ebx * 2]                    ; 1
        shl     eax, 16                                 ; 1
        mov     dl,  TEXTURE16[ebp]                     ; 0
        mov     ax,  CLUT16[edx * 2]                    ; 2
        add     ecx, 2                                  ; 0
        mov     [edi + ecx * 2 - 4], eax                ; 1

        mov     edx, TABLE16[esi + ecx*4 + 4 + SX16*8*4]; 0
        xor     ebx, ebx                                ; 1
        mov     ebp, TABLE16[esi + ecx*4 +     SX16*8*4]; 0
        mov     bl,  TEXTURE16[edx]                     ; 1
        xor     edx, edx                                ; 0
        mov     dl,  TEXTURE16[ebp]                     ; 1
        add     ecx, 2                                  ; 0
        mov     ax,  CLUT16[ebx * 2]                    ; 1
        shl     eax, 16                                 ; 1
        mov     ax,  CLUT16[edx * 2]                    ; 1

        mov     edx, TABLE16[esi + ecx*4 + 4 + SX16*8*4]; 0
        mov     [edi + ecx * 2 - 4], eax                ; 1
        xor     ebx, ebx                                ; 0
        mov     ebp, TABLE16[esi + ecx*4 +     SX16*8*4]; 1
        mov     bl,  TEXTURE16[edx]                     ; 0
        xor     edx, edx                                ; 1
        mov     ax,  CLUT16[ebx * 2]                    ; 1
        shl     eax, 16                                 ; 1
        mov     dl,  TEXTURE16[ebp]                     ; 0
        mov     ax,  CLUT16[edx * 2]                    ; 2
        add     ecx, SX16 - 6                           ; 0
        mov     [edi + ecx * 2 - (SX16 - 6) * 2], eax   ; 1

        jnz     visiona16                               ; 0

        sub     edi, (8 * SX16 - 8) * 2 ; 16 bits
        add     esi, 8 * 4

        dec     [cnt_x16]
        jnz     loop_x_block16

        add     edi, (8 - 1) * SX16 * 2 ; 16 bits
        add     esi, (8 - 1) * SX16 * 4

        dec     [cnt_y16]
        jnz     loop_y_block16

        .data

    ; -----------------

        align   16

cnt_x16 dd      ?
cnt_y16 dd      ?

    ; -----------------

        .code

        endm


