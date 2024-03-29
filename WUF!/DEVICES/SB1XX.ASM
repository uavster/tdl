;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sound Blaster DSP 1.xx routines for audio input/output
;       Ignacio Mellado Bataller ( B52 / the DarkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.386p
.model flat
.code
        PLAY_ON                 EQU 1
        PLAY_OFF                EQU 0
        DSP_8_BIT_PLAYBACK      EQU 14h	; Single-cycle transfer

        INCLUDE sounddev.inc
        INCLUDE sb1xx.inc
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
GetSB1xxDriverName	proc
		mov		eax,offset SB1xxDriverName
		ret
GetSB1xxDriverName	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Detect Sound Blaster DSP 1.xx with BLASTER environment variable
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DetectSB1xx	proc
		call	DetectBLASTER
		jc		sb1xx_det_end
				cmp		DSPVersion.Major,1	; >=1 -> CF = 0; <1 -> CF = 1
		sb1xx_det_end:
		ret
DetectSB1xx	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initializes SB 1.xx driver
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Init    proc
		AssertD	DMA_PLAY_BUFFER_LENGTH,_ltu,65536
		AssertD	DMA_REC_BUFFER_LENGTH,_ltu,65536
		; Set preferred play properties
		call	GetPlay1xxCaps
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
		; Set up the IRQ handler
		mov		eax,SBirq
		mov		ebx,offset PlayIRQ
		mov		ecx,offset end_of_play_irq-offset PlayIRQ
		call	IRQHook
		jc		init_error
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
		mov		eax,SBirq
		call 	IRQRestore
		jc		terminate_error
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

EnableDSP       MACRO	ret_label
        ; Set playback type (8 bits mono)
        mov     al,DSP_8_BIT_PLAYBACK
        call    WriteDSP
        ; Set transfer size
		jc		ret_label
        mov     eax,PlayBuff.NumBytes
        dec     eax
        push    eax
        call    WriteDSP
		jc		ret_label
        pop     eax
        mov     al,ah
        call    WriteDSP
		jc		ret_label
ENDM

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Starts playing sound from the playback buffer
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if hardware doesn't answer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
StartPlay       proc
        mov     PlayStatus,PLAY_ON
        mov     FirstPlayBuff,1
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
        ; Program DMA chip        
		mov		al,DMA_SINGLECYCLE
        mov     ah,SBdma
        mov     ebx,PlayBuff.Pointer
        mov     ecx,PlayBuff.NumBytes
        call    DMAWriteToDevice
        ; Turn DAC on
        mov     al,DSP_DAC_ON
        call    WriteDSP
        jc      splay_error
		EnableDSP splay_error
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

		; Program DMA controller for the next buffer
		mov		al,DMA_SINGLECYCLE
        mov     ah,SBdma
        mov     ebx,PlayBuff.Pointer
        test    FirstPlayBuff,1
        jz     	play_first_buffer
                add     ebx,PlayBuff.NumBytes
        play_first_buffer:
        mov     ecx,PlayBuff.NumBytes
        call    DMAWriteToDevice
		; Program DSP for the next block
        EnableDSP irq_error

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
end_of_play_irq:
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
        mov     al,DSP_DMA_STOP
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
GetPlay1xxCaps	proc
		mov		eax,offset PlayCaps
		clc
        ret
GetPlay1xxCaps  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets sound device hardware recording capabilities
;
; OUTPUT : EAX -> Recording capabilities (SoundHardwareCapabilities structure)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetRec1xxCaps	proc
		; Not yet supported
		xor		eax,eax
        ret
GetRec1xxCaps	endp

.data
SB1xxDevice     SoundDevice <offset GetSB1xxDriverName, offset SBGetDevName, offset DetectSB1xx, offset SBDetectHard, offset Init, offset Terminate, offset SBReset, offset StartPlay, offset StopPlay, offset StartRec, offset StopRec, offset GetSndBuffers, offset GetPlayProps, offset SetPlayProps, offset GetRecProps, offset SetRecProps, offset GetPlay1xxCaps, offset GetRec1xxCaps>

PlayStatus      		db PLAY_OFF

; Device properties for playback
PlayProps       SoundProperties <>

; Device capabilities for playback
PlayCaps			SoundHardwareCapabilities <1, offset PlayValidConfigs>
; The first capability in the list is the preferred one
PlayValidConfigs	SoundCapability <4000, 23000, 8, 1>

SB1xxDriverName			db "SB1XX",0

.data?

PlayBuff        SoundBuffer <>
RecBuff         SoundBuffer <>

FirstPlayBuff   dd ?

end
