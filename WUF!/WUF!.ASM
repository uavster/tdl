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
InitWUF         proc
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
        push    eax ebx
		mov		bh,bl
		and		bl,1
		inc		bl
		shl		bl,3
		shr		bh,1
		and		bh,1
		inc		bh
		pop		ecx
		push	ecx
		mov		ch,cl
		and		cl,1
		shr		ch,1
		and		ch,1
		add		cl,ch				
        mov     edx,DMA_PLAY_BUFFER_LENGTH
		shr		edx,cl
        mov     cl,MAX_CHANNELS		
        call    OpenMixer
        ErrorCodePOP eax, ebx eax
        pop     ebx eax
        mov     mix_rate,eax
        push    ebx
        and     ebx,1
        shl     ebx,3
        add     ebx,8
        mov     mix_bits,ebx
        mov     esi,offset set_mixp_msg
        call    Printf
        pop     ebx
        mov     esi,offset mono_msg
        test    ebx,10b
        jz      only_mono
                mov     esi,offset stereo_msg
        only_mono:
        call    Printf
        ret
InitWUF         endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Uninitializes wuF!
;
; OUTPUT : CF = 0 if ok
;              EAX = NULL
;          CF = 1 if error
;              EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CloseWUF        proc
        LPrintS "Closing wuF! - Wave Buffer v0.99:"
        LPrintS "  ş Closing mixer..."
        call    CloseMixer
        ErrorCode eax
        LPrintS "  ş Closing sound device driver..."
        call    CloseSoundDevice
        ErrorCode SDEV_CLOSE_ERROR
        ret
CloseWUF        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets buffers used by wuF!
;
; OUTPUT : EAX -> BufferInfo structure
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetWUFBuffers   proc
        call    GetSDBuffers
        mov     InternalBuffers.PlayBuffer,eax
        mov     InternalBuffers.RecBuffer,ebx
        mov     InternalBuffers.PlaySize,ecx
        mov     InternalBuffers.RecSize,edx
        mov     eax,offset InternalBuffers
        ret
GetWUFBuffers   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets playback and recording properties
;
; OUTPUT : EAX -> SoundProperties structure
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetWUFProperties        proc
        call    SDGetRecProperties
        mov     WUFProperties.RecRate,eax
        mov     WUFProperties.RecFlags,ebx
        call    SDGetPlayProperties
        mov     WUFProperties.PlayRate,eax
        mov     WUFProperties.PlayFlags,ebx
        mov     eax,offset WUFProperties
        ret
GetWUFProperties        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets playback and recording properties
;
; INPUT  : EAX -> SoundProperties structure
;
; OUTPUT : CF = 0 if ok
;               EAX = 0
;          CF = 1 if hardware capabilities exceeded or it doesn't answer
;               EAX = Error code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetWUFProperties        proc
        mov     eax,WUFProperties.PlayRate
        mov     ebx,WUFProperties.PlayFlags
        mov     ecx,WUFProperties.RecRate
        mov     edx,WUFProperties.RecFlags
        push    ecx edx
        call    SDSetPlayProperties
        pop     ebx eax
        jc      ssp_error
        call    SDSetRecProperties
        jc      ssp_error
        mov     eax,NO_ERROR
        ret

        ssp_error:
        mov     eax,HARDWARE_ERROR
        ret
SetWUFProperties        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets the underlying hardware maximum capabilities
;
; OUTPUT : EAX -> SoundHardCaps structure
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetWUFHardCaps  proc
        call    SDGetHardCapabilities
        mov     WUFHardCaps.MaxPlayRate,eax
        mov     WUFHardCaps.MaxPlayFlags,ebx
        mov     WUFHardCaps.MaxRecRate,ecx
        mov     WUFHardCaps.MaxRecFlags,edx
        mov     eax,offset WUFHardCaps
        ret
GetWUFHardCaps  endp

.data
NumChannels     dd MAX_CHANNELS
mix_msg         db "  ş Opening mixer with %dn"
                dd offset NumChannels
                db " virtual channels...",13,10,0

set_mixp_msg    db "  ş Mixing properties set as %dn"
                dd offset mix_rate
                db "Hz %dn"
                dd offset mix_bits
                db "bits ",0

mono_msg        db "Mono",13,10,0
stereo_msg      db "Stereo",13,10,0

.data?
mix_rate        dd ?
mix_bits        dd ?

InternalBuffers BufferInfo      <>
WUFProperties   SoundProperties <>
WUFHardCaps     SoundHardCaps   <>

end
