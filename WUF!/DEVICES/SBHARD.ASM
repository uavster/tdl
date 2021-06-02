;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; SoundBlaster routines for direct hardware manipulation
; NOTE: These routines are common to SB 1.x, 2.x, Pro & 16 device drivers
;
;       Ignacio Mellado Bataller ( B52 / the DarkRising )
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code

        INCLUDE utils.inc
        INCLUDE sbhard.inc

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Fixes SB registers
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
FixRegisters    proc
        mov     esi,offset SBRegs
        mov     ecx,SB_REGISTERS
        mov     eax,SBbase
        fix_em:
                add     dword ptr [esi],eax
                add     esi,4
        loop    fix_em
        mov     irq_ack_port,20h
        cmp     SBirq,7
        jbe     iack_ok
                mov     irq_ack_port,0a0h
        iack_ok:
        ret
FixRegisters    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Reads a byte from the DSP
;
; OUTPUT : CF = 0 if ok
;               AL = Byte read
;          CF = 1 if read timed out
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ReadDSP proc
        mov     ebx,SB_TIMEOUT
        mov     edx,DSPDataAvail
        read_da_byte:
                in      al,dx
                and     al,80h
                jnz     byte_read
        dec     ebx
        jnz     read_da_byte
        stc
        ret

        byte_read:
        mov     edx,DSPReadData
        in      al,dx
        clc
        ret
ReadDSP endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Writes a byte to the DSP
;
; INPUT  : AL = Byte to write to the DSP
; OUTPUT : CF = 0 if ok
;          CF = 1 if write timed out
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
WriteDSP        proc
        mov     cl,al
        mov     ebx,SB_TIMEOUT
        mov     edx,DSPWriteStatus
        write_da_byte:
                in      al,dx
                and     al,80h
                jz      byte_write
        dec     ebx
        jnz     write_da_byte
        stc
        ret

        byte_write:
        mov     al,cl
        mov     edx,DSPWriteData
        out     dx,al
        clc
        ret
WriteDSP        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Detects SoundBlaster parameters with the BLASTER environment variable
;
; OUTPUT -> CF = 0 if SoundBlaster parameters were detected
;           CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DetectBLASTER   proc
		cmp		SBEnvResult,0
		jl		wrong_env_var	; DetectBLASTER failed previously
		jg		env_var_parsed	; DetectBLASTER succeeded previously
		; DetectBLASTER not attempted yet
		mov		SBEnvResult,-1
        GetEnvVar "BLASTER"
        jc      wrong_env_var

		push	ebp eax
		mov		ebp,esp
		loop_params:
		mov		esi,ss:[ebp]
		mov		edi,offset TempBuffer
		call	GetCommandParam
		mov		ss:[ebp],esi
		mov		al,[edi]
		or		al,al
		jz		got_all_params
		cmp		al,'A'
		je		found_port
		cmp		al,'I'
		je		found_irq
		cmp		al,'D'
		je		found_dma
		cmp		al,'H'
		je		found_hdma
		jmp		loop_params
		found_port:
		cmp		SBbase,-1
		jne		wrong_env_var
        mov     esi,offset TempBuffer+1
        call    GetHexInteger
        jc      wrong_env_var
        mov     SBbase,eax
		jmp		loop_params
		found_irq:
		cmp		SBirq,-1
		jne		wrong_env_var
        mov     esi,offset TempBuffer+1
        call    GetInteger
        jc      wrong_env_var
        mov     SBirq,ecx
		jmp		loop_params
		found_dma:
		cmp		SBdma,-1
		jne		wrong_env_var
        mov     esi,offset TempBuffer+1
        call    GetInteger
        jc      wrong_env_var
        mov   	SBdma,cl
		jmp		loop_params
		found_hdma:
		cmp		SBhdma,-1
		jne		wrong_env_var
        mov     esi,offset TempBuffer+1
        call    GetInteger
        jc      wrong_env_var
        mov   	SBhdma,cl
		jmp		loop_params
		
		got_all_params:
		pop		eax ebp
		; Minimum configuration: port, irq and dma
		cmp		SBbase,-1
		je		wrong_env_var
		cmp		SBirq,-1
		je		wrong_env_var
		cmp		SBdma,-1
		je		wrong_env_var
		
		; Fix Sound Blaster registers addresses with base port
        call    FixRegisters
		
		; Get DSP version
		call	GetDSPVersion
		mov		word ptr [DSPVersion],ax
		mov		SBEnvResult,1
		
		env_var_parsed:
        clc
		ret
		
        wrong_env_var:
		stc
        ret
DetectBLASTER   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets the Sound Blaster DSP version
;
; OUTPUT -> CF = 0 if DSP version detected
;				AH:AL = Major:minor version
;			CF = 1 if error
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetDSPVersion	proc
	mov		al,DSP_GET_VERSION
	call	WriteDSP
	jc		get_version_error
	call 	ReadDSP
	jc		get_version_error
	push	eax
	call	ReadDSP
	pop		ebx
	mov		ah,al
	mov		al,bl
	get_version_error:
	ret
