;;__DEBUG__       equ 0

extrn   SBBase: WORD
extrn   SBIRQ:  BYTE
extrn   SBDMA:  BYTE

BUFSIZE         equ 16384
NCHANNELS       equ 32

        include MISC.MAC
        include MIXER.MAC

JUMPS
.486P
.MODEL  FLAT
        assume cs:@code, ds:@data, es:@data
        include pajavi.h

.CODE
        include modplay.def
        include modplay.inc
        include sb.inc
        include utils.inc

;        PUBLIC  InitPlayer, PLAY, STOP, Check4Sync, PlayNote
;        PUBLIC  PlayerFlags, frecuencia

;        PUBLIC  current_period, dmabuf

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± Mixer ±±
Mixer           PROC
        video   158, 'M'

        cmp     edi, dmabuf
        jne     noprincipiodelbuf

        add     bytesmezclados, BUFSIZE

noprincipiodelbuf:

        shr     ecx, 1                          ; es stereo

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° Mezclar 1 tick °

mezcla:
        cmp     muestras, 0             ; Mirar si ya se ha completado
        je      next_tick               ; el tick.

empezar_mezcla:
        xor     eax, eax
        mov     esi, ecx                ; Nos ahorramos un PUSH

        xor     ecx, ecx                ; Contador de canales a 0
        mezcla_canal NCHANNELS          ; Macro de mezcla (1 byte por canal)
_endmixjmp_:

        video   154, ' '

        test    PlayerFlags, 1
        jz      nosurround

        video   154, 'S'

        ; VAMOS A PROBAR EL BASS

comment ¤
        movsx   ecx, ANTBASSL
        movsx   edx, ANTBASSR

        movsx   ebx, ax
        sar     eax, 16

        add     eax, ecx
        sar     eax, 1

        add     ebx, edx
        sar     ebx, 1

        mov     ANTBASSL, ax
        mov     ANTBASSR, bx

comment „
        add     ax, 8000h
        add     bx, 8000h
        cmp     ax, 0fffeh
        jbe     noover1
        mov     ax, 0fffeh
noover1:
        cmp     bx, 0fffeh
        jbe     noover2
        mov     bx, 0fffeh
noover2:
        add     ax, 8000h
        add     bx, 8000h

        „

        shl     eax, 16
        mov     ax, bx

        ¤

;comment „
        mov     bx, ax                  ; Creamos el efecto surround :
        shr     eax, 16                 ; Se pasa el inverso de un canal al
        mov     cx, bx                  ; otro, un poco atenuado.
        mov     dx, ax
        sar     cx, 1
        sar     dx, 1
        neg     cx
        neg     dx
        add     ax, cx
        add     bx, dx


        shl     eax, 16
        mov     ax, bx
;        „

nosurround:

        sar     eax, 2
        add     al, 80h                 ; Convertimos a unsigned (L)
        stosb
        sar     eax, 16
        add     al, 80h                 ; Convertimos a unsigned (R)
        stosb

        dec     muestras
        mov     ecx, esi                ; Nos ahorramos un POP
        loop    mezcla

        video   158, ' '

        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° Cambio de tick/row °

next_tick:
        mov     currentdmaptr, edi
        mov     eax, ONETICK
        mov     muestras, eax

        cmp     tick_counter, 0
        je      next_row

        dec     tick_counter

; ################################################# Tratamiento de efectos
        push    eax ebx ecx edx esi edi ebp

        xor     ecx, ecx
        mov     cx, NumChannels
        xor     edi, edi
act_effect:
        mov     esi, automod_sptr[edi*4]
        cmp     dword ptr [esi], 0
        je      no_hay_nota

        mov     ax, slide[edi*2]
        or      ax, ax
        jz      no_slide

        ;int     3
        test    ah, 80h
        jnz     subir
        jmp     bajar

FINNOTASLIDE:

        MOV     ESI, AUTOMOD_SPTR[EDI*4]
        MOV     DWORD PTR [ESI], 0
        JMP     EXACTO

subir:
        MOVZX   ESI, WORD PTR CURRENT_period[edi*2]
        MOVSX   EAX, AX
        ADD     ESI, EAX
        SHR     ESI, 24
        CMP     ESI, 0FFH
        JE      exacto

        add     current_period[edi*2], ax
        js      exacto
        mov     ax, current_period[edi*2]

        cmp     ax, slideto[edi*2]
        jb      exacto
        jmp     sfgsgsfdgsfdg

bajar:
        MOVZX   ESI, WORD PTR CURRENT_period[edi*2]
        MOVZX   EAX, AX
        ADD     ESI, EAX
        CMP     ESI, 0FFFFH
        JA      exacto

        add     current_period[edi*2], ax
        mov     ax, current_period[edi*2]

        cmp     ax, slideto[edi*2]
        ja      exacto
        jmp     sfgsgsfdgsfdg

exacto:
        mov     slide[edi*2], 0
        mov     ax, slideto[edi*2]

sfgsgsfdgsfdg:
        xor     ebp, ebp
        mov     bp, ax

        or      ebp, ebp
        jz      nocalc0

        mov     current_period[edi*2], ax

        mov     eax, numero_magico
        xor     edx, edx
        div     ebp
        mov     ebp, eax
        mov     eax, constante_periodo1
        xor     edx, edx
        mul     ebp

        mov     esi, automod_decimales[edi*4]
        mov     dword ptr [esi], edx
        mov     esi, automod_incr[edi*4]
        mov     dword ptr [esi], eax
nocalc0:

;-------------------------------------

no_slide:
        cmp     volumeslide[edi], 0
        je      no_volslide

        mov     al, channel_volume[edi]

        add     al, volumeslide[edi]
        ;or      al, al
        ;jns     novolneg
        TEST    AL, 80H
        JZ      NOVOLNEG

        xor     al, al
        mov     volumeslide[edi], 0
        jmp     actvolslide
novolneg:
        cmp     al, 63
        jbe     actvolslide
        mov     al, 63
        mov     volumeslide[edi], 0
actvolslide:

        mov     channel_volume[edi], al

        mov     esi, automod_volume[edi*4]
        mov     byte ptr [esi], al



;-------------------------------------
no_volslide:

no_hay_nota:
        inc     edi
        loop    act_effect

        pop     ebp edi esi edx ecx ebx eax

        jmp     empezar_mezcla


next_row:
        cmp     row_counter, 1234h
automod_rowcounter:
        jne     nonextrow

        mov     row_counter, 0

volveramirarrow:

        xor     eax, eax
        mov     al, ordnum

        cmp     ax, NumOrders
        jb      nofinalsong

        xor     al, al
        dec     al
        mov     ordnum, al

nofinalsong:
        inc     ordnum
        mov     al, ordnum

        push    edx
        mov     dx, PattNRows[eax*2]
        mov     word ptr [automod_rowcounter-2], dx
        pop     edx

        mov     al, orders[eax]

        cmp     al, 0ffh                        ; <------- saltar 0ffh's
        jne     novolveramirarrow

        mov     ordnum, -1
        jmp     nofinalsong

