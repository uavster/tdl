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
		INCLUDE memcpy.inc

; Max. number of callbacks
MAX_NUM_CALLBACKS	EQU 4

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

TMixerCallback		struc
		CallbackAddress		dd ?
		SamplesPerTick		dd ?	; fixed point 24.8, unsigned
		MissingTickSamples	dd ?	; fixed point 24.8, unsigned
		UserPointer			dd ?
ends

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
		; TODO: Maker sure the audio IRQ does not call MixChannels before OpenMixer
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
		shl		ecx,1		; Double buffer of channels
		push	ecx
        call    malloc
		pop		ecx
        ErrorCode MALLOC_ERROR
        mov     ChannelPoolBack,ebx
		shr		ecx,1
        mov     ChannelPool,ebx
		add		ChannelPool,ecx
		shl		ecx,1
        mov     edi,ebx
        xor     eax,eax
        cld
        rep     stosb
		; Set frequency multipliers to 1.0 in case WUFPlaySounds passes "leave as is"
		movzx	ecx,MaxInputChannels
		shl		ecx,1
		mov		edi,ChannelPoolBack
		set_freq_mult_to_one:
				mov		[TChannel ptr edi.FreqMultiplier],1 SHL 24
				add		edi,size TChannel
		dec		ecx
		jnz 	set_freq_mult_to_one
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
		; where sample is within [0,255], and volume is within [0,256].
		; How to scale samples by their volume:
		; 8-bit: scaled_sample = sing(sample) * volume_table[volume][abs(sample)] >> 6
		; 16-bit: scaled_sample = sign(sample) * ((volume_table[volume][abs(sample) >> 8] << 8) + volume_table[volume][abs(sample) & 0xff]) >> 6
		mov		ecx,257*256*4
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
		cmp		ecx,257
		jnz		loop_volumes

		mov		eax,64
		call	WUFSetGlobalVolume

		; Init callbacks
		mov		ecx,size Callbacks
		xor		eax,eax
		mov		edi,offset Callbacks
		push	ds
		pop		es
		cld
		rep		stosb
		
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
		; TODO: Make sure audio IRQ is no longer called from here on.
		; Delete all added callbacks
		mov		cl,MAX_NUM_CALLBACKS
		mov		eax,offset Callbacks
		delete_all_callbacks:
				call 	WUFDeleteMixerCallback
				add		eax,size TMixerCallback
		dec		cl
		jnz		delete_all_callbacks
		
		mov		ebx,VolumeTable
		call	free
		ErrorCode FREE_ERROR
        mov     ebx,MixingBuffer
        call    free
        ErrorCode FREE_ERROR
        mov     ebx,ChannelPoolBack
        call    free
        ErrorCode FREE_ERROR
        mov     eax,NO_ERROR
        clc
        ret
CloseMixer      endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Adds a callback that will be called periodically from the playback IRQ
;
; This function can be called from any IRQ.
;
; INPUT  : EAX = Callback period in audio seconds (fixed point 16.16)
;				 Value must be lower than (2^32 - 1) / output_sampling_frequency
; 		   EBX -> Callback function
;				  Callback input is EDX -> Channel pool (TChannel elements),
;				  and EAX = Num. channels
;		   EDX = User-defined pointer
; NOTE: It's important that arguments of the callback follow Watcom's register
; calling convention (from left to right arguments): EAX, EDX, EBX, ECX.
;
; OUTPUT : CF = 0 if success
;		 		EAX -> TMixerCallback structure
;		   CF = 1 if error
;				EAX = NULL
;
; NOTE   : The audio period is not real time; the callback interrupts the 
;		   generation of the output audio buffer every number of samples 
; 		   corresponding to the callback period in seconds. If any channges
; 		   affecting the audio output are made in the callback, they will be 
;		   heard as periodic with one sampling period resolution, but the 
;		   callback may be called at any moment in real time.
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFAddMixerCallback	proc
		pushf
		cli
		; Find free callback
		mov		esi,offset Callbacks
		mov		cl,MAX_NUM_CALLBACKS
		find_free_callback:
				cmp		[TMixerCallback ptr esi.CallbackAddress],0
				jz		found_free_callback
				add		esi,size TMixerCallback
		dec		cl
		jnz		find_free_callback
		popf
		xor		eax,eax
		stc
		ret
		
		found_free_callback:
		push	ebx edx
		mov		ebx,esi
		call	WUFSetMixerCallbackPeriod
		pop		edx ebx
		mov		[TMixerCallback ptr esi.CallbackAddress],ebx
		mov		[TMixerCallback ptr esi.UserPointer],edx
		mov		eax,esi
		popf
		clc
		ret
WUFAddMixerCallback	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the period of a callback
;
; This function can be called from any IRQ.
;
; INPUT  : EBX = TMixerCallback structure of callback
;		   EAX = Callback period in audio seconds (fixed point 16.16)
;				 Value must be lower than (2^32 - 1) / (output_sampling_frequency * 256)
;
; NOTE   : The audio period is not real time; the callback interrupts the 
;		   generation of the output audio buffer every number of samples 
; 		   corresponding to the callback period in seconds. If any channges
; 		   affecting the audio output are made in the callback, they will be 
;		   heard as periodic with one sampling period resolution, but the 
;		   callback may be called at any moment in real time.
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFSetMixerCallbackPeriod	proc
		pushf
		cli
		xor		edx,edx
		mul		MixFreq
		shr		eax,8
		mov		[TMixerCallback ptr ebx.SamplesPerTick],eax
		mov		[TMixerCallback ptr ebx.MissingTickSamples],eax
		popf
		ret
WUFSetMixerCallbackPeriod	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Deletes a callback 
;
; This function can be called from any IRQ.
;
; INPUT  : EAX = TMixerCallback structure of callback to delete
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFDeleteMixerCallback	proc
		mov		[TMixerCallback ptr eax.CallbackAddress],0
		ret
WUFDeleteMixerCallback	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Looks for a free channel at or above a given number
;
; OUTPUT : CF = 0 if channel found
;				EBX -> Free channel's TChannel structure
;          CF = 1 if no free channels
;				EBX = NULL
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SearchFreeChannel       proc
        movzx   ecx,MaxInputChannels
        mov     ebx,ChannelPoolBack
        parse_channels:
                test    [TChannel ptr ebx.Flags],MIXER_CHANNEL_ALLOCATED
                jz      found_free_chan
                add     ebx,size TChannel
        loop    parse_channels
		xor		ebx,ebx
        stc
        ret

        found_free_chan:
        clc
        ret
