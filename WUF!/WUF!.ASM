;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; wuF! - Wave Buffer
;       Ignacio Mellado Bataller ( B52 / the DarkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.386p
.model flat
.code

        INCLUDE sounddev.inc
        INCLUDE stderror.inc
        INCLUDE wuf!.inc
        INCLUDE utils.inc
        INCLUDE mixer.inc
		INCLUDE snddev.def
		include assert.inc
		
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Restarts the mixer with the passed output properties
;
; INPUT  : EAX -> SoundProperties
; OUTPUT : CF = 0 if no error
;			 EAX = 0
;		     mix_rate = Mixing rate
;			 mix_bits = Mixing bit depth
;          CF = 1 if error
;			 EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
RestartMixer	proc
		mov		esi,eax
		mov		bl,[esi.SPBitsPerSample]
		mov		bh,[esi.SPNumChannels]
		movzx	ecx,bl
		shr		ecx,3	; bytes per sample
        movzx   edx,bh
		imul	ecx,edx
		push	esi ebx ecx
		call	GetSDBuffers
		mov		eax,[SoundBuffer ptr eax.NumBytes]
		pop		ecx ebx esi
		xor		edx,edx
		div		ecx
		mov		edx,eax
		mov		eax,[esi.SPSamplingRate]
        mov     cl,MAX_MIXER_CHANNELS
		push	eax ebx
        call    OpenMixer
        ErrorCodePOP eax, ebx ecx ebp
		pop		ebx eax
        mov     mix_rate,eax
        mov     mix_bits,bl
		mov		eax,NO_ERROR
		clc
		ret
endp

PrintMixerConfig	proc
        mov     esi,offset set_mixp_msg
		push	ebx
        call    Printf
        pop     ebx
        mov     esi,offset mono_msg
        cmp    	bh,1
        jz      num_channels_label_found
                mov     esi,offset stereo_msg
				cmp		bh,2
				jz		num_channels_label_found
						mov		mix_output_channels,bh
						mov		esi,offset n_channels_msg						
        num_channels_label_found:
        call    Printf
		ret
endp

StartDevice	proc
        LPrintS "  ş Opening audio device driver..."
        call    OpenSoundDevice
        ErrorCode SDEV_OPEN_ERROR
        call    SDPlay
        ErrorCode eax

        mov     esi,offset mix_msg
        call    Printf
        ; Set mix props. to the maximum available with the hardware
        call    SDGetPlayProperties
        ; Start mixer
		call	RestartMixer
		ErrorCode eax
		call	PrintMixerConfig
		mov		eax,NO_ERROR
		clc
		ret
endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initializes all the stuff needed by wuF!
;
; OUTPUT : CF = 0 if ok
;              EAX = NULL
;          CF = 1 if error
;              EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFInit         proc
		push	ebp		; Make sure this is callable from C.
        LPrintS "Starting wuF! - Wave Buffer v1.00:"

        ; Start sound device
        LPrintS "  ş Detecting audio device..."
        call    SearchSoundDevice
        ErrorCodePOP NO_SOUND_DEVICE, ebp
        PrintS  "    ş Found device:  "
        call    GetSoundDeviceName
        mov     esi,eax
        call    Printf
        LPrintS ""
		PrintS	"    ş Device driver:  "
		call	GetSoundDriverName
		mov		esi,eax
		call	Printf
		LPrintS ""
		call	StartDevice
		ErrorCodePOP eax, ebp
		pop		ebp
        ret
WUFInit         endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Uninitializes wuF!
;
; OUTPUT : CF = 0 if ok
;              EAX = NULL
;          CF = 1 if error
;              EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFClose        proc
        LPrintS "Closing wuF! - Wave Buffer v1.00:"
        LPrintS "  ş Closing mixer..."
        call    CloseMixer
        ErrorCode eax
        LPrintS "  ş Closing audio device driver..."
        call    CloseSoundDevice
        ErrorCode SDEV_CLOSE_ERROR
        ret
WUFClose        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets the underlying hardware capabilities
;
; INPUT : EAX -> Pointer to SoundHardwareCapabilities structure to be overwritten with internal pointer
;		  EBX -> Pointer to SoundHardwareCapabilities structure to be overwritten with internal pointer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFGetHardwareCapabilities	proc
		push	ebx
		push	eax
		call	SDGetPlayHardCapabilities
		pop		edi
		mov		[edi],eax
		call	SDGetRecHardCapabilities
		pop		edi
		mov		[edi],eax
		pop		ebx
		ret
WUFGetHardwareCapabilities	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets playback and recording properties
;
; INPUT : EAX -> SoundProperties structure to fill with playback properties, or NULL
;		  EBX -> SoundProperties structure to fill with recording properties, or NULL
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFGetProperties        proc
		push	ebx
		or		eax,eax
		jz		playback_struct_off
				push	eax
				call    SDGetPlayProperties
				pop		edi
				mov		esi,eax
				mov		ecx,size SoundProperties
				rep		movsb
		playback_struct_off:
		pop		ebx
		or		ebx,ebx
		jz		recording_struct_off
				push	ebx
				call    SDGetRecProperties
				pop		edi
				mov		esi,eax
				mov		ecx,size SoundProperties
				rep		movsb
		recording_struct_off:
        ret
WUFGetProperties        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets playback and recording properties
;
; INPUT  : EAX -> Playback SoundProperties structure, or NULL
;		   EBX -> Recording SoundProperties structure, or NULL
;
; OUTPUT : CF = 0 if ok
;               EAX = 0
;          CF = 1 if hardware capabilities exceeded or device not responding
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFSetProperties        proc
		push	eax ebx
		call	SDStopPlaying
		pop		ebx eax
		jc		ssp_error
		push	eax ebx
        call    SDSetPlayProperties
		pop		ebx eax
        jc      ssp_error
		push	eax ebx
        call    SDGetPlayProperties
		call	RestartMixer
		ErrorCodePOP eax, ebx ebx
		call	PrintMixerConfig
		pop		ebx eax
		call	SDPlay
		jc		ssp_error
		; TODO: Enable when recording is supported.
		; mov		eax,ebx
        ; call    SDSetRecProperties
        ; jc      ssp_error
        mov     eax,NO_ERROR
		clc
        ret

        ssp_error:
        mov     eax,HARDWARE_ERROR
        ret
WUFSetProperties        endp

.data
mix_input_channels	dd MAX_MIXER_CHANNELS
mix_msg         db "  ş Opening mixer with %dn"
                dd offset mix_input_channels
                db " virtual channels...",13,10,0

set_mixp_msg    db "  ş Mixing properties set as %dn"
                dd offset mix_rate
                db " Hz, %bn"
                dd offset mix_bits
                db " bits, ",0

mono_msg        db "mono",13,10,0
stereo_msg      db "stereo",13,10,0
n_channels_msg	db "%bn"
				dd offset mix_output_channels
				db " channels",13,10,0

.data?
mix_rate        	dd ?
mix_bits        	db ?
mix_output_channels	db ?

end
