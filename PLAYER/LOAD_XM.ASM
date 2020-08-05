;-----------------------------------------------------------------------------
; LOAD_XM
;-----------------------------------------------------------------------------
; Entrada :     EDX : Puntero al nombre del fichero
; Salida  :     CF = 0 + EAX = 0 si no hay error,
;               CF = 1 + EAX = C¢digo de error:
;                               01 = No se encuentra el fichero
;                               02 = No hay memoria
;                               03 = No es formato XM
;                               04 = Error interno de carga del fichero
;-----------------------------------------------------------------------------
JUMPS
.386P
.MODEL  FLAT
        assume cs:@code, ds:@data, es:@data
.CODE
        public  XM_Load

        include MODPLAY.DEF
        include MODPLAY.INC
        include FILES.INC
        include MEM.INC
        include \src\ttl\utils.inc

        EXTRN   handle  :WORD
        EXTRN   tmp     :BYTE
        EXTRN   tmp2    :BYTE

.DATA
        periodtab label word
                dw    907,900,894,887,881,875,868,862,856,850,844,838,832,826,820,814
                dw    808,802,796,791,785,779,774,768,762,757,752,746,741,736,730,725
                dw    720,715,709,704,699,694,689,684,678,675,670,665,660,655,651,646
                dw    640,636,632,628,623,619,614,610,604,601,597,592,588,584,580,575
                dw    570,567,563,559,555,551,547,543,538,535,532,528,524,520,516,513
                dw    508,505,502,498,494,491,487,484,480,477,474,470,467,463,460,457
                dw    453,450,447,443,440,437,434,431,428,425,422,419,416,413,410,407
                dw    404,401,398,395,392,389,386,383,381,378,376,373,370,368,365,363
;               dw    360,   ,                        339

        loading         db 'þ Loading Fasttracker [XM] Module ... ',0
        loadok          db 'OK.',13,10,0

.DATA?
        pattern_start           dd ?
        samples_start           dd ?
        mempatterns             dd ?
        memsamples              dd ?
        sizesamples             dd ?

        flag                    db ?
.CODE

XM_Load         PROC
        push    ebx ecx edx esi edi ebp

; ---------------------------------------------------------------------------
        mov     ax, 3d00h               ; Funci¢n abrir fichero
        int     21h
        jc      file_not_found
        mov     handle, ax
; ---------------------------------------------------------------------------
; Comprobamos que se trata de un fichero S3M

        fseek   handle, SEEK_START, 0
        fread   handle, tmp, 80 ;64

        mov     eax, dword ptr [tmp]
        cmp     eax, 'etxE'
        jne     bad_file
        mov     eax, dword ptr [tmp+4]
        cmp     eax, 'dedn'
        jne     bad_file
        mov     eax, dword ptr [tmp+8]
        cmp     eax, 'doM '
        jne     bad_file
        mov     eax, dword ptr [tmp+12]
        cmp     eax, ':elu'
        jne     bad_file

        mov     al, byte ptr [tmp+37]
        cmp     al, 1ah
        jne     bad_file


;        finit      ;juuuuuuuuuuuuuuuuuuuuuur ***


; ---------------------------------------------------------------------------
; Cargamos el t¡tulo de la canci¢n

        mov     esi, offset tmp+17
        mov     edi, offset SongName
        mov     ecx, 20
        rep     movsb


        print   loading

; ---------------------------------------------------------------------------
; Cargamos el n£mero de patterns, instrumentos y orders

        mov     ax, word ptr [tmp+64]
        mov     NumOrders, ax
        mov     ax, word ptr [tmp+68]
        mov     NumChannels, ax
        mov     ax, word ptr [tmp+70]
        mov     NumPatts, ax
        mov     ax, word ptr [tmp+72]
        mov     NumInstrs, ax

        mov     ax, word ptr [tmp+76]
        mov     TEMPO, al
        mov     ax, word ptr [tmp+78]
        mov     BPM, al


; ---------------------------------------------------------------------------
; Cargar los orders

        fread   handle, orders, 256

; ---------------------------------------------------------------------------
        mov     eax, dword ptr [tmp+60]         ; Header size
;        fseek   handle, SEEK_START, eax



;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        ; Primero miramos cuanto ocupan los patterns en el fichero
        ; y en memoria.

        ftell   handle
        mov     pattern_start, eax

        xor     edx, edx
        xor     ebp, ebp        ; rows totales