SearchFreeChannel       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Allocates a channel
;
; It is safe to call this function from main code and IRQs. Channel data races
; are avoided by disabling interrupts.
;
; Allocating a new channel from outside the mixer callback will not take
; effect until the next tick, so please do not play a sound in the new channel
; from the callback until it is effectively allocated.
;
; INPUT  : EAX = Flags: MIXER_CHANNEL_AUTO_FREE
; OUTPUT : CF = 0 if channel allocated
;				EBX -> Free channel's TChannel structure
;          CF = 1 if no free channels
;				EBX = NULL
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFAllocateChannel		proc
		; Disable interrupts while we look for a free channel. This prevents
		; an IRQ from changing the channels states in between.
		pushf
		cli
		push	eax
		call	SearchFreeChannel
		pop		eax
		jc		no_free_channel_found
		and		al,MIXER_CHANNEL_AUTO_FREE	; only MIXER_CHANNEL_AUTO_FREE is supported
		or		al,MIXER_CHANNEL_ALLOCATED
		mov		[TChannel ptr ebx.Flags],al
		popf
		clc
		ret
		
		no_free_channel_found:
		popf
		stc
		ret
WUFAllocateChannel		endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Allocates a number of channels
;
; It is safe to call this function from main code and IRQs. Channel data races
; are avoided by disabling interrupts.
;
; Allocating a new channel from outside the mixer callback will not take
; effect until the next tick, so please do not play a sound in the new channel
; from the callback until it is effectively allocated.
;
; INPUT  : EAX = Flags: MIXER_CHANNEL_AUTO_FREE
;		   ECX = Number of channels to allocate
;		   EDI -> TChannel pointer array with ECX or more capacity
; OUTPUT : CF = 0 if channel allocated
;		   		EAX = 0
;          CF = 1 if no free channels
;				EAX = Error code (NO_FREE_CHANNELS)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFAllocateChannels		proc
		or 		ecx,ecx
		jz		zero_channels_to_allocate
		; Set all to NULL in case something fails.
		push	ds
		pop		es
		cld
		push	eax ecx edi
		rep		stosd
		pop		edi ecx eax
		; Disable interrupts while we look for a free channel. This prevents
		; an IRQ from changing the channels states in between.
		pushf
		cli
		allocate_channels:
				push	eax edi ecx
				call	WUFAllocateChannel
				pop		ecx edi eax
				jc		error_allocating_channel
				mov		[edi],ebx
				add		edi,4
		loop	allocate_channels
		popf
		zero_channels_to_allocate:
		mov		eax,NO_ERROR
		clc
		ret
		
		error_allocating_channel:
		mov		eax,NO_FREE_CHANNELS
		popf
		stc
		ret
WUFAllocateChannels		endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Frees a channel
;
; It is safe to call this function from main code and IRQs. Channel data races
; are not possible with a single atomic instruction.
;
; Freeing a channel from outside the mixer callback will not take effect until
; the next tick, so please keep the active sound in memory until then.
;
; INPUT  : EBX -> TChannel to free (does nothing if NULL)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFFreeChannel		proc
		pushf
		cli
		test	ebx,ebx
		jz		pointer_is_null
				and		[TChannel ptr ebx.Flags],NOT (MIXER_CHANNEL_ALLOCATED OR MIXER_CHANNEL_AUTO_FREE OR MIXER_CHANNEL_EDITED)
		pointer_is_null:
		popf
		ret
WUFFreeChannel		endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Frees channels
;
; It is safe to call this function from main code and IRQs. Channel data races
; are not possible with a single atomic instruction.
;
; Freeing a channel from outside the mixer callback will not take effect until
; the next tick, so please keep the active sound in memory until then.
;
; INPUT  : EBX -> TChannel pointer array
;		   ECX = Number of channel pointers in array
; OUTPUT : Freed channels pointer in input array are NULLed.
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFFreeChannels		proc
		pushf
		cli
		free_channels:
				push 	ebx ecx
				mov		ebx,[ebx]
				call	WUFFreeChannel
				pop 	ecx ebx
				mov		dword ptr [ebx],0
				add		ebx,4
		loop 	free_channels
		popf
		ret
WUFFreeChannels		endp

CopyBackChannelPoolToFront	proc
		mov		esi,ChannelPoolBack
		mov		edi,ChannelPool
		movzx	ecx,MaxInputChannels
		pushf
		cli
		copy_back_to_front:
				; Always copy channel flags, so that IRQ knows which channels were allocated and which channels to autofree.
				; Clear the edited flag so that editions inside the audio IRQ from higher priority IRQs are sensed,
				; and the interface does not keep pushing the one-time changes to the audio IRQ.
				mov		al,[TChannel ptr esi.Flags]
				mov		bl,al
				and		al,NOT MIXER_CHANNEL_EDITED
				mov		[TChannel ptr esi.Flags],al
				mov		[TChannel ptr edi.Flags],al
				
				test	bl,MIXER_CHANNEL_EDITED
				jz		dont_copy_unedited_channel
						; Copy channel data except for flags
						push	esi edi ecx		
						mov		ecx,size TChannel-2	; size TChannel-size TChannel.Flags-size Reserved does not work (equals 0)
						add		esi,2	; size TChannel.Flags+size Reserved does not work (equals 0)
						add		edi,2	; size TChannel.Flags+size Reserved does not work (equals 0)
						cld
						; When entering the IRQ, we set ES = DS
						call	Memcopy
						pop		ecx edi esi
				dont_copy_unedited_channel:
				add		esi,size TChannel
				add		edi,size TChannel
		loop	copy_back_to_front
		popf
		ret
CopyBackChannelPoolToFront	endp

CopyFrontChannelPoolToBack	proc
		mov		esi,ChannelPool
		mov		edi,ChannelPoolBack
		movzx	ecx,MaxInputChannels
		pushf
		cli
		copy_front_to_back:
				; Always copy channel allocation status, so that the API knows which channels were auto freed (or allocated in the callback)
				mov		al,[TChannel ptr esi.Flags]
				and		al,NOT MIXER_CHANNEL_EDITED	; Clear edited flag introduced by mixer callback (via WUFPlaySound) to avoid propagation to back channels
				xchg	[TChannel ptr edi.Flags],al
				
				; If the channel was edited from the API in the middle of the audio IRQ, do not copy back the channel data,
				; as it would overwrite API-passed values, which have priority.
				test	al,MIXER_CHANNEL_EDITED
				jnz		dont_copy_edited_channel	; TODO: Copy values that are "left as is" for continuity
						; Otherwise, copy channel data except for flags
						push	esi edi ecx		
						mov		ecx,size TChannel-2	; size TChannel-size TChannel.Flags-size Reserved does not work (equals 0)
						add		esi,2	; size TChannel.Flags+size Reserved does not work (equals 0)
						add		edi,2	; size TChannel.Flags+size Reserved does not work (equals 0)
						cld
						; When entering the IRQ, we set ES = DS
						call	Memcopy
						pop		ecx edi esi
				dont_copy_edited_channel:
				add		esi,size TChannel
				add		edi,size TChannel
		loop	copy_front_to_back
		popf
		ret
