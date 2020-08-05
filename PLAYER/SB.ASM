extrn   frecuencia: DWORD

;;__DEBUG__       equ 0


video   macro pos, char
        if __DEBUG__ eq 1
                push    edi
                mov     edi, 0b8000h
                mov     byte ptr [edi+pos], char
                pop     edi
        endif
        endm
        IRQ_TIMEOUT             equ 600000
        SBTimeout               equ 1000

        MIXER_INDEX             equ 04h
        MIXER_DATA              equ 05h
        DSP_RESET               equ 06h
        DSP_READ_DATA           equ 0Ah
        DSP_WRITE_DATA          equ 0Ch
        DSP_WRITE_STATUS        equ 0Ch
        DSP_DATA_AVAIL          equ 0Eh

JUMPS
.486P
.MODEL  FLAT
        assume cs:@code, ds:@data, es:@data
.CODE
        PUBLIC  DSPVerH ; B52 -> se necesita en InitPlayer para limitar freq.
        PUBLIC  SBBase
        PUBLIC  SBIrq
        PUBLIC  SBDMA

        PUBLIC  ReadMixer
        PUBLIC  WriteMixer
        PUBLIC  ReadDSP
        PUBLIC  WriteDSP
        PUBLIC  SBReset
        PUBLIC  SBDetect
        PUBLIC  SBInfo
        PUBLIC  SBPlay
        PUBLIC  SBStop
        PUBLIC  GetSBDMAptr
        PUBLIC  SetVolume
        PUBLIC  SetGlobalVolume
        PUBLIC  SBManualSetup
        PUBLIC  ChangeMixR
        PUBLIC  GetMixR
.DATA?
        antirq02        dd ?
        antirq02sel     dw ?
        antirq03        dd ?
        antirq03sel     dw ?
        antirq05        dd ?
        antirq05sel     dw ?
        antirq07        dd ?
        antirq07sel     dw ?


        sbsize                  dd ?
        bufsize                 dd ?
        dmaddr                  dd ?
        sbfreq                  dd ?

        sbmitad                 db ?

        dmabytes                dd ?
.DATA
        SBbase                  dw  0h
        SBIRQ                   db  0h
        SBDMA                   db  0h
        SBHDMA                  db  0h
        DSPVerH                 db  0h
        DSPVerL                 db  0h
        IRQTest                 db  0h

        sb_testbuf              db 128 dup(0)

        msg_unk                 db 'Sound Blaster',0
        msg_sb16                db 'Sound Blaster 16/AWE32',0
        msg_sbpro               db 'Sound Blaster Pro',0
        msg_sb1                 db 'Sound Blaster 1.0',0
        msg_sb15                db 'Sound Blaster 1.5',0
        msg_sb2                 db 'Sound Blaster 2.0',0

        msg_ports               db 'P:000 I:0 D:0',0

        digital_volume          db 0FFh         ; B52 -> FFh = max.
        global_volume           db 0FFh         ; B52
.CODE

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° ReadMixer °°
; Entrada :     AL - Registro del Mixer
; Salida  :     AL - Valor del registro del Mixer
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
ReadMixer       PROC
        push    edx

        mov     dx, SBbase
        add     dx, MIXER_INDEX
        out     dx, al
        inc     dl
        in      al, dx

        pop     edx
        ret
ReadMixer       ENDP


;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° WriteMixer °°
; Entrada :     AL - Valor a escribir en el DSP
;               AH - Registro del Mixer
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
WriteMixer      PROC
        push    eax edx

        ror     ax, 8                   ; xchg ah, al

        mov     dx, SBbase
        add     dx, MIXER_INDEX
        out     dx, al

        inc     dl

        mov     al, ah

        out     dx, al

        pop     edx eax
        ret
WriteMixer      ENDP

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° WriteDSP °°
; Entrada :     AL - Valor a escribir en el DSP
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
WriteDSP        PROC
        push    ebx edx eax

        mov     bx, SBTimeout

        mov     dx, SBbase
        add     dx, DSP_WRITE_STATUS
wdsp1:
        dec     bx
        jz      wdspend
        in      al, dx
        and     al, 80h
        jnz     wdsp1