look_patterns:
        push    edx

        fread   handle, tmp, 9
        xor     ebx, ebx
        mov     bx, word ptr [tmp+5]
        mov     PattNRows[edx*2], bx

        add     ebp, ebx

        xor     edx, edx
        mov     dx, word ptr [tmp+7]

        mov     eax, dword ptr [tmp]
        sub     eax, 9
        add     eax, edx
        fseek   handle, SEEK_CURRENT, eax

        pop     edx
        inc     edx
        cmp     dx, NumPatts
        jb      look_patterns


        ; Alojar memoria para los patterns

        xor     ebx, ebx
        mov     bx, NumChannels
        imul    ebx, 6
        imul    ebx, ebp                ; ebx = bytes totales


        mov     ecx, ebx
        shr     ebx, 16
        ;mov     ax, 0501h
        ;int     31h
        CALL    MALLOC
        jc      nomem

        ;shl     ebx, 16
        ;mov     bx, cx


        mov     mempatterns, ebx







;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        ; Miramos cu nto ocupan los samples


        ftell   handle
        mov     samples_start, eax



        xor     ebp, ebp
        movzx   ecx, NumInstrs
nextinstr:
        push    ecx

        xor     edi, edi

        fread   handle, tmp, 29
        mov     esi, offset tmp

        mov     eax, dword ptr [tmp]            ; Instrument size
        sub     eax, 29
        mov     bx, word ptr [tmp+27]           ; Number of samples in instrument

        or      bx, bx
        jz      nohaysamples

        fread   handle, tmp+29, eax ;214 ;-29
        

        movzx   ecx, bx
nextsampleininstr:
        fread   handle, tmp2, 40

        add     ebp, dword ptr [tmp2]
        add     edi, dword ptr [tmp2]

        loop    nextsampleininstr

        ; Nos saltamos los samples

        fseek   handle, SEEK_CURRENT, edi

        jmp     sihaysamples

nohaysamples:

        fseek   handle, SEEK_CURRENT, eax

sihaysamples:
        pop     ecx
        loop    nextinstr


        mov     sizesamples, ebp


        ; Alojar memoria para los samples

        mov     ebx, ebp


        mov     ecx, ebx
        shr     ebx, 16
        ;mov     ax, 0501h
        ;int     31h
        CALL    MALLOC
        jc      nomem

        ;shl     ebx, 16
        ;mov     bx, cx


        mov     memsamples, ebx




;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        ; Cargar los samples

;        int 3

        xor     edx, edx
        mov     ecx, MAX_NINSTRS
vaoidoicc:
        mov     C2SPD[edx*4], 0
        mov     sample_length[edx*4], 0
        mov     loopstart[edx*4], 0
        mov     loopend[edx*4], 0
        mov     sample_volume[edx], 0
        inc     edx
        loop    vaoidoicc








        mov     eax, samples_start
        fseek   handle, SEEK_START, eax


        
        xor     edx, edx
        mov     esi, memsamples
        movzx   ecx, NumInstrs
load_nextinstr:
        push    ecx

        inc     edx                        ; Contador
        xor     edi, edi

        fread   handle, tmp, 29
;        mov     esi, offset tmp

        mov     eax, dword ptr [tmp]            ; Instrument size
        sub     eax, 29
        mov     bx, word ptr [tmp+27]           ; Number of samples in instrument

        or      bx, bx
        jz      load_nohaysamples

        fread   handle, tmp+29, eax ;214 ;-29
        


        movzx   ecx, bx
load_nextsampleininstr:
        fread   handle, tmp2, 40

        add     ebp, dword ptr [tmp2]
        add     edi, dword ptr [tmp2]

        mov     eax, dword ptr [tmp2]

        or      eax, eax
        jz      nohaynadadenada

        mov     sample_length[edx*4], eax

        xor     eax, eax
        xor     ebx, ebx
        test    byte ptr [tmp2+14], 11b
        jz      noloop

        mov     eax, dword ptr [tmp2+4]
        mov     ebx, dword ptr [tmp2+8]
        add     ebx, eax
noloop:
        mov     loopstart[edx*4], eax
        mov     loopend[edx*4], ebx

        mov     al, byte ptr [tmp2+14]
        mov     flag, al

        test    flag, 10h
        jz      noshr

        shr     loopstart[edx*4], 1
        shr     loopend[edx*4], 1
        shr     sample_length[edx*4], 1