novolveramirarrow:

        mov     eax, pattern[eax*4]
        mov     rowptr, eax

nonextrow:

        inc     row_counter
        pushad

        mov     al, TEMPO
        dec     al
        mov     tick_counter, al




        video   150, ' '
        test    PlayerFlags, 2
        jz      norowsync
        video   150, 'R'

        mov     al, 080h
        call    effect_sync2
        mov     al, byte ptr ordnum
        call    effect_sync2
        mov     al, byte ptr row_counter
        call    effect_sync2
norowsync:









        xor     edi, edi
get_channel:
        xor     edx, edx

        mov     slide[edi*2], 0
        mov     volumeslide[edi], 0
        mov     arpeggio[edi], 0

        mov     esi, rowptr
        mov     bx, word ptr [esi]              ; bl = volumen del canal
                                                ; bh = instrumento
        mov     dx, word ptr [esi+2]            ; dx = periodo
        mov     ax, word ptr [esi+4]            ; ah = comando
                                                ; al = parametro
        add     esi, 6
        mov     rowptr, esi

;        MOV     BL, 50;-1
        cmp     bl, -1
        je      no_hay_volumen
        mov     channel_volume[edi], bl
no_hay_volumen:

        push    eax ebx

        or      edx, edx
        jnz     SIQUEHAYNOTE
        or      bh, bh
        jz      no_note_in_this_channel

        mov     dx, current_period[edi*2]

        jmp     norecalcperiod

SIQUEHAYNOTE:
        cmp     dx, -1
        je      keyoff


        cmp     filetype, 2
        jne     noesS3M

        push    eax
        mov     eax, edx
        xor     edx, edx
        mov     ecx, 8363 ; 133808
        mul     ecx
        xor     ecx, ecx
        mov     cl, bh
        or      cl, cl
        jnz     hayinstr
        mov     cl, ant_sample[edi]
hayinstr:
        or      cl, cl
        jz      notratarperiodo23
        div     C2SPD[ecx*4]
        mov     edx, eax
notratarperiodo23:
        pop     eax

        jmp     esS3M


noesS3M:


        push    esi ebx

        or      bh, bh
        jnz     hayinstr33
        mov     bh, ant_sample[edi]
hayinstr33:
        movzx   esi, bh
        movsx   bx, byte ptr C2SPD[esi*4]      ; BUG
        add     dx, bx
        pop     ebx esi

        push    eax ebp

        movzx   eax, dx

        xor     edx, edx
        mov     ebp, 12
        div     ebp

        shl     edx, 3


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
        OR      ECX, ECX
        JZ      NOHACERDIV
        div     eCX
        mov     edx, eax

        pop     ebp eax
        JMP     ESS3M

NOHACERDIV:
        XOR     EDX, EDX
        POP     EBP EAX

esS3M:


norecalcperiod:
        cmp     bh, 0
        jne     hay_sample
        mov     bh, ant_sample[edi]


        cmp     ah, 9
        je      hay_volumen

        JMP     NOTRATARPERIODO
hay_sample:
        mov     ant_sample[edi], bh

        cmp     bl, -1
        jne     hay_volumen
        push    ebx
        movzx   ebx, bh
        mov     bl, sample_volume[ebx]
        mov     channel_volume[edi], bl
        pop     ebx

hay_volumen:

        ;

        cmp     ah, 3
        je      notratarperiodo
        cmp     ah, 5
        je      notratarperiodo

        cmp     ah, 01bh ;'R'
        jne     nohayretrig
        or      dx, dx
        jz      notratarperiodo
nohayretrig:
        mov     esi, automod_retrig[edi*4]
        mov     dword ptr [esi], -1




        mov     ebp, edx
        mov     current_period[edi*2], dx

        or      edx, edx
        jz      notratarperiodo

        ;

        mov     eax, numero_magico
        xor     edx, edx
        div     ebp
        mov     ecx, eax
        mov     eax, constante_periodo1
        xor     edx, edx
        mul     ecx

        mov     esi, automod_decimales[edi*4]           ; <<<< AQUI
        mov     dword ptr [esi], edx                    ; <<<< AQUI
        mov     esi, automod_contador[edi*4]            ; <<<< AQUI
        mov     dword ptr [esi], 0                      ; <<<< AQUI
        mov     esi, automod_incr[edi*4]                ; <<<< AQUI
        mov     dword ptr [esi], eax                    ; <<<< AQUI

        mov     esi, automod_sptr[edi*4]                ; <<<< AQUI
        movzx   ebx, bh                                 ; <<<< AQUI
        mov     eax, samples[ebx*4]                     ; <<<< AQUI
        mov     dword ptr [esi], eax                    ; <<<< AQUI

        mov     esi, automod_slen[edi*4]

        mov     edx, loopend[ebx*4]
        or      edx, edx
        jz      usar_longitud

        mov     edx, loopstart[ebx*4]
        add     edx, eax
        add     eax, loopend[ebx*4]
        jmp     usar_loopend
usar_longitud:
        add     eax, sample_length[ebx*4]
usar_loopend:
        mov     dword ptr [esi], eax


        mov     esi, automod_loop[edi*4]
        mov     dword ptr [esi], edx

        mov     edx, ebp

notratarperiodo:


        mov     al, panning[edi]
        mov     esi, automod_panning[edi*4]
        mov     byte ptr [esi], al

no_note_in_this_channel:
        pop     ebx

        mov     esi, automod_retrig[edi*4]
        mov     dword ptr [esi], -1

;        or      bh, bh                  ; ************************+
;        jz      noactvol

        mov     al, channel_volume[edi]
        mov     esi, automod_volume[edi*4]
        mov     byte ptr [esi], al

;        mov     al, panning[edi]
;        mov     esi, automod_panning[edi*4]
;        mov     byte ptr [esi], al


noactvol:

        pop     eax


        cmp     ah, 0fh
        je      effect_changespeed
        cmp     ah, 24h
        je      effect_changebpm
        cmp     ah, 25h
        je      effect_changetempo
        cmp     ah, 0dh
        je      effect_patternbreak
        cmp     ah, 0bh
        je      effect_positionjump
        cmp     ah, 1
        je      effect_slideup
        cmp     ah, 2
        je      effect_slidedn
        cmp     ah, 3
        je      effect_slideto
        cmp     ah, 9
        je      effect_sampleoffset
        cmp     ah, 0ah
        je      effect_volslide
        cmp     ah, 1ch;'S'
        je      effect_sync
        cmp     ah, 08h
        je      effect_panning
        cmp     ah, 21h
        je      effect_slideup
        cmp     ah, 22h
        je      effect_slidedn
        cmp     ah, 23h
        je      effect_slideto

        cmp     ah, 0ch
        je      effect_setvol

        cmp     ah, 05h
        je      effect_tonevolslide

        cmp     ah, 0eh
        je      effect_varios

        cmp     ah, 01bh ;'R'
        je      effect_retrig


        ;cmp     ah, 0
        ;jne     end_effect

        ;cmp     al, 0
        ;jne     effect_arpeggio

