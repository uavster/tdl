;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Digital mixer
;
; All existing channels are added in 32 bits. A constant compression factor
; is applied before converting to the device's bit depth to prevent clipping,
; assuming that channel signals will be rarely correlated.
;
; Author: Ignacio Mellado Bataller (a.k.a. B52 / the DarkRising)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code

        INCLUDE alloc.inc
        INCLUDE wuf!.inc
        INCLUDE mixer.inc
        INCLUDE stderror.inc
		INCLUDE utils.inc
		INCLUDE assert.inc

; Expansion bits for accuracy in stereo samples converted to mono
EXPANSION_BITS		EQU 1

; Compression factor is ~1/3. It is a good trade-off to prevent clipping while not making volume too low.
; We compute as 5/16 to avoid muls and divs.

DEBUG_MIXER_PERFORMANCE			EQU 1
DEBUG_MIXER_TIME_RESOLUTION		EQU 10000.0

ifdef DEBUG_MIXER_PERFORMANCE
		INCLUDE timer.inc
		INCLUDE utils.inc
endif

ClearMixingBuffer	proc
		mov		edi,MixingBuffer
		mov		ecx,NumOutputBytes
		shr		ecx,2
		xor		eax,eax
		cld
		rep		stosd
		and		ecx,011b
		jz		no_bytes_left
		rep		stosb
		no_bytes_left:
		ret
ClearMixingBuffer	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initializes mixer
;
; INPUT  : EAX = Mixing frequency
;		   BL = Bits per sample
;		   BH = Number of output channels
;		   CL = Maximum number of input channels
;		   EDX = Output buffer size (samples)
;
; OUTPUT : CF = 0 if ok
;               EAX = NO_ERROR
;          CF = 1 if error
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
OpenMixer       proc
		push	ebx
		movzx	ebx,bh
		AssertD ebx,_gtu,0
		AssertD ebx,_leu,2	; Output must be mono or stereo
		pop		ebx
		; Store configuration
		mov		MixFreq,eax
		mov		MixBitsPerSample,bl
		mov		NumOutputChannels,bh
        mov     MaxInputChannels,cl
		mov		NumOutputSamples,edx
		; Allocate array of input channel descriptors
		movzx	ecx,cl
        imul    ecx,size TChannel
        call    malloc
        ErrorCode MALLOC_ERROR
        mov     edi,ebx
        xor     eax,eax
        cld
        rep     stosb
        mov     ChannelPool,ebx
		; Allocate mixing buffer with 32 bits per sample
		mov		eax,NumOutputSamples
		movzx	ebx,NumOutputChannels
        imul	eax,ebx
		shl		eax,2	; 4 bytes per sample
		mov		NumOutputBytes,eax
		mov		ecx,eax
        call    malloc
        ErrorCode MALLOC_ERROR
        mov     MixingBuffer,ebx
		
		; Create channel volume table.
		; Each int32_t table entry at (volume,sample) contains (volume*sample), 
		; where sample is within [0,255], and volume is within [0,64].
		; How to scale samples by their volume:
		; 8-bit: scaled_sample = sing(sample) * volume_table[volume][abs(sample)] >> 6
		; 16-bit: scaled_sample = sign(sample) * ((volume_table[volume][abs(sample) >> 8] << 8) + volume_table[volume][abs(sample) & 0xff]) >> 6
		mov		ecx,65*256*4
		call	malloc
		ErrorExit "Unable to allocate volume table."
		mov		VolumeTable,ebx
		push	ds
		pop		es
		mov		edi,ebx
		cld
		
		xor		ecx,ecx
		loop_volumes:
				xor		ebx,ebx
				loop_sample_values:
						mov		eax,ecx
						movzx	edx,bl
						imul	edx
						stosd
				inc		bl
				jnz		loop_sample_values
		inc		ecx
		cmp		ecx,65
		jnz		loop_volumes
		
ifdef DEBUG_MIXER_PERFORMANCE
		; Set up performance debugging
		xor		eax,eax
		mov		DebugPerfCounter,eax
		mov		MixerRunTicks,eax
		mov		NumMixerRuns,eax
		movf	eax,DEBUG_MIXER_TIME_RESOLUTION
		mov		ebx,offset MixerDebugPerf
		call add_timer
endif
        mov     eax,NO_ERROR
        clc
        ret
OpenMixer       endp

ifdef DEBUG_MIXER_PERFORMANCE
MixerDebugPerf	proc
		inc		DebugPerfCounter
		ret
		endp
		