wdspend:
        pop     eax

        mov     dx, SBbase
        add     dx, DSP_WRITE_DATA
        out     dx, al

        pop     edx ebx
        ret
WriteDSP        ENDP


;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° ReadDSP °°
; Salida  :     AL - Valor le¡do del DSP
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
ReadDSP         PROC
        push    ebx edx

        mov     bx, SBTimeout

        mov     dx, SBbase
        add     dx, DSP_DATA_AVAIL
wdsp2:
        dec     bx
        jz      rdspend
        in      al, dx
        and     al, 80h
        jz      wdsp2


        mov     dx, SBbase
        add     dx, DSP_READ_DATA
        in      al, dx
rdspend:
        pop     edx ebx
        ret
ReadDSP         ENDP

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° SBReset °°
; Entrada :     Se tiene que haber inicializado la SB
; Salida  :     CF=0 y EAX=0 si no hay error,
;               CF=1 y EAX=N£mero de error:
;                               01 = SB no inicializada
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
SBReset         PROC
        push    eax edx

        cmp     SBBase, 0
        je      sbr_no_inicializado

        mov     dx, SBbase
        add     dx, DSP_RESET
        mov     al, 1
        out     dx, al

        in      al, dx
        in      al, dx
        in      al, dx
        in      al, dx
        in      al, dx
        in      al, dx

        mov     dx, SBbase
        add     dx, DSP_RESET
        mov     al, 0
        out     dx, al

        call    ReadDSP
        cmp     al, 0aah
        jne ÿ   errorsbreset

        pop     edx eax
        clc
        ret

errorsbreset:
        pop     edx eax
        stc
        ret

sbr_no_inicializado:
        pop     edx eax
        mov     eax, 1
        stc
        ret

SBReset         ENDP


;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° SBManualSetup °°
; Entrada :     AX = Puerto
;               BL = IRQ
;               BH = DMA
;               CH.CL = DSP Ver
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
SBManualSetup   PROC
        mov     SBbase, ax

        mov     SBIRQ, bl
        mov     SBDMA, bh

        mov     DSPVerH, ch
        mov     DSPVerL, cl

        mov     cl, SBIRQ
        mov     ah, 1
        shl     ah, cl
        not     ah
        in      al, 21h
        and     al, ah                  ; Habilitamos la IRQ correspondiente
        out     21h, al


        call    SBReset

        ret
SBManualSetup   ENDP

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° SBDetect °°
; Salida  :     CF=0 y EAX=0 si no hay error,
;               CF=1 y EAX=N£mero de error:
;                               01 = SB no detectada
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
SBDetect        PROC
        pushad

        cmp     sbbase, 0
        jne     sbyadetectada

        mov     SBbase, 200h
nosbdetected:
        add     SBbase, 10h
        cmp     SBbase, 280h
        ja      errorsbdetect
        call    SBReset
        jc      nosbdetected


        mov     al, 0e1h                ; Get DSP Version
        call    WriteDSP

        call    ReadDSP
        mov     ah, al
        call    ReadDSP



;        MOV     AH, 3      ; <-------------------------------------


        mov     DSPVerH, ah
        mov     DSPVerL, al

        cmp     ah, 4
        jb      nosb16
        call    GetSB16IRQnDMA
        jmp     sisb16
nosb16:
        call    GetIRQnDMA
sisb16:
;        MOV     SBIRQ, al
;        MOV     SBDMA, 1


        mov     cl, SBIRQ
        mov     ah, 1
        shl     ah, cl
        not     ah
        in      al, 21h
        and     al, ah                  ; Habilitamos la IRQ correspondiente
        out     21h, al

sbyadetectada:

        popad
        xor     eax, eax
        clc
        ret

errorsbdetect:
        mov     SBBase, 0
        popad
        mov     eax, 1
        stc
        ret
SBDetect        ENDP


TestIRQ2        PROC
        push    eax edx

        mov     dx, SBbase
        add     dx, DSP_DATA_AVAIL
        in      al, dx

        mov     IRQTest , 2
        mov     al, 20h
        out     20h, al
        pop     edx eax
        iret