end_effect:


        inc     edi
        cmp     di, NumChannels
        jne     get_channel


        mov     eax, ONETICK
        mov     muestras, eax

        mov     al, TEMPO                       ; me lo dejabarll!!!!!!!
        dec     al
        mov     tick_counter, al






        cmp     jump, 0
        je      nosaltar

        mov     eax, jump
        mov     rowptr, eax
        mov     jump, 0

nosaltar:


        popad
        jmp     empezar_mezcla
;----------------------------------------------------------------------------
keyoff:
        mov     esi, automod_sptr[edi*4]
        mov     dword ptr [esi], 0
        jmp     no_note_in_this_channel

;----------------------------------------------------------------------------
effect_retrig:
        push    eax
        or      al, al
        jnz     noantretrig
        mov     al, antretrig[edi]
noantretrig:
        mov     antretrig[edi], al

        movzx   eax, al
        shl     eax, 9
        or      dx, dx
        jz      seguirconelretrig

        mov     esi, automod_retrigx[edi*4]
        movzx   ebx, bh
        mov     ebp, samples[ebx*4]
        mov     dword ptr [esi], ebp

        add     ebp, eax
        mov     esi, automod_retrig[edi*4]
        mov     dword ptr [esi], ebp

        mov     byte ptr [esi], al
        pop     eax
        jmp     end_effect

seguirconelretrig:

        mov     esi, automod_retrigx[edi*4]
        mov     ebp, [esi]

        add     ebp, eax
        mov     esi, automod_retrig[edi*4]
        mov     dword ptr [esi], ebp

        mov     byte ptr [esi], al
        pop     eax
        jmp     end_effect

;----------------------------------------------------------------------------
effect_panning:
        mov     esi, automod_panning[edi*4]
        shr     al, 2 ; 0-64
        mov     byte ptr [esi], al
        jmp     end_effect
;----------------------------------------------------------------------------
effect_varios:
        mov     ah, al
        shr     al, 4
        and     ah, 0fh
        cmp     al, 0ah
        je      finevolslideup

        cmp     al, 0bh
        je      finevolslidedn

        jmp     end_effect

;----------------------------------------------------------------------------
effect_changevol:
        mov     channel_volume[edi], al
        mov     esi, automod_volume[edi*4]
        mov     byte ptr [esi], al
        jmp     end_effect
;----------------------------------------------------------------------------
effect_volslide:
        or      al, al
        jnz     nuevovolslide
        mov     al, antvolumeslide[edi]
nuevovolslide:
        mov     antvolumeslide[edi], al
        mov     ah, al
        shr     ah, 4
        and     al, 0fh
        cmp     ah, 0fh
        je      finevolslidedn
        cmp     ah, 0
        je      volslidedn
        cmp     al, 0fh
        je      finevolslideup
        mov     al, ah
        jmp     volslideup
volslidedn:
        neg     al
volslideup:
        mov     volumeslide[edi], al
        jmp     end_effect

finevolslidedn:
comment „
        mov     al, channel_volume[edi]
        dec     al
        js      end_effect
        mov     channel_volume[edi], al
        mov     esi, automod_volume[edi*4]
        mov     byte ptr [esi], al
        jmp     end_effect
        „

        ror     ax, 8   ; xchg al, ah

        mov     al, channel_volume[edi]         ; NUEVO
        sub     al, ah
        jns     no_finevolslidezero1
        xor     al, al
no_finevolslidezero1:
        mov     channel_volume[edi], al
        mov     esi, automod_volume[edi*4]
        mov     byte ptr [esi], al
        jmp     end_effect


finevolslideup:
comment „
        mov     al, channel_volume[edi]
        inc     al
        cmp     al, 64
        ja      end_effect
        mov     channel_volume[edi], al
        mov     esi, automod_volume[edi*4]
        mov     byte ptr [esi], al
        jmp     end_effect
        „

        mov     al, channel_volume[edi]         ; NUEVO
        add     al, ah
        cmp     al, 63
        jbe     no_finevolslidezero2
        mov     al, 63
no_finevolslidezero2:
        mov     channel_volume[edi], al
        mov     esi, automod_volume[edi*4]
        mov     byte ptr [esi], al
        jmp     end_effect

;----------------------------------------------------------------------------
effect_tonevolslide:

        or      al, al
        jnz     tonenuevovolslide
        mov     al, antvolumeslide[edi]
tonenuevovolslide:
        mov     antvolumeslide[edi], al

        mov     ah, al
        shr     ah, 4
        and     al, 0fh

        cmp     ah, 0fh
        je      tonefinevolslidedn
        cmp     ah, 0
        je      tonevolslidedn
        cmp     al, 0fh
        je      tonefinevolslideup
        mov     al, ah
        jmp     tonevolslideup
tonevolslidedn:
        neg     al
tonevolslideup:
        mov     volumeslide[edi], al
        jmp     toneporta

tonefinevolslidedn:
        mov     ah, al ;ror     ax, 8   ; xchg al, ah

        mov     al, channel_volume[edi]         ; NUEVO
        sub     al, ah
        jns     no_finevolslidezero3
        xor     al, al
no_finevolslidezero3:
        mov     channel_volume[edi], al
        mov     esi, automod_volume[edi*4]
        mov     byte ptr [esi], al
        jmp     toneporta

tonefinevolslideup:
        mov     al, channel_volume[edi]         ; NUEVO
        add     al, ah
        cmp     al, 63
        jbe     no_finevolslidezero4
        mov     al, 63
no_finevolslidezero4:
        mov     channel_volume[edi], al
        mov     esi, automod_volume[edi*4]
        mov     byte ptr [esi], al
        ;jmp     end_effect

;continue tone portamento
toneporta:

        xor ax, ax              ; NUEVORL
        jmp effect_slideto

COMMENT Ž
        mov     ax, antslide[edi*2]
        mov     dx, antslideto[edi*2]

        cmp     word ptr current_period[edi*2], 0
        jnz     tonepnuevoslide2
        mov     current_period[edi*2], dx
tonepnuevoslide2:
        mov     antslideto[edi*2], dx
        mov     slideto[edi*2], dx
        cmp     dx, current_period[edi*2]
        ja      effect_slide2dn
        jb      effect_slide2up
        jmp     end_effect              Ž
;----------------------------------------------------------------------------
effect_setvol:
        mov     channel_volume[edi], al
        mov     esi, automod_volume[edi*4]
        mov     byte ptr [esi], al
        jmp     end_effect
;----------------------------------------------------------------------------
effect_slideup:
        mov     slideto[edi*2], 3     ; 113
        xor     ah, ah
        or      al, al
        jnz     effect_slide2up
        mov     ax, antslide[edi*2]
effect_slide2up:
        mov     antslide[edi*2], ax

        cmp     al, 0f0h
        ja      fineslideup
nofineslideup:
        shl     ax, 2
        neg     ax
        mov     slide[edi*2], ax
        jmp     end_effect

