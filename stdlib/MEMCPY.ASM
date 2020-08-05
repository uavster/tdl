;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  [tDR], 1998                                    Copyright the DarkRising
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Funciones de copia de memoria                          Coded by: Nitro!
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    .386p
    .model  flat
     jumps
    .code
    include     memcpy.inc
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Lista de funciones de la librer¡a
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  InitMemCopy : Inicializa las rutinas de copia para el procesador actual
;³  Memcopy : Copia una cadena de bytes
;³  FastQcopy : copia estando todo alineado a qword
;³  Fast2Qcopy  : copia estando todo alineado a qword pero copia de 16 en 16
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Memcopy_        dd  offset Normal_memcopy
Fast2Qcopy_     dd  offset Normal_Fast2Qcopy

Memcopy proc
    jmp     [Memcopy_]
    endp
Fast2Qcopy proc
    jmp     [Fast2Qcopy_]
    endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Inicializa las rutinas de copia para procesadores con MMX
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  InitMemCopy     Entrada: nada.
;³                  Salida : nada.
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
InitMemCopy proc
    ; if mmx ala k te vas pa mmxinit
normalinit:
    ;copias normales...
    ret        
mmxinit:
    ret
    endp
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Rutinas normales de copia
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³  Entrada : ESI=fuente EDI=destino ECX=tama¤o en bytes
;³            (para los Qwords copys ECX = numero de qwords multiplo de 2)
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Normal_MemCopy  proc
    test    edi, 1b
    jz      aligned_to_word
    mov     al, [esi]
    dec     ecx
    mov     [edi], al
    lea     esi, [esi+1]
    lea     edi, [edi+1]
    jz      finmemcopy
aligned_to_word:
    test    edi, 10b
    jz      aligned_to_dword
    stosw
    sub     ecx, 2
    jz      finmemcopy
aligned_to_dword:
    mov     edx, ecx
    shr     ecx, 2
    or      ecx, ecx
    jz      nodwords

    lea     esi, [esi+ecx*4]
    lea     edi, [edi+ecx*4]
    xor     ecx, -1
    inc     ecx
buclecopydwords:
    mov     eax, [esi+ecx*4]
    inc     ecx
    mov     [edi+ecx*4], eax
    jnz     buclecopydwords

nodwords:
    shr     edx, 1
    jnc     nooddword
    stosw
nooddword:
    shr     edx, 1
    jnc     finmemcopy
    stosb
finmemcopy:
    ret
    endp

Normal_Fast2Qcopy    proc
    lea     esi, [esi+ecx*8]
    lea     edi, [edi+ecx*8]
    xor     ecx, -1
    inc     ecx
NUQC001:
    fild    qword ptr [esi+ecx*8]
    fild    qword ptr [esi+ecx*8+8]
    fxch
    fistp   qword ptr [edi+ecx*8]
    fistp   qword ptr [edi+ecx*8+8]
    add     ecx, 2
    jnz     nuqc001
    ret
    endp

;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
END