CopyFrontChannelPoolToBack	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Plays a sound in a channel
;
; It is safe to call this function from main code and IRQs. Channel data races
; are avoided by disabling interrupts.
;
; Playing a new sound on a channel from outside the mixer callback will not take
; effect until the next tick, so please keep the active sound in memory until
; then.
;
; INPUT  : EAX -> TWave structure of sample to play in channel, or NULL to leave as is.
;				  Setting a new sample sets the offset to zero.
;		   EBX -> TChannel where to play sound.
;		   ECX = Frequency multiplier (fixed point 8.24).
;		   		 -1 plays the sound with the current channel frequency multiplier.
;		   EDX = Volume multiplier, from 0 (silent) to 64 (as is). 
;				 -1 plays the sound with the current channel volume.
;		   ESI = New wave offset (fixed point 24.8), or -1 to leave as is. 
;				 The sound won't loop if the offset is beyond the loop end. 
;				 No sound is played if the offset is beyond the sound end.
;		   EDI = Panning, from 0 (left) to 64 (right), or -1 to leave as is.
;
; OUTPUT : CF = 0 if no error
;               EAX = NO_ERROR
;          CF = 1 if error
;               EAX = Error code
;					FREQUENCY_TOO_HIGH: Base frequency * multiplier > 16,776,960 Hz
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFPlaySound       proc		
		pushf
		cli
		
		; For safety, check that the channel was actually allocated
		push	eax
		movzx	eax,[TChannel ptr ebx.Flags]
		and		eax,MIXER_CHANNEL_ALLOCATED
		AssertDword eax, _NE, 0
		pop		eax
		
		; If this function runs outside an IRQ, the audio IRQ will not touch the channel state from here.
		; If this function runs inside an IRQ, it could be one with higher priority than the audio IRQ (e.g. keyboard).
		; In such case, we could be changing channel state in the middle of channel mixing.
		; Possible solutions:
		; 	a) CLI inside audio IRQ - Bad idea as it would block higher priority events resulting in unresponsive keyboard and timer jitter
		;   b) Double buffer of TChannels, so that the interface can write to the back buffer while the audio IRQ reads from the front buffer.
		;      The audio IRQ copies the back buffer to the front buffer before entering. The copy cost has to be small compared to the audio buffer size
		;	   (num_channels * size(TChannel)) for this option to be good. On the other hand, there is no need for code to disable interrupts for a long
		;	   time, so latency is minimal.
		
		; Change channel state
		test	eax,eax
		jz		leave_sample_as_is
				mov     [TChannel ptr ebx.ChanWave],eax				
				and		[TChannel ptr ebx.Flags],NOT MIXER_CHANNEL_IS_LOOPING
				mov     [TChannel ptr ebx.CurrentSample],0
				jmp		sample_wave_set
		leave_sample_as_is:
				mov		eax,[TChannel ptr ebx.ChanWave]
		sample_wave_set:
		
		; Set offset, if set.
		cmp		esi,-1
		je		leave_offset_as_is
				mov     [TChannel ptr ebx.CurrentSample],esi				
		leave_offset_as_is:
		
		; Set volume.
		cmp		edx,-1
		jz		leave_volume_as_is
				mov		[TChannel ptr ebx.Volume],dl
		leave_volume_as_is:
		
		; Set panning.
		cmp		edi,-1
		jz		leave_panning_as_is
				push	eax
				mov		eax,edi
				mov		[TChannel ptr ebx.Panning],al
				pop		eax
		leave_panning_as_is:
		
		; Recalculate sample increment
		cmp		ecx,-1
		jz		leave_frequency_as_is
				mov		[TChannel ptr ebx.FreqMultiplier],ecx
				jmp		freq_multiplier_set
		leave_frequency_as_is:
				mov		ecx,[TChannel ptr ebx.FreqMultiplier]
		freq_multiplier_set:

		test	eax,eax
		jz		no_sample_skip_increment_calculation
				; EDX:EAX = base_frequency * (multiplier << 24)
				xor		edx,edx
				mov		eax,[TWave ptr eax.BaseRate]
				mul		ecx
				; EAX = (base_frequency * (multiplier << 24)) >> 16
				cmp		edx,0ffffh
				jbe		resulting_freq_ok
						popf
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
				mov		[TChannel ptr ebx.SampleIncrement],eax
		no_sample_skip_increment_calculation:
		
		or		[TChannel ptr ebx.Flags],MIXER_CHANNEL_EDITED
		and		[TChannel ptr ebx.Flags],NOT MIXER_CHANNEL_IS_PAUSED
		
		popf
		xor		eax,eax
		clc		
        ret
WUFPlaySound       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Pauses the current sound in a channel
;
; It is safe to call this function from main code and IRQs.
;
; INPUT  : EBX -> TChannel where sound is playing
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFPauseSound	proc
	or		[TChannel ptr ebx.Flags],MIXER_CHANNEL_IS_PAUSED
	ret
WUFPauseSound	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Returns a handler to a channel that may be used from inside a callback.
;
; INPUT  : EBX -> Allocated TChannel
; OUTPUT : EBX -> TChannel that can be used with WUFPlaySound from inside a
;			      callback
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFChannelInCallback	proc
		sub		ebx,ChannelPoolBack
		add		ebx,ChannelPool
		ret
WUFChannelInCallback	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the global volume.
;
; INPUT  : EAX = Global volume within [0, 64]
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFSetGlobalVolume	proc
		pushf
		cli
		AssertD 	eax,_leu,64
		shl			eax,2+8+2	; volume_units * num_rows_per_volume_unit (256/64=4) * sample_values_per_row (256) * sizeof(DWORD) (4)
		add			eax,VolumeTable
		mov			GlobalVolumeTablePtr,eax
		popf
		ret
WUFSetGlobalVolume	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; All macros below share the same interface.
;
; INPUT  : EAX = Signed 16-bit sample
;		   ESI -> LUT for the sample volume
; OUTPUT : EAX = Signed 16-bit sample scaled by volume
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

ScaleSampleByVolume8	macro	volume_table_ptr_reg
	local	is_negative_u8
	local	volume_done_u8
	cmp		eax,7fffffffh	; 1
	ja		is_negative_u8	; 1 (not jump) or 3 (jump)
			mov		eax,[volume_table_ptr_reg+eax*4]	; 1
			jmp 	volume_done_u8	; 3
	is_negative_u8:
			neg		eax		; 1
			mov		eax,[volume_table_ptr_reg+eax*4]	; 1
			neg		eax		; 1
	volume_done_u8:
endm

ScaleSampleByVolume16	macro	volume_table_ptr_reg
	local	is_negative_s16
	local	volume_done_s16
	cmp		eax,7fffffffh	; 1
	ja		is_negative_s16	; 1 (not jump) or 3 (jump)
			mov		ecx,eax	; 1

			shr		eax,8	; 2
			mov		eax,[volume_table_ptr_reg+eax*4]	; 1
			shl		eax,8	; 2
			xor		ch,ch	; 1
			add		eax,[volume_table_ptr_reg+ecx*4]	; 2	(may be better as mov+add in 386)

			jmp 	volume_done_s16	; 3
	is_negative_s16:
			neg		eax		; 1
			mov		ecx,eax	; 1

			shr		eax,8	; 2
			mov		eax,[volume_table_ptr_reg+eax*4]	; 1
			shl		eax,8	; 2

			xor		ch,ch	; 1
			add		eax,[volume_table_ptr_reg+ecx*4]	; 2

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

