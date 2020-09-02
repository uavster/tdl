;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; SoundBlaster 1.x routines for sound input/output
;       Ignacio Mellado Bataller ( B52 / the DarkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.386p
.model flat
.code
        PLAY_ON                 EQU 1
        PLAY_OFF                EQU 0

        MAX_PLAY_SAMPLE_RATE    EQU 22050
        MAX_PLAY_PROPS          EQU 0           ; (8 bits, mono)

        INCLUDE sounddev.inc
        INCLUDE sb1x.inc
        INCLUDE utils.inc
        INCLUDE dma.inc
        INCLUDE stderror.inc
        INCLUDE snddev.def
        INCLUDE sbhard.inc
        INCLUDE mixer.inc

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
; Initializes SB 1.x driver
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Init    proc
        call    SBReset
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
        mov     ecx,DMA_PLAY_BUFFER_LENGTH*2    ; double buffering
        call    AllocDMABuffer
        jc      init_error
        mov     PlayBuff,ebx
        mov     ecx,DMA_REC_BUFFER_LENGTH
        call    AllocDMABuffer
        jc      init_error
        mov     RecBuff,ebx
        ; Clear play/rec buffers
        mov     ecx,DMA_PLAY_BUFFER_LENGTH
        xor     eax,eax
        mov     edi,PlayBuff
        rep     stosw   ; double buffering
        mov     ecx,DMA_REC_BUFFER_LENGTH
        mov     edi,RecBuff
        rep     stosb
        clc
        init_error:
        ret
Init    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Terminates SB 1.x driver
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Terminate       proc
        call    StopPlay
        jc      terminate_error
        call    StopRec
        jc      terminate_error
        call    SBReset
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
        mov     FirstPlayBuff,1
        ; Send time constant
        mov     al,DSP_WRITE_TIME_CT
        call    WriteDSP
        jc      splay_error
        mov     eax,PlaySampRate
        call    GetTimeCt
        call    WriteDSP
        jc      splay_error
        ; Program DMA chip        
        mov     eax,SBdma
        mov     ebx,PlayBuff
        mov     ecx,DMA_PLAY_BUFFER_LENGTH*2    ; double buffering
        call    DMAWriteToDevice
        ; Turn speakers on
        mov     al,DSP_SPEAKER_ON
        call    WriteDSP
        jc      splay_error
        ; Set playback type (8 bits mono)
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

EnableDSP       MACRO
        ; Set playback type (8 bits mono)
        mov     al,DSP_8_BIT_PLAYBACK
        call    WriteDSP
        ; Set transfer size
        mov     eax,DMA_PLAY_BUFFER_LENGTH
        dec     eax
        push    eax
        call    WriteDSP
        pop     eax
        mov     al,ah
        call    WriteDSP
ENDM

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; IRQ handler to refresh DMA transfer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
PlayIRQ         proc
        pushad
        push    ds es
        mov     ax,DataSelector
        mov     ds,ax
        mov     es,ax

        ; DSP Acknowledge
        mov     edx,DSPDataAvail
        in      al,dx
        EnableDSP
        ; IRQ acknowledge
        mov     al,20h
        mov     edx,irq_ack_port
        out     dx,al
        sti
        ; Mix all channels
        mov     eax,PlayBuff
        test    FirstPlayBuff,1
        jnz     its_first_half
                add     eax,DMA_PLAY_BUFFER_LENGTH
        its_first_half:
        xor     FirstPlayBuff,1
        call    MixChannels
        pop     es ds
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
        cmp     PlayStatus,PLAY_OFF
        jz      stop_error
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Detects SB 1.x with BLASTER environment variable
;
; OUTPUT : CF = 0 if SB 1.x detected
;          CF = 1 otherwise
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DetectBLASTER1x proc
        call    DetectBLASTER
        ErrorCode eax
        call    BuildDevName
        ret
DetectBLASTER1x endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Detects SB 1.x with direct hardware access
;
; OUTPUT : CF = 0 if SB 1.x detected
;          CF = 1 otherwise
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DetectHard1x    proc
        call    SBDetectHard
        ErrorCode eax
        call    BuildDevName
        ret
DetectHard1x    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets SB 1.x hardware capabilities
;
; OUTPUT : EAX = Max. playback sample
;          EBX = Max. playback sound properties (bit 0: 16 bits, bit 1: Stereo)
;          ECX = Max. recording sample        
;          EDX = Max. recording sound properties (bit 0: 16 bits, bit 1: Stereo)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Get1xCaps       proc
        mov     eax,MAX_PLAY_SAMPLE_RATE
        mov     ebx,MAX_PLAY_PROPS
        ret
Get1xCaps       endp

.data
SB1xDevice      SoundDevice <offset DevName, offset DetectBLASTER1x, offset DetectHard1x, offset Init, offset Terminate, offset SBReset, offset StartPlay, offset StopPlay, offset StartRec, offset StopRec, offset GetSndBuffers, offset GetPlayProps, offset SetPlayProps, offset GetRecProps, offset SetRecProps, offset Get1xCaps>

; Device name
DevName         db "[ SoundBlaster 1.x - A:"
address_str     db ?,?,?,"h I:"
irq_str         db ?,?," D:"
dma_str         db ?," ]",0

; Current sample rate
PlaySampRate    dd MAX_PLAY_SAMPLE_RATE
PlayProps       dd MAX_PLAY_PROPS

PlayStatus      db 0

.data?

IRQVector       STRUC
        IRQOffset       dd ?
        IRQSegment      dd ?
ENDS

OldIRQ          IRQVector <>

PlayBuff        dd ?
RecBuff         dd ?

FirstPlayBuff   dd ?

end
