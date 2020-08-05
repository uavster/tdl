;ÚÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³³ Rutinas para tablas de iluminacion                                    ³
;³³ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
;³³ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³³ Coded by Nitro! / [tDR], 1999                                         ³
;ÀÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
        JUMPS
        .386p
        .model flat
        .code
        include littable.inc
        include sli.inc
        include utils.inc
        include stderror.inc            ; B52
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  LinearTableOrig2White: Crea una tabla de iluminacion en 32 bits de color
;³                         a partir de una paleta ARGB de 8 bits/canal.
;³                         Crecimiento Lineal
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Entrada:            ESI : Paleta 256 colores formato ARGB
;³                      EDI : Buffer donde insertar la tabla
;³                      ECX : numero de niveles de iluminacion
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Salida:             Si no hay carry
;³                      EDI : rellenado
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
LinearTableOrig2White   proc
            push    ebp
            cmp     ecx, 2
            jl      LTO2W004

            mov     ebp, ecx
            mov     ecx, 256
    LTO2W001:
            push    ecx
            mov     ecx, 3
    LTO2W002:
            push    ecx
            push    edi
            xor     ebx, ebx
            mov     eax, 0ffh
            mov     bl, byte ptr [esi]
            sub     eax, ebx
            sal     eax, 16
            mov     edx, eax
            sar     edx, 31
            idiv    ebp
            sal     ebx, 16
            mov     ecx, ebp
    LTO2W003:
            push    ecx
            mov     ecx, ebx
            sar     ecx, 16
            mov     [edi], cl
            add     ebx, eax
            add     edi, 256*4
            pop     ecx
            loop    LTO2W003
            pop     edi
            inc     edi
            inc     esi
            pop     ecx
            loop    LTO2W002

;            mov     ecx, ebp            ; Juuuuuuur by Teknik
;            shl     ecx, 8 + 2
;            inc     edi
;            inc     esi
;            add     edi, ecx
            inc     edi
            inc     esi

;            mov     al, [esi]
;            mov     [edi], al
;            inc     esi
;            inc     edi
            pop     ecx
            loop    LTO2W001
            pop     ebp
            clc
            ret
    LTO2W004:
            pop     ebp
            stc
            ret
            endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  LinearTableBlack2Orig: Crea una tabla de iluminacion en 32 bits de color
;³                         a partir de una paleta ARGB de 8 bits/canal.
;³                         Crecimiento Lineal
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Entrada:            ESI : Paleta 256 colores formato ARGB
;³                      EDI : Buffer donde insertar la tabla
;³                      ECX : numero de niveles de iluminacion
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Salida:             Si no hay carry
;³                      EDI : rellenado
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
LinearTableBlack2Orig   proc
            push    ebp
            cmp     ecx, 2
            jl      LTB2O004

            mov     ebp, ecx
            mov     ecx, 256
    LTB2O001:
            push    ecx
            mov     ecx, 3
    LTB2O002:
            push    ecx
            push    edi
            xor     ebx, ebx
            mov     eax, 0h
            mov     bl, byte ptr [esi]
            sub     eax, ebx
            neg     eax
            sal     eax, 16
            mov     edx, eax
            sar     edx, 31
            idiv    ebp
            ;sal     ebx, 16
            xor     ebx, ebx
            mov     ecx, ebp
    LTB2O003:
            push    ecx
            mov     ecx, ebx
            sar     ecx, 16
            mov     [edi], cl
            add     ebx, eax
            add     edi, 256*4
            pop     ecx
            loop    LTB2O003
            pop     edi
            inc     edi
            inc     esi
            pop     ecx
            loop    LTB2O002

;            mov     ecx, ebp            ; Juuuuuuur by Teknik
;            shl     ecx, 8 + 2
;            inc     edi
;            inc     esi
;            add     edi, ecx
            inc     edi
            inc     esi

            ;mov     al, [esi]
            ;mov     [edi], al
            ;inc     esi
            ;inc     edi
            pop     ecx
            loop    LTB2O001
            pop     ebp
            clc
            ret
    LTB2O004:
            pop     ebp
            stc
            ret
            endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  LinearTableBlack2Orig2White: Crea una tabla de iluminacion en 32 bits de color
