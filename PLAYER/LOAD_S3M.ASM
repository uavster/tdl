;-----------------------------------------------------------------------------
; MOD_LOAD
;-----------------------------------------------------------------------------
; Entrada :     EDX : Puntero al nombre del fichero
; Salida  :     CF = 0 + EAX = 0 si no hay error,
;               CF = 1 + EAX = C¢digo de error:
;                               01 = No se encuentra el fichero
;                               02 = No hay memoria
;                               03 = No es formato S3M
;                               04 = Error interno de carga del fichero
;-----------------------------------------------------------------------------
JUMPS
.386P
.MODEL  FLAT
        assume cs:@code, ds:@data, es:@data
.CODE
        public  S3M_Load

        include MODPLAY.DEF
        include MODPLAY.INC
        include FILES.INC
        include MEM.INC
        include \src\ttl\utils.inc

        EXTRN   handle  :WORD
        EXTRN   tmp     :BYTE
        EXTRN   tmp2    :BYTE

.DATA
        S3M_Effect      db 00h,00h,00h,0bh,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
                        db 256 dup(0)

        converts3mnote label word
        ;         0    1    2    3    4    5    6    7    8    9    A    B
        ;         C    C#   D    D#   E    F    F#   G    G#   A    A#   B
            dw 1712,1616,1525,1440,1357,1281,1209,1141,1077,1017, 961, 907 ; Octave 0
            dw  856, 808, 762, 720, 678, 640, 604, 570, 538, 508, 480, 453 ; Octave 1
            dw  428, 404, 381, 360, 339, 320, 302, 285, 269, 254, 240, 226 ; Octave 2
            dw  214, 202, 190, 180, 170, 160, 151, 143, 135, 127, 120, 113 ; Octave 3
            dw  107, 101,  95,  90,  85,  80,  76,  71,  67,  64,  60,  57 ; Octave 4
            dw   53,  50,  47,  45,  42,  40,  38,  35,  33,  32,  30,  28 ; Octave 5
            dw   26,  25,  23,  22,  21,  20,  19,  17,  16,  16,  15,  14 ; Octave 6
            dw   13,  12,  11,  11,  10,  10,   9,   8,   8,   8,   7,   7 ; Octave 7


        C4SPD                   dd 107

        loading         db '‏ Loading Scream Tracker 3 [S3M] Module ... ',0
        loadok          db 'OK.',13,10,0

        pepe            dd 0
.CODE

S3M_Load        PROC
        push    ebx ecx edx esi edi ebp

; ---------------------------------------------------------------------------
        mov     ax, 3d00h               ; Funci¢n abrir fichero
        int     21h
        jc      S3M_not_found
        mov     handle, ax
; ---------------------------------------------------------------------------
; Comprobamos que se trata de un fichero S3M

        fseek   handle, SEEK_START, 02ch
        fread   handle, tmp, 4
        mov     eax, dword ptr [tmp]
        cmp     eax, 'MRCS'
        jne     S3M_bad_file

        print   loading

; ---------------------------------------------------------------------------
; Cargamos el t¡tulo de la canci¢n

        fseek   handle, SEEK_START, 0h
        fread   handle, SongName, 28
; ---------------------------------------------------------------------------
; Cargamos el n£mero de patterns, instrumentos y orders

        fseek   handle, SEEK_START, 20h
        fread   handle, tmp, 32

        mov     ax, word ptr [tmp]      ; OrdNum
        mov     word ptr NumOrders, ax
        mov     ax, word ptr [tmp+2]    ; InsNum
        mov     word ptr NumInstrs, ax
        mov     ax, word ptr [tmp+4]    ; PatNum
        mov     word ptr NumPatts, ax

        mov     ax, word ptr [tmp+0ah]
        mov     sample_sign, al

        mov     al, byte ptr [tmp+11h]
        mov     TEMPO, al
        mov     al, byte ptr [tmp+12h]
        mov     BPM, al