PrintMixerPerf	proc
		pushfd
		cli
		cmp		NumMixerRuns,0
		jnz		mixer_did_run
				; The mixer was never run
				mov 	esi,offset NoPerfDataMsg
				call	printf
				jmp		leave_print_mixer_perf
		mixer_did_run:
		; Average mixer run time per DMA buffer
		fild	MixerRunTicks
		fild	NumMixerRuns
		fdivp
		fldf	DEBUG_MIXER_TIME_RESOLUTION
		fdivp
		fst		AvgMixerExecTime
		; Maximum mixer run time per DMA buffer to keep sampling rate
		fild	NumOutputSamples
		fild	MixFreq
		fdivp
		fdivp
		fldf	100.0
		fmulp
		fstp	AvgMixerPercentCPU
		mov		esi,offset PerfDataMsg
		call	printf
		leave_print_mixer_perf:
		popfd
		ret
		endp
endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Frees memory used by the mixer
;
; OUTPUT : CF = 0 if ok
;               EAX = NO_ERROR
;          CF = 1 if error
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CloseMixer      proc
ifdef DEBUG_MIXER_PERFORMANCE
		mov		ebx,offset MixerDebugPerf
		call	remove_timer
		call	PrintMixerPerf
endif
		mov		ebx,VolumeTable
		call	free
		ErrorCode FREE_ERROR
        mov     ebx,MixingBuffer
        call    free
        ErrorCode FREE_ERROR
        mov     ebx,ChannelPool
        call    free
        ErrorCode FREE_ERROR
        mov     eax,NO_ERROR
        clc
        ret
CloseMixer      endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets a callback that will be called periodically from the playback IRQ
;
; INPUT  : EAX = Callback period in seconds (float)
; 		   EBX -> Callback function, or NULL to disable
;				  Callback input is EBX -> Channel pool (TChannel elements),
;				  and ECX = Num. channels
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetMixerCallback	proc
		pushfd
		cli
		mov		MixerCallback,ebx
		mov		smc_tmp,eax
		fld		smc_tmp
		fimul	MixFreq
		mov		smc_tmp,256
		fimul	smc_tmp
		fist	SamplesPerTick
		fistp	MissingTickSamples
		popfd
		ret
smc_tmp	dd ?
SetMixerCallback	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Looks for a free channel at or above a given number
;
; INPUT  : BL = Channel number at or above which to search for a free channel
;
; OUTPUT : CF = 0 if channel found
;				EAX = NO_ERROR
;               BL = Free channel number
;				ECX -> Pointer to free channel's TChannel structure
;          CF = 1 if no free channels
;               EAX = NO_FREE_CHANNELS
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SearchFreeChannel       proc
        movzx   ecx,MaxInputChannels
		movzx	ebx,bl
		sub		ecx,ebx
		mov		eax,size TChannel
		xor		edx,edx
		mul		ebx
        add     eax,ChannelPool
        parse_channels:
                cmp     [eax.ChanWave],0
                jz      found_free_chan
                add     eax,size TChannel
				inc		bl
        loop    parse_channels
        mov     eax,NO_FREE_CHANNELS
        stc
        ret

        found_free_chan:
		mov		ecx,eax
		xor		eax,eax
        clc
        ret
SearchFreeChannel       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Fills a channel with the given wave
;
; This function may be called from an IRQ, but it is not reentrant.
; TODO: make it reentrant with atomic allocation of channels, so that a module
; can be played, while triggering sounds with the keyboard, for instance.
;
; INPUT  : EAX = Pointer to TWave structure of sample to play in channel
;		   If BH == SPECIFIC_CHANNEL, BL contains the number of the channel on 
;		   which to play.
;		   If BH == ANY_FREE_CHANNEL, the sound is played on any free channel greater 
;		   or equal than BL.
;		   ECX = Frequency multiplier (fixed point 8.24)
;		   EDX = Volume multiplier (0-64)
;		   ESI = Sample offset
;
; OUTPUT : CF = 0 if no error
;               EAX = NO_ERROR
;				BL = Channel playing the sound
;          CF = 1 if error
;               EAX = Error code
;					NO_FREE_CHANNELS: No available channels
;					FREQUENCY_TOO_HIGH: Base frequency * multiplier > 16,776,960 Hz
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
PlaySound       proc
		mov		esi,eax
		cmp		bh,ANY_FREE_CHANNEL
		jne		channel_specified
				push	ecx edx
				call    SearchFreeChannel
				pop		edx edi
				ErrorCode eax
				mov		eax,ecx
				mov		ecx,edi
				jmp		got_channel
		channel_specified:
				push	edx
				xor		edx,edx
				mov		eax,size TChannel
				movzx	ebx,bl
				mul		ebx				
				add		eax,ChannelPool
				pop		edx
		got_channel:
		push	eax edx
		; EDX:EAX = base_frequency * (multiplier << 24)
		mov		eax,[TWave ptr esi.BaseRate]
		mul		ecx
		; EAX = (base_frequency * (multiplier << 24)) >> 16
		cmp		edx,0ffffh
		jbe		resulting_freq_ok
				pop		edx eax
				mov		eax,FREQUENCY_TOO_HIGH
				stc
				ret
		resulting_freq_ok:
		shr		eax,16
		mov		ecx,edx
		shl		ecx,16
		or		eax,ecx
		shr		edx,16
		; EAX = ((base_frequency * (multiplier << 24)) >> 16) / mixing_frequency
		div		MixFreq
		; EDX = (((Base frequency * (multiplier << 24)) >> 16) / mixing_frequency)
		mov		ebx,eax
		pop		edx eax
		mov		[TChannel ptr eax.SampleIncrement],ebx
        mov     [TChannel ptr eax.CurrentSample],0
		mov		[TChannel ptr eax.Volume],edx
		; Atomic allocation of the channel
        mov     [TChannel ptr eax.ChanWave],esi
		xor		eax,eax
		clc		
        ret
