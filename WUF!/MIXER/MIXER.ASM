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
		fild	NumMixerRuns
		fldz
		fcompp
		fstsw	ax
		fwait
		sahf
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
		fild	NumOutputBytes
		xor		eax,eax
		mov		al,MixBitsPerSample
		shr		al,3
		mov		BytesPerSample,eax
		fild	BytesPerSample
		fdivp
		fild	MixFreq
		fdivp
		fdivp
		fldf	100.0
		fmulp
		fstp	AvgMixexPercentCPU
		mov		esi,offset PerfDataMsg
		call	printf
		leave_print_mixer_perf:
		popfd
		ret
		endp
BytesPerSample	dd ?
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
; Looks for a free channel
;
; OUTPUT : CF = 0 if channel found
;               EAX -> Free channel
;          CF = 1 if no free channels
;               EAX = NO_FREE_CHANNELS
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SearchFreeChannel       proc
        movzx   ecx,MaxInputChannels
        mov     eax,ChannelPool
        parse_channels:
                cmp     [eax.ChanWave],0
                jz      found_free_chan
                add     eax,size TChannel
        loop    parse_channels
        stc
        mov     eax,NO_FREE_CHANNELS
        ret

        found_free_chan:
        clc
        ret
SearchFreeChannel       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Fills a channel with the given wave
;
; INPUT  : EAX -> TWave structure
;
; OUTPUT : CF = 0 if channel found
;               EAX = NO_ERROR
;          CF = 1 if no free channels
;               EAX = NO_FREE_CHANNELS
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
PlaySound       proc
        mov     ebx,eax
        call    SearchFreeChannel
        ErrorCode eax
        mov     [eax.ChanWave],ebx
		xor		edx,edx
		mov		eax,[ebx.BaseRate]
		shl		eax,8
		div		MixFreq
		mov		[ebx.SampleIncrement],eax
        mov     [ebx.CurrentSample],0
        ret
PlaySound       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Mixes an active channel on a mono output buffer
;
; INPUT  : EBX -> Wave data
;		   EDX = Current sample index
;		   ESI -> ChanWave structure
;		   EDI -> offset MixingBuffer + MixBytesPerSample(4) * NumOutputChannels(1) * NumOutputSamples
;		   EBP = -NumOutputSamples
; OUTPUT : CF = 0 if channel is still active
;		   CF = 1 if channel went inactive
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MixChannelToMono	proc
		; Number of loops = min(NumOutputSamples, esi.WaveLen - esi.CurrentSample) 
		test    [esi.WaveType],1
		jz      its_8_bits
				; 16-bit signed samples
				test    [esi.WaveType],10b
				jz      mono16
				stereo16:
						; Stereo, 16 bits
						mov		ecx,edx
						shr		ecx,8
						mov     eax,[ebx+ecx*4]
						movsx   ecx,ax
						shr		eax,16
						movsx	eax,ax
						add     eax,ecx
						add		eax,65536
						add		[edi+ebp*4],eax
						inc		ebp
						jz		no_samp_end
						add     edx,[esi.SampleIncrement]
						mov		ecx,[esi.WaveLen]
						shl		ecx,8
						cmp     edx,ecx
						jb		stereo16
						jmp		wave_mixed
				mono16:
						; Mono, 16 bits												
						mov		ecx,edx
						shr		ecx,8
						movsx   eax,word ptr [ebx+ecx*2]
						add		eax,32768
						shl		eax,EXPANSION_BITS	; Expand to match 16+1 bits in stereo16
						add		[edi+ebp*4],eax
						inc		ebp
						jz		no_samp_end
						add     edx,[esi.SampleIncrement]
						mov		ecx,[esi.WaveLen]
						shl		ecx,8
						cmp     edx,ecx
						jb		mono16
						jmp     wave_mixed
		its_8_bits:
				; 8-bit unsigned samples
				test	[esi.WaveType],10b
				jz		mono8
				stereo8:
						; Stereo, 8 bits
						mov		ecx,edx
						shr		ecx,8
						mov		ax,[ebx+ecx*2]
						movzx	ecx,ah
						movzx	eax,al
						add		eax,ecx
						shl		eax,8	; Expand to match 16+1 bits in stereo16
						add		[edi+ebp*4],eax
						inc		ebp
						jz		no_samp_end
						add     edx,[esi.SampleIncrement]
						mov		ecx,[esi.WaveLen]
						shl		ecx,8
						cmp     edx,ecx
						jb		stereo8
						jmp		wave_mixed
				mono8:
						; Mono, 8 bits
						mov		ecx,edx
						shr		ecx,8
						movzx   eax,byte ptr [ebx+ecx]
						shl		eax,8+EXPANSION_BITS	; Expand to match 16+1 bits in stereo16
						add		[edi+ebp*4],eax
						inc		ebp
						jz		no_samp_end
						add     edx,[esi.SampleIncrement]
						mov		ecx,[esi.WaveLen]
						shl		ecx,8
						cmp     edx,ecx
						jb		mono8
		wave_mixed:
		stc
		ret
		no_samp_end:
		clc
		ret
