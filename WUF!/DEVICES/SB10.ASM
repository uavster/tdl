;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; SoundBlaster 1.0 routines for sound input/output
;       Ignacio Mellado Bataller ( B52 / the DarkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.386p
.model flat
.code
        PLAY_ON                 EQU 1
        PLAY_OFF                EQU 0

        SB_TIMEOUT              EQU 100000
        SB_REGISTERS            EQU 7

        ; DSP commands
        DSP_SPEAKER_ON          EQU 0D1h
        DSP_SPEAKER_OFF         EQU 0D3h
        DSP_DMA_STOP            EQU 0D0h
        DSP_DMA_CONTINUE        EQU 0D4h
        DSP_WRITE_TIME_CT       EQU 40h
        DSP_8_BIT_PLAYBACK      EQU 14h

        INCLUDE sounddev.inc
        INCLUDE sb10.inc
        INCLUDE utils.inc
        INCLUDE dma.inc
        INCLUDE stderror.inc
        INCLUDE snddev.def

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Fixes SB registers
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
FixRegisters    proc
        mov     esi,offset SBRegs
        mov     ecx,SB_REGISTERS
        mov     eax,SBbase
        fix_em:
                add     dword ptr [esi],eax
                add     esi,4
        loop    fix_em
        mov     irq_ack_port,20h
        cmp     SBirq,7
        jbe     iack_ok
                mov     irq_ack_port,0a0h
        iack_ok:
        ret
FixRegisters    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Builds the name string of the device
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
BuildDevName    proc
        mov     eax,SBbase
        mov     esi,offset address_str
        mov     ebx,16
        call    TransToBase
        mov     esi,offset DevName
        call    StringLength
        mov     [DevName+ecx],'h'
        mov     eax,SBirq
        mov     esi,offset irq_str
        mov     ebx,10
        call    TransToBase
        mov     esi,offset DevName
        call    StringLength
        mov     [DevName+ecx],' '
        mov     eax,SBdma
        mov     esi,offset dma_str
        mov     ebx,10
        call    TransToBase
        mov     esi,offset DevName
        call    StringLength
        mov     [DevName+ecx],' '
        ret
BuildDevName    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Reads a byte from the DSP
;
; OUTPUT : CF = 0 if ok
;               AL = Byte read
;          CF = 1 if read timed out
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ReadDSP proc
        mov     ebx,SB_TIMEOUT
        mov     edx,DSPDataAvail
        read_da_byte:
                in      al,dx
                and     al,80h
                jnz     byte_read
        dec     ebx
        jnz     read_da_byte
        stc
        ret

        byte_read:
        mov     edx,DSPReadData
        in      al,dx
        clc
        ret
ReadDSP endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Writes a byte to the DSP
;
; INPUT  : AL = Byte to write to the DSP
; OUTPUT : CF = 0 if ok
;          CF = 1 if write timed out
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WriteDSP        proc
        mov     cl,al
        mov     ebx,SB_TIMEOUT
        mov     edx,DSPWriteStatus
        write_da_byte:
                in      al,dx
                and     al,80h
                jz      byte_write
        dec     ebx
        jnz     write_da_byte
        stc
        ret

        byte_write:
        mov     al,cl
        mov     edx,DSPWriteData
        out     dx,al
        clc
        ret
WriteDSP        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Detects SoundBlaster 1.0 parameters with the BLASTER environment variable
;
; OUTPUT -> CF = 0 if SoundBlaster 1.0 parameters were detected
;           CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DetectBLASTER   proc
        GetEnvVar "BLASTER"
        jc      wrong_env_var
        ; Looking for A...
        mov     esi,eax         ; pointer to environment variable
        mov     edi,offset TempBuffer
        call    GetCommandParam
        cmp     ecx,4
        jnz     wrong_env_var
        cmp     byte ptr [edi],'A'
        jnz     wrong_env_var
        ; Looking for I...
        add     edi,4
        call    GetCommandParam
        cmp     ecx,3           ; irq 10 string is 3 bytes long
        ja      wrong_env_var
        cmp     ecx,2           ; otherwise, 2 bytes long
        jnz     wrong_env_var
        cmp     byte ptr [edi],'I'
        jnz     wrong_env_var
        dec     ecx
        mov     IrqLength,ecx
        ; Looking for D...
        add     edi,3
        call    GetCommandParam
        cmp     ecx,2
        jnz     wrong_env_var
        cmp     byte ptr [edi],'D'
        jnz     wrong_env_var

        ; Parameter conversion
        ; Port
        mov     esi,offset TempBuffer+1
        mov     byte ptr [esi+3],0
        call    GetHexInteger
        jc      wrong_env_var
        mov     SBbase,eax
        ; irq
        mov     esi,offset TempBuffer+5
        mov     ecx,IrqLength
        mov     byte ptr [esi+ecx],0
        call    GetInteger
        jc      wrong_env_var
        mov     SBirq,ecx
        ; dma
        mov     esi,offset TempBuffer+8
        mov     byte ptr [esi+1],0
        call    GetInteger
        jc      wrong_env_var
        mov     SBdma,ecx
        call    FixRegisters
        call    BuildDevName
        clc
        wrong_env_var:
        ret
DetectBLASTER   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Tries to detect SoundBlaster 1.0 parameters with direct hardware access
;
; OUTPUT -> CF = 0 if SoundBlaster 1.0 detected ok
;           CF = 1 if SoundBlaster 1.0 not detected
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DetectHard      proc
        call    FixRegisters
        call    BuildDevName
        stc
        ret
DetectHard      endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Resets SoundBlaster 1.0
;
; OUTPUT -> CF = 0 if SoundBlaster 1.0 reset ok
;           CF = 1 otherwise
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Reset   proc
        mov     edx,DSPReset
        mov     al,1
        out     dx,al

        in      al,dx
        in      al,dx
        in      al,dx
        in      al,dx
        in      al,dx
        in      al,dx

        xor     al,al
        out     dx,al

        call    ReadDSP
        jc      reset_error
        cmp     al, 0AAh
        jne ÿ   reset_error
        clc
        ret

        reset_error:
        stc
        ret
Reset   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initializes SB 1.0 driver
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Init    proc
        call    Reset
        jc      init_error
        ; Save old IRQ
        mov     ax,204h
        mov     ebx,SBirq
        add     bl,8
        int     31h
        mov     OldIRQ.IRQOffset,edx
        mov     OldIRQ.IRQSegment,ecx
        ; Allocate IRQ
        mov     ax,205h
        mov     ebx,SBirq
        add     bl,8
        mov     cx,cs
        mov     edx,offset PlayIRQ
        int     31h
        ; Need memory for DMA buffers
        mov     ecx,DMA_PLAY_BUFFER_LENGTH
        call    AllocDMABuffer
        jc      init_error
        mov     PlayBuff,ebx
        mov     ecx,DMA_REC_BUFFER_LENGTH
        call    AllocDMABuffer
        jc      init_error
        mov     RecBuff,ebx
        clc
        init_error:
        ret
Init    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Terminates SB 1.0 driver
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Terminate       proc
        call    StopPlay
        jc      terminate_error
        call    StopRec
        jc      terminate_error
        call    Reset
        jc      terminate_error
        ; Restoring IRQ
        mov     ax,205h
        mov     ebx,SBirq
        add     bl,8
        mov     edx,OldIRQ.IRQOffset
        mov     ecx,OldIRQ.IRQSegment
        int     31h
        ; Freeing buffers
        mov     ebx,PlayBuff
        call    FreeDMABuffer
        jc      terminate_error
        mov     ebx,RecBuff
        call    FreeDMABuffer
        jc      terminate_error
        clc
        terminate_error:
        ret
Terminate       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Returns the time constant for a given sample rate
;
; INPUT  : EAX = Sample rate
; OUTPUT : AL = Time constant
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetTimeCt       proc
        mov     ebx,eax
        mov     eax,1000000
        xor     edx,edx
        div     ebx
        sub     eax,256
        neg     eax
        ret
GetTimeCt       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Starts playing sound from the playback buffer
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if hardware doesn't answer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
StartPlay       proc
        ; Program DMA chip        
        mov     eax,SBdma
        mov     ebx,PlayBuff
        mov     ecx,DMA_PLAY_BUFFER_LENGTH
        call    DMAWriteToDevice
        ; Turn speakers on
        mov     al,DSP_SPEAKER_ON
        call    WriteDSP
        jc      splay_error
        ; Send time constant
        mov     al,DSP_WRITE_TIME_CT
        call    WriteDSP
        jc      splay_error
        mov     eax,PlaySampRate
        call    GetTimeCt
        call    WriteDSP
        jc      splay_error
        ; Set playback type (8 bits)
        mov     al,DSP_8_BIT_PLAYBACK
        call    WriteDSP
        jc      splay_error
        ; Set transfer size
        mov     eax,DMA_PLAY_BUFFER_LENGTH
        dec     eax
        push    eax
        call    WriteDSP
        pop     eax
        jc      splay_error
        mov     al,ah
        call    WriteDSP
        jc      splay_error
        mov     PlayStatus,PLAY_ON
        clc
        splay_error:
        ret
StartPlay       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; IRQ handler to refresh DMA transfer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
PlayIRQ         proc
        pushad
        ; DSP Acknowledge
        mov     edx,DSPDataAvail
        in      al,dx
        call    StartPlay
        ; IRQ acknowledge
        mov     al,20h
        mov     edx,irq_ack_port
        out     dx,al
        popad
        iretd
PlayIRQ         endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Stops playing sound from the playback buffer
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if hardware doesn't answer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
StopPlay        proc
        ; Maybe SB didn't get acknowledge
        mov     edx,DSPDataAvail
        in      al,dx
        mov     al,DSP_DMA_STOP
        call    WriteDSP
        jc      stop_error
        mov     al,DSP_SPEAKER_OFF
        call    WriteDSP
        jc      stop_error
        mov     PlayStatus,PLAY_OFF
        stop_error:
        ret
StopPlay        endp

StartRec        proc
        ret
StartRec        endp

StopRec         proc
        ret
StopRec         endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Returns information about the playback and record buffers
;
; OUTPUT : EAX -> Playback buffer
;          EBX -> Record buffer
;          ECX = Size of playback buffer
;          EDX = Size of record buffer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetSndBuffers   proc
        mov     eax,PlayBuff
        mov     ebx,RecBuff
        mov     ecx,DMA_PLAY_BUFFER_LENGTH
        mov     edx,DMA_REC_BUFFER_LENGTH
        ret
GetSndBuffers   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets playback properties
;
; OUTPUT : EAX = Sample rate
;          EBX = Flags  ( bit 0: 16 bits , bit 1: Stereo )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetPlayProps    proc
        mov     eax,PlaySampRate
        mov     ebx,PlayProps
        ret
GetPlayProps    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets playback properties
;
; INPUT  : EAX = Sample rate
;          EBX = Flags  ( bit 0: 16 bits , bit 1: Stereo )
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if properties exceed hardware capabilities
;                 or hardware doesn't answer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetPlayProps    proc
        test    ebx,11b
        jnz     spp_error
        cmp     eax,22050
        ja      spp_error
        mov     PlaySampRate,eax
        cmp     PlayStatus,PLAY_OFF
        jz      dnts
        call    StopPlay
        jc      spp_error
        call    StartPlay
        jc      spp_error
        dnts:
        clc
        ret

        spp_error:
        stc
        ret
SetPlayProps    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets recording properties
;
; OUTPUT : EAX = Sample rate
;          EBX = Flags  ( bit 0: 16 bits , bit 1: Stereo )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetRecProps     proc        
        ret
GetRecProps     endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets recording properties
;
; INPUT  : EAX = Sample rate
;          EBX = Flags  ( bit 0: 16 bits , bit 1: Stereo )
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if properties exceed hardware capabilities
;                 or hardware doesn't answer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetRecProps     proc
        clc
        ret
SetRecProps     endp

.data
SB10Device      SoundDevice <offset DevName, offset DetectBLASTER, offset DetectHard, offset Init, offset Terminate, offset Reset, offset StartPlay, offset StopPlay, offset StartRec, offset StopRec, offset GetSndBuffers, offset GetPlayProps, offset SetPlayProps, offset GetRecProps, offset SetRecProps>

; SB registers
SBRegs  LABEL
        MixerIndex      dd 04h
        MixerData       dd 05h
        DSPReset        dd 06h
        DSPReadData     dd 0Ah
        DSPWriteData    dd 0Ch
        DSPWriteStatus  dd 0Ch
        DSPDataAvail    dd 0Eh

; Device name
DevName         db "[ SoundBlaster 1.0 - A:"
address_str     db ?,?,?,"h I:"
irq_str         db ?,?," D:"
dma_str         db ?," ]",0

; Current sample rate
PlaySampRate    dd 22050
PlayProps       dd 0    ; (8 bits, mono)

PlayStatus      db 0

.data?

IRQVector       STRUC
        IRQOffset       dd ?
        IRQSegment      dd ?
ENDS

OldIRQ          IRQVector <>

PlayBuff        dd ?
RecBuff         dd ?

irq_ack_port    dd ?

SBbase          dd ?
SBirq           dd ?
SBdma           dd ?
IrqLength       dd ?
TempBuffer      db 128 dup(?)

end