TestIRQ2        ENDP

TestIRQ3        PROC
        push    eax edx

        mov     dx, SBbase
        add     dx, DSP_DATA_AVAIL
        in      al, dx

        mov     IRQTest , 3
        mov     al, 20h
        out     20h, al
        pop     edx eax
        iret
TestIRQ3        ENDP

TestIRQ5        PROC
        push    eax edx

        mov     dx, SBbase
        add     dx, DSP_DATA_AVAIL
        in      al, dx

        mov     IRQTest , 5
        mov     al, 20h
        out     20h, al
        pop     edx eax
        iret
TestIRQ5        ENDP

TestIRQ7        PROC
        push    eax edx

        mov     dx, SBbase
        add     dx, DSP_DATA_AVAIL
        in      al, dx

        mov     IRQTest , 7
        mov     al, 20h
        out     20h, al
        pop     edx eax
        iret
TestIRQ7        ENDP

TestIRQ10       PROC
        push    eax edx

        mov     dx, SBbase
        add     dx, DSP_DATA_AVAIL
        in      al, dx

        mov     IRQTest , 10
        mov     al, 020h                ; B52 -> slave PIC
        out     0a0h, al                ; B52
        pop     edx eax
        iret
TestIRQ10       ENDP







;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° SBInfo °°
; Salida  :     ESI - Puntero al nombre de la tarjeta de sonido
;               EDI - Configuraci¢n de los puertos
;               AX  - Versi¢n del DSP (ax=040d -> ver=4.13)
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
SBInfo          PROC
        mov     ah, DSPVerH
        mov     al, DSPVerL

        mov     esi, offset msg_sb1
        cmp     ah, 1
        je      sb_ver_ok
        mov     esi, offset msg_sb15
        cmp     ax, 200h
        je      sb_ver_ok
        mov     esi, offset msg_sb2
        cmp     ah, 2
        je      sb_ver_ok
        mov     esi, offset msg_sbpro
        cmp     ah, 3
        je      sb_ver_ok
        mov     esi, offset msg_sb16
        cmp     ah, 4
        je      sb_ver_ok

        mov     esi, offset msg_unk

sb_ver_ok:




        mov     ax, SBbase
        add     ah, '0'
        mov     byte ptr [msg_ports+2], ah
        mov     ah, al
        shr     ah, 4
        and     al, 0fh
        add     ah, '0'
        mov     byte ptr [msg_ports+3], ah
        add     al, '0'
        mov     byte ptr [msg_ports+4], al


        mov     al, SBIRQ
        add     al, '0'
        mov     byte ptr [msg_ports+8], al

        mov     al, SBDMA
        add     al, '0'
        mov     byte ptr [msg_ports+12], al



        mov     edi, offset msg_ports



        ret
SBInfo          ENDP


GetSB16IRQnDMA  PROC
        mov     al, 80h
        call    ReadMixer

        mov     SBIRQ, 2
        test    al, 1
        jnz     irq_lista
        mov     SBIRQ, 5
        test    al, 2
        jnz     irq_lista
        mov     SBIRQ, 7
        test    al, 4
        jnz     irq_lista
        mov     SBIRQ, 10
        test    al, 8
        jnz     irq_lista

        mov     SBIRQ, 0
irq_lista:
        mov     al, 81h
        call    ReadMixer

        mov     SBDMA, 0
        test    al, 1
        jnz     dma_lista
        mov     SBDMA, 1
        test    al, 2
        jnz     dma_lista
        mov     SBDMA, 3
        test    al, 4
        jnz     dma_lista


        mov     SBDMA, 0
dma_lista:
        mov     SBHDMA, 5
        test    al, 20h
        jnz     hdma_lista
        mov     SBHDMA, 6
        test    al, 40h
        jnz     hdma_lista
        mov     SBHDMA, 7
        test    al, 80h
        jnz     hdma_lista

        mov     SBHDMA, 0
hdma_lista:
        ret
GetSB16IRQnDMA  ENDP