PlaySound       endp


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the properties of a channel
;
; INPUT  : BL = Channel number
; 		   EAX = Pointer to TWave structure of sample to play in channel, or null
;		   to leave it as is.
;		   ECX = Frequency multiplier (fixed point 16.16)
;		   DL = Volume (0..64)
;		   DH = Panning (?..?)
;
; OUTPUT : CF = 0 if channel found
;               EAX = NO_ERROR
;				BL = Channel playing the sound
;          CF = 1 if no free channels
;               EAX = NO_FREE_CHANNELS
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetChannelProperties	proc
		ret
SetChannelProperties	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; All macros below share the same interface.
;
; INPUT  : EAX = Signed 16-bit sample
;		   ESI -> LUT for the sample volume
; OUTPUT : EAX = Signed 16-bit sample scaled by volume
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

ScaleSampleByVolume8	macro
	local	is_negative_u8
	local	volume_done_u8
	cmp		eax,7fffffffh	; 1
	ja		is_negative_u8	; 1 (not jump) or 3 (jump)
			mov		eax,[esi+eax*4]	; 1
;			shr		eax,6	; 2
			jmp 	volume_done_u8	; 3
	is_negative_u8:
			neg		eax		; 1
			mov		eax,[esi+eax*4]	; 1
;			shr		eax,6	; 2
			neg		eax		; 1
	volume_done_u8:
endm

ScaleSampleByVolume16	macro
	local	is_negative_s16
	local	volume_done_s16
	cmp		eax,7fffffffh	; 1
	ja		is_negative_s16	; 1 (not jump) or 3 (jump)
			mov		ecx,eax	; 1

			shr		eax,8	; 2
			mov		eax,[esi+eax*4]	; 1
			shl		eax,8	; 2
			xor		ch,ch	; 1
			add		eax,[esi+ecx*4]	; 2	(may be better as mov+add in 386)

;			shr		eax,6	; 2

			jmp 	volume_done_s16	; 3
	is_negative_s16:
			neg		eax		; 1
			mov		ecx,eax	; 1

			shr		eax,8	; 2
			mov		eax,[esi+eax*4]	; 1
			shl		eax,8	; 2

			xor		ch,ch	; 1
			add		eax,[esi+ecx*4]	; 2

;			shr		eax,6	; 2
			neg		eax		; 1
	volume_done_s16:
endm

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; All mixing macros below share the same interface.
;
; INPUT  : ESI -> LUT for sample volume
;		   EBX -> Wave data
;		   EDX = Current sample index
;		   EBP = -NumOutputSamples
;		   EDI -> offset MixingBuffer + MixBytesPerSample(4) * NumOutputChannels(2) * (NumOutputSamples + MixOffsetSamples)
;		   wave_len = Length of the wave in samples
;		   sample_increment = Number of samples to increment the sample index at every loop (fixed point 24.8)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

MixStereoS16InMonoBuffer macro
local sample_loop
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		mov     eax,[ebx+ecx*4]
		movsx   ecx,ax
		shr		eax,16
		movsx	eax,ax
		add     eax,ecx
		rol		eax,6	; *64 (volume)
		add		[edi+ebp*4],eax
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
endm

MixStereoS16WithVolumeInMonoBuffer macro
local sample_loop
sample_loop:
		; Left channel
		mov		ecx,edx
		shr		ecx,8
		mov     eax,[ebx+ecx*4]
		movsx   eax,ax
		ScaleSampleByVolume16		
		add		[edi+ebp*4],eax
		; Right channel
		mov		ecx,edx
		shr		ecx,8
		mov     eax,[ebx+ecx*4]
		shr		eax,16
		movsx	eax,ax
		ScaleSampleByVolume16
		add		[edi+ebp*4],eax
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
endm