fineslideup:
        and     al, 0fh
        jz      nofineslideup               ; BUG
;        MOV     AX, 1
        add     current_period[edi*2], ax
        xor     ebp, ebp
        mov     bp, ax

        or      ebp, ebp
        jz      nocalc20


        mov     eax, numero_magico
        xor     edx, edx
        div     ebp
        mov     ebp, eax
        mov     eax, constante_periodo1
        xor     edx, edx
        mul     ebp

        mov     esi, automod_decimales[edi*4]
        mov     dword ptr [esi], edx
        mov     esi, automod_incr[edi*4]
        mov     dword ptr [esi], eax
nocalc20:
        jmp     end_effect
;----------------------------------------------------------------------------
effect_slidedn:
        mov     slideto[edi*2], 40000 ; 856
        xor     ah, ah
        or      al, al
        jnz     effect_slide2dn
        mov     ax, antslide[edi*2]
effect_slide2dn:
        mov     antslide[edi*2], ax

        cmp     al, 0f0h
        ja      fineslidedn
nofineslidedn:

        shl     ax, 2
        mov     slide[edi*2], ax
        jmp     end_effect

fineslidedn:
        and     al, 0fh
        jz      nofineslidedn           ; BUG
        mov     bp, current_period[edi*2]
        sub     bp, ax
        js      nocalc10

        mov     ax, bp
        mov     current_period[edi*2], bp
        xor     ebp, ebp
        mov     bp, ax

        or      ebp, ebp
        jz      nocalc10


        mov     eax, numero_magico
        xor     edx, edx
        div     ebp
        mov     ebp, eax
        mov     eax, constante_periodo1
        xor     edx, edx
        mul     ebp

        mov     esi, automod_decimales[edi*4]
        mov     dword ptr [esi], edx
        mov     esi, automod_incr[edi*4]
        mov     dword ptr [esi], eax
nocalc10:
        jmp     end_effect
;----------------------------------------------------------------------------
effect_slideto:
        xor     ah, ah
        or      al, al
        jnz     hayvalor
        mov     ax, antslide[edi*2]
hayvalor:
        or      dx, dx
        jnz     nuevoslide
        mov     dx, antslideto[edi*2]
nuevoslide:
        cmp     word ptr current_period[edi*2], 0
        jnz     nuevoslide2
        mov     current_period[edi*2], dx
nuevoslide2:
        mov     antslideto[edi*2], dx
        mov     slideto[edi*2], dx
        cmp     dx, current_period[edi*2]
        ja      effect_slide2dn
        jb      effect_slide2up
        jmp     end_effect
;----------------------------------------------------------------------------
effect_patternbreak:
        push    ebx
        mov     byte ptr [row_counter], al
        mov     byte ptr [row_counter+1], 0
        xor     ebx, ebx
        mov     bl, al
        imul    bx, NumChannels
        ;shl     ebx, 3
        LEA     EBX, [EBX*2+EBX]
        SHL     EBX, 1
estepattnovale:
        xor     eax, eax
        inc     ordnum
        mov     al, ordnum
        cmp     ax, NumPatts
        jae     bueeeenosiquevale
        mov     al, orders[eax]
        cmp     al, 0ffh
        jne     bueeeenosiquevale
        mov     ordnum, -1
        jmp     estepattnovale
bueeeenosiquevale:
        mov     eax, pattern[eax*4]
        add     eax, ebx
        mov     jump, eax
        pop     ebx
        jmp     end_effect
;----------------------------------------------------------------------------
effect_sampleoffset:
        movzx   eax, al
        shl     eax, 8
        mov     esi, automod_sptr[edi*4]
        add     dword ptr [esi], eax
        jmp     end_effect
;----------------------------------------------------------------------------
effect_positionjump:
        movzx   eax, al
        mov     ordnum, al
        mov     al, orders[eax]
        mov     eax, pattern[eax*4]
        mov     jump, eax
        mov     row_counter, 0
        jmp     end_effect
;----------------------------------------------------------------------------
effect_changespeed:
        cmp     al, 31
        jbe     change_tempo
        mov     BPM, al
        jmp     change_bpm
change_tempo:
        mov     TEMPO, al
change_bpm:
        call    CalcTicks
        jmp     end_effect
;----------------------------------------------------------------------------
effect_changebpm:
        mov     BPM, al
        call    CalcTicks
        jmp     end_effect
;----------------------------------------------------------------------------
effect_changetempo:
        mov     TEMPO, al
        call    CalcTicks
        jmp     end_effect
;----------------------------------------------------------------------------
effect_arpeggio:
        or      dx, dx
        jnz     newarp

        mov     dx, current_period[edi*2]

newarp:
        mov     arpeggio_orig[edi*2], dx
        mov     arpeggio_n[edi], 0
        mov     arpeggio[edi], al
        jmp     end_effect

;----------------------------------------------------------------------------
effect_sync:
        call    effect_sync2
        jmp     end_effect


effect_sync2:
        mov     esi, syncptr

        cmp     esi, offset sync+5000
        ja      nomassync

        mov     byte ptr [esi], al
        mov     eax, currentdmaptr
        sub     eax, dmabuf
        add     eax, bytesmezclados
        mov     dword ptr [esi+1], eax
        add     esi, 5
        mov     syncptr, esi

        ret

nomassync:
        video   140, '!'
        ret
Mixer           ENDP










;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± InitPlayer ±±
; Salida  :     CF = 0 + EAX = 0 si no hay error,
;               CF = 1 + EAX = C¢digo de error:
;                               01 = SB no detectada
;                               02 = No hay memoria para el buffer DMA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
InitPlayer      PROC
        e
        push    ebp

        mov     frecuencia, eax

        finit

;-------------------------
; We get the BLASTER variable parameters
;-------------------------
;comment „

        GetEnvVar "BLASTER"
        jc      no_env_var



        mov     esi,eax         ; pointer to environment variable
        mov     edi,offset temp_buffer
        call    GetCommandParam


        cmp     ecx,4
        jnz     no_env_var
        cmp     byte ptr [edi],'A'
        jnz     no_env_var

        add     edi,4
        call    GetCommandParam
        cmp     ecx,3           ; irq 10 string is 3 bytes long
        ja      no_env_var
        cmp     ecx,2           ; otherwise, 2 bytes long
        jnz     no_env_var
        cmp     byte ptr [edi],'I'
        jnz     no_env_var
        dec     ecx
        mov     irqlength,ecx

        add     edi,3
        call    GetCommandParam
        cmp     ecx,2
        jnz     no_env_var
        cmp     byte ptr [edi],'D'
        jnz     no_env_var

        ; parameter conversion
        ; port
        mov     esi,offset temp_buffer+1
        mov     byte ptr [esi+3],0
        call    GetHexInteger
        jc      no_env_var
        mov     SBbase,ax
        ; irq
        mov     esi,offset temp_buffer+5
        mov     ecx,irqlength
        mov     byte ptr [esi+ecx],0
        call    GetInteger
        jc      no_env_var
        mov     SBirq,cl
        ; dma
        mov     esi,offset temp_buffer+8
        mov     byte ptr [esi+1],0
        call    GetInteger
        jc      no_env_var
        mov     SBdma,cl

        ; we set parameters manually
        mov     al, 0e1h                ; Get DSP Version
        call    WriteDSP
        call    ReadDSP
        mov     ah, al
        call    ReadDSP
        mov     ecx,eax
        mov     ax,SBbase
        mov     bl,SBirq
        mov     bh,SBdma
        call    SBManualSetup
        jmp     filter_freq

