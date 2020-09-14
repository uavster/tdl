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
		
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Initializes all the stuff needed by wuF!
;
; OUTPUT : CF = 0 if ok
;              EAX = NULL
;          CF = 1 if error
;              EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFInit         proc
        LPrintS "Starting wuF! - Wave Buffer v0.99:"

        ; Start sound device
        LPrintS "  ş Autodetecting sound device..."
        call    SearchSoundDevice
        ErrorCode NO_SOUND_DEVICE
        PrintS  "    ş Found device name:  "
        call    GetSoundDeviceName
        mov     esi,eax
        call    Printf
        LPrintS ""
        LPrintS "  ş Opening sound device driver..."
        call    OpenSoundDevice
        ErrorCode SDEV_OPEN_ERROR
        call    SDPlay
        ErrorCode eax

        mov     esi,offset mix_msg
        call    Printf
        ; Set mix props. to the maximum available with the hardware
        call    SDGetPlayProperties
        ; Start mixer
		mov		esi,eax
		mov		bl,[esi.BitsPerSample]
		mov		bh,[esi.NumChannels]
		movzx	ecx,bl
		shr		ecx,3	; bytes per sample
        movzx   edx,bh
		imul	ecx,edx
		mov		eax,DMA_PLAY_BUFFER_LENGTH
		xor		edx,edx
		div		ecx
		mov		edx,eax
		mov		eax,[esi.SamplingRate]
        mov     cl,MAX_CHANNELS
		push	eax ebx
        call    OpenMixer
        ErrorCode eax, ebx ecx
		pop		ebx eax
        mov     mix_rate,eax
        mov     mix_bits,bl
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
        LPrintS "Closing wuF! - Wave Buffer v0.99:"
        LPrintS "  ş Closing mixer..."
        call    CloseMixer
        ErrorCode eax
        LPrintS "  ş Closing sound device driver..."
        call    CloseSoundDevice
        ErrorCode SDEV_CLOSE_ERROR
        ret
WUFClose        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets the underlying hardware maximum capabilities
;
; OUTPUT : EAX -> Playback capabilities (SoundHardwareCapabilities structure)
;		   EBX -> Recording capabilities (SoundHardwareCapabilities structure)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFGetHardwareCapabilities	proc
		call	SDGetPlayHardCapabilities
		push	eax
		call	SDGetRecHardCapabilities
		pop		ebx
		ret
WUFGetHardwareCapabilities	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets buffers used by wuF!
;
; OUTPUT : EAX -> Playback buffer
;          EBX -> Record buffer
;          ECX = Size of playback buffer
;          EDX = Size of record buffer
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFGetBuffers   proc
        call    GetSDBuffers
        mov     InternalBuffers.PlayBuffer,eax
        mov     InternalBuffers.RecBuffer,ebx
        mov     InternalBuffers.PlaySize,ecx
        mov     InternalBuffers.RecSize,edx
        mov     eax,offset InternalBuffers
        ret
WUFGetBuffers   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets playback and recording properties
;
; OUTPUT : EAX -> Playback properties (SoundProperties structure)
;		   EBX -> Recording properties (SoundProperties structure)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WUFGetProperties        proc
        call    SDGetPlayProperties
		push	eax
        call    SDGetRecProperties
		pop		ebx
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
		push	eax
        call    SDSetPlayProperties
		pop		eax
        jc      ssp_error
        call    SDSetRecProperties
        jc      ssp_error
        mov     eax,NO_ERROR
        ret

        ssp_error:
        mov     eax,HARDWARE_ERROR
        ret
WUFSetProperties        endp

.data
mix_input_channels	dd MAX_CHANNELS
mix_msg         db "  ş Opening mixer with %dn"
                dd offset mix_input_channels
                db " virtual channels...",13,10,0

set_mixp_msg    db "  ş Mixing properties set as %dn"
                dd offset mix_rate
                db " Hz %bn"
                dd offset mix_bits
                db "bits ",0

mono_msg        db "Mono",13,10,0
stereo_msg      db "Stereo",13,10,0
n_channels_msg	db "%bn"
				dd offset mix_output_channels
				db " channels",13,10,0

.data?
mix_rate        	dd ?
mix_bits        	db ?
mix_output_channels	db ?

InternalBuffers BufferInfo      <>

end