; ---------------------------------------------------------------------------
; Cargar el panning

        fseek   handle, SEEK_START, 40h
        fread   handle, tmp, 32


        mov     esi, offset tmp
        mov     edi, offset panning
        mov     ebp, offset channel_info
        mov     ecx, 32
        mov     bx, 0
S3M_convert_panning:
        lodsb
        mov     ah, 000h                ; canal desactivado
        test    al, 80h
        jnz     S3M_channel_disabled
        and     al, 00001111b
        shl     al, 2
        mov     ah, 0ffh                ; canal activado
        inc     bx
S3M_channel_disabled:
        mov     byte ptr [edi], al
        mov     byte ptr [ebp], ah
        inc     edi
        inc     ebp
        loop    S3M_convert_panning

        mov     NumChannels, bx

; ---------------------------------------------------------------------------
; Cargar los orders

        movzx   eax, NumOrders
        fread   handle, orders, eax

; ---------------------------------------------------------------------------
; Cargar los instrumentos


        movzx   eax, NumInstrs
        shl     eax, 1
        fread   handle, tmp, eax

        movzx   ecx, NumInstrs
        mov     esi, offset tmp
        xor     ebx, ebx
        xor     edx, edx
S3M_load_instrument:
        inc     ebx
        xor     eax, eax
        lodsw
        shl     eax, 4
        fseek   handle, SEEK_START, eax
        fread   handle, tmp2, 50h

        push    ecx esi                 ; Copiar el nombre del fichero
        mov     esi, offset tmp2+1
        mov     edi, ebx
        shl     edi, 4
        add     edi, offset sample_dosfilename
        mov     ecx, 12
        rep     movsb
        mov     ecx, 4
        xor     al, al
        rep     stosb
        pop     esi ecx


        push    ecx esi                 ; Copiar el nombre del sample
        mov     esi, offset tmp2+30h
        mov     edi, ebx
        shl     edi, 7
        add     edi, offset sample_name
        mov     ecx, 28
        rep     movsb
        mov     ecx, 128-28
        xor     al, al
        rep     stosb
        pop     esi ecx


        mov     C2SPD[ebx*4], 0
        mov     sample_length[ebx*4], 0
        mov     loopstart[ebx*4], 0
        mov     loopend[ebx*4], 0
        mov     sample_volume[ebx], 0


        mov     eax, dword ptr [tmp2+4ch]
        cmp     eax, 'SRCS'
        jne     S3M_sample_vacio






        mov     eax, dword ptr [tmp2+20h]
        mov     C2SPD[ebx*4], eax

        mov     eax, dword ptr [tmp2+10h]
        mov     sample_length[ebx*4], eax
        add     edx, eax

        mov     al, byte ptr [tmp2+1fh]
        test    al, 1
        jz      S3M_sample_sin_loop


        mov     eax, dword ptr [tmp2+14h]
        mov     loopstart[ebx*4], eax
        mov     eax, dword ptr [tmp2+18h]
        mov     loopend[ebx*4], eax

S3M_sample_sin_loop:
        mov     al, byte ptr [tmp2+1ch]
        mov     sample_volume[ebx], al

        mov     eax, dword ptr [tmp2+0ch]
        shr     eax, 12
        mov     sample_fileptr[ebx*4], eax
S3M_sample_vacio:
        loop    S3M_load_instrument

        mov     samples_filesize, edx

; ---------------------------------------------------------------------------
; Cargar los patterns


        movzx   eax, NumInstrs
        shl     eax, 1
        movzx   ebx, NumOrders
        add     eax, ebx
        add     eax, 60h
        fseek   handle, SEEK_START, eax

        movzx   eax, NumPatts
        shl     eax, 1
        fread   handle, tmp, eax        ; En tmp est n los punteros a los patterns

        mov     esi, offset tmp

        movzx   ebp, NumPatts
        movzx   edx, NumChannels
        imul    edx, 64*6               ; 64*6
        imul    edx, ebp                ; bytes totales
        mov     ecx, edx
        mov     mem_patterns, edx

        alloc_mem
        ;mov     ax, 0ee42h
        ;int     31h
        jc      S3M_no_memory           ; edx = puntero a memoria