MixMonoS16InMonoBuffer macro
local sample_loop
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		movsx   eax,word ptr [ebx+ecx*2]
		rol		eax,EXPANSION_BITS+6	; Expand to match 16+1 bits in stereo16, *64 (volume)
		add		[edi+ebp*4],eax
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
endm

MixMonoS16WithVolumeInMonoBuffer macro
local sample_loop
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		movsx   eax,word ptr [ebx+ecx*2]
		ScaleSampleByVolume16
		rol		eax,EXPANSION_BITS	; Expand to match 16+1 bits in stereo16
		add		[edi+ebp*4],eax
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
endm

MixStereoU8InMonoBuffer macro
local sample_loop
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		mov		ax,[ebx+ecx*2]
		sub		al,128
		sub		ah,128
		movsx	ecx,ah
		movsx	eax,al
		add		eax,ecx
		rol		eax,8+6	; Expand to match 16+1 bits in stereo16, *64 (volume)
		add		[edi+ebp*4],eax
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
endm

MixStereoU8WithVolumeInMonoBuffer macro
local sample_loop
sample_loop:
		mov		eax,edx
		shr		eax,8
		mov		cx,[ebx+eax*2]
		sub		cl,128		
		movsx	eax,cl
		ScaleSampleByVolume8
		
		sub		ch,128
		movsx	ecx,ch
		xchg	eax,ecx
		ScaleSampleByVolume8
		
		add		eax,ecx
		rol		eax,8	; Expand to match 16+1 bits in stereo16
		add		[edi+ebp*4],eax
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
endm

MixMonoU8InMonoBuffer macro
local sample_loop
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		mov   	al,byte ptr [ebx+ecx]
		sub		al,128
		movsx	eax,al
		rol		eax,8+EXPANSION_BITS+6	; Expand to match 16+1 bits in stereo16, *64 (volume)
		add		[edi+ebp*4],eax
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
endm

MixMonoU8WithVolumeInMonoBuffer macro
local sample_loop
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		mov   	al,byte ptr [ebx+ecx]
		sub		al,128
		movsx	eax,al
		ScaleSampleByVolume8
		rol		eax,8+EXPANSION_BITS	; Expand to match 16+1 bits in stereo16
		add		[edi+ebp*4],eax
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
endm

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Mixes an active channel on a mono output buffer
;
; INPUT  : EAX -> TChannel structure
;		   EBX -> Wave data
;		   EDX = Current sample index (fixed point 24.8)
;		   ESI -> ChanWave structure
;		   EDI -> offset MixingBuffer + MixBytesPerSample(4) * NumOutputChannels(1) * (NumOutputSamples + MixOffsetSamples)
;		   EBP = -NumOutputSamples
; OUTPUT : EDX = Current sample index (fixed point 24.8)
;		   CF = 0 if channel is still active
;		   CF = 1 if channel went inactive
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MixChannelToMono	proc
		; Number of loops = min(NumOutputSamples, esi.WaveLen - eax.CurrentSample)
		mov		ecx,[TChannel ptr eax.SampleIncrement]
		mov		sample_increment,ecx
		; Volume table offset
		mov		ecx,[TChannel ptr eax.Volume]
		shl		ecx,8+2
		add		ecx,VolumeTable
		mov		volume_table_ptr,ecx
		mov		ecx,[esi.WaveLen]
		mov		wave_len,ecx
		test    [esi.WaveType],1
		jz      its_8_bits
				; 16-bit signed samples
				test    [esi.WaveType],10b
				jz      mono16
						mov		esi,volume_table_ptr
						cmp		[TChannel ptr eax.Volume],64
						jb		mix_with_volume_s16_m
								MixStereoS16InMonoBuffer
								jmp		wave_mixed
						mix_with_volume_s16_m:
								MixStereoS16WithVolumeInMonoBuffer
								jmp		wave_mixed
								
				mono16:
						mov		esi,volume_table_ptr
						cmp		[TChannel ptr eax.Volume],64
						jb		mix_with_volume_m16_m
								MixMonoS16InMonoBuffer
								jmp		wave_mixed
						mix_with_volume_m16_m:
								MixMonoS16WithVolumeInMonoBuffer
								jmp		wave_mixed
								
		its_8_bits:
				; 8-bit unsigned samples
				test	[esi.WaveType],10b
				jz		mono8
						mov		esi,volume_table_ptr
						cmp		[TChannel ptr eax.Volume],64
						jb		mix_with_volume_s8_m
								MixStereoU8InMonoBuffer
								jmp		wave_mixed
						mix_with_volume_s8_m:
								MixStereoU8WithVolumeInMonoBuffer
								jmp		wave_mixed
								
				mono8:
						mov		esi,volume_table_ptr
						cmp		[TChannel ptr eax.Volume],64
						jb		mix_with_volume_m8_m
								MixMonoU8InMonoBuffer
								jmp		wave_mixed
						mix_with_volume_m8_m:
								MixMonoU8WithVolumeInMonoBuffer
								
		wave_mixed:
		stc
		ret
		no_samp_end:
		clc
		ret