MixChannelToMono	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Mixes an active channel on a stereo output buffer
;
; INPUT  : EBX -> Wave data
;		   EDX = Current sample index
;		   ESI -> ChanWave structure
;		   EDI -> offset MixingBuffer + MixBytesPerSample(4) * NumOutputChannels(2) * NumOutputSamples
;		   EBP = -NumOutputSamples
; OUTPUT : CF = 0 if channel is still active
;		   CF = 1 if channel went inactive
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MixChannelToStereo	proc
		; Number of loops = min(NumOutputSamples, esi.WaveLen - esi.CurrentSample) 
		test    [esi.WaveType],1
		jz      its_8_bits_s
				; 16-bit signed samples
				test    [esi.WaveType],10b
				jz      mono16_s
				stereo16_s:
						; Stereo, 16 bits
						mov		ecx,edx
						shr		ecx,8
						mov     eax,[ebx+ecx*4]
						movsx   ecx,ax	; ecx = left channel
						shr		eax,16
						movsx	eax,ax	; eax = right channel
						add		ecx,32768
						shl		ecx,EXPANSION_BITS
						add		eax,32768
						shl		eax,EXPANSION_BITS
						add		[edi+ebp*8],ecx
						add		[edi+ebp*8+4],eax
						inc		ebp
						jz		no_samp_end_s
						add     edx,[esi.SampleIncrement]
						mov		ecx,[esi.WaveLen]
						shl		ecx,8
						cmp     edx,ecx
						jb		stereo16_s
						jmp		wave_mixed
				mono16_s:
						; Mono, 16 bits												
						mov		ecx,edx
						shr		ecx,8
						movsx   eax,word ptr [ebx+ecx*2]
						add		eax,32768
						shl		eax,EXPANSION_BITS
						add		[edi+ebp*8],eax
						add		[edi+ebp*8+4],eax
						inc		ebp
						jz		no_samp_end_s
						add     edx,[esi.SampleIncrement]
						mov		ecx,[esi.WaveLen]
						shl		ecx,8
						cmp     edx,ecx
						jb		mono16_s
						jmp     wave_mixed_s
		its_8_bits_s:
				; 8-bit unsigned samples
				test	[esi.WaveType],10b
				jz		mono8_s
				stereo8_s:
						; Stereo, 8 bits
						mov		ecx,edx
						shr		ecx,8
						mov		ax,[ebx+ecx*2]
						movzx	ecx,ah	; ecx = right channel
						movzx	eax,al	; eax = left channel
						shl		ecx,8+EXPANSION_BITS
						shl		eax,8+EXPANSION_BITS
						add		[edi+ebp*8],eax
						add		[edi+ebp*8+4],ecx
						inc		ebp
						jz		no_samp_end_s
						add     edx,[esi.SampleIncrement]
						mov		ecx,[esi.WaveLen]
						shl		ecx,8
						cmp     edx,ecx
						jb		stereo8_s
						jmp		wave_mixed_s
				mono8_s:
						; Mono, 8 bits
						mov		ecx,edx
						shr		ecx,8
						movzx   eax,byte ptr [ebx+ecx]
						shl		eax,8+EXPANSION_BITS	; Expand to match 16+1 bits in stereo16
						add		[edi+ebp*8],eax
						add		[edi+ebp*8+4],eax
						inc		ebp
						jz		no_samp_end_s
						add     edx,[esi.SampleIncrement]
						mov		ecx,[esi.WaveLen]
						shl		ecx,8
						cmp     edx,ecx
						jb		mono8_s
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
		mov		nchannels,bl
		call	ClearMixingBuffer
		mov		CurrentChannelOffset,0
		walk_channels:
			mov		ebp,NumOutputSamples
			mov		edi,ebp
			shl		edi,2
			add		edi,MixingBuffer
			neg		ebp
			mov		eax,ChannelPool
			add		eax,CurrentChannelOffset
			mov     esi,[eax.ChanWave]
			test    esi,esi
			jz      no_wave_in_channel
				mov     ebx,[esi.WavePtr]
				mov     edx,[esi.CurrentSample]
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
				mov     [eax.ChanWave],0
				channel_continues:
				mov		[esi.CurrentSample],edx
			no_wave_in_channel:
			add	CurrentChannelOffset,size TChannel
		dec     nchannels
		jnz     walk_channels
		dont_mix_anything:
		; Compress mixing buffer into output buffer
		mov		esi,MixingBuffer
		mov		ecx,NumOutputSamples
		mov		edi,OutputBuffer
		xor		ebx,ebx
		compress_output:
				mov		eax,[esi+ebx*4]
				lea		eax,[eax*4+eax]			; Compression factor *5
				shr		eax,4+8+EXPANSION_BITS	; Compression factor /16, 16 bits -> 8 bits, EXPANSION_BITS
				mov		[edi+ebx],al
				inc		ebx
				loop	compress_output

ifdef DEBUG_MIXER_PERFORMANCE
		mov		ebx,DebugPerfCounter
		add 	MixerRunTicks,ebx
		inc		NumMixerRuns
endif
		ret

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

ifdef DEBUG_MIXER_PERFORMANCE
DebugPerfCounter	dd ?
MixerRunTicks		dd ?
NumMixerRuns		dd ?
AvgMixerExecTime	dq ?
AvgMixexPercentCPU	dq ?
endif

.data
ifdef DEBUG_MIXER_PERFORMANCE
PerfDataMsg		db "Average mixer execution time: %dfn"
				dd offset AvgMixerExecTime
				db "s ; %dfn"
				dd offset AvgMixexPercentCPU
				db "%% of CPU", 13, 10, 0
NoPerfDataMsg	db "Unable to estimate the mixer execution time. The mixer was never run.",13,10,0
endif

end