AdjustStateForLoop macro bytes_per_sample
		mov		ecx,wave_loop_start
		sub		wave_len,ecx
		lea		ebx,[ebx+bytes_per_sample*ecx]
		mov		wave_loop_start,-2
endm

IfSampleLoopsGoTo macro sample_loop, bytes_per_sample
local	end_loop
		; ECX = wave_len (24.8), EDX = current sample (24.8), wave_loop_start (32.0)
		cmp		wave_loop_start,-1
		jz		end_loop
		xor		edx,edx
		cmp		wave_loop_start,-2
		jz		sample_loop
		AdjustStateForLoop 	bytes_per_sample
		jmp		sample_loop
		end_loop:
endm

IfSampleIsLoopingAdjustForLoop macro bytes_per_sample
local	channel_is_not_looping
		; If the sample is looping, increment the wave data pointer [esi.LoopStart] samples
		test	[TChannel ptr eax.Flags],MIXER_CHANNEL_IS_LOOPING
		jz		channel_is_not_looping
				AdjustStateForLoop 	bytes_per_sample
		channel_is_not_looping:
endm

MixStereoS16InMonoBuffer macro
local sample_loop, out_ptr
; Edit code to include output offset as literal
mov		dword ptr [out_ptr-4],edi
IfSampleIsLoopingAdjustForLoop 4
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		mov     eax,[ebx+ecx*4]
		movsx   ecx,ax
		shr		eax,16
		movsx	eax,ax
		add     eax,ecx
		shl		eax,EXPANSION_BITS+6+2	; *64*4 (volume)
		add		[ebp*4+12345678h],eax
out_ptr:
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,4
endm

MixStereoS16WithVolumeInMonoBuffer macro
local sample_loop, out_ptr1, out_ptr2
; Edit code to include output offset as literal
mov		dword ptr [out_ptr1-4],edi
mov		dword ptr [out_ptr2-4],edi
mov		edi,volume_table_ptr_right
IfSampleIsLoopingAdjustForLoop 4
sample_loop:
		; Left channel
		mov		ecx,edx
		shr		ecx,8
		mov     eax,[ebx+ecx*4]
		movsx   eax,ax
		ScaleSampleByVolume16 esi
		shl		eax,EXPANSION_BITS
		add		[ebp*4+12345678h],eax
out_ptr1:
		; Right channel
		mov		ecx,edx
		shr		ecx,8
		mov     eax,[ebx+ecx*4]
		shr		eax,16
		movsx	eax,ax
		ScaleSampleByVolume16 edi
		shl		eax,EXPANSION_BITS
		add		[ebp*4+12345678h],eax
out_ptr2:
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,4
endm

MixStereoS16AllLeftInMonoBuffer macro
local sample_loop, out_ptr1, out_ptr2
; Edit code to include output offset as literal
mov		dword ptr [out_ptr1-4],edi
IfSampleIsLoopingAdjustForLoop 4
sample_loop:
		; Left channel
		mov		ecx,edx
		shr		ecx,8
		movsx   eax,word ptr [ebx+ecx*4]
		ScaleSampleByVolume16 esi
		shl		eax,EXPANSION_BITS
		add		[ebp*4+12345678h],eax
out_ptr1:
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,4
endm

MixStereoS16AllRightInMonoBuffer macro
local sample_loop, out_ptr1, out_ptr2
; Edit code to include output offset as literal
mov		dword ptr [out_ptr1-4],edi
mov		edi,volume_table_ptr_right
IfSampleIsLoopingAdjustForLoop 4
sample_loop:
		; Right channel
		mov		ecx,edx
		shr		ecx,8
		movsx   eax,word ptr [ebx+ecx*4+2]
		ScaleSampleByVolume16 edi
		shl		eax,EXPANSION_BITS
		add		[ebp*4+12345678h],eax
out_ptr1:
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,4
endm

MixMonoS16InMonoBuffer macro
local sample_loop, out_ptr
; Edit code to include output offset as literal
mov		dword ptr [out_ptr-4],edi
IfSampleIsLoopingAdjustForLoop 2
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		movsx   eax,word ptr [ebx+ecx*2]
		shl		eax,EXPANSION_BITS+6+2	; Expand to match 16+1 bits in stereo16, *64*4 (volume)
		add		[ebp*4+12345678h],eax
out_ptr:
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,2
endm

MixMonoS16WithVolumeInMonoBuffer macro
local sample_loop, out_ptr
; Edit code to include output offset as literal
mov		dword ptr [out_ptr-4],edi
IfSampleIsLoopingAdjustForLoop 2
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		movsx   eax,word ptr [ebx+ecx*2]
		ScaleSampleByVolume16 esi
		shl		eax,EXPANSION_BITS	; Expand to match 16+1 bits in stereo16
		add		[ebp*4+12345678h],eax
out_ptr:
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,2
endm

MixStereoU8InMonoBuffer macro
local sample_loop, out_ptr
; Edit code to include output offset as literal
mov		dword ptr [out_ptr-4],edi
IfSampleIsLoopingAdjustForLoop 2
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		mov		ax,[ebx+ecx*2]
		sub		al,128
		sub		ah,128
		movsx	ecx,ah
		movsx	eax,al
		add		eax,ecx
		shl		eax,8+EXPANSION_BITS+6+2	; Expand to match 16+1 bits in stereo16, *64*4 (volume)
		add		[ebp*4+12345678h],eax
out_ptr:
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,2
endm

MixStereoU8WithVolumeInMonoBuffer macro
local sample_loop, out_ptr
; Edit code to include output offset as literal
mov		dword ptr [out_ptr-4],edi
mov		edi,volume_table_ptr_right
IfSampleIsLoopingAdjustForLoop 2
sample_loop:
		mov		eax,edx
		shr		eax,8
		mov		cx,[ebx+eax*2]
		sub		cl,128		
		movsx	eax,cl
		ScaleSampleByVolume8 esi
		
		sub		ch,128
		movsx	ecx,ch
		xchg	eax,ecx
		ScaleSampleByVolume8 edi
		
		add		eax,ecx
		shl		eax,8+EXPANSION_BITS	; Expand to match 16+1 bits in stereo16
		add		[ebp*4+12345678h],eax
out_ptr:
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,2
endm

MixMonoU8InMonoBuffer macro
local sample_loop, out_ptr
; Edit code to include output offset as literal
mov		dword ptr [out_ptr-4],edi
IfSampleIsLoopingAdjustForLoop 1
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		mov   	al,byte ptr [ebx+ecx]
		sub		al,128
		movsx	eax,al
		shl		eax,8+EXPANSION_BITS+6+2	; Expand to match 16+1 bits in stereo16, *64*4 (volume)
		add		[ebp*4+12345678h],eax