MixChannelToMono	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; All mixing macros below share the same interface.
;
; INPUT  : ESI -> LUT for sample volume
;		   EBX -> Wave data
;		   EDX = Current sample index
;		   EBP = -NumOutputSamples
;		   EDI -> offset MixingBuffer + MixBytesPerSample(4) * NumOutputChannels(2) * (NumOutputSamples + MixOffsetSamples)
;		   wave_len = Length of the wave in samples
;		   sample_increment = Number of samples to increment the sample index at every loop (fixed point 24.8)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

MixStereoS16WithVolume macro
local sample_loop
sample_loop:		
		; Precondition: EDX = Current sample index (fixed point 24.8)
		; Load left channel sample in EAX
		mov		ecx,edx
		shr		ecx,8
		mov     eax,[ebx+ecx*4]
		movsx   eax,ax	; eax = left channel
		ScaleSampleByVolume16
		rol		eax,EXPANSION_BITS
		add		[edi+ebp*8],eax
		
		; Precondition: EDX = Current sample index (fixed point 24.8)
		; Load right channel sample in EAX
		mov		ecx,edx
		shr		ecx,8
		mov     eax,[ebx+ecx*4]
		shr		eax,16
		movsx	eax,ax	; eax = right channel
		ScaleSampleByVolume16
		rol		eax,EXPANSION_BITS
		add		[edi+ebp*8+4],eax
		
		inc		ebp
		jz		no_samp_end_s
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
endm

MixStereoS16 macro
local sample_loop
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		mov     eax,[ebx+ecx*4]
		movsx   ecx,ax	; ecx = left channel
		shr		eax,16
		movsx	eax,ax	; eax = right channel
		rol		ecx,EXPANSION_BITS+6	; *64 (volume)
		rol		eax,EXPANSION_BITS+6	; *64 (volume)
		add		[edi+ebp*8],ecx
		add		[edi+ebp*8+4],eax
		inc		ebp
		jz		no_samp_end_s
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
endm

MixMonoS16WithVolume macro
local sample_loop
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		movsx   eax,word ptr [ebx+ecx*2]
		ScaleSampleByVolume16
		rol		eax,EXPANSION_BITS
		add		[edi+ebp*8],eax
		add		[edi+ebp*8+4],eax
		inc		ebp
		jz		no_samp_end_s
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
endm

MixMonoS16 macro
local sample_loop
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		movsx   eax,word ptr [ebx+ecx*2]
		rol		eax,EXPANSION_BITS+6	; *64 (volume)
		add		[edi+ebp*8],eax
		add		[edi+ebp*8+4],eax
		inc		ebp
		jz		no_samp_end_s
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
endm

MixStereoU8WithVolume macro
local sample_loop
sample_loop:
		mov		eax,edx
		shr		eax,8
		mov		cx,[ebx+eax*2]
		sub		ch,128
		sub		cl,128
		movsx	eax,cl	; left channel
		ScaleSampleByVolume8
		rol		eax,8+EXPANSION_BITS
		add		[edi+ebp*8],eax
		movsx	eax,ch	; right channel
		ScaleSampleByVolume8
		rol		eax,8+EXPANSION_BITS
		add		[edi+ebp*8+4],eax
		inc		ebp
		jz		no_samp_end_s
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
endm

MixStereoU8 macro
local sample_loop
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		mov		ax,[ebx+ecx*2]
		sub		ah,128
		sub		al,128
		movsx	ecx,ah	; ecx = right channel
		movsx	eax,al	; eax = left channel
		rol		ecx,8+EXPANSION_BITS+6	; *64 (volume)
		rol		eax,8+EXPANSION_BITS+6	; *64 (volume)
		add		[edi+ebp*8],eax
		add		[edi+ebp*8+4],ecx
		inc		ebp
		jz		no_samp_end_s
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
endm

MixMonoU8WithVolume macro
local sample_loop
sample_loop:
		mov		ecx,edx
		shr		ecx,8						
		mov   	al,byte ptr [ebx+ecx]
		sub		al,128
		movsx	eax,al
		ScaleSampleByVolume8		
		rol		eax,8+EXPANSION_BITS	; Expand to match 16+1 bits in stereo16
		add		[edi+ebp*8],eax
		add		[edi+ebp*8+4],eax
		inc		ebp
		jz		no_samp_end_s
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
endm