;„

        no_env_var:


;-------------------------
; If BLASTER variable is not found or is not Ok, we talk to user
;-------------------------


;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° DETECCION DE LA TARJETA DE SONIDO °°

        Verbose "þ Autodetecting Sound Card."

        call    SBDetect                ; Miramos si hay Chound Plaster
        jc      no_detectado            ; oohhh, que pena

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° BUFFER DMA °°

filter_freq:

;        ret ; |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||1

;-------------------------
        cmp     DSPVerH,4                       ; B52 ³ Si hay SBPro, s¢lo
        jae     sb16maxfreq                     ; B52 ³ se puede mandar a
                cmp     frecuencia,22050        ; B52 ³ 22050Hz en Stereo.
                jbe     sb16maxfreq             ; B52 ³
                mov     frecuencia,22050        ; B52 ³
        sb16maxfreq:                            ; B52 ³
;-------------------------
        cmp     _verbose, 0
        je      noverb1

        print   msg_punt
        call    SBInfo
        call    Printf
        mov     esi, edi
        print   msg_at
        call    Printf
        print   msg_sb

        Verbose 'þ Initializing player ... '

noverb1:
        Verbose 'ù Allocating DMA buffer.'

;        mov     ax, 0100h
;        mov     bx, 8192 ; 128*1024/16
;        int     31h
;        jc      nodmamem
;
;        movzx   eax, ax
;        shl     eax, 4

        mov     ebx,BUFSIZE
        call    AllocDMABuffer
        jc      nodmamem
        mov     eax,ebx


;        xor     ax, ax
;        add     eax, 10000h

        mov     dmabuf, eax


;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° CREAR LA TABLA DE VOLUMENES (8 bits) °°

        Verbose 'ù Calculating 8bit volume table.'

        mov     edi, offset volumetable

        mov     ecx, 256
        xor     al, al
        cld
        rep     stosb

        mov     ecx, 64
fillvolumetable:
        push    ecx
        mov     ebx, 64
        sub     ebx, ecx

        mov     ecx, 256
fill2:
        push    ecx
        dec     cl
        mov     al, 255
        sub     al, cl
        cbw
        cwde

        imul    eax, ebx
        sar     eax, 6

        stosb
        pop     ecx
        loop    fill2

        pop     ecx
        loop    fillvolumetable

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° CREAR LA TABLA DE PANNING (32 bits) °°

        Verbose 'ù Calculating 32bit panning table.'

        mov     edi, offset panningtable
        xor     ebx, ebx
        xor     edx, edx

        mov     ecx, 64
calcpantable_panning:
        push    ecx
        mov     ecx, 256
        xor     bl, bl
calcpantable_muestra:

        mov     dl, bl
        mov     dh, 63
        sub     dh, bh
        mov     al, volumetable[edx]
        mov     ah, al
        sar     ah, 7
        shl     eax, 16

        mov     dl, bl
        mov     dh, bh
        mov     al, volumetable[edx]
        mov     ah, al
        sar     ah, 7

        stosd

        inc     bl
        loop    calcpantable_muestra
        pop     ecx
        inc     bh
        loop    calcpantable_panning




        Verbose 'ù Doing some variable inicialization.'


        call    CalcTicks

;        cmp     filetype, 2             ; los s3m tienen los periodos 4 veces
;        jne     nos3m                   ; mas finos que los mods
        shl     numero_magico, 2
;nos3m:
;        cmp     filetype, 3             ; y los xm tambi‚n
;        jne     noxm                    ;
        ;shl     numero_magico, 2
;        mov     numero_magico, 8363*1712
;noxm:

        mov     muestras, 0
        mov     tick_counter, 0

        xor     eax, eax                ; Precalculo para ahorrarnos algunos
        mov     edx, 1                  ; ciclos
        div     frecuencia

        mov     constante_periodo1, eax
        mov     constante_periodo2, edx


        mov     ordnum, 0               ; Estamos en el orden 0,
        mov     row_counter, 0          ; row 0.

        xor     eax, eax                ; Cargamos el puntero al pattern
        mov     al, ordnum              ; que toque.

        mov     dx, PattNRows[eax*2]
        mov     word ptr [automod_rowcounter-2], dx

        mov     al, orders[eax]
        mov     eax, pattern[eax*4]
        mov     rowptr, eax

        mov     ecx, NCHANNELS
        xor     eax, eax
vaciar_canales:
        mov     ebx, automod_sptr[eax*4]
        mov     dword ptr [ebx], 0

        mov     slide[eax], 0
        mov     volumeslide[eax], 0
        mov     arpeggio[eax], 0

        mov     esi, automod_retrig[eax*4]
        mov     dword ptr [esi], -1

        inc     eax
        loop    vaciar_canales


        mov     row_counter, 0
        mov     jump, 0

        Verbose 'ù Initilization complete.'






        ; speed up : quitamos los canales que no suenan con un jmp

        xor     edi, edi
        mov     di, NumChannels
        mov     esi, automod_nomezclar[edi*4]
        mov     ebx, esi

        mov     al, 0e9h
        cld
        stosb                           ; jmp 32 bits

        mov     eax, offset _endmixjmp_
        sub     eax, ebx
        sub     eax, 5          ; 5 bytes de la instr.
        stosd





        DEC     NumOrders

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° FIN RUTINA °°

        xor     eax, eax
        clc
        pop     ebp
        s
        ret


;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° TRATAMIENTO DE ERRORES °°

no_detectado:
        mov     eax, 1
        pop     ebp
        stc
        s
        ret

nodmamem:
        mov     eax, 2
        pop     ebp
        stc
        s
        ret

InitPlayer      ENDP



PLAY            PROC
        e
        push    ebp
        mov     bytesmezclados, 0-BUFSIZE
        mov     syncptr, offset sync

        mov     edi, dmabuf
        mov     ecx, BUFSIZE
        call    Mixer

        mov     bytesmezclados, 0

        mov     eax, frecuencia
        mov     ecx, BUFSIZE OR 80000000h
        mov     ebx, offset Mixer
        mov     esi, dmabuf
        call    SBPlay
        pop     ebp
        s
        ret
PLAY            ENDP

STOP            PROC
        e
        push    ebp
        call    SBStop

        mov     al, 34h
        out     43h, al
        mov     al, 0ffh
        out     40h, al
        out     40h, al
        pop     ebp
        s
        ret