noshr:

        mov     al, byte ptr [tmp2+12]
        mov     sample_volume[edx], al

        mov     al, byte ptr [tmp2+16]
        mov     byte ptr C2SPD[edx*4], al

nohaynadadenada:

        loop    load_nextsampleininstr




        ; Cargamos los samples

        mov     samples[edx*4], esi

        or      edi, edi
        jz      nohaynadarl

        fread   handle, [esi], edi

        push    ecx esi edi             ; Convertir el sample

        ;int 3

        mov     al, flag
        test    al, 10h
        jz      bits8

        mov     ecx, edi
        mov     edi, esi
        mov     bx, 0
;        shl     ecx, 1
convertsampledata16:
        lodsw
        add     ax, bx
        push    ax
        sar     ax, 8
        ;mov     al, 0
        stosb
        pop     ax
        mov     bx, ax
        loop    convertsampledata16

        pop     edi esi ecx

        shr     edi, 1
        add     esi, edi

        jmp     bits16

bits8:
        mov     ecx, edi
        mov     edi, esi
        mov     ah, 0
convertsampledata:
        lodsb
        add     al, ah
        stosb
        mov     ah, al
        loop    convertsampledata

        pop     edi esi ecx

        add     esi, edi

bits16:

nohaynadarl:

        jmp     load_sihaysamples

load_nohaysamples:

        fseek   handle, SEEK_CURRENT, eax

load_sihaysamples:
        pop     ecx
        loop    load_nextinstr





;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        ; Cargar los patterns

        mov     eax, pattern_start
        fseek   handle, SEEK_START, eax

        mov     edi, mempatterns

        xor     edx, edx
        xor     ebp, ebp        ; rows totales
load_patterns:
        push    edx

        fread   handle, tmp, 9
        xor     ebx, ebx
        mov     bx, word ptr [tmp+5]
        mov     PattNRows[edx*2], bx

        mov     pattern[edx*4], edi
        

        mov     eax, dword ptr [tmp]
        sub     eax, 9
        fseek   handle, SEEK_CURRENT, eax

        xor     eax, eax
        mov     ax, word ptr [tmp+7]
        fread   handle, tmp2, eax


        mov     esi, offset tmp2

        xor     ecx, ecx
        mov     cx, PattNRows[edx*2]
cargar_rows:
        push    ecx edx

        xor     ecx, ecx
        mov     cx, NumChannels
cargar_canales:
        push    ecx

        xor     ax, ax
        xor     bx, bx
        xor     dx, dx

        mov     dl, -1


        mov     cl, byte ptr [esi]
        inc     esi

        test    cl, 80h
        jnz     comprimido

        mov     al, cl

        ; AX=NOTE

        mov     dh, byte ptr [esi]      ; Sample num
        inc     esi

        mov     dl, byte ptr [esi]      ; Volume column
        inc     esi

        mov     bh, byte ptr [esi]      ; Effect type
        inc     esi

        mov     bl, byte ptr [esi]      ; Effect parameter
        inc     esi

        jmp     no_comprimido

comprimido:
        xor     ax, ax
        xor     bx, bx
        xor     dx, dx

        mov     dl, -1

        test    cl, 1
        jz      noreadnote

        lodsb

noreadnote:
        test    cl, 2
        jz      noreadinstr

        mov     dh, byte ptr [esi]      ; Sample num
        inc     esi

noreadinstr:
        test    cl, 4
        jz      noreadvolume

        mov     dl, byte ptr [esi]      ; Volume column

        cmp     dl, 50h
        jb      es_un_volumen

        mov     dl, -1
        jmp     noesovodov
es_un_volumen:
        SUB     DL, 10H
        AND     DL, 63

noesovodov:

        inc     esi

noreadvolume:
        test    cl, 8
        jz      noreadeffect

        mov     bh, byte ptr [esi]      ; Effect type
        inc     esi

noreadeffect:
        test    cl, 16
        jz      noreadparam

        mov     bl, byte ptr [esi]      ; Effect parameter
        inc     esi

noreadparam:


no_comprimido:
        or      ax, ax
        jz      nohaynota


        cmp     al, 61h
        jne     nosilencio
        mov     ax, 0ffffh
        jmp     nohaynota
nosilencio:

    comment ¤


        push    esi ebx
        movzx   esi, dh
        movsx   bx, byte ptr C2SPD[esi*4]      ; BUG
        add     ax, bx
        pop     ebx esi