GetIRQnDMA      PROC
; Salvar vectores
        in      al, 0a1h                ; B52 -> slave PIC
        mov     ah,al                   ; B52
        in      al, 21h
        push    eax                     ; B52

        mov     ax, 0204h
        mov     bl, (8+2)
        int     31h
        mov     antirq02, edx
        mov     antirq02sel, cx

        mov     ax, 0204h
        mov     bl, (8+3)
        int     31h
        mov     antirq03, edx
        mov     antirq03sel, cx

        mov     ax, 0204h
        mov     bl, (8+5)
        int     31h
        mov     antirq05, edx
        mov     antirq05sel, cx

        mov     ax, 0204h
        mov     bl, (8+7)
        int     31h
        mov     antirq07, edx
        mov     antirq07sel, cx



        mov     ax, 0205h
        mov     edx, offset TestIRQ2
        mov     cx, cs
        mov     bl, (8+2)
        int     31h

        mov     ax, 0205h
        mov     edx, offset TestIRQ3
        mov     cx, cs
        mov     bl, (8+3)
        int     31h

        mov     ax, 0205h
        mov     edx, offset TestIRQ5
        mov     cx, cs
        mov     bl, (8+5)
        int     31h

        mov     ax, 0205h
        mov     edx, offset TestIRQ7
        mov     cx, cs
        mov     bl, (8+7)
        int     31h

        jmp     TestDMAs        ; B52



TestDMA proc    ; AH = n£mero de DMA    ; B52
        mov     al, 48h
        mov     ebx, offset sb_testbuf
        mov     ecx, 1                   ; B52 -> 1 byte
        call    DMA_Setup

;        mov     al, 0d1h               ; B52   No queremos el t¡pico
;        call    WriteDSP               ; B52   chasquido... ;)

        mov     al, 40h
        call    WriteDSP

;        mov     al,206                  ; B52 -> 20KHz (206)
        mov     eax,1000000
        div     frecuencia
        sub     eax,256
        neg     eax
        call    WriteDSP                ; Time constant

        mov     al, 14h                 ; B52 -> single DMA to DAC
        call    WriteDSP

        xor     al,al                   ; B52 -> 1 byte
        call    WriteDSP
        xor     al, al
        call    WriteDSP

        mov     al, 100b                ; Deshabilitamos todos los canales DMA
        out     00ah, al
        mov     al, 101b
        out     00ah, al
        mov     al, 110b
        out     00ah, al
        mov     al, 111b
        out     00ah, al

        in      al, 21h
        and     al, 01010011b           ; ** IRQ's 2, 3, 5, 7 (falta la 10) **
        out     21h, al

;        in      al, 0a1h                ; B52
;        and     al, 11111011b           ; B52 -> IRQ 10 (slave PIC)
;        out     0a1h, al                ; B52
        ret
TestDMA endp

TestDMAs:

; TEST DMA CHANNEL 0

        mov     IRQTest, 0
        mov     SBDMA, 0

        xor     ah,ah           ; B52
        call    TestDMA         ; B52

        mov     ecx, IRQ_TIMEOUT
wait4irq01:
        mov     dx, 61h
        in      al, dx
        cmp     IRQTest, 0
        jne     irq_detected
        loop    wait4irq01

; TEST DMA CHANNEL 1

        mov     SBDMA, 1

        mov     ah,1            ; B52
        call    TestDMA         ; B52

        mov     ecx, IRQ_TIMEOUT
wait4irq02:
        mov     dx, 61h
        in      al, dx
        cmp     IRQTest, 0
        jne     irq_detected
        loop    wait4irq02

; TEST DMA CHANNEL 3

        mov     SBDMA, 3

        mov     ah,3            ; B52
        call    TestDMA         ; B52

        mov     ecx, IRQ_TIMEOUT
wait4irq03:
        mov     dx, 61h
        in      al, dx
        cmp     IRQTest, 0
        jne     irq_detected
        loop    wait4irq03

        jmp     irq_not_detected

irq_detected:
        mov     al, IRQTest
        mov     SBIRQ, al

        mov     al, 100b
        out     00ah, al
        mov     al, 101b
        out     00ah, al
        mov     al, 110b
        out     00ah, al
        mov     al, 111b
        out     00ah, al

        call    SBStop

        pop     eax             ; B52
        out     21h, al
        mov     al,ah           ; B52
        out     0a1h,al         ; B52 -> slave PIC
        ret