;        mov     al, 0 ; 0ffh
;        mov     edi, edx
;        rep     stosb


; נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
        PUSH    EDX

        movzx   ebp, NumPatts
        movzx   edx, NumChannels
        imul    edx, 64
        imul    edx, ebp                ; bytes totales
        mov     ecx, edx

        ;MOV     EDX, ECX
        ALLOC_MEM

        mov     orig_ptr, edx

        mov     al, 0 ; 0ffh
        mov     edi, edx
        cld
        rep     stosb

        POP     EDX
; נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ


        movzx   ecx, NumPatts
        xor     ebp, ebp                ; ebp = n£mero del pattern
S3M_Load_Pattern:
        push    ecx

        xor     eax, eax
        lodsw
        shl     eax, 4

        push    esi

        fseek   handle, SEEK_START, eax

        fread   handle, tmp2, 2
        xor     ecx, ecx
        mov     cx, word ptr [tmp2]
        MOV     PEPE, ECX
        fread   handle, tmp2, ecx


        mov     pattern[ebp*4], edx
; נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
        PUSH    EDX
        MOV     EDX, ORIG_PTR
        mov     orig_patterns[ebp*4], edx
        POP     EDX
; נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
        push    edi ecx
        xor     ecx, ecx
        mov     cx, NumChannels
        shl     ecx, 6
        mov     edi, edx
S3M_vaciar_pattern:
        mov     word ptr [edi], 000ffh
        mov     dword ptr [edi+2], 0
        add     edi, 6
        loop    S3M_vaciar_pattern
        pop     ecx edi


        mov     esi, offset tmp2

        push    ebp
        xor     ebp, ebp                ; ahora lo usamos para contar rows
S3M_load_row:
        cmp     ebp, 64
        je      S3M_end_pattern
        lodsb
        or      al, al
        je      S3M_end_row

        DEC     PEPE
        JS      S3M_end_pattern

        mov     ah, al
        and     ah, 31
        movzx   edi, ah                 ; edi = canal

        ;CMP     DI, NumChannels
        ;JAE     S3M_no_coger_nota

        xor     ebx, ebx
        mov     ah, -1

        test    al, 32
        jz      S3M_no_coger_nota
        mov     bh, byte ptr [esi]
        inc     esi
        mov     bl, byte ptr [esi]
        inc     esi

        ;MOV     BL, 1

        CMP     BH, 0FFH                ; Empty note
        JNE     S3M_no_coger_nota

        MOV     BH, 0

S3M_no_coger_nota:
        shl     ebx, 16

        test    al, 64
        jz      S3M_no_coger_volumen
        mov     ah, byte ptr [esi]
        inc     esi
S3M_no_coger_volumen:

        test    al, 128
        jz      S3M_no_coger_comando
        mov     bh, byte ptr [esi]
        inc     esi
        mov     bl, byte ptr [esi]
        inc     esi

        call    S3M_convertir_comando

S3M_no_coger_comando:

        CMP     DI, NumChannels
        JAE     S3M_load_row


; נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
        PUSH    EDI EBP EAX
        MOV     EAX, EDI

        MOVZX   EDI, NumChannels
        IMUL    EDI, EBP

        ADD     EDI, ORIG_PTR
        ADD     EDI, EAX

        MOV     EAX, EBX
        SHR     EAX, 16

        MOV     BYTE PTR [EDI], AH

        POP     EAX EBP EDI
; נננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ


        ;imul    edi, 6                  ; calcular la pos. dentro del row
        LEA     EDI, [EDI * 2 + EDI]
        SHL     EDI, 1

        push    ebx ebp
        movzx   ebx, NumChannels
        imul    ebp, ebx
        ;imul    ebp, 6 ;8


        LEA     EBP, [EBP * 2 + EBP]
        SHL     EBP, 1

        add     edi, ebp
        pop     ebp ebx




nosdfosdfsnod:

        add     edi, edx
        mov     byte ptr [edi+4], bl    ; par metro del comando
        mov     byte ptr [edi+5], bh    ; comando
        shr     ebx, 16
        ;mov     byte ptr [edi+2], bh    ; nota
        mov     byte ptr [edi+1], bl      ; instrumento
        mov     byte ptr [edi], ah    ; volumen


        cmp     bh, 0feh ; keyoff
        jae     convertkeyoff
endkeyoff:
        ;cmp     bl, 0
        CMP     BH, 0               ; JURLLLLL
        je      noconvertnoteeee


        pusha
        movzx   eax, bh
        and     al, 0fh
        movzx   eax, word ptr converts3mnote[eax*2]
        shr     bh, 4
        movzx   ecx, bh

        ;mov     ebp, 8363
        ;mul     ebp

        or      bh, bh
        jz      nodividirporecx

        shl     eax, 4              ; BUG
        shr     eax, cl

;dividirporecx:
;        shr     edx, 1
;        rcr     eax, 1
;        loop    dividirporecx

nodividirporecx:
        movzx   ebp, bl

;        cmp     c2spd[ebp*4], 0
;        je      noconvertnoteeee2

;        xor     edx, edx
        ;div     c2spd[ebp*4]

        cmp     eax, 0
        je      noconvertnoteeee2

        ;SHR     AX, 2
        mov     word ptr [edi+2], ax    ; nota
noconvertnoteeee2:
        popa

        jmp     S3M_load_row

noconvertnoteeee:
        mov     word ptr [edi+2], 0     ; nota
        jmp     S3M_load_row

convertkeyoff:
        mov     word ptr [edi+2], -1 ; nota  ******ANTES ERA UN DWORD!!!****
        jmp     S3M_load_row ;endkeyoff

S3M_end_row:
        inc     ebp
        jmp     S3M_load_row

S3M_end_pattern:


        ;movzx   ebp, NumChannels
        ;imul    ebp, 64*6               ; 64*6

        movzx   ebp, NumChannels
        imul    ebp, 64                 ; 64*6
        ADD     ORIG_PTR, EBP
        imul    ebp, 6                  ; 64*6

        add     edx, ebp

        pop     ebp
        pop     esi ecx
        inc     ebp
        loop    S3M_Load_Pattern




; ---------------------------------------------------------------------------
; Cargar los samples

        mov     edx, samples_filesize
        alloc_mem
        ;mov     ax, 0ee42h
        ;int     31h
        jc      S3M_no_memory           ; edx = puntero a memoria

        movzx   ecx, NumInstrs
        mov     esi, offset sample_fileptr+4
        xor     ebp, ebp
S3M_load_sample:
        inc     ebp
        lodsd
        cmp     dword ptr sample_length[ebp*4], 0
        je      S3M_noleernada
        fseek   handle, SEEK_START, eax
        mov     eax, sample_length[ebp*4]
        mov     samples[ebp*4], edx
        fread   handle, [edx], eax

        cmp     sample_sign, 2
        jne     S3M_do_not_negate


        push    ecx esi eax
        mov     ecx, eax
        mov     edi, edx
        mov     esi, edx
S3M_convert_2_signed:
        lodsb
        add     al, 80h
        stosb
        loop    S3M_convert_2_signed
        pop     eax esi ecx

S3M_do_not_negate:
        add     edx, sample_length[ebp*4]
S3M_noleernada:
        loop    S3M_load_sample


        print   loadok

; ---------------------------------------------------------------------------
        mov     eax, 00h
        clc

S3M_Exit:

;        mov     eax, 0
;        call    SavePattern

        pop     ebp edi esi edx ecx ebx
        ret
