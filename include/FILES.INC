       include filesys.inc

SEEK_START              equ 0
SEEK_CURRENT            equ 1
SEEK_END                equ 2

fseek   macro   hand, mode, pos
        push    eax ebx edx ecx
        mov     edx, pos
        mov     bx, hand
        mov     al,mode
        call    ttl_seek
        pop     ecx edx ebx eax
        endm

ftell   macro   hand
        push    ebx edx ecx
        mov     edx, 0
        mov     bx, hand
        mov     al,01h
        call    ttl_seek
        pop     ecx edx ebx
        endm

fread   macro   hand, buffer, tam
        push    eax ebx ecx edx
        mov     ecx, tam
        lea     edx, buffer
        mov     bx, hand
        call    ttl_read
        pop     edx ecx ebx eax
        endm
