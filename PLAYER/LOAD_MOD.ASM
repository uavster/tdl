;-----------------------------------------------------------------------------
; MOD_LOAD
;-----------------------------------------------------------------------------
; Entrada :     EDX : Puntero al nombre del fichero
; Salida  :     CF = 0 + EAX = 0 si no hay error,
;               CF = 1 + EAX = C¢digo de error:
;                               01 = No se encuentra el fichero
;                               02 = No hay memoria
;                               03 = No es formato MOD
;                               04 = Error interno de carga del fichero
;-----------------------------------------------------------------------------
JUMPS
.486P
.MODEL  FLAT
        assume cs:@code, ds:@data, es:@data
;.DATA
;        numero_magico           dq 3579545        
.CODE
        public  MOD_Load

        include MODPLAY.DEF
        include MODPLAY.INC
        include FILES.INC
        include MEM.INC
        include \src\ttl\utils.inc

        EXTRN   handle  :WORD
        EXTRN   tmp     :BYTE
        EXTRN   tmp2    :BYTE
.DATA
        loading         db 'þ Loading Protracker [MOD] Module ... ',0
        loadok          db 'OK.',13,10,0
.DATA?
        dwordtmp                dd ?
.CODE

MOD_Load        PROC
        push    ebx ecx edx esi edi ebp
; ---------------------------------------------------------------------------
        mov     ax, 3d00h               ; Funci¢n abrir fichero
        int     21h
        jc      MOD_not_found
        mov     handle, ax
; ---------------------------------------------------------------------------
; Comprobamos que se trata de un fichero MOD

        fseek   handle, SEEK_START, 1080
        fread   handle, tmp, 4

        mov     eax, dword ptr [tmp]
        ror     ax, 8
        ror     eax, 16
        ror     ax, 8

        mov     NumChannels, 4
        mov     NumInstrs, 31
        cmp     eax, 'M.K.'
        je      MOD_identificado
        cmp     eax, 'M!K!'
        je      MOD_identificado


        mov     ebx, eax
        shr     ebx, 24
        sub     bl, '0'
        movzx   bx, bl

        mov     NumChannels, bx
        mov     NumInstrs, 31

        mov     ebx, eax
        and     ebx, 00ffffffh
        cmp     ebx, 'CHN'
        je      MOD_identificado

      


        mov     ebx, eax
        shr     ebx, 16
        mov     ecx, ebx
        shr     ebx, 8
        and     ecx, 0ffh
        sub     ebx, '0'
        sub     ecx, '0'
        imul    ebx, 10
        add     ebx,  ecx
        mov     NumChannels, bx
        mov     NumInstrs, 31

        cmp     ax, 'CH'
        je      MOD_identificado





        mov     ebx, eax
        sub     bl, '0'
        movzx   bx, bl

        mov     NumChannels, bx
        mov     NumInstrs, 31

        mov     ebx, eax
        shr     ebx, 8
        and     ebx, 00ffffffh
        cmp     ebx, 'FLT'
        je      MOD_identificado









        mov     NumChannels, 4
        mov     NumInstrs, 15

MOD_identificado:

        fseek   handle, SEEK_END, 0
        ftell   handle
        push    eax

        fseek   handle, SEEK_START, 0
        fread   handle, SongName, 20

; ---------------------------------------------------------------------------
; Cargar instrumentos

        movzx   ecx, NumInstrs
        xor     edx, edx
        xor     ebp, ebp
MOD_load_instr:
        inc     edx
        fread   handle, tmp, 30
        mov     esi, offset tmp
        mov     edi, edx
        shl     edi, 7
        add     edi, offset sample_name
        push    ecx
        mov     ecx, 20
        rep     movsb
        pop     ecx

        xor     eax, eax
        mov     ax, word ptr [tmp+22]
        xchg    ah, al
        shl     eax, 1
        mov     sample_length[edx*4], eax
        add     ebp, eax

        mov     al, byte ptr [tmp+25]
        mov     sample_volume[edx], al

        xor     eax, eax
        mov     ax, word ptr [tmp+26]
        xchg    ah, al
        shl     eax, 1
        cmp     eax, 2
        ja      poner_loopstart
        xor     eax, eax
poner_loopstart:
        mov     loopstart[edx*4], eax

        xor     ebx, ebx
        mov     bx, word ptr [tmp+28]
        xchg    bh, bl
        shl     ebx, 1

        cmp     ebx, 2
        ja      poner_loopend
        xor     ebx, ebx
poner_loopend:

        add     eax, ebx
        mov     loopend[edx*4], eax

        loop    MOD_load_instr

        pop     eax

        mov     samples_filesize, ebp

        cmp     eax, ebp
        jb      MOD_bad_file

        print   loading

; ---------------------------------------------------------------------------
; Cargar info

        fread   handle, tmp, 2

        movzx   ax, byte ptr [tmp]
        mov     NumOrders, ax

        fread   handle, orders, 128

        cmp     word ptr NumChannels, 15
        je      MOD_saltar_id

        fread   handle, tmp, 4

MOD_saltar_id:




        mov     esi, offset orders
        movzx   ecx, NumOrders
        xor     ah, ah
