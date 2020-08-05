        include MODPLAY.DEF

JUMPS
.486P
.MODEL  FLAT
        assume cs:@code, ds:@data, es:@data
        include pajavi.h
.CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± PUBLIC ±±

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° FUNCIONES °°
        PUBLIC  LoadModule

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° VARIABLES °°
        PUBLIC  handle, tmp, tmp2

        PUBLIC  filetype, SongName, handle
        PUBLIC  NumOrders, NumPatts, NumInstrs, NumChannels
        PUBLIC  panning, channel_info, orders, pattern
        PUBLIC  sample_dosfilename, sample_name, loopstart, loopend
        PUBLIC  C2SPD

        PUBLIC  samples, sample_volume, sample_fileptr, sample_length
        PUBLIC  samples_filesize, sample_sign, mem_patterns

        PUBLIC  TEMPO, BPM

        PUBLIC  PattNRows

        PUBLIC orig_patterns, orig_ptr

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± EXTRN ±±
        EXTRN   S3M_Load:NEAR, MOD_Load:NEAR, XM_Load:NEAR ;, IT_Load:NEAR

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± DATA ±±
.DATA?
        filetype                db ?

        SongName                db 128 dup(?)
        handle                  dw ?
        NumOrders               dw ?
        NumPatts                dw ?
        NumInstrs               dw ?
        NumChannels             dw ?
        panning                 db MAX_NCHANNELS dup(?)
        channel_info            db MAX_NCHANNELS dup(?)
        orders                  db MAX_ORDERS dup(?)
        pattern                 dd MAX_PATTERNS dup(?)
        sample_dosfilename      db MAX_NINSTRS*16 dup(?)
        sample_name             db MAX_NINSTRS*128 dup(?)
        C2SPD                   dd MAX_NINSTRS dup(?)
        loopstart               dd MAX_NINSTRS dup(?)
        loopend                 dd MAX_NINSTRS dup(?)

        samples                 dd MAX_NINSTRS dup(?)
        sample_volume           db MAX_NINSTRS dup(?)
        sample_fileptr          dd MAX_NINSTRS dup(?)
        sample_length           dd MAX_NINSTRS dup(?)
        samples_filesize        dd ?
        sample_sign             db ?
        mem_patterns            dd ?

        PattNRows               label word
                                dw MAX_PATTERNS dup(?)

        tmp                     label byte
                                db 65536 dup(?)
        tmp2                    label byte
                                db 65536 dup(?)

        TEMPO                   db ?
        BPM                     db ?


        orig_patterns           dd MAX_PATTERNS dup(?)
        orig_ptr                dd ?
.DATA
        EmptyPattern            dw 64*32 dup(00ffh,0,0)

        msg_intro               db 1,9h
                                db 'ÚÄÄÄÄÄÄ-Ä--Äù-ùùúúú                     ú     ú úúùúù-ù-Ä-ÄÄ-ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',13
                                db '³',1,0fh,' MOD Player ',1,7,' version 2.06 á                    ',1,3,'><',1,7, ' In Stereo (where available) ',1,9h,'³',13
                                db '³',1,3,' Demon ',1,7,'of ',1,11,'The DarkRising',1,7,', 22/07/1999                    "Quid Vobis Videtur?" ',1,9h,'³',13
                                db '³',1,7,' Released at ...',1,0fh,' E U S K A L    P A R T Y    V I I     ',1,7,'      La vamos a armar ',1,9h,'³',13
                                db 'ÀÄÄÄÄÄÄÄÄÄÄÄÄ-ÄÄÄ-Ä--Äù-ù-ùù-ùùúùúúú úú    ú                 ú  úúúùùú-Ä-ÄÄÄ-ÄÄÙ',13,0

        copyright               db 0

        ANCHOX                  dd 160
        ANCHOY                  dd 25
        SCREENBYTES             dd 4000

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± CODE ±±
.CODE



;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° LoadModule °°
; Entrada :     DS:EDX - Puntero al nombre del fichero
; Salida  :     CF = 0 + EAX = 0 si no hay error,
;               CF = 1 + EAX = C¢digo de error:
;                               01 = No se encuentra el fichero
;                               02 = No hay memoria
;                               03 = No es formato MOD ni S3M
;                               04 = Error interno de carga del fichero
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
LoadModule              PROC
        e
        PUSH    EBP
        pushad


        cmp     copyright, 0
        jne     mensyapuesto
        mov     esi, offset msg_intro
        call    xprint
        mov     copyright, 0ffh
