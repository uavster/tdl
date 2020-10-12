;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sound Blaster DSP 3.xx routines for audio input/output
;       Ignacio Mellado Bataller ( B52 / the DarkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.386p
.model flat
.code
        PLAY_ON                 EQU 1
        PLAY_OFF                EQU 0
        DSP_8_BIT_PLAYBACK      EQU 1Ch	; Auto-initialize transfer
		DSP_8_BIT_PLAYBACK_HS	EQU 90h ; High-speed auto-initialize transfer
		DSP_EXIT_AUTOINIT		EQU 0DAh
		
        INCLUDE sounddev.inc
        INCLUDE sb3xx.inc
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
GetSB3xxDriverName	proc
		mov		eax,offset SB3xxDriverName
		ret
GetSB3xxDriverName	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Detect Sound Blaster DSP 3.xx with BLASTER environment variable
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DetectSB3xx	proc
		call	DetectBLASTER
		jc		sb3xx_det_end
				cmp		DSPVersion.Major,3	; >=3 -> CF = 0; <3 -> CF = 1
		sb3xx_det_end:	
		ret
DetectSB3xx	endp
		
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initializes SB 3.xx driver
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Init    proc
		AssertD	DMA_PLAY_BUFFER_LENGTH,_ltu,65536
		AssertD	DMA_REC_BUFFER_LENGTH,_ltu,65536
		; Clear playback buffers
		mov		PlayBuff.Pointer,0
		; Set preferred play properties
		call	GetPlay3xxCaps
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
		; Allocate DMA recording buffer
        mov     ecx,DMA_REC_BUFFER_LENGTH
        call    AllocDMABuffer
        jc      init_error
        mov     RecBuff.Pointer,ebx
		mov		RecBuff.NumBytes,DMA_REC_BUFFER_LENGTH
        mov     ecx,RecBuff.NumBytes
        mov     edi,RecBuff.Pointer
        rep     stosb
        clc
        init_error:
        ret
Init    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Terminates SB 3.xx driver
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
		call	FreePlaybackDMABuffers
		jc		terminate_error
        mov     ebx,RecBuff.Pointer
        call    FreeDMABuffer
        jc      terminate_error
        clc
        terminate_error:
        ret
Terminate       endp

SetStereoOutput	proc
		movzx	eax,PlayStatus
		push	eax
		mov		PlayStatus,PLAY_OFF
		mov		irq_received,0
		; Set stereo mode
		mov		al,MIXER_CONFIG_STEREO
		call	SBMixerOutputConfigEnableBits
		; Program DMA controller for 1-byte single-cycle output
		mov		al,DMA_SINGLECYCLE
        mov     ah,SBdma
        mov     ebx,PlayBuff.Pointer
        mov     ecx,1
        call    DMAWriteToDevice
		; Program the DSP to output one silent byte
		mov		al,DSP_1_SILENT_BYTE_OUT
		call	WriteDSP
		jc		sso_end
		xor		al,al
		call	WriteDSP
		jc		sso_end
		xor		al,al
		call	WriteDSP
		jc		sso_end
		; Wait for the DSP interrupt
		wait_irq:
		cmp		irq_received,0
		jz		wait_irq
		sso_end:
		pop		eax
		mov		PlayStatus,al
		ret
SetStereoOutput	endp

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
		cmp		PlayProps.SPNumChannels,1
		je		skip_set_stereo_output
				; Set hardware to stereo mode
				call	SetStereoOutput
				jc		splay_error
		skip_set_stereo_output:
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
		cmp		PlayProps.SPNumChannels,1
		je		skip_turn_off_filter
				; Save filter status and turn it off
				mov		al,MIXER_CONFIG_FILTER_OFF
				call	SBMixerOutputConfigEnableBits
				mov		previous_filter_output_config,al
		skip_turn_off_filter:
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
		mov		ebx,PlayCapabilityIndex
		cmp		byte ptr [ebx+offset IsHighSpeedMode],0
		je		normal_mode
				; High speed mode
				mov		al,DSP_8_BIT_PLAYBACK_HS
		normal_mode:
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
		inc		irq_received
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
        jz      stopped
		; Exit DMA high-speed auto-initialize mode
		mov		ebx,PlayCapabilityIndex
		cmp		byte ptr [ebx+offset IsHighSpeedMode],0
		jne		stop_high_speed_mode
				; Normal mode
				mov     al,DSP_EXIT_AUTOINIT
				call    WriteDSP
				jc      stop_error
				jmp		continue_stopping
		stop_high_speed_mode:
				; High speed mode
				call    SBReset
				jc      init_error
		continue_stopping:
		cmp		PlayProps.SPNumChannels,1
		je		skip_restore_filter_and_mono
				; Restore filter status
				mov		al,previous_filter_output_config
				mov		ah,al
				mov		bl,MIXER_OUTPUT_CONFIG
				call 	SBMixerReadWriteBits
				; Set hardware to mono mode
				mov		al,NOT MIXER_CONFIG_STEREO
				call	SBMixerOutputConfigDisableBits
		skip_restore_filter_and_mono:
		; Turn off DAC
        mov     al,DSP_DAC_OFF
        call    WriteDSP
        jc      stop_error
        mov     PlayStatus,PLAY_OFF
		stopped:
		clc
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

AllocPlaybackDMABuffers	proc
		call	FreePlaybackDMABuffers
		jc		alloc_playback_end
        mov     eax,DMA_PLAY_BUFFER_LENGTH
		mov		PlayBuff.NumBytes,eax
		mov		ecx,eax
		shl 	ecx,1	; Double buffering
        call    AllocDMABuffer
        jc      alloc_playback_end
        mov     PlayBuff.Pointer,ebx
        ; Clear play/rec buffers
        mov     ecx,PlayBuff.NumBytes
        xor     eax,eax
        mov     edi,PlayBuff.Pointer
        rep     stosw   ; double buffering
		alloc_playback_end:
		ret
AllocPlaybackDMABuffers	endp

FreePlaybackDMABuffers	proc	
        mov     ebx,PlayBuff.Pointer
		or		ebx,ebx
		jz		free_playback_end
        call    FreeDMABuffer
        jc      free_playback_end
		mov		PlayBuff.Pointer,0
		free_playback_end:
		ret
FreePlaybackDMABuffers	endp

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
		mov		PlayCapabilityIndex,ebx
		; Stop, if it is playing
        cmp     PlayStatus,PLAY_OFF
        jz      not_playing
				push	eax
				call    StopPlay
				pop		eax
				jc      spp_error
        not_playing:
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
		; Allocate DMA buffers (frees any previous buffer)
		call	AllocPlaybackDMABuffers
		; Restart, if it was playing
        cmp     PlayStatus,PLAY_OFF
        jz      not_playing2
				; Restart, if it is playing
				call    StartPlay
				jc      spp_error
        not_playing2:
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
GetPlay3xxCaps	proc
		mov		eax,offset PlayCaps
		clc
        ret
GetPlay3xxCaps  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets sound device hardware recording capabilities
;
; OUTPUT : EAX -> Recording capabilities (SoundHardwareCapabilities structure)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetRec3xxCaps	proc
		; Not yet supported
		xor		eax,eax
        ret
GetRec3xxCaps	endp

.data
SB3xxDevice     SoundDevice <offset GetSB3xxDriverName, offset SBGetDevName, offset DetectSB3xx, offset SBDetectHard, offset Init, offset Terminate, offset SBReset, offset StartPlay, offset StopPlay, offset StartRec, offset StopRec, offset GetSndBuffers, offset GetPlayProps, offset SetPlayProps, offset GetRecProps, offset SetRecProps, offset GetPlay3xxCaps, offset GetRec3xxCaps>

PlayStatus      	db PLAY_OFF

; Device capabilities for playback
PlayCaps			SoundHardwareCapabilities <1, offset PlayValidConfigs>
; The first capability in the list is the preferred one
PlayValidConfigs	SoundCapability <11025, 22050, 8, 2>, <23000, 44100, 8, 1>, <4000, 23000, 8, 1>
IsHighSpeedMode		db 1, 1, 0

SB3xxDriverName		db "SB3XX",0

.data?

; Device properties for playback
PlayProps       	SoundProperties <>
PlayCapabilityIndex	dd ?

IRQVector       STRUC
        IRQOffset       dd ?
        IRQSegment      dw ?
ENDS

OldIRQ          IRQVector <>

PlayBuff        SoundBuffer <>
RecBuff         SoundBuffer <>

FirstPlayBuff   dd ?

irq_received	db ?
previous_filter_output_config	db ?

end