out_ptr:
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,1
endm

MixMonoU8WithVolumeInMonoBuffer macro
local sample_loop, out_ptr
; Edit code to include output offset as literal
mov		dword ptr [out_ptr-4],edi
IfSampleIsLoopingAdjustForLoop 1
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		mov   	al,byte ptr [ebx+ecx]
		sub		al,128
		movsx	eax,al
		ScaleSampleByVolume8 esi
		shl		eax,8+EXPANSION_BITS	; Expand to match 16+1 bits in stereo16
		add		[ebp*4+12345678h],eax
out_ptr:
		inc		ebp
		jz		no_samp_end
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,1
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
		; wave_len = min([esi.WaveLen], [esi.LoopEnd])
		mov		ecx,[esi.WaveLen]
		cmp		ecx,[esi.LoopEnd]
		jbe		no_loop_mono
				mov		ecx,[esi.LoopEnd]
		no_loop_mono:
		mov		wave_len,ecx
		; wave_loop_start = [esi.LoopStart]
		mov		ecx,[esi.LoopStart]
		mov		wave_loop_start,ecx
		
		; Choose inner loop depending on sample type
		test    [esi.WaveType],1
		jz      its_8_bits
				; 16-bit signed samples
				test    [esi.WaveType],10b
				jz      mono16
						call	SetVolumeTablePointersForChannel_Stereo						
						mov		esi,volume_table_ptr
						cmp		[TChannel ptr eax.Volume],64
						jb		mix_with_volume_s16_m
						cmp		[TChannel ptr eax.Panning],32
						jne		mix_with_volume_s16_m
								MixStereoS16InMonoBuffer
								jmp		wave_mixed
						mix_with_volume_s16_m:
						cmp		[TChannel ptr eax.Panning],0
						je		mix_all_left_s16_m
						cmp		[TChannel ptr eax.Panning],64
						je		mix_all_right_s16_m
								MixStereoS16WithVolumeInMonoBuffer
								jmp		wave_mixed
						mix_all_left_s16_m:
								MixStereoS16AllLeftInMonoBuffer
								jmp		wave_mixed
						mix_all_right_s16_m:
								MixStereoS16AllRightInMonoBuffer
								jmp		wave_mixed
								
				mono16:
						call	SetVolumeTablePointersForChannel_Mono
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
						call	SetVolumeTablePointersForChannel_Stereo
						mov		esi,volume_table_ptr
						cmp		[TChannel ptr eax.Volume],64
						jb		mix_with_volume_s8_m
						cmp		[TChannel ptr eax.Panning],32
						jne		mix_with_volume_s8_m
								MixStereoU8InMonoBuffer
								jmp		wave_mixed
						mix_with_volume_s8_m:
								MixStereoU8WithVolumeInMonoBuffer
								jmp		wave_mixed
								
				mono8:
						call	SetVolumeTablePointersForChannel_Mono
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
local sample_loop, out_ptr_left, out_ptr_right
; Edit code to include output offset as literal
mov		dword ptr [out_ptr_left-4],edi
mov		dword ptr [out_ptr_right-4],edi
add		dword ptr [out_ptr_right-4],4
mov		edi,volume_table_ptr_right
IfSampleIsLoopingAdjustForLoop 4
sample_loop:		
		; Precondition: EDX = Current sample index (fixed point 24.8)
		; Load left channel sample in EAX
		mov		ecx,edx
		shr		ecx,8
		mov     eax,[ebx+ecx*4]
		movsx   eax,ax	; eax = left channel
		ScaleSampleByVolume16 esi
		shl		eax,EXPANSION_BITS
		add		[ebp*8+12345678h],eax
out_ptr_left:
		
		; Precondition: EDX = Current sample index (fixed point 24.8)
		; Load right channel sample in EAX
		mov		ecx,edx
		shr		ecx,8
		mov     eax,[ebx+ecx*4]
		shr		eax,16
		movsx	eax,ax	; eax = right channel
		ScaleSampleByVolume16 edi
		shl		eax,EXPANSION_BITS
		add		[ebp*8+4+12345678h],eax
out_ptr_right:
		
		inc		ebp
		jz		no_samp_end_s
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,4
endm

MixStereoS16 macro
local sample_loop, out_ptr_left, out_ptr_right
; Edit code to include output offset as literal
mov		dword ptr [out_ptr_left-4],edi
mov		dword ptr [out_ptr_right-4],edi
add		dword ptr [out_ptr_right-4],4
IfSampleIsLoopingAdjustForLoop 4
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		mov     eax,[ebx+ecx*4]
		movsx   ecx,ax	; ecx = left channel
		shr		eax,16
		movsx	eax,ax	; eax = right channel
		shl		ecx,EXPANSION_BITS+6+2	; *64*4 (volume)
		shl		eax,EXPANSION_BITS+6+2	; *64*4 (volume)
		add		[ebp*8+12345678h],ecx
out_ptr_left:
		add		[ebp*8+4+12345678h],eax
out_ptr_right:
		inc		ebp
		jz		no_samp_end_s
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,4
endm

MixMonoS16WithVolume macro
local sample_loop, out_ptr_left, out_ptr_right
; Edit code to include output offset as literal
mov		dword ptr [out_ptr_left-4],edi
mov		dword ptr [out_ptr_right-4],edi
add		dword ptr [out_ptr_right-4],4
mov		edi,volume_table_ptr_right
IfSampleIsLoopingAdjustForLoop 2
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		movsx   eax,word ptr [ebx+ecx*2]
		ScaleSampleByVolume16 esi
		shl		eax,EXPANSION_BITS
		add		[ebp*8+12345678h],eax
out_ptr_left:
		mov		ecx,edx
		shr		ecx,8
		movsx   eax,word ptr [ebx+ecx*2]
		ScaleSampleByVolume16 edi
		shl		eax,EXPANSION_BITS		
		add		[ebp*8+4+12345678h],eax
out_ptr_right:
		inc		ebp
		jz		no_samp_end_s
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,2
endm

MixMonoS16 macro
local sample_loop, out_ptr_left, out_ptr_right
; Edit code to include output offset as literal
mov		dword ptr [out_ptr_left-4],edi
mov		dword ptr [out_ptr_right-4],edi
add		dword ptr [out_ptr_right-4],4
IfSampleIsLoopingAdjustForLoop 2
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		movsx   eax,word ptr [ebx+ecx*2]
		shl		eax,EXPANSION_BITS+6+2	; *64*4 (volume)
		add		[ebp*8+12345678h],eax
out_ptr_left:
		add		[ebp*8+4+12345678h],eax
out_ptr_right:
		inc		ebp
		jz		no_samp_end_s
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,2
endm

