comment „
alloc_mem       macro
        push    eax ebx ecx esi edi
        mov     ecx, edx
        mov     ebx, edx
        shr     ebx, 16
        mov     ax, 501h
        int     31h
        pushf
        shl     ebx, 16
        mov     bx, cx
        mov     edx, ebx
        popf
        pop     edi esi ecx ebx eax
        endm
        „

extrn malloc:near

alloc_mem       macro
        push    eax ebx ecx esi edi

        mov     ecx, edx
        call    malloc
        mov     edx, ebx

        pop     edi esi ecx ebx eax
        endm