MixMonoU8 macro
local sample_loop
sample_loop:
		mov		ecx,edx
		shr		ecx,8						
		mov   	al,byte ptr [ebx+ecx]
		sub		al,128
		movsx	eax,al
		rol		eax,8+EXPANSION_BITS+6	; Expand to match 16+1 bits in stereo16, *64 (volume)
		add		[edi+ebp*8],eax
		add		[edi+ebp*8+4],eax
		inc		ebp
		jz		no_samp_end_s
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
endm

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Mixes an active channel on a stereo output buffer
;
; INPUT  : EAX -> TChannel structure
;		   EBX -> Wave data
;		   EDX = Current sample index (fixed point 24.8)
;		   ESI -> ChanWave structure
;		   EDI -> offset MixingBuffer + MixBytesPerSample(4) * NumOutputChannels(2) * (NumOutputSamples + MixOffsetSamples)
;		   EBP = -NumOutputSamples
; OUTPUT : EDX = Current sample index (fixed point 24.8)
;		   CF = 0 if channel is still active
;		   CF = 1 if channel went inactive
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MixChannelToStereo	proc
		; Number of loops = min(NumOutputSamples, esi.WaveLen - eax.CurrentSample) 
		mov		ecx,[TChannel ptr eax.SampleIncrement]
		mov		sample_increment,ecx
		; Volume table offset
		mov		ecx,[TChannel ptr eax.Volume]
		shl		ecx,8+2
		add		ecx,VolumeTable
		mov		volume_table_ptr,ecx
		mov		ecx,[esi.WaveLen]
		mov		wave_len,ecx
		; Choose inner loop depending on sample type
		test    [esi.WaveType],1
		jz      its_8_bits_s
				; 16-bit signed samples
				test    [esi.WaveType],10b
				jz      mono16_s
						mov		esi,volume_table_ptr
						cmp		[TChannel ptr eax.Volume],64
						jb		mix_with_volume_s16
								MixStereoS16
								jmp		wave_mixed_s
						mix_with_volume_s16:
								MixStereoS16WithVolume
								jmp		wave_mixed_s
				
				mono16_s:
						mov		esi,volume_table_ptr
						cmp		[TChannel ptr eax.Volume],64
						jb		mix_with_volume_m16
								MixMonoS16
								jmp		wave_mixed_s
						mix_with_volume_m16:
								MixMonoS16WithVolume
								jmp     wave_mixed_s
						
		its_8_bits_s:
				; 8-bit unsigned samples
				test	[esi.WaveType],10b
				jz		mono8_s
						mov		esi,volume_table_ptr
						cmp		[TChannel ptr eax.Volume],64
						jb		mix_with_volume_s8
								MixStereoU8
								jmp		wave_mixed_s
						mix_with_volume_s8:
								MixStereoU8WithVolume
								jmp		wave_mixed_s
				mono8_s:
						mov		esi,volume_table_ptr
						cmp		[TChannel ptr eax.Volume],64
						jb		mix_with_volume_m8
								MixMonoU8
								jmp		wave_mixed_s
						mix_with_volume_m8:
								MixMonoU8WithVolume
								jmp		wave_mixed_s
		wave_mixed_s:
		stc
		ret
		no_samp_end_s:
		clc
		ret
MixChannelToStereo	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Mixes all active channels
;
; INPUT  : EAX -> Output buffer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MixChannels     proc
ifdef DEBUG_MIXER_PERFORMANCE
		mov		ebx,DebugPerfCounter
		sub 	MixerRunTicks,ebx