MOD_mirar_patterns:
        lodsb
        cmp     al, ah
        jbe     MOD_no_mayor
        mov     ah, al
MOD_no_mayor:
        loop    MOD_mirar_patterns

        movzx   ax, ah
        inc     ax
        mov     NumPatts, ax

        movzx   ecx, ax



; ---------------------------------------------------------------------------
; Cargar los patterns

        finit

        mov     dwordtmp, 0

        movzx   ecx, NumPatts
        movzx   edx, NumChannels
        imul    edx, 64*6               ; 64 rows * 6 bytes/note
        imul    edx, ecx
        mov     mem_patterns, edx

        alloc_mem
        ;mov     ax, 0ee42h
        ;int     31h
        jc      MOD_no_memory
        xor     ebx, ebx
        mov     eax, edx
load_patts:
        push    ecx
        
        mov     pattern[ebx*4], eax
        movzx   edx, NumChannels
        shl     edx, 8

        fread   handle, tmp, edx
        SHR     EDX, 2
        IMUL    EDX, 6 ; 8
        ADD     EAX, EDX



; ---------------------------------------------------------------------------
; Convertir las notas del MOD

        push    eax ebx edx

        movzx   ecx, NumChannels
        shl     ecx, 6
        mov     esi, offset tmp
        mov     edi, pattern[ebx*4]


convert_notes:
        xor     eax, eax
        mov     ah, byte ptr [esi+0]
        mov     al, byte ptr [esi+1]
        mov     dh, byte ptr [esi+2]
        mov     bl, byte ptr [esi+3]

        mov     bh, dh
        and     bh, 0fh                 ; bx = Effect

        shr     dh, 4
        mov     dl, ah
        and     dl, 0f0h
        or      dh, dl                  ; dh = sample num
        and     dh, 00011111b
        mov     dl, -1                  ; dl = volume

        and     ah, 0fh                 ; ax = period

        SHL     AX, 2       ; ****************************************

;        mov     dwordtmp, eax
        
;        fild    qword ptr numero_magico
;        fidiv   dword ptr dwordtmp
;        fistp   dword ptr dwordtmp

;        mov     eax, dwordtmp
;        SHR     EAX, 3
;        and     eax, 7fffffffh

; ****************************************
        cmp     bh, 3
        jne     noadjust1
        shl     bl, 1
noadjust1:
        cmp     bh, 1
        jne     noadjust2
        shl     bl, 1
noadjust2:
        cmp     bh, 2
        jne     noadjust3
        shl     bl, 1
noadjust3:

        mov     word ptr [edi], dx
        mov     word ptr [edi+2], ax
        mov     word ptr [edi+4], bx

        add     esi, 4
        add     edi, 6

        loop    convert_notes

        pop     edx ebx eax

; ---------------------------------------------------------------------------
        inc     ebx
        pop     ecx
        loop    load_patts

; ---------------------------------------------------------------------------


; ---------------------------------------------------------------------------
; Cargar los samples

        mov     eax, samples_filesize
        mov     edx, eax
        mov     ecx, eax
        
        neg     ecx
        fseek   handle, SEEK_END, ecx

        alloc_mem
;        mov     ax, 0ee42h
;        int     31h
        jc      MOD_no_memory           ; edx = puntero a memoria

        fread   handle, [edx], eax



        movzx   ecx, NumInstrs
        xor     ebp, ebp
sample_pointer:
        inc     ebp
        mov     samples[ebp*4], edx
        add     edx, sample_length[ebp*4]
        loop    sample_pointer





        mov     ah, 3eh
        mov     bx, handle
        int     21h


        mov     TEMPO, 6
        mov     BPM, 125

        mov     edi, offset panning
        mov     al, 15
        stosb
        mov     ecx, MAX_NCHANNELS
        sub     ecx, 2
        shr     ecx, 2
mod_panning:
        mov     ax, 3030h
        stosw
        mov     ax, 0f0fh
        stosw
        loop    mod_panning

        mov     al, 48
        stosb

comment „
        push    eax
        mov     edx, offset fileraw
        mov     ah, 3ch
        mov     ecx, 0
        int     21h
        mov     bx, ax
        mov     ecx, 2048
        mov     edx, pattern
        mov     ah, 40h
        int     21h
        mov     ah, 3eh
        int     21h
        pop     eax
        „

        print   loadok

        mov     eax, 00h
        clc
MOD_Exit:
        pop     ebp edi esi edx ecx ebx
        ret
; ---------------------------------------------------------------------------
MOD_not_found:
        mov     eax, 01h                ; Salida con c¢digo de error 01
        stc
        jmp     MOD_Exit
MOD_bad_file:
        mov     ah, 3eh
        mov     bx, handle
        int     21h
        mov     eax, 03h                ; Salida con c¢digo de error 03
        stc
        jmp     MOD_Exit
MOD_no_memory:
        mov     ah, 3eh
        mov     bx, handle
        int     21h
        mov     eax, 02h                ; Salida con c¢digo de error 02
        stc
        jmp     MOD_Exit
MOD_load_error:
        mov     ah, 3eh
        mov     bx, handle
        int     21h
        mov     eax, 04h                ; Salida con c¢digo de error 04
        stc
        jmp     MOD_Exit
        
MOD_Load        ENDP

END
