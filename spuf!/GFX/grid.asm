; fitxer: grid.asm
;
;   Rutines per a la creaci¢ de grids per utilitzar amb la rutina de
;   texturitzat de 8x8 amb ilúluminaci¢.
;
;   by Xavier Rubio Jansana, a.k.a. Teknik / the D@rkRising 20.7.1999

        .486p
        .model  flat
        jumps

        .code

; GRID *CreateGrid(DWORD dwXSize, DWORD dwYSize);
; #pragma aux CreateGrid "*" parm   [eax] [ebx] \
;                            value  [eax] \
;                            modify [eax ebx ecx edx esi edi];

        include grid.inc
        include alloc.inc
        include stderror.inc

        global  CreateGRID: near

CreateGRID proc

        push    eax ebx
        imul    eax, ebx
        lea     ecx, [eax * 8]
        lea     ecx, [eax * 4 + ecx]
        add     ecx, size GRID
        call    malloc
        ErrorCodePOP 0, ebx eax

        mov     esi, ebx
        pop     ebx eax

        mov     [GRID ptr esi.GRIDXSize], eax
        mov     [GRID ptr esi.GRIDYSize], ebx
        lea     ecx, [esi + size GRID]
        mov     [GRID ptr esi.GRIDPtr], ecx

        mov     eax, esi
        clc
        ret

CreateGRID endp

        end