STOP            ENDP

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± CalcTicks ±±
; Calcula las muestras que hay en cada tick
CalcTicks       PROC
        push    eax ebx edx ebp

        xor     ebx, ebx

        mov     eax, frecuencia
        shr     eax, 1
        imul    eax, 5
        mov     ebp, eax
        mov     bl, TEMPO
        imul    eax, ebx
        mov     edx, eax
        sar     edx, 31
        mov     bl, BPM
        idiv    ebx
        mov     TICK, eax
        mov     eax, ebp
        mov     edx, eax
        sar     edx, 31
        idiv    ebx
        mov     ONETICK, eax

        pop     ebp edx ebx eax
        ret
CalcTicks       ENDP

Check4Sync      PROC
        ;int 3
        e
        push    ebp
        push    ebx ecx esi edi

        mov     esi, offset sync

        cmp     esi, syncptr
        je      finlistasync

        mov     bl, byte ptr [esi]
        mov     ecx, dword ptr [esi+1]

        call    GetSBDMAptr

        cmp     eax, ecx
        jae     siefecto

finlistasync:
        pop     edi esi ecx ebx
        mov     eax, -1
        pop     ebp
        stc
        s
        ret


siefecto:
        cmp     syncptr, offset sync
        jbe     finlistasync

        sub     syncptr, 5
        mov     esi, offset sync+5
        mov     edi, offset sync
        mov     ecx, 100;20
        cld
        rep     movsd

        xor     eax, eax
        mov     al, bl
        pop     edi esi ecx ebx
        pop     ebp
        clc
        s
        ret

Check4Sync      ENDP