GetDSPVersion	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Tries to detect SoundBlaster parameters with direct hardware access
;
; OUTPUT -> CF = 0 if SoundBlaster detected ok
;           CF = 1 if SoundBlaster not detected
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SBDetectHard    proc
        call    FixRegisters
        stc
        ret
SBDetectHard    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Resets SoundBlaster 
;
; OUTPUT -> CF = 0 if SoundBlaster reset ok
;           CF = 1 otherwise
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SBReset proc
        mov     edx,DSPReset
        mov     al,1
        out     dx,al

        in      al,dx
        in      al,dx
        in      al,dx
        in      al,dx
        in      al,dx
        in      al,dx

        xor     al,al
        out     dx,al

        call    ReadDSP
        jc      reset_error
        cmp     al, 0AAh
        jne     reset_error
        clc
        ret

        reset_error:
        stc
        ret
SBReset endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Builds the name string of the Sound Blaster device
; OUTPUT -> EAX -> ASCIIZ string with device name
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SBGetDevName	proc
		mov		esi,offset DevNameFormat
		mov		edi,offset DevName
		call	FormatString
		mov		eax,offset DevName		
        ret
SBGetDevName	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Returns the time constant and actual sampling frequency for a desired
; sampling frequency
;
; INPUT  : EAX = Desired sampling frequency
;		   BL = Number of channels
; OUTPUT : AL = Time constant
;		   EBX = Actual sampling frequency
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SBGetTimeConstant	proc
		movzx	ebx,bl
		mov		ecx,ebx
		imul	ecx,eax
        mov     eax,256000000
        xor     edx,edx
        div     ecx
        sub     eax,65536
        neg     eax
		shr		eax,8
		push	eax
		; Reconstruct frequency from constant to get actual value
		shl		eax,8
		sub		eax,65536
		neg		eax
		imul	ebx,eax
		mov		eax,256000000
		xor		edx,edx
		div		ebx
		mov		ebx,eax
		pop		eax
        ret
SBGetTimeConstant	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Writes bits to a mixer register and returns the previous value
;
; First, the mask in AH is ANDed with the current value; then, the mask in AL
; is ORed with the result. The resulting byte is sent to the mixer data port.
;
; INPUT  : AH = Bit mask to AND with the mixer register
;		   AL = Bit mask to OR with the mixer register
;		   BL = Mixer register
; OUTPUT : AL = Previous register value
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SBMixerReadWriteBits	proc
		mov		bh,al
		mov		edx,MixerIndex
		mov		al,bl
		out		dx,al
		mov		edx,MixerData
		in		al,dx
		mov		bl,al
		and		al,ah
		or		al,bh
		out		dx,al
		mov		al,bl
		ret
SBMixerReadWriteBits	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Enables bits in the mixer output configuration and returns the previous value
;
; INPUT  : AL = Bit mask to OR with the mixer configuration
; OUTPUT : AL = Previous mixer configuration
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SBMixerOutputConfigEnableBits	proc
		mov		bl,MIXER_OUTPUT_CONFIG
		mov		ah,0FFh
		call	SBMixerReadWriteBits
		ret
SBMixerOutputConfigEnableBits	endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Disables bits in the mixer output configuration and returns the previous value
;
; INPUT  : AL = Bit mask to AND with the mixer configuration
; OUTPUT : AL = Previous mixer configuration
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SBMixerOutputConfigDisableBits	proc
		mov		bl,MIXER_OUTPUT_CONFIG
		mov		ah,al
		xor		al,al
		call	SBMixerReadWriteBits
		ret
SBMixerOutputConfigDisableBits	endp

.data
; Device name
DevNameFormat   db "[ Sound Blaster DSP v%bn"
				dd offset DSPVersion.Major
				db ".%b02n"
				dd offset DSPVersion.Minor
				db " - A:%dhn"
				dd offset SBbase
				db "h I:%dn"
				dd offset SBirq
				db " D:%bn"
				dd offset SBdma
				db " ]",0
				
SBEnvResult		db 0	; 0: Environment detection not attempted, 1: Environment detection succeeded, -1: Environment detection failed.

; SB registers
SBRegs  LABEL
        MixerIndex      dd 04h
        MixerData       dd 05h
        DSPReset        dd 06h
        DSPReadData     dd 0Ah
        DSPWriteData    dd 0Ch
        DSPWriteStatus  dd 0Ch
        DSPDataAvail    dd 0Eh
		DSPDataAvail16	dd 0Fh

SBbase          dd -1
SBirq           dd -1
SBdma           db -1
SBhdma			db -1

.data?

DSPVersion		DSPVersionStruc <>
IrqLength       dd ?

irq_ack_port    dd ?


DevName			db size DevNameFormat dup(?)
TempBuffer      db 128 dup(?)

end
