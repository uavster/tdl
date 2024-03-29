; fitxer: draw4x4g.asm
;
;   Texturitza una graella de blocs de 4x4 amb il�luminaci�.
;
;   by Xavier Rubio Jansana, a.k.a. Teknik / the D@rkRising 25.7.1999
;       fet a partir del grid de 8x8! :9

        .486p
        .model  flat
        jumps

        .code

; void Draw4x4Grid32Lit(SLI *output, GRID *Grid, SLI *texture);
; #pragma aux Draw4x4Grid "*" parm   [edi] [esi] [edx] \
;                             modify [eax ebx ecx edx esi edi];

        include sli.inc
        include grid.inc

        global  Draw4x4Grid32Lit: near

Draw4x4Grid32Lit proc

        push    ebp

        mov     eax, [SLI ptr edi.SLIPitch]
        mov     dword ptr [dwScanLineWidth], eax

        mov     eax, [GRID ptr esi.GRIDXSize]
        dec     eax
        mov     ebx, [GRID ptr esi.GRIDYSize]
        dec     ebx
        mov     esi, [GRID ptr esi.GRIDPtr]         ; esi -> grid
        mov     edi, [SLI ptr edi.SLIFramePtr]      ; edi -> output SLI
        mov     ecx, [SLI ptr edx.SLIFramePtr]      ; ecx -> textura
        mov     edx, [SLI ptr edx.SLILitTable]      ; edx -> littable

        mov     dword ptr [dwHBlocs], eax         ; Inicialitza comptadors
        mov     dword ptr [dwVBlocs], ebx
        mov     dword ptr [dwTexture - 4], ecx    ; "Hard-codeja" par�metres :)
        mov     dword ptr [dwLitTable - 4], edx

        mov     ebx, [dwHBlocs]         ; ebx = offset a l�nia
        inc     ebx                     ;  seg�ent dins l'estructura
        mov     eax, ebx                ;  de grid.
        shl     ebx, 3
        shl     eax, 2
        add     ebx, eax
        mov     [dwGridPitch], ebx

        VBucle:                         ; Bucle per *blocs* vertical

            mov     eax, [dwHBlocs]
            mov     [dwHCounter], eax

            HBucle:                         ; Bucle per *blocs* horitzontal

                mov     ebx, [dwGridPitch]      ; ebx = offset a l�nia

                mov     eax, [esi + ebx]        ; Calcula du/dy
                sub     eax, [esi]
                mov     edx, eax
                sar     edx, 2
                sal     eax, 8 - 2              ; / 4 * 256 per fp 8.8
                mov     byte ptr [dudy_frac - 1], al
                mov     byte ptr [dudy_int - 1], dl

                mov     eax, [esi + ebx + 4]    ; Calcula dv/dy
                sub     eax, [esi + 4]
                mov     edx, eax
                sar     edx, 2
                sal     eax, 8 - 2              ; / 4 * 256 per fp 8.8
                mov     byte ptr [dvdy_frac - 1], al
                mov     byte ptr [dvdy_int - 1], dl

                mov     eax, [esi + 12]         ; Calcula du/dx
                sub     eax, [esi]
                mov     edx, eax
                sar     edx, 2
                sal     eax, 8 - 2              ; / 4 * 256 per fp 8.8
                mov     byte ptr [dudx_frac - 1], al
                mov     byte ptr [dudx_int - 1], dl

                mov     eax, [esi + ebx + 12]   ; Calcula delta(du/dx)
                sub     eax, [esi + ebx]
                mov     edx, eax
                sar     edx, 2
                sal     eax, 8 - 2              ; / 4 * 256 per fp 8.8
                sub     al, byte ptr [dudx_frac - 1]
                sbb     dl, byte ptr [dudx_int - 1]
                mov     ah, dl
                sar     eax, 2                  ; / 4 pq increment cada l�nia
                sar     dl, 2
                mov     byte ptr [dudx_frac_inc - 1], al
                mov     byte ptr [dudx_int_inc - 1], dl

                mov     eax, [esi + 12 + 4]     ; Calcula dv/dx
                sub     eax, [esi + 4]
                mov     edx, eax
                sar     edx, 2
                sal     eax, 8 - 2              ; / 4 * 256 per fp 8.8
                mov     byte ptr [dvdx_frac - 1], al
                mov     byte ptr [dvdx_int - 1], dl

                mov     eax, [esi + ebx + 12 + 4]   ; Calcula delta(dv/dx)
                sub     eax, [esi + ebx + 4]
                mov     edx, eax
                sar     edx, 2
                sal     eax, 8 - 2              ; / 4 * 256 per fp 8.8
                sub     al, byte ptr [dvdx_frac - 1]
                sbb     dl, byte ptr [dvdx_int - 1]
                mov     ah, dl
                sar     eax, 2                  ; / 4 pq increment cada l�nia
                sar     dl, 2
                mov     byte ptr [dvdx_frac_inc - 1], al
                mov     byte ptr [dvdx_int_inc - 1], dl

            ; Il�luminaci� !!!

                mov     eax, [esi + ebx + 8]    ; Calcula dl/dy
                sub     eax, [esi + 8]
                mov     edx, eax
                sar     edx, 2
                sal     eax, 8 - 2              ; / 4 * 256 per fp 8.8
                mov     byte ptr [dldy_frac - 1], al
                mov     byte ptr [dldy_int - 1], dl

                mov     eax, [esi + 12 + 8]     ; Calcula dl/dx
                sub     eax, [esi + 8]
                mov     edx, eax
                sar     edx, 2
                sal     eax, 8 - 2              ; / 4 * 256 per fp 8.8
                mov     byte ptr [dldx_frac - 1], al
                mov     byte ptr [dldx_int - 1], dl

                mov     eax, [esi + ebx + 12 + 8]   ; Calcula delta(dl/dx)
                sub     eax, [esi + ebx + 8]
                mov     edx, eax
                sar     edx, 2
                sal     eax, 8 - 2              ; / 4 * 256 per fp 8.8
                sub     al, byte ptr [dldx_frac - 1]
                sbb     dl, byte ptr [dldx_int - 1]
                mov     ah, dl
                sar     eax, 2                  ; / 4 pq increment cada l�nia
                sar     dl, 2
                mov     byte ptr [dldx_frac_inc - 1], al
                mov     byte ptr [dldx_int_inc - 1], dl

            ; �������� Bucle intern del bloc de 8x8 ��������

                ; dl = part fraccionaria de u
                ; cl = part fraccionaria de v
                ; dh = part fraccionaria de l
                ; bl = part entera de u
                ; bh = part entera de v
                ; ch = part entera de l

                xor     ebx, ebx
                xor     edx, edx                ; Parts fraccionaries = 0
                xor     cl, cl
                mov     bl, [esi]               ; Carrega u, v, l
                mov     bh, [esi + 4]
                mov     ch, [esi + 8]

                add     edi, 4 * 4
                push    edi

                mov     dword ptr [dwYCounter], 4

            bucley:
                mov     ebp, -4
                push    edx
                push    ecx
                push    ebx

                align   16

            buclex:
                xor     eax, eax
                add     dl, 12h
            dudx_frac:
                mov     al, [12345678h + ebx]
            dwTexture:
                adc     bl, 12h
            dudx_int:

                ;shl     eax, 5                  ; lit [0..31] a 16 bits
                ;or      al, ch                  ; Il�luminaci� !!!
                ;shl     eax, 1
                mov     ah, ch
                ;shl     eax, 2

                add     dh, 12h
            dldx_frac:
                adc     ch, 12h
            dldx_int:

                add     cl, 12h
            dvdx_frac:
                ; inc comptador ?
                mov     eax, [12345678h + eax * 4] ; AGI
            dwLitTable:
                adc     bh, 12h
            dvdx_int:
                mov     [edi + ebp * 4], eax
                inc     ebp
                jnz     buclex

                pop     ebx
                pop     ecx
                pop     edx

            ; Increments d'increments (per considerar el v�rtex inferior dret)

                add     byte ptr [dudx_frac - 1], 12h
            dudx_frac_inc:
                adc     byte ptr [dudx_int - 1], 12h
            dudx_int_inc:
                add     byte ptr [dvdx_frac - 1], 12h
            dvdx_frac_inc:
                adc     byte ptr [dvdx_int - 1], 12h
            dvdx_int_inc:
                add     byte ptr [dldx_frac - 1], 12h
            dldx_frac_inc:
                adc     byte ptr [dldx_int - 1], 12h
            dldx_int_inc:

            ; Increments normals...

                add     dl, 12h
            dudy_frac:
                adc     bl, 12h
            dudy_int:
                add     cl, 12h
            dvdy_frac:
                adc     bh, 12h
            dvdy_int:
                add     dh, 12h            ; Il�luminaci� !!!
            dldy_frac:
                adc     ch, 12h
            dldy_int:
                add     edi, [dwScanLineWidth]

                dec     dword ptr [dwYCounter]
                jnz     bucley

            ; �������� Fi del bucle intern del bloc de 8x8 ��������

                pop     edi                     ; edi ja te sumats 16
                                                ; (4 * 4 bytes)
                add     esi, 12

            dec     dword ptr [dwHCounter]
            jnz     HBucle

            add     esi, 12

            mov     eax, [dwScanLineWidth]
            shl     eax, 2
            sub     eax, [dwScanLineWidth]  ; eax = 3 * dwScanLineWidth
            add     edi, eax                ; Es salta la resta de mem�ria del
                                            ;  SLI (3 scanlines + el que ja
                                            ;  s'ha sumat al bucle intern).

        dec     dword ptr [dwVBlocs]
        jnz     VBucle

        pop     ebp
        ret
endp

; ����������������������������������������������������������������������������

        .data?

dwHBlocs        dd      ?               ; Nombre de blocs en horitzontal
dwVBlocs        dd      ?               ; Nombre de blocs en vertical
dwHCounter      dd      ?               ; Comptador de blocs horitzontals
dwYCounter      dd      ?               ; Comptador de scanlines del bloc
dwScanLineWidth dd      ?               ; Amplada d'un scanline en bytes
dwGridPitch     dd      ?               ; Offset a la seg�ent l�nia del grid

        end