irq_not_detected:
        mov     SBDMA, 0
        mov     SBIRQ, 0

        mov     al, 100b
        out     00ah, al
        mov     al, 101b
        out     00ah, al
        mov     al, 110b
        out     00ah, al
        mov     al, 111b
        out     00ah, al

        pop     eax             ; B52
        out     21h, al
        mov     al,ah           ; B52
        out     0a1h,al         ; B52 -> slave PIC
        ret
GetIRQnDMA      ENDP


comment $
ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
³ "DMA_Setup"   PROGRAM A CHANNEL ON THE 8237 DMA CONTROLLER               ³
³             A general routine to program the DMA controler.              ³
³                                                                          ³
³ By Adam Seychell                                                         ³
³                                                                          ³
³                                                                          ³
³ INPUT:        AL    Mode Register  ( bits 0..1 ignored )                 ³
³               AH    channel   ( 0..7 )                                   ³
³               EBX   Physical Base Address ( 0..0ffffffh )                ³
³               ECX   Bytes to transfer     ( 1..10000h )                  ³
³                                                                          ³
³                                                                          ³
³Distroys:  EAX, EDX & ECX                                                 ³
³                                                                          ³
³        code has been optimized and fully tested.                         ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ $

DMA_Setup PROC
        push    edi
        push    ebx
        xor     edx,edx
        and     ah,7
        mov     DMA_channel,ah
        and     al,NOT 3
        mov     mode,al

        ; -----  set channel mask register ------
        movzx   edi,DMA_channel
        mov     eax,edi
        shr     edi,2
        and     al,0011b
        or      al,0100b
        mov     dl,DMA_SNGL[edi]
        out     dx,al

        ; ----- set mode register ------
        and     al,03h
        or      al,mode
        mov     dl,DMA_MODE[edi]
        out     dx,al

        ; ------  clear MSB/LSB flip flop -----------
        xor     al,al                   ; B52
        mov     dl,DMA_CLRFF[edi]
        out     dx,al



        ;---- set byte count register ----
        movzx   edi,DMA_channel
        mov     eax,ecx
        mov     ecx,edi
        shr     ecx,2
        shr     eax,cl                ; divide count address by 2 for DMA # 2
        dec     eax                     ; count - 1
        mov     dl,DMA_CNT[edi]         ; bits 0..7
        out     dx,al
        shr     eax,8
        out     dx,al                   ; bits 8..15


        ;---- set channel base address ---
        shr     ebx,cl                ; divide base address by 2 for DMA # 2
        mov     al,BL                       ; set bits 0..7
        mov     dl,DMA_ADDR[edi]
        out     dx,al
        mov     al,BH                       ; set bits 8..15
        out     dx,al

        shr     ebx,15           ; divide base address by 8000h for DMA # 2
        xor     cl,1
        shr     ebx,cl           ; divide base address by 10000h for DMA # 1
        mov     al,BL            ; set bits 16..23 ( in LSB page register )
        mov     dl,DMA_PAGE[edi]
        out     dx,al


        ; -----  clear channel (mask register) ------
        mov     eax,edi
        shr     edi,2
        and     al,03h
        mov     dl,DMA_SNGL[edi]
        out     dx,al
        pop     ebx
        pop     edi
        ret


mode            Db  ?
DMA_channel     Db  ?


;* 1st & 2nd DMA Controler's ports *;

  DMA_STAT   db 008h,0D0h        ;* read status register *;
  DMA_CMD    db 008h,0D0h        ;* write command register *;
  DMA_REQ    db 009h,0D2h        ;* write request register *;
  DMA_SNGL   db 00Ah,0D4h        ;* write single bit register *;
  DMA_MODE   db 00Bh,0D6h        ;* write mode register *;
  DMA_CLRFF  db 00Ch,0D8h        ;* clear byte ptr flip;flop *;
  DMA_MCLR   db 00Dh,0DAh        ;* master clear register *;
  DMA_CLRM   db 00Eh,0DCh        ;* clear mask register *;
  DMA_WRTALL db 00Fh,0DEh        ;* write all mask register *;