endif
		mov		OutputBuffer,eax
		mov     bl,MaxInputChannels
        test	bl,bl
        jz      dont_mix_anything
		call	ClearMixingBuffer
		mov		eax,NumOutputSamples
		mov		MissingMixerBufferSamples,eax
		mov		MixingBufferOffset,0
		tick_loop:
			; Samples to process = min(missing tick samples, missing mixer buffer samples)
			mov		eax,MissingMixerBufferSamples
			mov		ebp,MissingTickSamples
			shl		eax,8
			cmp		ebp,eax
			jbe		not_over_buffer_end
					mov		ebp,eax
			not_over_buffer_end:
			test	ebp,ebp
			jz		no_samples_to_play
			mov		eax,ebp
			shr		eax,8
			add		MixingBufferOffset,eax
			mov		edi,MixingBufferOffset
			shl		edi,2	; 4 bytes per mixer sample
			mov		cl,NumOutputChannels
			dec		cl
			shl		edi,cl
			add		edi,MixingBuffer
			neg		ebp
			mov		CurrentChannelOffset,0
			mov     al,MaxInputChannels
			mov		nchannels,al
			walk_channels:
				push	ebp
				sar		ebp,8
				mov		eax,ChannelPool
				add		eax,CurrentChannelOffset
				mov     esi,[eax.ChanWave]
				test    esi,esi
				jz      no_wave_in_channel
					mov     ebx,[esi.WavePtr]
					mov     edx,[eax.CurrentSample]
					cmp		NumOutputChannels,2
					jz		stereo_output
							call	MixChannelToMono
							jc		channel_mixed
							jmp		channel_continues
					stereo_output:
							call	MixChannelToStereo
							jnc		channel_continues
					channel_mixed:
					mov		eax,ChannelPool
					add		eax,CurrentChannelOffset
					; Atomic freeing of the channel
					mov     [eax.ChanWave],0
					; The channel may have been allocated from a higher priority IRQ at this point: don't touch it.
					jmp		no_wave_in_channel
					channel_continues:
					mov		eax,ChannelPool
					add		eax,CurrentChannelOffset
					mov		[eax.CurrentSample],edx
				no_wave_in_channel:
				add		CurrentChannelOffset,size TChannel
				pop		ebp
			dec     nchannels
			jnz     walk_channels
			
			no_samples_to_play:
			add 	MissingTickSamples,ebp
			jg		tick_samples_not_expired
				; End of tick
				mov		eax,SamplesPerTick
				add		MissingTickSamples,eax
				; Call mixer callback, if set			
				mov		eax,MixerCallback
				or		eax,eax
				jz		tick_samples_not_expired
				mov		ebx,ChannelPool
				movzx	ecx,MaxInputChannels
				push	ebp
				call	eax
				pop		ebp
			tick_samples_not_expired:
			sar		ebp,8
		add		MissingMixerBufferSamples,ebp
		jnz		tick_loop
		; Mixer buffer processed
		
		dont_mix_anything:
		; Compress mixing buffer into output buffer
		mov		esi,MixingBuffer
		mov		ecx,NumOutputSamples
		mov		edi,OutputBuffer
		xor		ebx,ebx
		cmp		NumOutputChannels,2
		jz		stereo_compression
		mono_compression:
		cmp		MixBitsPerSample,16
		je		mono16_compression

		mono8_compression:
				; Compress
				mov		eax,[esi+ebx*4]
				lea		eax,[eax*4+eax]			; Compression factor *5
				sar		eax,4+8+EXPANSION_BITS+6	; Compression factor /16, 16 bits -> 8 bits, EXPANSION_BITS, /64 (volume normalization)s
				; Saturate
				cmp		eax,127
				jg		sat_m8_pos
				cmp		eax,-128
				jl		sat_m8_neg
				sat_m8_done:
				; Signed -> unsigned
				add		al,128
				; Write output
				mov		[edi+ebx],al
				inc		ebx
				dec		ecx
				jnz		mono8_compression
				jmp		compression_done
				
				sat_m8_pos:
						mov	eax,127
						jmp	sat_m8_done
				sat_m8_neg:
						mov	eax,-128
						jmp	sat_m8_done

		mono16_compression:
				; Compress
				mov		eax,[esi+ebx*4]
				lea		eax,[eax*4+eax]			; Compression factor *5
				sar		eax,4+EXPANSION_BITS+6	; Compression factor /16, EXPANSION_BITS, /64 (volume normalization)
				; Saturate
				cmp		eax,32767
				jg		sat_m16_pos
				cmp		eax,-32768
				jl		sat_m16_neg
				sat_m16_done:
				; Write output
				mov		[edi+ebx*2],ax
				inc		ebx
				dec		ecx
				jnz		mono16_compression
				jmp		compression_done
				
				sat_m16_pos:
						mov	eax,32767
						jmp	sat_m16_done
				sat_m16_neg:
						mov	eax,-32768
						jmp	sat_m16_done

		stereo_compression:
		cmp		MixBitsPerSample,16
		je		stereo16_compression
		stereo8_compression:
				; Compress left channel
				mov		eax,[esi+ebx*8]
				lea		eax,[eax*4+eax]			; Compression factor *5
				sar		eax,4+8+EXPANSION_BITS+6	; Compression factor /16, 16 bits -> 8 bits, EXPANSION_BITS, /64 (volume normalization)
				
				; Saturate left channel
				cmp		eax,127
				jg		sat_l8_pos
				cmp		eax,-128
				jl		sat_l8_neg
				sat_l8_done:

				; Compress right channel
				mov		edx,[esi+ebx*8+4]
				lea		edx,[edx*4+edx]			; Compression factor *5
				sar		edx,4+8+EXPANSION_BITS+6	; Compression factor /16, 16 bits -> 8 bits, EXPANSION_BITS, /64 (volume normalization)
				
				; Saturate right channel
				cmp		edx,127
				jg		sat_r8_pos
				cmp		edx,-128
				jl		sat_r8_neg
				sat_r8_done:
				
				; Signed -> unsigned
				mov		ah,dl
				add		ah,128
				add		al,128
				mov		[edi+ebx*2],ax
				inc		ebx
				dec		ecx
				jnz		stereo8_compression
				jmp		compression_done

				sat_l8_pos:
						mov	eax,127
						jmp	sat_l8_done
				sat_l8_neg:
						mov	eax,-128
						jmp	sat_l8_done
				sat_r8_pos:
						mov	edx,127
						jmp	sat_r8_done
				sat_r8_neg:
						mov	edx,-128
						jmp	sat_r8_done

		stereo16_compression:
				; Compress left channel
				mov		eax,[esi+ebx*8]
				lea		eax,[eax*4+eax]			; Compression factor *5
				sar		eax,4+EXPANSION_BITS+6	; Compression factor /16, EXPANSION_BITS, /64 (volume normalization)

				; Saturate left channel (cycles 386,486)
				cmp		eax,32767		; 2, 1
				jg		sat_l16_pos		; 3/7+m2, 1/3
				cmp		eax,-32768		; 2, 1
				jl		sat_l16_neg		; 3/7+m2, 1/3
										; TOTAL:
										; No saturation: 10, 4 (most likely case)
										; Saturation positive: 18+m4=23, 8
										; Saturation negative: 23+m4=18, 11
				sat_l16_done:

				; Compress right channel
				mov		edx,[esi+ebx*8+4]
				lea		edx,[edx*4+edx]			; Compression factor *5
				sar		edx,4+EXPANSION_BITS+6	; Compression factor /16, 16 bits -> 8 bits, EXPANSION_BITS, /64 (volume normalization)

				; Saturate right channel (same timing as left channel saturation)
				cmp		edx,32767
				jg		sat_r16_pos
				cmp		edx,-32768
				jl		sat_r16_neg
				sat_r16_done:

				; Write output
				and		eax,0ffffh
				shl		edx,16				
				or		eax,edx
				mov		[edi+ebx*4],eax
				inc		ebx
				dec		ecx
				jnz		short stereo16_compression
		compression_done:

ifdef DEBUG_MIXER_PERFORMANCE
		mov		ebx,DebugPerfCounter
		add 	MixerRunTicks,ebx
		inc		NumMixerRuns
endif
		ret

				sat_l16_pos:
						mov	eax,32767				; 2, 1
						jmp	sat_l16_done			; 7+m2, 3
				sat_l16_neg:
						mov	eax,-32768				; 2, 1
						jmp	sat_l16_done			; 7+m2, 3
				sat_r16_pos:
						mov	edx,32767
						jmp	sat_r16_done
				sat_r16_neg:
						mov	edx,-32768
						jmp	sat_r16_done

MixChannels     endp

.data?
MaxInputChannels		db ?
MixBitsPerSample		db ?
NumOutputChannels		db ?
nchannels       		db ?
ChannelPool     		dd ?    ; Pointer to channel array
MixFreq         		dd ?    ; Mixing frequency
OutputBuffer			dd ?
NumOutputSamples		dd ?
NumOutputBytes			dd ?
MixingBuffer			dd ?
CurrentChannelOffset    dd ?
wave_len				dd ?
sample_increment		dd ?
volume_table_ptr		dd ?
VolumeTable				dd ?

MissingMixerBufferSamples	dd ?
MixingBufferOffset		dd ?

ifdef DEBUG_MIXER_PERFORMANCE
DebugPerfCounter	dd ?
MixerRunTicks		dd ?
NumMixerRuns		dd ?
AvgMixerExecTime	dq ?
AvgMixerPercentCPU	dq ?
endif

.data
SamplesPerTick		dd -1	; fixed point 24.8, unsigned
MissingTickSamples	dd -1	; fixed point 24.8, unsigned
MixerCallback		dd 0

ifdef DEBUG_MIXER_PERFORMANCE
PerfDataMsg		db "Average mixer execution time: %dfn"
				dd offset AvgMixerExecTime
				db "s ; %dfn"
				dd offset AvgMixerPercentCPU
				db "%% of CPU", 13, 10, 0
NoPerfDataMsg	db "Unable to estimate the mixer execution time. The mixer was never run.",13,10,0
endif

end