MixStereoU8WithVolume macro
local sample_loop, out_ptr_left, out_ptr_right
; Edit code to include output offset as literal
mov		dword ptr [out_ptr_left-4],edi
mov		dword ptr [out_ptr_right-4],edi
add		dword ptr [out_ptr_right-4],4
mov		edi,volume_table_ptr_right
IfSampleIsLoopingAdjustForLoop 2
sample_loop:
		mov		eax,edx
		shr		eax,8
		mov		cx,[ebx+eax*2]
		sub		ch,128
		sub		cl,128
		movsx	eax,cl	; left channel
		ScaleSampleByVolume8 esi
		shl		eax,8+EXPANSION_BITS
		add		[ebp*8+12345678h],eax
out_ptr_left:
		movsx	eax,ch	; right channel
		ScaleSampleByVolume8 edi
		shl		eax,8+EXPANSION_BITS
		add		[ebp*8+4+12345678h],eax
out_ptr_right:
		inc		ebp
		jz		no_samp_end_s
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,2
endm

MixStereoU8 macro
local sample_loop, out_ptr_left, out_ptr_right
; Edit code to include output offset as literal
mov		dword ptr [out_ptr_left-4],edi
mov		dword ptr [out_ptr_right-4],edi
add		dword ptr [out_ptr_right-4],4
IfSampleIsLoopingAdjustForLoop 2
sample_loop:
		mov		ecx,edx
		shr		ecx,8
		mov		ax,[ebx+ecx*2]
		sub		ah,128
		sub		al,128
		movsx	ecx,ah	; ecx = right channel
		movsx	eax,al	; eax = left channel
		shl		ecx,8+EXPANSION_BITS+6+2	; *64*4 (volume)
		shl		eax,8+EXPANSION_BITS+6+2	; *64*4 (volume)
		add		[ebp*8+12345678h],eax
out_ptr_left:
		add		[ebp*8+4+12345678h],ecx
out_ptr_right:
		inc		ebp
		jz		no_samp_end_s
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,2
endm

MixMonoU8WithVolume macro
local sample_loop, out_ptr_left, out_ptr_right
; Edit code to include output offset as literal
mov		dword ptr [out_ptr_left-4],edi
mov		dword ptr [out_ptr_right-4],edi
add		dword ptr [out_ptr_right-4],4
mov		edi,volume_table_ptr_right
IfSampleIsLoopingAdjustForLoop 1
sample_loop:
		mov		ecx,edx
		shr		ecx,8						
		mov   	al,byte ptr [ebx+ecx]
		sub		al,128
		movsx	eax,al
		mov		ecx,eax
		ScaleSampleByVolume8 esi		
		shl		eax,8+EXPANSION_BITS	; Expand to match 16+1 bits in stereo16
		add		[ebp*8+12345678h],eax
out_ptr_left:
		mov		eax,ecx
		ScaleSampleByVolume8 edi		
		shl		eax,8+EXPANSION_BITS	; Expand to match 16+1 bits in stereo16
		add		[ebp*8+4+12345678h],eax
out_ptr_right:
		inc		ebp
		jz		no_samp_end_s
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,1
endm

MixMonoU8 macro
local sample_loop, out_ptr_left, out_ptr_right
; Edit code to include output offset as literal
mov		dword ptr [out_ptr_left-4],edi
mov		dword ptr [out_ptr_right-4],edi
add		dword ptr [out_ptr_right-4],4
IfSampleIsLoopingAdjustForLoop 1
sample_loop:
		mov		ecx,edx
		shr		ecx,8						
		mov   	al,byte ptr [ebx+ecx]
		sub		al,128
		movsx	eax,al
		shl		eax,8+EXPANSION_BITS+6+2-1	; Expand to match 16+1 bits in stereo16, *64*4 (volume), /2 to be equivalent to center panning.
		add		[ebp*8+12345678h],eax
out_ptr_left:
		add		[ebp*8+4+12345678h],eax
out_ptr_right:
		inc		ebp
		jz		no_samp_end_s
		add     edx,sample_increment
		mov		ecx,wave_len
		shl		ecx,8
		cmp     edx,ecx
		jb		sample_loop
		IfSampleLoopsGoTo sample_loop,1
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
;		   wave_table_ptr -> Row of volume table for the channel volume and panning
;		   wave_table_ptr_right -> Row of volume table for the channel volume and panning
; OUTPUT : EDX = Current sample index (fixed point 24.8)
;		   CF = 0 if channel is still active
;		   CF = 1 if channel went inactive
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MixChannelToStereo	proc
		call	SetVolumeTablePointersForChannel_Stereo
		; Number of loops = min(NumOutputSamples, esi.WaveLen - eax.CurrentSample) 
		mov		ecx,[TChannel ptr eax.SampleIncrement]
		mov		sample_increment,ecx
		
		; wave_len = min([esi.WaveLen], [esi.LoopEnd])
		mov		ecx,[esi.WaveLen]
		cmp		ecx,[esi.LoopEnd]
		jbe		no_loop_stereo
				mov		ecx,[esi.LoopEnd]
		no_loop_stereo:
		mov		wave_len,ecx
		; wave_loop_start = [esi.LoopStart]
		mov		ecx,[esi.LoopStart]		
		mov		wave_loop_start,ecx
		
		; Choose inner loop depending on sample type
		push	edi
		test    [esi.WaveType],1
		jz      its_8_bits_s
				; 16-bit signed samples
				test    [esi.WaveType],10b
				jz      mono16_s
						mov		esi,volume_table_ptr
						cmp		[TChannel ptr eax.Volume],64
						jb		mix_with_volume_s16
						cmp		[TChannel ptr eax.Panning],32
						jne		mix_with_volume_s16
								MixStereoS16
								jmp		wave_mixed_s
						mix_with_volume_s16:
								MixStereoS16WithVolume
								jmp		wave_mixed_s
				
				mono16_s:
						mov		esi,volume_table_ptr
						cmp		[TChannel ptr eax.Volume],64
						jb		mix_with_volume_m16
						cmp		[TChannel ptr eax.Panning],32
						jne		mix_with_volume_m16
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
						cmp		[TChannel ptr eax.Panning],32
						jne		mix_with_volume_s8
								MixStereoU8
								jmp		wave_mixed_s
						mix_with_volume_s8:
								MixStereoU8WithVolume
								jmp		wave_mixed_s
				mono8_s:
						mov		esi,volume_table_ptr						
						cmp		[TChannel ptr eax.Volume],64
						jb		mix_with_volume_m8
						cmp		[TChannel ptr eax.Panning],32
						jne		mix_with_volume_m8
								MixMonoU8
								jmp		wave_mixed_s
						mix_with_volume_m8:
								MixMonoU8WithVolume
								jmp		wave_mixed_s
		wave_mixed_s:
		pop		edi
		stc
		ret
		no_samp_end_s:
		pop		edi
		clc
		ret
MixChannelToStereo	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the volume table pointer to the right row given the channel volume in mono output
;
; INPUT  : EAX -> TChannel structure
; OUTPUT : volume_table_ptr -> volume table row channel volume
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetVolumeTablePointersForChannel_Mono	proc
		; Set volume table offset
		movzx	ecx,[TChannel ptr eax.Volume]
		shl		ecx,2+8+2		; volume_units * num_rows_per_volume_unit (256/64=4) * sample_values_per_row (256) * sizeof(DWORD) (4)
		add		ecx,VolumeTable
		mov		volume_table_ptr,ecx
		ret