; * ports for 8 channels *;

DMA_PAGE        db 087h,083h,081h,082h,08Fh,08Bh,089h,08Ah ; page register
DMA_ADDR        db 000h,002h,004h,006h,0C0h,0C4h,0C8h,0CCh ; base adddress
DMA_CNT         db 001h,003h,005h,007h,0C2h,0C6h,0CAh,0CEh ; base count

DMA_Setup   Endp






;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° SBPlay °°
; Entrada :     EAX    - Frecuencia
;               ECX    - Tama¤o del buffer (bit31=1 para usar t‚cnica del
;                                           doble buffer)
;               CS:EBX - Rutina dentro de la IRQ (EBX=0 para no cambiarla)
;               DS:ESI - Buffer DMA (m x 64 Kb, direcci¢n f¡sica)
;               DL     - Flags (no implementados --> siempre en Stereo)
; Salida  :     CF = 0 + EAX = 0 si no hay error,
;               CF = 1 + EAX = C¢digo de error:
;                               01 = La SB no hab¡a sido inicializada
;                               02 = Tarjeta incompatible
;                               03 = No es formato MOD ni S3M
;                               04 = Error interno de carga del fichero
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
SBPlay                  PROC
        mov     word ptr [rutina_sb-2], cs
        mov     segdata, ds

        mov     sbmitad, 0
        mov     dmabytes, 0

        mov     dmaddr, esi
        mov     sbfreq, eax

        mov     esi, ecx
        and     ecx, 0ffffh

        mov     bufsize, ecx
        mov     sbsize, ecx

        test    esi, 80000000h
        jz      nodoblebuffer
        shr     sbsize, 1
nodoblebuffer:

        or      ebx, ebx
        jz      nocambiarirq

        mov     dword ptr [rutina_sb-6], ebx
        mov     word ptr [rutina_sb-2], cs
nocambiarirq:
        cmp     ebx, -1
        jne     noponerdummy

        mov     dword ptr [rutina_sb-6], offset SBDummy
        mov     word ptr [rutina_sb-2], cs

noponerdummy :
        mov     bl, SBIRQ               ; Ponemos nuestra IRQ en su sitio
        add     bl, 8                   ; para atender a la Sound Blaster
        mov     edx, offset SBISR
        mov     ax, 0205h
        mov     cx, cs
        int     31h



;        xor     ax, ax
;        call    WriteMixer

        cmp     SBBase, 0
        je      error_no_inicializado

        cmp     DSPVerH, 4
        je      iniciar_transferencia_sb16
        cmp     DSPVerH, 3
        je      iniciar_transferencia_sbpro

        mov     eax, 2
        stc
        ret
;----------------------------------------------------------------------------
iniciar_transferencia_sb16:
        mov     al, 58h
        mov     ah, SBDMA
        mov     ebx, dmaddr
        mov     ecx, bufsize
        call    DMA_Setup

        xor     edx, edx
        mov     eax, 1000000
        div     sbfreq
        mov     bx, 256
        sub     bx, ax



        mov     al, 0d1h
        call    WriteDSP

        mov     al, 40h
        call    WriteDSP
        mov     al, bl ;210;234
        call    WriteDSP                ; Time constant


        mov     al, 0c6h                ; ####### (c6 = 8 bits)
        call    WriteDSP
        mov     al, 00100000b           ; 00110000b = stereo
        call    WriteDSP

        mov     eax, sbsize
        dec     eax
        call    WriteDSP
        shr     ax, 8
        call    WriteDSP

        mov     al, digital_volume
        call    SetVolume
        mov     al, global_volume
        call    SetGlobalVolume


        xor     eax, eax
        clc
        ret




iniciar_transferencia_sbpro:
;        call    SBReset
        call    SBStop          ; B52
;        xor     eax,eax         ; B52
;        call    WriteDSP        ; B52

