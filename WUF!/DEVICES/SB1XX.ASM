;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sound Blaster DSP 1.xx routines for audio input/output
;       Ignacio Mellado Bataller ( B52 / the DarkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.386p
.model flat
.code
        PLAY_ON                 EQU 1
        PLAY_OFF                EQU 0
        DSP_8_BIT_PLAYBACK      EQU 14h

		MIN_PLAY_SAMPLE_RATE	EQU 4000
        MAX_PLAY_SAMPLE_RATE    EQU 23000
		MIN_PLAY_NUM_CHANNELS	EQU 1
		MAX_PLAY_NUM_CHANNELS	EQU 1
		VALID_BITS_PER_SAMPLE	EQU 8	; Comma-separated list in descending order

        INCLUDE sounddev.inc
        INCLUDE sb1xx.inc
        INCLUDE utils.inc
        INCLUDE dma.inc
        INCLUDE stderror.inc
        INCLUDE snddev.def
        INCLUDE sbhard.inc
        INCLUDE mixer.inc

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initializes SB 1.xx driver
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Init    proc
		; Set maximum play properties
		sub		esp,size SoundProperties
		mov		eax,esp
		mov		[SoundProperties ptr eax.SamplingRate],MAX_PLAY_SAMPLE_RATE
		mov		bl,ValidPlaySampleBits	; First byte is the highest valid value
		mov		[SoundProperties ptr eax.BitsPerSample],bl
		mov		bl,MAX_PLAY_NUM_CHANNELS
		mov		[SoundProperties ptr eax.NumChannels],bl
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
        mov     FirstPlayBuff,1
        ; Send time constant
        mov     al,DSP_WRITE_TIME_CT
        call    WriteDSP
        jc      splay_error
		call	GetPlayProps
		mov		bl,[eax.NumChannels]
		mov		eax,[eax.SamplingRate]
        call    SBGetTimeConstant
        call    WriteDSP
        jc      splay_error
        ; Program DMA chip        
		mov		al,DMA_SINGLECYCLE
        mov     ah,SBdma
        mov     ebx,PlayBuff.Pointer
        mov     ecx,PlayBuff.NumBytes
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
        mov     eax,PlayBuff.NumBytes
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
        mov     eax,PlayBuff.NumBytes
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
        EnableDSP
        ; IRQ acknowledge
        mov     al,20h
        mov     edx,irq_ack_port
        out     dx,al
        sti
        ; Mix all channels
        mov     eax,PlayBuff.Pointer
        test    FirstPlayBuff,1
        jnz     its_first_half
                add     eax,PlayBuff.NumBytes
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
;
; OUTPUT : CF = 0 if ok
;          CF = 1 if hardware capabilities exceeded or it doesn't answer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetPlayProps    proc
		; If NULL, leave
		or		eax,eax
		jz		dnts
		; Check that requested properties are within bounds
		cmp		[eax.SamplingRate],MIN_PLAY_SAMPLE_RATE
		jb		spp_error
        cmp     [eax.SamplingRate],MAX_PLAY_SAMPLE_RATE
        ja      spp_error
		cmp		[eax.NumChannels],MIN_PLAY_NUM_CHANNELS
		jb		spp_error
		cmp		[eax.NumChannels],MAX_PLAY_NUM_CHANNELS
		ja		spp_error
		mov		bl,[eax.BitsPerSample]
		mov		ecx,offset ValidPlaySampleBitsEnd - offset ValidPlaySampleBits
		mov		edx,offset ValidPlaySampleBits
		check_bits_per_sample:
				cmp	bl,[edx]
				je 	bits_per_sample_valid
				inc	edx
		loop	check_bits_per_sample
		jmp		spp_error
		bits_per_sample_valid:
		; Copy properties
		mov		ecx,size SoundProperties
		mov		edi,offset PlayProps
		mov		esi,eax
		rep		movsb
		; Get actual frequency due to time constant resolution
		mov		bl,[eax.NumChannels]
		mov		eax,[eax.SamplingRate]
		call	SBGetTimeConstant
		mov		eax,offset PlayProps
		mov		[eax.SamplingRate],ebx
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
		; If NULL, leave
		or		eax,eax
		jz		dnts
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
		mov		[eax.MinSamplingRate],MIN_PLAY_SAMPLE_RATE
		mov		[eax.MaxSamplingRate],MAX_PLAY_SAMPLE_RATE
		mov		[eax.ValidBitsPerSampleArrayLen],offset ValidPlaySampleBitsEnd - offset ValidPlaySampleBits
		mov		[eax.ValidBitsPerSampleArray],offset ValidPlaySampleBitsEnd
		mov		[eax.MinNumChannels],MIN_PLAY_NUM_CHANNELS
		mov		[eax.MaxNumChannels],MAX_PLAY_NUM_CHANNELS
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
SB1xxDevice     SoundDevice <offset SBGetDevName, offset DetectBLASTER, offset SBDetectHard, offset Init, offset Terminate, offset SBReset, offset StartPlay, offset StopPlay, offset StartRec, offset StopRec, offset GetSndBuffers, offset GetPlayProps, offset SetPlayProps, offset GetRecProps, offset SetRecProps, offset GetPlay1xxCaps, offset GetRec1xxCaps>

PlayStatus      		db PLAY_OFF
ValidPlaySampleBits		db VALID_BITS_PER_SAMPLE
ValidPlaySampleBitsEnd 	db ?

; Device properties for playback
PlayProps       SoundProperties <>

; Device capabilities for playback
PlayCaps		SoundHardwareCapabilities <>

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