;³                         a partir de una paleta ARGB de 8 bits/canal.
;³                         Crecimiento Lineal
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Entrada:            ESI : Paleta 256 colores formato ARGB
;³                      EDI : Buffer donde insertar la tabla
;³                      ECX : numero de niveles de iluminacion
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Salida:             Si no hay carry
;³                      EDI : rellenado
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
LinearTableBlack2Orig2White   proc
            push    ebp
            cmp     ecx, 3
            jl      LTB2O2W004

            push    ecx
            push    esi
            mov     ebp, ecx
            shr     ebp, 1
            mov     ecx, 256
    LTB2O2W001:
            push    ecx
            mov     ecx, 3
    LTB2O2W002:
            push    ecx
            push    edi
            xor     ebx, ebx
            mov     eax, 0h
            mov     bl, byte ptr [esi]
            sub     eax, ebx
            neg     eax
            sal     eax, 16
            mov     edx, eax
            sar     edx, 31
            idiv    ebp
            ;sal     ebx, 16
            xor     ebx, ebx
            mov     ecx, ebp
    LTB2O2W003:
            push    ecx
            mov     ecx, ebx
            sar     ecx, 16
            mov     [edi], cl
            add     ebx, eax
            add     edi, 256*4
            pop     ecx
            loop    LTB2O2W003
            pop     edi
            inc     edi
            inc     esi
            pop     ecx
            loop    LTB2O2W002

;            mov     ecx, ebp            ; Juuuuuuur by Teknik
;            shl     ecx, 8 + 2
;            inc     edi
;            inc     esi
;            add     edi, ecx
            inc     edi
            inc     esi

            ;mov     al, [esi]
            ;mov     [edi], al
            ;inc     esi
            ;inc     edi

            pop     ecx
            loop    LTB2O2W001
            pop     esi

            ;push    esi
            ;mov     ecx, 256
            ;rep     movsd
            ;pop     esi

            pop     ecx

            mov     ebp, ecx
            shr     ecx, 1
            inc     ecx
            sub     ebp, ecx
            sub     ecx, 2

            shl     ecx, 8+2
            add     edi, ecx

            mov     ecx, 256
    LTB2O2W005:
            push    ecx
            mov     ecx, 3
    LTB2O2W006:
            push    ecx
            push    edi
            xor     ebx, ebx
            mov     eax, 0ffh
            mov     bl, byte ptr [esi]
            sub     eax, ebx
            sal     eax, 16
            mov     edx, eax
            sar     edx, 31
            idiv    ebp
            sal     ebx, 16
            mov     ecx, ebp
    LTB2O2W007:
            push    ecx
            mov     ecx, ebx
            sar     ecx, 16
            mov     [edi], cl
            add     ebx, eax
            add     edi, 256*4
            pop     ecx
            loop    LTB2O2W007
            pop     edi
            inc     edi
            inc     esi
            pop     ecx
            loop    LTB2O2W006

;            mov     ecx, ebp            ; Juuuuuuur by Teknik
;            shl     ecx, 8 + 2
;            inc     edi
;            inc     esi
;            add     edi, ecx
            inc     edi
            inc     esi

            ;mov     al, [esi]
            ;mov     [edi], al
            ;inc     esi
            ;inc     edi

            pop     ecx
            loop    LTB2O2W005
            pop     ebp
            clc
            ret
    LTB2O2W004:
            pop     ebp
            stc
            ret
            endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  CreateLitTable32:   Crea una tabla de iluminacion en 32 bits de color
;³                      a partir de una paleta.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Entrada:            ESI : Paleta 256 colores
;³                      EDI : Buffer donde insertar la tabla
;³                      EAX : Tipo de tabla de iluminacion
;³                            00  0 - Original .... 31 - Blanco
;³                            01  0 - Negro    .... 31 - Original
;³                            02  0 - Negro ... 15 - Original ... 31 - Blanco
;³                            03  0 - Original
;³                      ECX : niveles de iluminacion
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Salida:             EDI : rellenado
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CreateLitTable32  proc
            cmp     eax, 0
            je      LinearTableOrig2White
            cmp     eax, 1
            je      LinearTableBlack2Orig
            cmp     eax, 2
            je      LinearTableBlack2Orig2White
            mov     ecx, 768
            rep     movsd
            ret
            endp

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  CreateLitTableSLI:  Crea una tabla de iluminacion en 32 bits de color
;³                      a partir de una paleta.
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Entrada:            EAX : SLI
;³                      EBX : Tipo de tabla de iluminacion
;³                            00  0 - Original .... 31 - Blanco
;³                            01  0 - Negro    .... 31 - Original
;³                            02  0 - Negro ... 15 - Original ... 31 - Blanco
;³                            03  0 - Original
;³                      ECX : niveles de iluminacion
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Salida:             nada.
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CreateLitTableSLI proc
            push    eax ebx ecx
            shl     ecx, 8+2
            call    malloc
            ErrorCode MALLOC_ERROR              ; B52
            mov     edi, ebx
            pop     ecx ebx eax
            lea     esi, [SLI ptr eax.SLIPalette]
            mov     [SLI ptr eax.SLILitTable], edi
            mov     eax, ebx

            push    edi ecx eax
            shl     ecx, 8
            xor     eax, eax
            rep     stosd
            pop     eax ecx edi

            jmp     CreateLitTable32
            endp
END