SetVolumeTablePointersForChannel_Mono	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the volume table pointers to the right rows given the channel volume and panning in stereo output
;
; INPUT  : EAX -> TChannel structure
; OUTPUT : volume_table_ptr -> volume table row for (channel_volume * (64 - channel_panning) / 64)
; 		   volume_table_ptr_right -> volume table row for (channel_volume * channel_panning / 64)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetVolumeTablePointersForChannel_Stereo	proc
		; Set volume table offsets
		push	ebx
		; Left channel volume: volume * (64 - panning) / 64
		mov		ebx,64
		movzx	ecx,[TChannel ptr eax.Panning]
		sub		ebx,ecx
		shl		ebx,2+8+2	; volume_units * num_rows_per_volume_unit (256/64=4) * sample_values_per_row (256) * sizeof(DWORD) (4)
		add		ebx,VolumeTable
		movzx	ecx,[TChannel ptr eax.Volume]
		mov		ecx,[ebx+4*ecx]
		shr		ecx,6		; Values in volume table are pre-multiplied by volume dynamic range
		shl		ecx,2+8	; volume_units * num_rows_per_volume_unit (256/64=4) * sample_values_per_row (256) * sizeof(DWORD) (4)
		add		ecx,VolumeTable
		mov		volume_table_ptr,ecx
		; Right channel volume: volume * panning / 64
		movzx	ebx,[TChannel ptr eax.Panning]
		shl		ebx,2+8+2	; volume_units * num_rows_per_volume_unit (256/64=4) * sample_values_per_row (256) * sizeof(DWORD) (4)
		add		ebx,VolumeTable
		movzx	ecx,[TChannel ptr eax.Volume]
		mov		ecx,[ebx+4*ecx]
		shr		ecx,6		; Values in volume table are pre-multiplied by volume dynamic range
		shl		ecx,2+8	; volume_units * num_rows_per_volume_unit (256/64=4) * sample_values_per_row (256) * sizeof(DWORD) (4)
		add		ecx,VolumeTable
		mov		volume_table_ptr_right,ecx
		pop		ebx
		ret
SetVolumeTablePointersForChannel_Stereo	endp

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
			call	CopyBackChannelPoolToFront

			; Samples to process = min(missing tick samples for each callback, missing mixer buffer samples)
			mov		ebp,MissingMixerBufferSamples
			shl		ebp,8
			mov		esi,offset Callbacks
			mov		cl,MAX_NUM_CALLBACKS
			pushf
			cli		; Clear interrupts, so that callback modification functions in the API can be called from anywhere
			find_min_missing_samples:
					cmp		[TMixerCallback ptr esi.CallbackAddress],0
					jz		greater_than_or_equal_to_min
					mov		eax,[TMixerCallback ptr esi.MissingTickSamples]
					cmp		eax,ebp
					jae		greater_than_or_equal_to_min
							mov		ebp,eax
					greater_than_or_equal_to_min:
					add		esi,size TMixerCallback
			dec		cl
			jnz		find_min_missing_samples
			popf
			
			test	ebp,ebp
			jz		no_samples_to_play
			mov		eax,ebp
			shr		eax,8
			jz		no_samples_to_play
			add		MixingBufferOffset,eax
			mov		edi,MixingBufferOffset
			shl		edi,2	; 4 bytes per mixer sample
			mov		cl,NumOutputChannels
			dec		cl
			shl		edi,cl
			add		edi,MixingBuffer
			mov		CurrentChannelOffset,0
			mov     al,MaxInputChannels
			mov		nchannels,al
			walk_channels:
				push	ebp
				shr		ebp,8
				neg		ebp
				mov		eax,ChannelPool
				add		eax,CurrentChannelOffset
				test	[TChannel ptr eax.Flags],MIXER_CHANNEL_ALLOCATED
				jz		no_wave_in_channel
				test	[TChannel ptr eax.Flags],MIXER_CHANNEL_IS_PAUSED
				jnz		no_wave_in_channel
				mov     esi,[TChannel ptr eax.ChanWave]
				test    esi,esi
				jz      no_wave_in_channel				
					mov     ebx,[esi.WavePtr]
					mov     edx,[eax.CurrentSample]
					; Is current sample at or beyond length?
					mov		ecx,[esi.WaveLen]
					shl		ecx,8
					cmp     edx,ecx
					jae		channel_mixed
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
					mov		[eax.CurrentSample],edx	; Advance play position
					; Atomic freeing of the channel
					pushf
					cli
					test	[TChannel ptr eax.Flags],MIXER_CHANNEL_AUTO_FREE
					jz		no_auto_free
							mov		ebx,eax
							call	WUFFreeChannel
					no_auto_free:
					popf
					; The channel may have been allocated from a higher priority IRQ at this point: don't touch it.
					jmp		no_wave_in_channel

					channel_continues:
					mov		eax,ChannelPool
					add		eax,CurrentChannelOffset
					cmp		wave_loop_start,-2
					jne		sample_not_looping
							; wave_loop_start == -2, so sample started looping 
							or		[TChannel ptr eax.Flags],MIXER_CHANNEL_IS_LOOPING
					sample_not_looping:
					mov		[eax.CurrentSample],edx	; Advance play position
				no_wave_in_channel:
				add		CurrentChannelOffset,size TChannel
				pop		ebp
			dec     nchannels
			jnz     walk_channels
			
			no_samples_to_play:
			mov		eax,offset Callbacks
			mov		cl,MAX_NUM_CALLBACKS
			pushf
			cli		; Clear interrupts, so that callback modification functions in the API can be called from anywhere
			iterate_on_callbacks:
					mov		ebx,[TMixerCallback ptr eax.CallbackAddress]
					test	ebx,ebx
					jz		tick_samples_not_expired					
					sub 	[TMixerCallback ptr eax.MissingTickSamples],ebp
					jg		tick_samples_not_expired
							; End of tick
							mov		edx,[TMixerCallback ptr eax.SamplesPerTick]
							add		[TMixerCallback ptr eax.MissingTickSamples],edx
							; Call mixer callback, if set.
							; First argument (eax) is the pointer to the TMixerCallback structure.
							mov		edx,[TMixerCallback ptr eax.UserPointer]
							popf	; Re-allow interrupts if they were enabled in this IRQ, as the callback may take long
							
							push	eax ecx ebp
							call	ebx
							pop		ebp ecx eax
							
							pushf
							cli		; Clear interrupts again, so that callback modification functions in the API can be called from anywhere
					tick_samples_not_expired:
					add		eax,size TMixerCallback
			dec		cl
			jnz		iterate_on_callbacks
			popf	; Re-allow interrupts if they were enabled in this IRQ, as the callback may be heavy
			
			call	CopyFrontChannelPoolToBack
		shr		ebp,8
		sub		MissingMixerBufferSamples,ebp		
		jnz		tick_loop
		; Mixer buffer processed
		
		dont_mix_anything:			
		; Compress mixing buffer into output buffer