;--------------------------------------------
;        movzx   eax, ax
;        mov     ax, word ptr convertxmnote[eax*2]
;        shl     ax, 4
;--------------------------------------------
;        movzx   ecx, ax
;        shl     ecx, 6
;        mov     eax, 6*12*16*4 ;7680
;        sub     eax, ecx
;--------------------------------------------
;        int 3

        push    eax edx ebp

        movzx   eax, ax

        xor     edx, edx
        mov     ebp, 12
        div     ebp

        shl     edx, 3

;       CMP     EDX, 6*12
;       JB      NOSALIR

;       MOV     AX, 4C00H
;       INT     21H

NOSALIR:
        movzx   ebp, word ptr periodtab[edx*2]

        shl     ebp, 1

        ;mov     note, eax

        comment „
        fild    note
        fld1
        fidiv   dieciseis
        fscale

        fld1
        fdivrp  st(1), st

        mov     note, ebp

        fimul   note

        fistp   period

        fistp   note
        ;„

        ; a=(2^eax)/16
        ; period=(1/a)*ebp

        ; period=(1/((2^eax)/16))*ebp;

        mov     ecx, eax
        mov     eax, 1
        shl     eax, cl
        SHR     EAX, 4
        mov     ecx, eax
        mov     eax, ebp
        xor     edx, edx
        div     eCX
        mov     period, eax

        pop     ebp edx eax


        mov     ax, word ptr period

        jmp     nohaynota

        note            dd 0
        dieciseis       dd 16
        period          dd 0

    ¤

nohaynota:


;        mov     ax, 5712

        ;MOV     AX, 2000
        ;MOV     DL, -1
        ;MOV     BX, 0



        mov     word ptr [edi], dx
        mov     word ptr [edi+2], ax
        mov     word ptr [edi+4], bx
        
        add     edi, 6

        pop     ecx

        loop    cargar_canales

        pop     edx ecx
        loop    cargar_rows
        

        

        pop     edx
        inc     edx
        cmp     dx, NumPatts
        jb      load_patterns





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




        mov     ah, 3eh
        mov     bx, handle
        int     21h


;        xor     eax, eax
;        mov     ecx, 20
;dfsdf:
;        inc     eax
;        call    SaveSample
;        loop    dfsdf

        ;mov     eax, 0
        ;call    SavePattern


        print   loadok


        pop     ebp edi esi edx ecx ebx
        xor     eax, eax
        clc
        ret


; ---------------------------------------------------------------------------
file_not_found:
        pop     ebp edi esi edx ecx ebx
        mov     eax, 1
        stc
        ret

bad_file:
        mov     ah, 3eh
        mov     bx, handle
        int     21h

        pop     ebp edi esi edx ecx ebx
        mov     eax, 3
        stc
        ret

nomem:
        mov     ah, 3eh
        mov     bx, handle
        int     21h

        pop     ebp edi esi edx ecx ebx
        mov     eax, 2
        stc
        ret

XM_Load         ENDP


SaveSample      PROC
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
        mov     ecx, sample_length[esi*4]
        mov     edx, samples[esi*4]
        mov     ah, 40h
        int     21h
        mov     ah, 3eh
        int     21h

        popad
        popfd

        ret

        filepat         db 'SAMP_A.',0

SaveSample      ENDP



SavePattern     PROC
        pushfd
        pushad

        mov     esi, eax

        add     al, 'A'
        mov     byte ptr filepat[5], al

        mov     edx, offset filepat2
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

        filepat2        db 'PATT_A.',0

SavePattern     ENDP





comment „
        push    esi ebx
        movzx   esi, dh
        movsx   bx, byte ptr C2SPD[esi*4]      ; BUG
        add     ax, bx
        pop     ebx esi

        push    eax edx ebp

        movzx   eax, ax

        xor     edx, edx
        mov     ebp, 12
        div     ebp

        shl     edx, 3


NOSALIR:
        movzx   ebp, word ptr periodtab[edx*2]

        shl     ebp, 1


        ; a=(2^eax)/16
        ; period=(1/a)*ebp

        ; period=(1/((2^eax)/16))*ebp;

        mov     ecx, eax
        mov     eax, 1
        shl     eax, cl
        SHR     EAX, 4
        mov     ecx, eax
        mov     eax, ebp
        xor     edx, edx
        div     eCX
        mov     period, eax

        pop     ebp edx eax

        mov     ax, word ptr period
        „

END