; ---------------------------------------------------------------------------
S3M_not_found:
        mov     eax, 01h                ; Salida con c¢digo de error 01
        stc
        jmp     S3M_Exit
S3M_bad_file:
        mov     ah, 3eh
        mov     bx, handle
        int     21h
        mov     eax, 03h                ; Salida con c¢digo de error 03
        stc
        jmp     S3M_Exit
S3M_no_memory:
        mov     ah, 3eh
        mov     bx, handle
        int     21h
        mov     eax, 02h                ; Salida con c¢digo de error 02
        stc
        jmp     S3M_Exit
S3M_load_error:
        mov     ah, 3eh
        mov     bx, handle
        int     21h
        mov     eax, 04h                ; Salida con c¢digo de error 04
        stc
        jmp     S3M_Exit
        
S3M_Load        ENDP


S3M_convertir_comando   PROC
        cmp     bh, 'C' - 64
        je      S3M_pattbreak
        cmp     bh, 'B' - 64
        je      S3M_posjump
        cmp     bh, 'A' - 64
        je      S3M_changetempo
        cmp     bh, 'T' - 64
        je      S3M_changebpms
        cmp     bh, 'F' - 64
        je      S3M_slideup
        cmp     bh, 'E' - 64
        je      S3M_slidedn
        cmp     bh, 'G' - 64
        je      S3M_slide2note
        cmp     bh, 'D' - 64
        je      S3M_volumeslide
        cmp     bh, 'O' - 64
        je      S3M_sampleoffset
        cmp     bh, 'J' - 64
        je      S3M_arpeggio

        cmp     bh, 'X' - 64
        je      S3M_sincronia

        cmp     bh, 'L' - 64
        je      S3M_tonevol

        cmp     bh, 'Q' - 64
        je      S3M_retrig

        xor     bx, bx



endconversion:
        ret

S3M_pattbreak:
        push    eax
        mov     bh, 0dh
        xor     eax, eax
        mov     al, bl
        shr     al, 4
        lea     eax, [eax * 4 + eax]
        shl     eax, 1
        and     bl, 0fh
        add     al, bl
        adc     ah, 0
        mov     bl, al
        pop     eax
        jmp     endconversion
S3M_posjump:
        mov     bh, 0bh
        jmp     endconversion

S3M_changetempo:
        mov     bh, 25h ; juuuurururururllllll
        jmp     endconversion
S3M_changebpms:
;        mov     bh, 0fh
        mov     bh, 24h ; juuuurururururllllll
;        add     bl, 32
        jmp     endconversion

S3M_slideup:
        mov     bh, 1h
        jmp     endconversion

S3M_slidedn:
        mov     bh, 2h
        jmp     endconversion

S3M_slide2note:
        mov     bh, 3h
        jmp     endconversion

S3M_volumeslide:
        mov     bh, 0ah
        jmp     endconversion

S3M_sampleoffset:
        mov     bh, 09h
        jmp     endconversion

S3M_arpeggio:
        mov     bh, 00h
        jmp     endconversion

S3M_sincronia:
        mov     bh, 01ch
        jmp     endconversion

S3M_tonevol:
        mov     bh, 05h
        jmp     endconversion

S3M_retrig:
        mov     bh, 01bh
        jmp     endconversion

S3M_convertir_comando   ENDP










SavePattern     PROC
        pushfd
        pushad

        mov     esi, eax

        add     al, 'A'
        mov     byte ptr filepat[5], al

        mov     edx, offset filepat
        mov     ah, 3ch
        mov     ecx, 0
        int     21h
        mov     bx, ax
        mov     ecx, 16*6*64
        mov     edx, pattern[esi*4]
        mov     ah, 40h
        int     21h
        mov     ah, 3eh
        int     21h

        popad
        popfd

        ret

        filepat         db 'PATT_A.',0

SavePattern     ENDP



END