.DATA
        numero_magico           dd 3579545
        automod_decimales       dd (offset decimales0)-4
                                dd (offset decimales1)-4
                                dd (offset decimales2)-4
                                dd (offset decimales3)-4
                                dd (offset decimales4)-4
                                dd (offset decimales5)-4
                                dd (offset decimales6)-4
                                dd (offset decimales7)-4
                                dd (offset decimales8)-4
                                dd (offset decimales9)-4
                                dd (offset decimales10)-4
                                dd (offset decimales11)-4
                                dd (offset decimales12)-4
                                dd (offset decimales13)-4
                                dd (offset decimales14)-4
                                dd (offset decimales15)-4
                                dd (offset decimales16)-4
                                dd (offset decimales17)-4
                                dd (offset decimales18)-4
                                dd (offset decimales19)-4
                                dd (offset decimales20)-4
                                dd (offset decimales21)-4
                                dd (offset decimales22)-4
                                dd (offset decimales23)-4
                                dd (offset decimales24)-4
                                dd (offset decimales25)-4
                                dd (offset decimales26)-4
                                dd (offset decimales27)-4
                                dd (offset decimales28)-4
                                dd (offset decimales29)-4
                                dd (offset decimales30)-4
                                dd (offset decimales31)-4
        automod_contador        dd (offset contador0)-4
                                dd (offset contador1)-4
                                dd (offset contador2)-4
                                dd (offset contador3)-4
                                dd (offset contador4)-4
                                dd (offset contador5)-4
                                dd (offset contador6)-4
                                dd (offset contador7)-4
                                dd (offset contador8)-4
                                dd (offset contador9)-4
                                dd (offset contador10)-4
                                dd (offset contador11)-4
                                dd (offset contador12)-4
                                dd (offset contador13)-4
                                dd (offset contador14)-4
                                dd (offset contador15)-4
                                dd (offset contador16)-4
                                dd (offset contador17)-4
                                dd (offset contador18)-4
                                dd (offset contador19)-4
                                dd (offset contador20)-4
                                dd (offset contador21)-4
                                dd (offset contador22)-4
                                dd (offset contador23)-4
                                dd (offset contador24)-4
                                dd (offset contador25)-4
                                dd (offset contador26)-4
                                dd (offset contador27)-4
                                dd (offset contador28)-4
                                dd (offset contador29)-4
                                dd (offset contador30)-4
                                dd (offset contador31)-4
        automod_incr            dd (offset incr0)-4
                                dd (offset incr1)-4
                                dd (offset incr2)-4
                                dd (offset incr3)-4
                                dd (offset incr4)-4
                                dd (offset incr5)-4
                                dd (offset incr6)-4
                                dd (offset incr7)-4
                                dd (offset incr8)-4
                                dd (offset incr9)-4
                                dd (offset incr10)-4
                                dd (offset incr11)-4
                                dd (offset incr12)-4
                                dd (offset incr13)-4
                                dd (offset incr14)-4
                                dd (offset incr15)-4
                                dd (offset incr16)-4
                                dd (offset incr17)-4
                                dd (offset incr18)-4
                                dd (offset incr19)-4
                                dd (offset incr20)-4
                                dd (offset incr21)-4
                                dd (offset incr22)-4
                                dd (offset incr23)-4
                                dd (offset incr24)-4
                                dd (offset incr25)-4
                                dd (offset incr26)-4
                                dd (offset incr27)-4
                                dd (offset incr28)-4
                                dd (offset incr29)-4
                                dd (offset incr30)-4
                                dd (offset incr31)-4
        automod_sptr            dd (offset sptr0)-4
                                dd (offset sptr1)-4
                                dd (offset sptr2)-4
                                dd (offset sptr3)-4
                                dd (offset sptr4)-4
                                dd (offset sptr5)-4
                                dd (offset sptr6)-4
                                dd (offset sptr7)-4
                                dd (offset sptr8)-4
                                dd (offset sptr9)-4
                                dd (offset sptr10)-4
                                dd (offset sptr11)-4
                                dd (offset sptr12)-4
                                dd (offset sptr13)-4
                                dd (offset sptr14)-4
                                dd (offset sptr15)-4
                                dd (offset sptr16)-4
                                dd (offset sptr17)-4
                                dd (offset sptr18)-4
                                dd (offset sptr19)-4
                                dd (offset sptr20)-4
                                dd (offset sptr21)-4
                                dd (offset sptr22)-4
                                dd (offset sptr23)-4
                                dd (offset sptr24)-4
                                dd (offset sptr25)-4
                                dd (offset sptr26)-4
                                dd (offset sptr27)-4
                                dd (offset sptr28)-4
                                dd (offset sptr29)-4
                                dd (offset sptr30)-4
                                dd (offset sptr31)-4
        automod_slen            dd (offset slen0)-4
                                dd (offset slen1)-4
                                dd (offset slen2)-4
                                dd (offset slen3)-4
                                dd (offset slen4)-4
                                dd (offset slen5)-4
                                dd (offset slen6)-4
                                dd (offset slen7)-4
                                dd (offset slen8)-4
                                dd (offset slen9)-4
                                dd (offset slen10)-4
                                dd (offset slen11)-4
                                dd (offset slen12)-4
                                dd (offset slen13)-4
                                dd (offset slen14)-4
                                dd (offset slen15)-4
                                dd (offset slen16)-4
                                dd (offset slen17)-4
                                dd (offset slen18)-4
                                dd (offset slen19)-4
                                dd (offset slen20)-4
                                dd (offset slen21)-4
                                dd (offset slen22)-4
                                dd (offset slen23)-4
                                dd (offset slen24)-4
                                dd (offset slen25)-4
                                dd (offset slen26)-4
                                dd (offset slen27)-4
                                dd (offset slen28)-4
                                dd (offset slen29)-4
                                dd (offset slen30)-4
                                dd (offset slen31)-4
        automod_loop            dd (offset loop0)-4
                                dd (offset loop1)-4
                                dd (offset loop2)-4
                                dd (offset loop3)-4
                                dd (offset loop4)-4
                                dd (offset loop5)-4
                                dd (offset loop6)-4
                                dd (offset loop7)-4
                                dd (offset loop8)-4
                                dd (offset loop9)-4
                                dd (offset loop10)-4
                                dd (offset loop11)-4
                                dd (offset loop12)-4
                                dd (offset loop13)-4
                                dd (offset loop14)-4
                                dd (offset loop15)-4
                                dd (offset loop16)-4
                                dd (offset loop17)-4
                                dd (offset loop18)-4
                                dd (offset loop19)-4
                                dd (offset loop20)-4
                                dd (offset loop21)-4
                                dd (offset loop22)-4
                                dd (offset loop23)-4
                                dd (offset loop24)-4
                                dd (offset loop25)-4
                                dd (offset loop26)-4
                                dd (offset loop27)-4
                                dd (offset loop28)-4
                                dd (offset loop29)-4
                                dd (offset loop30)-4
                                dd (offset loop31)-4
        automod_panning         dd (offset panning0)-1
                                dd (offset panning1)-1
                                dd (offset panning2)-1
                                dd (offset panning3)-1
                                dd (offset panning4)-1
                                dd (offset panning5)-1
                                dd (offset panning6)-1
                                dd (offset panning7)-1
                                dd (offset panning8)-1
                                dd (offset panning9)-1
                                dd (offset panning10)-1
                                dd (offset panning11)-1
                                dd (offset panning12)-1
                                dd (offset panning13)-1
                                dd (offset panning14)-1
                                dd (offset panning15)-1
                                dd (offset panning16)-1
                                dd (offset panning17)-1
                                dd (offset panning18)-1
                                dd (offset panning19)-1
                                dd (offset panning20)-1
                                dd (offset panning21)-1
                                dd (offset panning22)-1
                                dd (offset panning23)-1
                                dd (offset panning24)-1
                                dd (offset panning25)-1
                                dd (offset panning26)-1
                                dd (offset panning27)-1
                                dd (offset panning28)-1
                                dd (offset panning29)-1
                                dd (offset panning30)-1
                                dd (offset panning31)-1
        automod_volume          dd (offset volume0)-1
                                dd (offset volume1)-1
                                dd (offset volume2)-1
                                dd (offset volume3)-1
                                dd (offset volume4)-1
                                dd (offset volume5)-1
                                dd (offset volume6)-1
                                dd (offset volume7)-1
                                dd (offset volume8)-1
                                dd (offset volume9)-1
                                dd (offset volume10)-1
                                dd (offset volume11)-1
                                dd (offset volume12)-1
                                dd (offset volume13)-1
                                dd (offset volume14)-1
                                dd (offset volume15)-1
                                dd (offset volume16)-1
                                dd (offset volume17)-1
                                dd (offset volume18)-1
                                dd (offset volume19)-1
                                dd (offset volume20)-1
                                dd (offset volume21)-1
                                dd (offset volume22)-1
                                dd (offset volume23)-1
                                dd (offset volume24)-1
                                dd (offset volume25)-1
                                dd (offset volume26)-1
                                dd (offset volume27)-1
                                dd (offset volume28)-1
                                dd (offset volume29)-1
                                dd (offset volume30)-1
                                dd (offset volume31)-1
        automod_nomezclar       dd (offset nomezclar0)-1
                                dd (offset nomezclar1)-1
                                dd (offset nomezclar2)-1
                                dd (offset nomezclar3)-1
                                dd (offset nomezclar4)-1
                                dd (offset nomezclar5)-1
                                dd (offset nomezclar6)-1
                                dd (offset nomezclar7)-1
                                dd (offset nomezclar8)-1
                                dd (offset nomezclar9)-1
                                dd (offset nomezclar10)-1
                                dd (offset nomezclar11)-1
                                dd (offset nomezclar12)-1
                                dd (offset nomezclar13)-1
                                dd (offset nomezclar14)-1
                                dd (offset nomezclar15)-1
                                dd (offset nomezclar16)-1
                                dd (offset nomezclar17)-1
                                dd (offset nomezclar18)-1
                                dd (offset nomezclar19)-1
                                dd (offset nomezclar20)-1
                                dd (offset nomezclar21)-1
                                dd (offset nomezclar22)-1
                                dd (offset nomezclar23)-1
                                dd (offset nomezclar24)-1
                                dd (offset nomezclar25)-1
                                dd (offset nomezclar26)-1
                                dd (offset nomezclar27)-1
                                dd (offset nomezclar28)-1
                                dd (offset nomezclar29)-1
                                dd (offset nomezclar30)-1
                                dd (offset nomezclar31)-1
        automod_retrig          dd (offset retrig0)-4
                                dd (offset retrig1)-4
                                dd (offset retrig2)-4
                                dd (offset retrig3)-4
                                dd (offset retrig4)-4
                                dd (offset retrig5)-4
                                dd (offset retrig6)-4
                                dd (offset retrig7)-4
                                dd (offset retrig8)-4
                                dd (offset retrig9)-4
                                dd (offset retrig10)-4
                                dd (offset retrig11)-4
                                dd (offset retrig12)-4
                                dd (offset retrig13)-4
                                dd (offset retrig14)-4
                                dd (offset retrig15)-4
                                dd (offset retrig16)-4
                                dd (offset retrig17)-4
                                dd (offset retrig18)-4
                                dd (offset retrig19)-4
                                dd (offset retrig20)-4
                                dd (offset retrig21)-4
                                dd (offset retrig22)-4
                                dd (offset retrig23)-4
                                dd (offset retrig24)-4
                                dd (offset retrig25)-4
                                dd (offset retrig26)-4
                                dd (offset retrig27)-4
                                dd (offset retrig28)-4
                                dd (offset retrig29)-4
                                dd (offset retrig30)-4
                                dd (offset retrig31)-4
        automod_retrigx         dd (offset retrigx0)-4
                                dd (offset retrigx1)-4
                                dd (offset retrigx2)-4
                                dd (offset retrigx3)-4
                                dd (offset retrigx4)-4
                                dd (offset retrigx5)-4
                                dd (offset retrigx6)-4
                                dd (offset retrigx7)-4
                                dd (offset retrigx8)-4
                                dd (offset retrigx9)-4
                                dd (offset retrigx10)-4
                                dd (offset retrigx11)-4
                                dd (offset retrigx12)-4
                                dd (offset retrigx13)-4
                                dd (offset retrigx14)-4
                                dd (offset retrigx15)-4
                                dd (offset retrigx16)-4
                                dd (offset retrigx17)-4
                                dd (offset retrigx18)-4
                                dd (offset retrigx19)-4
                                dd (offset retrigx20)-4
                                dd (offset retrigx21)-4
                                dd (offset retrigx22)-4
                                dd (offset retrigx23)-4
                                dd (offset retrigx24)-4
                                dd (offset retrigx25)-4
                                dd (offset retrigx26)-4
                                dd (offset retrigx27)-4
                                dd (offset retrigx28)-4
                                dd (offset retrigx29)-4
                                dd (offset retrigx30)-4
                                dd (offset retrigx31)-4

        PlayerFlags                   db 0

        msg_at                  db ' detected at ',0
        msg_sb                  db '.',13,10,0
        msg_punt                db 'ù ',0

        _verbose                db 0ffh

        ANTBASSR                dw 8000h
        ANTBASSL                dw 8000h



        ; PA LOS XM

        periodtab label word
                dw    907,900,894,887,881,875,868,862,856,850,844,838,832,826,820,814
                dw    808,802,796,791,785,779,774,768,762,757,752,746,741,736,730,725
                dw    720,715,709,704,699,694,689,684,678,675,670,665,660,655,651,646
                dw    640,636,632,628,623,619,614,610,604,601,597,592,588,584,580,575
                dw    570,567,563,559,555,551,547,543,538,535,532,528,524,520,516,513
                dw    508,505,502,498,494,491,487,484,480,477,474,470,467,463,460,457
                dw    453,450,447,443,440,437,434,431,428,425,422,419,416,413,410,407
                dw    404,401,398,395,392,389,386,383,381,378,376,373,370,368,365,363