;		mov		esi,MixingBuffer
		mov		ebp,NumOutputSamples
		mov		edi,OutputBuffer
		xor		ebx,ebx
		cmp		NumOutputChannels,2
		jz		stereo_compression

		; Mono compression
		cmp		MixBitsPerSample,16
		je		mono16_compression

		mono8_compression:
				; Compress
				mov		esi,MixingBuffer
				mov		eax,[esi+ebx*4]
				lea		eax,[eax*4+eax]				; Compression factor *5
				sar		eax,4+8+EXPANSION_BITS+6+2	; Compression factor /16, 16 bits -> 8 bits, EXPANSION_BITS, /(64*4) (volume normalization)
				; Saturate
				cmp		eax,127
				jg		sat_m8_pos
				cmp		eax,-128
				jl		sat_m8_neg
				sat_m8_done:
				
				; Apply global volume
				mov		esi,GlobalVolumeTablePtr
				ScaleSampleByVolume8 esi
				sar		eax,6+2		; ~ /(64*4)
				
				; Signed -> unsigned
				add		al,128
				; Write output
				mov		[edi+ebx],al
				inc		ebx
				dec		ebp
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
				mov		esi,MixingBuffer
				mov		eax,[esi+ebx*4]
				lea		eax,[eax*4+eax]				; Compression factor *5
				sar		eax,4+EXPANSION_BITS+6+2	; Compression factor /16, EXPANSION_BITS, /(64*4) (volume normalization)
				; Saturate
				cmp		eax,32767
				jg		sat_m16_pos
				cmp		eax,-32768
				jl		sat_m16_neg
				sat_m16_done:
				
				; Apply global volume
				mov		esi,GlobalVolumeTablePtr
				ScaleSampleByVolume16 esi
				sar		eax,6+2		; ~ /(64*4)
				
				; Write output
				mov		[edi+ebx*2],ax
				inc		ebx
				dec		ebp
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
				mov		esi,MixingBuffer
				mov		eax,[esi+ebx*8]
				lea		eax,[eax*4+eax]				; Compression factor *5
				sar		eax,4+8+EXPANSION_BITS+6+2	; Compression factor /16, 16 bits -> 8 bits, EXPANSION_BITS, /(64*4) (volume normalization)
				
				; Saturate left channel
				cmp		eax,127
				jg		sat_l8_pos
				cmp		eax,-128
				jl		sat_l8_neg
				sat_l8_done:
				
				; Apply global volume
				mov		esi,GlobalVolumeTablePtr
				ScaleSampleByVolume8 esi
				sar		eax,6+2		; ~ /(64*4)

				; Compress right channel
				mov		esi,MixingBuffer
				mov		edx,[esi+ebx*8+4]
				lea		edx,[edx*4+edx]				; Compression factor *5
				sar		edx,4+8+EXPANSION_BITS+6+2	; Compression factor /16, 16 bits -> 8 bits, EXPANSION_BITS, /(64*4) (volume normalization)
				
				; Saturate right channel
				cmp		edx,127
				jg		sat_r8_pos
				cmp		edx,-128
				jl		sat_r8_neg
				sat_r8_done:
				
				; Apply global volume
				mov		esi,GlobalVolumeTablePtr
				xchg	eax,edx
				ScaleSampleByVolume8 esi
				sar		eax,6+2		; ~ /(64*4)

				xchg	eax,edx				
				
				; Signed -> unsigned
				mov		ah,dl
				add		ah,128
				add		al,128
				xchg	ah,al

				mov		[edi+ebx*2],ax
				inc		ebx
				dec		ebp
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
				mov		esi,MixingBuffer
				mov		eax,[esi+ebx*8]
				lea		eax,[eax*4+eax]				; Compression factor *5
				sar		eax,4+EXPANSION_BITS+6+2	; Compression factor /16, EXPANSION_BITS, /(64*4) (volume normalization)

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
				
				; Apply global volume
				mov		esi,GlobalVolumeTablePtr
				ScaleSampleByVolume16 esi
				sar		eax,6+2		; ~ /(64*4)
				
				; Scale 
				; Compress right channel
				mov		esi,MixingBuffer
				mov		edx,[esi+ebx*8+4]
				lea		edx,[edx*4+edx]				; Compression factor *5
				sar		edx,4+EXPANSION_BITS+6+2	; Compression factor /16, EXPANSION_BITS, /(64*4) (volume normalization)

				; Saturate right channel (same timing as left channel saturation)
				cmp		edx,32767
				jg		sat_r16_pos
				cmp		edx,-32768
				jl		sat_r16_neg
				sat_r16_done:

				; Apply global volume
				mov		esi,GlobalVolumeTablePtr
				xchg	eax,edx
				ScaleSampleByVolume16 esi
				sar		eax,6+2		; ~ /(64*4)
				xchg	eax,edx
				
				; Write output
				and		eax,0ffffh
				shl		edx,16				
				or		eax,edx
				mov		[edi+ebx*4],eax
				inc		ebx
				dec		ebp
				jnz		stereo16_compression
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
ChannelPoolBack			dd ?	; Pointer to channel array back buffer
MixFreq         		dd ?    ; Mixing frequency
OutputBuffer			dd ?
NumOutputSamples		dd ?
NumOutputBytes			dd ?
MixingBuffer			dd ?
CurrentChannelOffset    dd ?
GlobalVolumeTablePtr	dd ?

; These are variables used to cache channel fields in the channel 
; mixing loop. They are loaded before the mixing loop from front
; channel data, which may also be used within the channel loop.
; The variables and the channel fields are always in sync because 
; front channel data only changes at the start of the mixing loop,
; when copied from the back channel data.
wave_len				dd ? 
sample_increment		dd ?
wave_loop_start			dd ?

volume_table_ptr		dd ?
volume_table_ptr_right	dd ?
VolumeTable				dd ?

MissingMixerBufferSamples	dd ?
MixingBufferOffset		dd ?

Callbacks				TMixerCallback MAX_NUM_CALLBACKS dup(<?,?,?>)

ifdef DEBUG_MIXER_PERFORMANCE
DebugPerfCounter	dd ?
MixerRunTicks		dd ?
NumMixerRuns		dd ?
AvgMixerExecTime	dq ?
AvgMixerPercentCPU	dq ?
endif

.data
ifdef DEBUG_MIXER_PERFORMANCE
PerfDataMsg		db "Average mixer execution time: %dfn"
				dd offset AvgMixerExecTime
				db "s ; %dfn"
				dd offset AvgMixerPercentCPU
				db "%% of CPU", 13, 10, 0
NoPerfDataMsg	db "Unable to estimate the mixer execution time. The mixer was never run.",13,10,0
endif

end
