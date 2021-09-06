.386p
.model flat
.stack 1000h
.code
        INCLUDE utils.inc
        INCLUDE wuf!.inc
        INCLUDE dma.inc

        INCLUDE sounddev.inc
        INCLUDE mixer.inc
        INCLUDE waveload.inc
		include assert.inc

PROTECTED_MODE_LOOP		EQU 0
WAIT_KEY_WITH_BIOS		EQU 1
POLL_KEY_WITH_BIOS		EQU 2
POLL_KEY_WITH_DOS		EQU 3

; Select the different main loop modes above to see how
; the frequency of switching between real and protected
; modes impacts performance.
MAIN_LOOP_METHOD		EQU PROTECTED_MODE_LOOP

NUM_RESERVED_CHANNELS	EQU 4

FREQ_MULTIPLIER_INCREMENT	EQU (1 SHL (24 - 4))	; 1/16 in fixed point 8.24

CHANNEL_VOLUME_INCREMENT	EQU 1
CHANNEL_VOLUME_MAX			EQU 64

ReservedChannelKeyHandler	proc
		sub		eax,Key_1
		mov		bh,SPECIFIC_CHANNEL
		mov		bl,al
        mov     eax,[wav_ptr+eax*4]
		mov		edx,channel_volume
		mov		ecx,frequency_multiplier
        call    PlaySound
		xor		eax,eax		; Do not chain with default ISR
		ret
		endp

AnyFreeChannelKeyHandler	proc
		sub		eax,Key_5
        mov     eax,[wav_ptr+eax*4]
		mov		bh,ANY_FREE_CHANNEL
		mov		bl,NUM_RESERVED_CHANNELS
		mov		edx,channel_volume
		mov		ecx,frequency_multiplier
        call    PlaySound
		xor		eax,eax		; Do not chain with default ISR
		ret
		endp

DefaultKeyHandler	proc
		xor		eax,eax		; Do not chain with default ISR
		ret
		endp
		
EscHandler	proc
		mov		exit_loop,1
		xor		eax,eax		; Do not chain with default ISR
IF MAIN_LOOP_METHOD NE PROTECTED_MODE_LOOP
		inc 	eax			; Chain with default ISR
ENDIF
		ret
		endp
		
IncFreqMultiplier	proc
		add		frequency_multiplier,FREQ_MULTIPLIER_INCREMENT
		xor		eax,eax		; Do not chain with default ISR
		ret
		endp
		
DecFreqMultiplier	proc
		cmp		frequency_multiplier,FREQ_MULTIPLIER_INCREMENT
		jb		zero_freq_multiplier
				sub		frequency_multiplier,FREQ_MULTIPLIER_INCREMENT
				xor		eax,eax		; Do not chain with default ISR
				ret
		zero_freq_multiplier:
		mov		frequency_multiplier,0
		xor		eax,eax		; Do not chain with default ISR
		ret
		endp
		
IncChannelVolume	proc
		cmp		channel_volume,CHANNEL_VOLUME_MAX-CHANNEL_VOLUME_INCREMENT
		ja		max_channel_volume
				add		channel_volume,CHANNEL_VOLUME_INCREMENT
				xor		eax,eax		; Do not chain with default ISR
				ret
		max_channel_volume:
		mov		channel_volume,CHANNEL_VOLUME_MAX
		xor		eax,eax		; Do not chain with default ISR
		ret
		endp
		
DecChannelVolume	proc
		cmp		channel_volume,CHANNEL_VOLUME_INCREMENT
		jb		zero_channel_volume
				sub		channel_volume,CHANNEL_VOLUME_INCREMENT
				xor		eax,eax		; Do not chain with default ISR
				ret
		zero_channel_volume:
		mov		channel_volume,0
		xor		eax,eax		; Do not chain with default ISR
		ret
		endp

MixerCallback	proc
		; Do not call printf if a DOS service was interrupted, 
		; as it would reenter DOS through service 40h, which might crash.
		call	IRQDOSFlags
		test	eax,eax
		jnz		leave_callback
		
		; Show symbol in sequence.
		movzx	eax,tick_index
		mov		al,[eax+offset tick_sequence]
		mov		tick_message,al
		mov		esi,offset tick_message

		call	printf
		inc		tick_index
		and		tick_index,3

		leave_callback:
		ret
		
tick_message	db ?,13,0
tick_index		db 0
tick_sequence	db "|/-\"
		endp
		