.DATA?
        dmabuf                  dd ?
        frecuencia              dd ?
        TICK                    dd ?
        ONETICK                 dd ?

        constante_periodo1      dd ?
        constante_periodo2      dd ?

        panningtable            dd 64*256 dup(?)
        muestras                dd ?
        rowptr                  dd ?


        current_sample          db MAX_NCHANNELS dup(?)
        ant_sample              db MAX_NCHANNELS dup(?)
        current_effect          dw MAX_NCHANNELS dup(?)
        ant_effect              dw MAX_NCHANNELS dup(?)
        channel_volume          db MAX_NCHANNELS dup(?)
        current_period          dw MAX_NCHANNELS dup(?)
        current_real_sample     db MAX_NCHANNELS dup(?)
        ordnum                  db ?

        row_counter             dw ?
        tick_counter            db ?

        volumetable             db 65*256 dup(?)

        jump                    dd ?
        slide                   dw MAX_NCHANNELS dup(?)
        slideto                 dw MAX_NCHANNELS dup(?)
        antslide                dw MAX_NCHANNELS dup(?)
        antslideto              dw MAX_NCHANNELS dup(?)

        volumeslide             db MAX_NCHANNELS dup(?)
        antvolumeslide          db MAX_NCHANNELS dup(?)

        arpeggio                db MAX_NCHANNELS dup(?)
        arpeggio_orig           dw MAX_NCHANNELS dup(?)
        arpeggio_n              db MAX_NCHANNELS dup(?)

        antretrig               db MAX_NCHANNELS dup(?)

        sync                    db 5120 dup(?)   ; 256
        syncptr                 dd ?
        currentdmaptr           dd ?
        bytesmezclados          dd ?

        temp_buffer             db 256 dup(?)   ; para par metros BLASTER
        irqlength               dd ?
.CODE

PlayNote                PROC
        pushad

        movzx   edi, bx         ; edi = canal
        movzx   edx, dx         ; edx = periodo
        mov     bh, al          ; bh = instr
        mov     bl, cl          ; bl = volume

;------------------------------------------------- MEZCLA EN EL BUFFER DMA --

        call    GetSBDMAptr
        and     eax, (_MIXBUFFERSIZE-1)
        mov     edi, eax
        add     edi, dmabuf


        cmp     eax, _MIXBUFFERSIZE/2
        jae     segunda_mitad

        mov     ecx, _MIXBUFFERSIZE
        sub     ecx, eax             ; bytes que quedan hasta final de buffer
        call    SumarSample

        jmp     hecholodeladma

segunda_mitad:
        mov     ecx, _MIXBUFFERSIZE/2
        sub     ecx, eax             ; bytes que quedan hasta final de buffer
        call    SumarSample

        mov     edi, dmabuf
        mov     ecx, _MIXBUFFERSIZE/2
        call    SumarSample

hecholodeladma:




;----------------------- A¥ADIR LO QUE QUEDA DE NOTA A LA RUTINA DE MEZCLA --

        push    ebx


        mov     ebp, edx
        mov     current_period[edi*2], dx

        mov     eax, numero_magico
        xor     edx, edx
        div     ebp
        mov     ecx, eax
        mov     eax, constante_periodo1
        xor     edx, edx
        mul     ecx

        mov     esi, automod_decimales[edi*4]
        mov     dword ptr [esi], edx
        mov     esi, automod_contador[edi*4]
        mov     dword ptr [esi], 0
        mov     esi, automod_incr[edi*4]
        mov     dword ptr [esi], eax
        mov     esi, automod_sptr[edi*4]
        movzx   ebx, bh
        mov     eax, samples[ebx*4]
        mov     dword ptr [esi], eax


        mov     esi, automod_slen[edi*4]

        mov     edx, loopend[ebx*4]
        or      edx, edx
        jz      pn_usar_longitud

        mov     edx, loopstart[ebx*4]
        add     edx, eax
        add     eax, loopend[ebx*4]
        jmp     pn_usar_loopend
pn_usar_longitud:
        add     eax, sample_length[ebx*4]
pn_usar_loopend:
        mov     dword ptr [esi], eax


        mov     esi, automod_loop[edi*4]
        mov     dword ptr [esi], edx

        mov     edx, ebp

        pop     ebx

        mov     esi, automod_volume[edi*4]
        mov     byte ptr [esi], bl

        mov     al, panning[edi]
        mov     esi, automod_panning[edi*4]
        mov     byte ptr [esi], al

        popad

        ret

PlayNote                ENDP


SumarSample             PROC

comment „
        mov     edx, 12345678h          ; puntero al sample
sptr&x:
        or      edx, edx
        jz      nomezclar&x

        mov     ebx, 12345678h
contador&x:
        add     ebx, 12345678h
incr&x:
        adc     edx, 12345678h
decimales&x:

        cmp     edx, 12345678h
slen&x:
        jb      mezclar&x

        mov     dword ptr [sptr&x-4], 12345678h
loop&x:
        jmp     nomezclar&x
mezclar&x:

        mov     dword ptr [contador&x-4], ebx

        mov     cl, byte ptr [edx]
        mov     ch, 0                   ; volumen
volume&x:
        mov     cl, volumetable[ecx]
        mov     ch, 0                   ; panning
panning&x:
        add     eax, panningtable[ecx*4]

        mov     dword ptr [sptr&x-4], edx

nomezclar&x:

        „

        ret

SumarSample             ENDP


END