mensyapuesto:

        mov     edi, offset pattern
        mov     ecx, MAX_PATTERNS
        mov     eax, offset EmptyPattern
        cld
        rep     stosd

        mov     edi, offset PattNRows
        mov     ecx, MAX_PATTERNS
        mov     ax, 64
        cld
        rep     stosw

        popad

comment „
        mov     filetype, 4             ; Suponer que el fichero es IT
        call    IT_Load                 ; Cargamos IT
        jnc     module_loaded_ok        ; Si todo va bien, salimos
        cmp     eax, 02
        je      salirdeaquicorriendo
        cmp     eax, 04
        je      salirdeaquicorriendo
        „

        mov     filetype, 3             ; Suponer que el fichero es XM
        call    XM_Load                 ; Cargamos XM
        jnc     module_loaded_ok        ; Si todo va bien, salimos

comment „
        cmp     eax, 02
        je      salirdeaquicorriendo
        cmp     eax, 04
        je      salirdeaquicorriendo

        mov     filetype, 2             ; Suponer que el fichero es S3M
        call    S3M_Load                ; Cargamos S3M
        jnc     module_loaded_ok        ; Si todo va bien, salimos
        cmp     eax, 02
        je      salirdeaquicorriendo
        cmp     eax, 04
        je      salirdeaquicorriendo

        mov     filetype, 1             ; Suponemos que es un MOD ...
        call    MOD_Load                ; ... lo cargamos
        jnc     module_loaded_ok        ; ¨Todo bien?
        „


        mov     filetype, 0             ; Nos ha jod¡o...
        jmp     salirdeaquicorriendo    ; hala... pues vamonos de aqu¡...
;        jc      salirdeaquicorriendo    ; hala... pues vamonos de aqu¡...

module_loaded_ok:
        xor     eax, eax
        POP     EBP
        clc
        s
        ret

salirdeaquicorriendo:
        POP     EBP
        stc
        s
        ret

LoadModule              ENDP








;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± XPRINT ±±


getxy           macro
        push    dx
        xor     eax, eax
        mov     dx, 3d4h
        mov     al, 0eh
        out     dx, al
        inc     dx
        in      al, dx
        mov     ah, al
        dec     dx
        mov     al, 0fh
        out     dx, al
        inc     dx
        in      al, dx
        shl     eax, 1
        pop     dx
        endm

setxy           macro
        push    bx dx
        shr     ebx, 1
        xor     eax, eax
        mov     dx, 3d4h
        mov     al, 0eh
        out     dx, al
        inc     dx
        mov     al, bh
        out     dx, al
        mov     ah, al
        dec     dx
        mov     al, 0fh
        out     dx, al
        inc     dx
        mov     al, bl
        out     dx, al

        push    ax bx dx edi

        mov     edi, 450h

        mov     ax, 80
        xchg    bx, ax
        xor     dx, dx
        div     bx
        mov     byte ptr [edi+1], al
        imul    dx, 80
        mov     byte ptr [edi], dl

        pop     edi dx bx ax

        pop     dx bx
        endm


.CODE
;        PUBLIC  xprint

xprint          PROC
        push    ax
        getxy
        mov     edi, eax
        mov     ebx, edi
        add     edi, 0b8000h
        pop     ax
poner:
        lodsb
        or      al, al
        jz      endprint
        cmp     al, 13
        je      intro
        cmp     al, 1
        je      cambiarcolor
        stosb
        or      ah, ah
        jz      nocolor
        mov     byte ptr [edi], ah
nocolor:
        inc     edi
        jmp     poner

cambiarcolor:
        lodsb
        mov     ah, al
        jmp     poner

intro:
        add     ebx, 160
        cmp     ebx, 4000
        jae     scroll
finscroll:
        mov     edi, ebx
        add     edi, 0b8000h
        jmp     poner

scroll:
        push    eax esi edi
        mov     ecx, 1000-40
        mov     edi, 0b8000h
        mov     esi, edi
        add     esi, 160
        cld
        rep     movsd
        sub     ebx, 160
        mov     ecx, 40
        mov     eax, 07200720h
        rep     stosd
        pop     edi esi eax
        jmp     finscroll

endprint:

        setxy
        ret
xprint          ENDP



END