;        xor     eax,eax         ; B52
;        call    WriteMixer

        mov     al, 58h
        mov     ah, SBDMA
        mov     ebx, dmaddr
        mov     ecx, bufsize
        call    DMA_Setup

        mov     al,0eh                  ; B52
        call    ReadMixer               ; B52
        or      al,10b                  ; B52
        mov     ah,0eh                  ; B52
        call    WriteMixer

        mov     al, 0d1h
        call    WriteDSP

        xor     edx, edx
        mov     eax, 500000
        div     sbfreq
        mov     bx, 256
        sub     bx, ax

        mov     al, 40h
        call    WriteDSP
        mov     al, bl
        call    WriteDSP                ; Time constant

        mov     al, 048h
        call    WriteDSP
        mov     eax, sbsize
        dec     eax            ; B52
        call    WriteDSP
        shr     ax, 8
        call    WriteDSP

        mov     al, 0a8h
        call    WriteDSP                ; Pa'l stereo

        mov     al, 090h
        call    WriteDSP

        mov     al, digital_volume
        call    SetVolume
        mov     al, global_volume
        call    SetGlobalVolume

        xor     eax, eax
        clc
        ret



error_no_inicializado:
        mov     eax, 1
        stc
        ret

SBPlay                  ENDP



SBStop                  PROC
        mov     al, 0d0h                        ; Parar la SB
        call    WriteDSP
        mov     al, 0d3h
        call    WriteDSP

        call    SBReset

        mov     al, SBDMA                       ; Parar la DMA
        or      al, 100b
        out     00ah, al

        ret
SBStop                  ENDP








;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±± SBISR ±±
SBISR           PROC
        push    es ds
        push    eax edx ecx edi

        cld

        PUSH    EBX ESI EBP

;        pushad

        mov     ax, word ptr cs:[segdata]
        mov     ds, ax
        mov     es, ax

;        call    ReadDSP

        mov     dx, SBbase                      ; SB ACK
        add     dx, DSP_DATA_AVAIL
        in      al, dx


        mov     edi, dmaddr
        mov     ecx, sbsize

        add     dmabytes, ecx

        xor     sbmitad, -1
        video   156, '1'
        jnz     primera_mitad
        add     edi, ecx
        video   156, '2'
primera_mitad:
        push    offset rutina_sb
        db      0eah
        dd      offset SBDummy
        dw      0
rutina_sb:

;        popad

        POP     EBP ESI EBX

        pop     edi ecx

        mov     al,20h
        mov     dx,20h

        cmp     SBIRQ, 7
        jbe     hirq

                mov     dx,0a0h
hirq:
        out     dx,al

        pop     edx eax

        pop     ds es

        iretd



        segdata         dw 0
SBISR           ENDP

SBDummy         PROC
        ret
SBDummy         ENDP


GetSBDMAptr     PROC
        push    edx
        xor     dh, dh

        mov     dl, SBDMA
        shl     dx, 1

        xor     eax, eax

        in      al, dx
        shl     ax, 8
        in      al, dx
        rol     ax, 8

        cmp     eax, sbsize
        jb      nadadma

        sub     eax, sbsize

nadadma:
        add     eax, dmabytes

        pop     edx
        ret
GetSBDMAptr     ENDP

SetVolume       PROC
        PUSH    EBP
        mov     digital_volume, al

        push    eax
        mov     ah, 04h
        call    WriteMixer
        pop     eax
        POP     EBP
        ret
SetVolume       ENDP

SetGlobalVolume PROC
        PUSH    EBP
        mov     global_volume, al

        push    eax
        mov     ah, 22h
        call    WriteMixer
        pop     eax
        POP     EBP
        ret
SetGlobalVolume ENDP

ChangeMixR      PROC

        or      ebx, ebx
        jz      nocambiarirq2

        mov     dword ptr [rutina_sb-6], ebx
        mov     word ptr [rutina_sb-2], cs
nocambiarirq2:
        cmp     ebx, -1
        jne     noponerdummy2

        mov     dword ptr [rutina_sb-6], offset SBDummy
        mov     word ptr [rutina_sb-2], cs

noponerdummy2:
        ret

ChangeMixR      ENDP

GetMixR         PROC
        mov     ebx, dword ptr [rutina_sb-6]
        ret
GetMixR         ENDP

END