start:
        InitDPMI
		
		mov		al,Key_ESC
		mov		ebx,offset EscHandler
		call	add_key
		
		mov		al,Key_1
		mov		ebx,offset ReservedChannelKeyHandler
		call	add_key
		mov		al,Key_2
		mov		ebx,offset ReservedChannelKeyHandler
		call	add_key
		mov		al,Key_3
		mov		ebx,offset ReservedChannelKeyHandler
		call	add_key
		mov		al,Key_4
		mov		ebx,offset ReservedChannelKeyHandler
		call	add_key
		
		mov		al,Key_5
		mov		ebx,offset AnyFreeChannelKeyHandler
		call	add_key
		mov		al,Key_6
		mov		ebx,offset AnyFreeChannelKeyHandler
		call	add_key
		mov		al,Key_7
		mov		ebx,offset AnyFreeChannelKeyHandler
		call	add_key
		mov		al,Key_8
		mov		ebx,offset AnyFreeChannelKeyHandler
		call	add_key
		
		mov		al,Key_Q
		mov		ebx,offset IncFreqMultiplier
		call	add_key
		mov		al,Key_A
		mov		ebx,offset DecFreqMultiplier
		call	add_key
		
		mov		al,Key_W
		mov		ebx,offset IncChannelVolume
		call	add_key
		mov		al,Key_S
		mov		ebx,offset DecChannelVolume
		call	add_key
		
		mov		ebx,offset DefaultKeyHandler
		call	add_default_key
		
        call    WUFInit
        ErrorExit "Error initializing wuF!"
		
		movf	eax,0.25
		mov		ebx,offset MixerCallback
		call	WUFSetMixerCallback

		xor		esi,esi
		load_files:		
				mov     eax,[esi*4+wav_files]
				test	eax,eax
				jz		loading_done
				push	esi
				call    LoadWAVE
				pop		esi
				ErrorExit "Error: Can't load WAVE file"				
				mov     [wav_ptr+esi*4],eax
				mov	    ebx,[eax.WaveType]
				mov		ecx,ebx
				and		ecx,1
				inc		ecx
				shl		ecx,3
				mov		wbps,ecx
				shr		ebx,1
				and		ebx,1
				inc		ebx
				mov		wcps,ebx
				lea     ebx,[eax.BaseRate]
				mov     wrate,ebx
				lea     ebx,[eax.WaveLen]
				mov     wlen,ebx
				push	esi
				mov     esi,offset info_msg
				call    printf
				pop		esi		
				inc		esi
		jmp		load_files

		loading_done:
		LPrintS ""
		LPrintS "Keys 1-4 to play the four samples above in channels 0-3, with a one-to-one mapping. Keys 5-8 to play them in any available channel. Q/A to increase/decrease frequency multiplier. ESC to quit."
		
        wait_loop:
IF MAIN_LOOP_METHOD EQ PROTECTED_MODE_LOOP
		cmp		exit_loop,0
		jz	    wait_loop
ELSE
IF MAIN_LOOP_METHOD EQ WAIT_KEY_WITH_BIOS
		xor 	ah,ah
		int     16h
		cmp     al,27
		jnz     wait_loop
ELSE
IF MAIN_LOOP_METHOD EQ POLL_KEY_WITH_BIOS
		mov     ah,1
		int     16h
		jz      wait_loop
		xor     ah,ah
		int     16h
		cmp     al,27
		jnz     wait_loop
ELSE
IF MAIN_LOOP_METHOD EQ POLL_KEY_WITH_DOS
		mov 	ah,6
		mov 	dl,0ffh
		int 	21h
		jz 		wait_loop
		cmp 	al,27
		jnz 	wait_loop
ENDIF
ENDIF
ENDIF
ENDIF

        call    WUFClose
        ErrorExit "Error closing wuF!"

        Exit

.data

wav_files		dd offset fname8mono, offset fname8stereo, offset fname16mono, offset fname16stereo,0

fname8mono   	db "W8M22K.WAV",0
fname8stereo   	db "W8S8K.WAV",0
fname16mono		db "W16M8K.WAV",0
fname16stereo	db "W16S44K.WAV",0

info_msg        db 13,10,"WAV type: %dn"
				dd offset wbps
				db " bits, %dn"
				dd offset wcps
				db " channel(s)"
                db 13,10,"Length: %dn"
wlen            dd ?
				db " samples"
                db 13,10,"Sampling rate: %dn"
wrate           dd ?
				db " Hz"
                db 13,10,0                        
wbps			dd ?
wcps			dd ?
exit_loop		db 0
frequency_multiplier	dd 1 SHL 24	; Fixed point 8.24
channel_volume			dd 64

comment #
sound_struc     TWave <0,offset my_sound,50000,44000,?>
sound_struc1     TWave <0,offset my_sound1,50000,44000,?>

my_sound LABEL
I=0
REPT 5000
db I,0,0,0,0,0,0,0,0,0,0
I=I XOR -1
ENDM

my_sound1 LABEL
I=0
REPT 625
db I,79 dup(0)
I=I XOR -1
ENDM
#
.data?
wav_ptr			dd ?,?,?,?
end start
