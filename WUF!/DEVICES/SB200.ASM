;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sound Blaster DSP 2.00 routines for audio input/output
;       Ignacio Mellado Bataller ( B52 / the DarkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.386p
.model flat
.code
        PLAY_ON                 EQU 1
        PLAY_OFF                EQU 0
        DSP_8_BIT_PLAYBACK      EQU 1Ch	; Auto-initialize transfer
		DSP_EXIT_AUTOINIT		EQU 0DAh
		
        INCLUDE sounddev.inc
        INCLUDE sb200.inc
        INCLUDE utils.inc
        INCLUDE dma.inc
        INCLUDE stderror.inc
        INCLUDE snddev.def
        INCLUDE sbhard.inc
        INCLUDE mixer.inc
		INCLUDE assert.inc
		INCLUDE irq.inc

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Return driver name
;
; OUTPUT : EAX -> Driver name
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetSB200DriverName	proc
		mov		eax,offset SB200DriverName
		ret
GetSB200DriverName	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Detect Sound Blaster DSP 2.00 with BLASTER environment variable
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DetectSB200	proc
		call	DetectBLASTER
		jc		sb200_det_end
				cmp		DSPVersion.Major,2	; >=2 -> CF = 0; <2 -> CF = 1
		sb200_det_end:	
		ret
DetectSB200	endp
		
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initializes SB 2.00 driver
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Init    proc
		AssertD	DMA_PLAY_BUFFER_LENGTH,_ltu,65536
		AssertD	DMA_REC_BUFFER_LENGTH,_ltu,65536
		; Set maximum play properties
		; Set preferred play properties
		call	GetPlay200Caps
		mov		edx,eax
		movzx	ebx,[edx.NumCapabilities]
		AssertD	ebx,_gtu,0
		mov		edx,[edx.Capabilities]	; The first capability is the preferred one
		sub		esp,size SoundProperties
		mov		eax,esp
		mov		ebx,[edx.SCMaxSamplingRate]
		mov		[eax.SPSamplingRate],ebx
		mov		bl,[edx.SCBitsPerSample]
		mov		[eax.SPBitsPerSample],bl
		mov		bl,[edx.SCNumChannels]
		mov		[eax.SPNumChannels],bl
		xor		ebx,ebx
		call	SetPlayProps
		lea		esp,[esp+size SoundProperties]
		jc		init_error
        call    SBReset
        jc      init_error
        ; Save old IRQ
        mov     ax,204h
        mov     ebx,SBirq
        add     bl,8
        int     31h
        mov     OldIRQ.IRQOffset,edx
        mov     OldIRQ.IRQSegment,cx
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
        mov     PlayBuff.Pointer,ebx
		mov		PlayBuff.NumBytes,DMA_PLAY_BUFFER_LENGTH
        mov     ecx,DMA_REC_BUFFER_LENGTH
        call    AllocDMABuffer
        jc      init_error
        mov     RecBuff.Pointer,ebx
		mov		RecBuff.NumBytes,DMA_REC_BUFFER_LENGTH
        ; Clear play/rec buffers
        mov     ecx,PlayBuff.NumBytes
        xor     eax,eax
        mov     edi,PlayBuff.Pointer
        rep     stosw   ; double buffering
        mov     ecx,RecBuff.NumBytes
        mov     edi,RecBuff.Pointer
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
        mov     cx,OldIRQ.IRQSegment
        int     31h
        ; Freeing buffers
        mov     ebx,PlayBuff.Pointer
        call    FreeDMABuffer
        jc      terminate_error
        mov     ebx,RecBuff.Pointer
        call    FreeDMABuffer
        jc      terminate_error
        clc
        terminate_error:
        ret
Terminate       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Starts playing sound from the playback buffer
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if hardware doesn't answer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
StartPlay       proc
        mov     PlayStatus,PLAY_ON
        mov     FirstPlayBuff,1
        ; Turn DAC on
        mov     al,DSP_DAC_ON
        call    WriteDSP
        jc      splay_error
        ; Program DMA chip  
		mov		al,DMA_AUTOINIT
        mov     ah,SBdma
        mov     ebx,PlayBuff.Pointer
        mov     ecx,PlayBuff.NumBytes
		shl		ecx,1	; DMA transfers the two buffers and restarts
        call    DMAWriteToDevice
        ; Send time constant
        mov     al,DSP_WRITE_TIME_CT
        call    WriteDSP
        jc      splay_error
		call	GetPlayProps
		mov		bl,[eax.SPNumChannels]
		mov		eax,[eax.SPSamplingRate]
        call    SBGetTimeConstant
        call    WriteDSP
        jc      splay_error
		; Set DSP block transfer size
		mov		al,DSP_BLOCK_TRANSFER_SIZE
		call	WriteDSP
		jc		splay_error
		mov		eax,PlayBuff.NumBytes
		dec		eax
		push	eax
		call	WriteDSP
		pop		eax
		jc		splay_error
		mov		al,ah
		call	WriteDSP
		jc		splay_error
        ; Set playback type (8 bits mono)
        mov     al,DSP_8_BIT_PLAYBACK
        call    WriteDSP
		jc		splay_error
        clc
		ret
        splay_error:
		call	StopPlay
		stc
        ret
StartPlay       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; IRQ handler to refresh DMA transfer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
PlayIRQ         proc
		IRQEnter
		
		; Only higher priority interrupts will nest, like timer or keyboard.
        sti
		
        cmp     PlayStatus,PLAY_OFF
        jz      irq_error

        ; Mix all channels
        mov     eax,PlayBuff.Pointer
        test    FirstPlayBuff,1
        jnz     its_first_half
                add     eax,PlayBuff.NumBytes
        its_first_half:
        xor     FirstPlayBuff,1
        call    MixChannels

		irq_error:
        ; Acknowledge DSP before PIC so it does not re-trigger
        mov     edx,DSPDataAvail
        in      al,dx
		; Acknowledge PIC/s and return
		IRQAck	SBirq
		IRQLeave
PlayIRQ         endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Stops playing sound from the playback buffer
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if hardware doesn't answer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
StopPlay        proc
		pushfd
		cli
        cmp     PlayStatus,PLAY_OFF
        jz      stop_error
		; Exit DMA auto-initialize mode
        mov     al,DSP_EXIT_AUTOINIT
        call    WriteDSP
        jc      stop_error
        mov     al,DSP_DAC_OFF
        call    WriteDSP
        jc      stop_error
        mov     PlayStatus,PLAY_OFF
        stop_error:
		popfd
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
; OUTPUT : EAX -> Playback buffer (SoundBuffer structure)
;          EBX -> Record buffer (SoundBuffer structure)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetSndBuffers   proc
        mov     eax,offset PlayBuff
        mov     ebx,offset RecBuff
        ret
GetSndBuffers   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets playback properties
;
; OUTPUT : EAX -> Playback properties (SoundProperties structure)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetPlayProps    proc
        mov     eax,offset PlayProps
        ret
GetPlayProps    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets playback properties
;
; INPUT  : EAX -> Playback properties (SoundProperties structure), or NULL
;		   EBX = Playback capability index
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if hardware capabilities exceeded or device does not respond
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetPlayProps    proc
		; Copy properties
		mov		ecx,size SoundProperties
		mov		edi,offset PlayProps
		mov		esi,eax
		rep		movsb
		; Get actual frequency due to time constant resolution
		mov		bl,[eax.SPNumChannels]
		mov		eax,[eax.SPSamplingRate]
		call	SBGetTimeConstant
		mov		eax,offset PlayProps
		mov		[eax.SPSamplingRate],ebx
        cmp     PlayStatus,PLAY_OFF
        jz      dnts
				; Restart, if it is playing
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
; OUTPUT : EAX -> Recording properties (SoundProperties structure)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetRecProps     proc
		; Not yet supported
		xor		eax,eax
        ret
GetRecProps     endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets recording properties
;
; INPUT  : EAX -> Recording properties (SoundProperties structure), or NULL
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if hardware capabilities exceeded or device does not respond
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetRecProps     proc
		; Not yet supported
        stc
        ret
SetRecProps     endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets sound device hardware playback capabilities
;
; OUTPUT : EAX -> Playback capabilities (SoundHardwareCapabilities structure)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetPlay200Caps	proc
		mov		eax,offset PlayCaps
		clc
        ret
GetPlay200Caps  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets sound device hardware recording capabilities
;
; OUTPUT : EAX -> Recording capabilities (SoundHardwareCapabilities structure)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetRec200Caps	proc
		; Not yet supported
		xor		eax,eax
        ret
GetRec200Caps	endp

.data
SB200Device     SoundDevice <offset GetSB200DriverName, offset SBGetDevName, offset DetectSB200, offset SBDetectHard, offset Init, offset Terminate, offset SBReset, offset StartPlay, offset StopPlay, offset StartRec, offset StopRec, offset GetSndBuffers, offset GetPlayProps, offset SetPlayProps, offset GetRecProps, offset SetRecProps, offset GetPlay200Caps, offset GetRec200Caps>

PlayStatus      		db PLAY_OFF

; Device properties for playback
PlayProps       SoundProperties <>

; Device capabilities for playback
PlayCaps			SoundHardwareCapabilities <1, offset PlayValidConfigs>
; The first capability in the list is the preferred one
PlayValidConfigs	SoundCapability <4000, 23000, 8, 1>

SB200DriverName			db "SB200",0

.data?

IRQVector       STRUC
        IRQOffset       dd ?
        IRQSegment      dw ?
ENDS

OldIRQ          IRQVector <>

PlayBuff        SoundBuffer <>
RecBuff         SoundBuffer <>

FirstPlayBuff   dd ?

end
