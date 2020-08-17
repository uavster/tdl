;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Digital signal multiplexor
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initializes mixer with a given channel number
;
; INPUT  : EAX = Number of channels
;
; OUTPUT : CF = 0 if ok
;               EAX = NO_ERROR
;          CF = 1 if error
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
OpenMixer       proc
        mov     TotalChannels,eax
        mov     NumChannels,eax
        imul    eax,size TChannel
        mov     ecx,eax
        call    malloc
        ErrorCode MALLOC_ERROR
        mov     edi,ebx
        xor     eax,eax
        cld
        rep     stosb
        mov     ChannelPool,ebx
        mov     eax,NO_ERROR
        clc
        ret
OpenMixer       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the mixing properties
;
; INPUT : EAX = Mixing frequency
;         EBX = Flags (bit 0 : 8/16 bits , bit 1 : Mono/Stereo)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetMixingProperties     proc
        mov     MixFreq,eax
        mov     MixFlags,ebx
        ret
SetMixingProperties     endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Frees memory used by the mixer
;
; INPUT  : EAX = Number of channels
;
; OUTPUT : CF = 0 if ok
;               EAX = NO_ERROR
;          CF = 1 if error
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CloseMixer      proc
        mov     ebx,ChannelPool
        call    free
        ErrorCode FREE_ERROR
        mov     eax,NO_ERROR
        clc
        ret
CloseMixer      endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the number of active channels
;
; INPUT : EAX = Number of active channels
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetActiveChannels       proc
        mov     NumChannels,eax
        ret
SetActiveChannels       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Looks for a free channel
;
; OUTPUT : CF = 0 if channel found
;               EAX -> Free channel
;          CF = 1 if no free channels
;               EAX = NO_FREE_CHANNELS
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SearchFreeChannel       proc
        mov     ecx,NumChannels
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
; Mixes all data in channels
;
; INPUT  : EAX -> Destination buffer
;          ECX = Destination buffer size in bytes
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MixChannels     proc
        cmp     NumChannels,0
        jz      dont_mix_anything
        mov     edi,eax
        mov     nsamples,ecx
        walk_samples:
                mov     ebp,NumChannels
                mov     esi,ChannelPool
                xor     eax,eax
                mov     ActiveChannels,0
                walk_channels:
                        mov     ebx,[esi.ChanWave]
                        test    ebx,ebx
                        jz      no_wave_in_channel
                                mov     edx,[ebx.WavePtr]
                                mov     ecx,[ebx.CurrentSample]
								shr		ecx,8
                                test    [ebx.WaveType],1
                                jz      its_8_bits
										; 16-bit signed samples
                                        test    [ebx.WaveType],10b
                                        jz      mono16					
												; Stereo, 16 bits
                                                mov     ecx,[edx+ecx*4]
                                                movsx   edx,cx
                                                shl		ecx,16
												movsx	ecx,cx
                                                add     edx,ecx
												ror		edx,1
												add		edx,32768
                                                shr     edx,8 ; Make 8 bits with mixing
                                                jmp     take_sample_done
                                        mono16:
												; Mono, 16 bits												
                                                movsx   edx,word ptr [edx+ecx*2]
												add		edx,32768
                                                shr     edx,8   ; Make 8 bits
                                                jmp     take_sample_done
                                its_8_bits:
										; 8-bit unsigned samples
										test	[ebx.WaveType],10b
										jz		mono8
												; Stereo, 8 bits
												mov		dx,[edx+ecx*2]
												movzx	ecx,dh
												movzx	edx,dl
												add		edx,ecx
												shr		edx,1
												jmp		take_sample_done
										mono8:
												; Mono, 8 bits
												movzx   edx,byte ptr [edx+ecx]
                                take_sample_done:
                                add     eax,edx
                                inc     ActiveChannels
								mov		ecx,[ebx.SampleIncrement]
                                add     [ebx.CurrentSample],ecx
								mov		ecx,[ebx.WaveLen]
								shl		ecx,8
                                cmp     [ebx.CurrentSample],ecx
                                jb      no_samp_end
                                        mov     [esi.ChanWave],0
                                no_samp_end:
                        no_wave_in_channel:
                        add     esi,size TChannel
                dec     ebp
                jnz     walk_channels
                xor     edx,edx
                cmp     ActiveChannels,edx
                jz      no_channels_to_mix
                        div     ActiveChannels
                no_channels_to_mix:
                mov     [edi],al
                inc     edi
        dec     nsamples
        jnz     walk_samples

        dont_mix_anything:
        ret
MixChannels     endp

.data?
TotalChannels   dd ?    ; Number of total channels
NumChannels     dd ?    ; Number of active channels
ChannelPool     dd ?    ; Pointer to channel array
MixFreq         dd ?    ; Mixing frequency
MixFlags        dd ?    ; (bit 0 : 8/16 bits , bit 1 : Mono/Stereo)

nsamples        dd ?

ActiveChannels  dd ?

end
