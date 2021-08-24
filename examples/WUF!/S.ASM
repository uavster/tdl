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

ReservedChannelKeyHandler	proc
		sub		eax,Key_1
		mov		bh,SPECIFIC_CHANNEL
		mov		bl,al
        mov     eax,[wav_ptr+eax*4]
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
		ret
		endp
		
DecFreqMultiplier	proc
		cmp		frequency_multiplier,FREQ_MULTIPLIER_INCREMENT
		jb		zero_freq_multiplier
				sub		frequency_multiplier,FREQ_MULTIPLIER_INCREMENT
				ret
		zero_freq_multiplier:
		mov		frequency_multiplier,0
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


		mov		ecx,65*256*4*2
		call	malloc
;		ErrorCode MALLOC_ERROR
		mov		VolumeTables,ebx
		push	ds
		pop		es
		mov		edi,ebx
		cld
		xor		ecx,ecx
		loop_volumes:
				xor		ebx,ebx
				loop_sample_values:
						mov		eax,ecx
						movsx	edx,bl
						imul	edx
						stosd
				inc		bl
				jnz		loop_sample_values
		inc		ecx
		cmp		ecx,65
		jnz		loop_volumes

		xor		ecx,ecx
		loop_volumes2:
				xor		ebx,ebx
				loop_sample_values2:
						mov		eax,ecx
						movzx	edx,bl
						imul	edx
						stosd
				inc		bl
				jnz		loop_sample_values2
		inc		ecx
		cmp		ecx,65
		jnz		loop_volumes2
		
fstcw word ptr test1
or test1,(1 SHL 10) OR (1 SHL 11)
fldcw word ptr test1
mov		ebx,0
test_table_mults_16_0:
mov		eax,-32768; 0ffffa3fch; -32768	;-30789
test_table_mults_16:
push	eax ebx

mov		esi,VolumeTables
mov		edx,ebx
shl		edx,8+2
lea		esi,[esi+edx]

cmp		eax,7fffffffh
ja		is_negative

mov		ecx,eax

shr		eax,8
mov		eax,[esi+eax*4+65*256*4]
shl		eax,8

xor		ch,ch
mov		ecx,[esi+ecx*4+65*256*4]

add		eax,ecx
shr		eax,6

jmp 	done_sample

is_negative:
neg		eax
mov		ecx,eax

shr		eax,8
mov		eax,[esi+eax*4+65*256*4]
shl		eax,8

xor		ch,ch
mov		ecx,[esi+ecx*4+65*256*4]

add		eax,ecx
shr		eax,6
neg		eax

done_sample:

pop ebx ecx
push ecx ebx

mov edi,eax
mov test1,ecx
fild test1
mov test1,ebx
fild test1
fmulp
mov test1,64
fild test1
fdivp
fistp test1
mov ecx,test1
; mov eax,ecx
; imul ebx
; sar eax,6
; mov ecx,eax

pop ebx eax

;int 3

cmp edi,ecx
jz all_good
; pushad
; mov dividend,eax
; mov divisor,ebx
; mov result,ecx
; mov result2,edi
; mov esi,offset msg_test
; call printf
; popad
sub ecx,edi
jge not_neg
neg ecx
not_neg:
add error_accum,ecx
inc num_errors
all_good:
inc total_cases

inc eax
cmp	eax,32768
jnz test_table_mults_16
inc ebx
cmp ebx,65
jnz test_table_mults_16_0

mov test1,100
fild test1
fild num_errors
fidiv total_cases
fmulp
fstp error_percent

fild error_accum
fidiv num_errors
fabs
fstp avg_error

mov esi,offset summary_txt
call printf

Exit

dividend dd ?
divisor dd ?
result dd ?
result2 dd ?
test1 dd ?
num_errors dd 0
total_cases dd 0
error_percent dq 0
error_accum dd 0
avg_error dq 0

msg_test db "%dhn"
		dd offset dividend
		db "/%dhn"
		dd offset divisor		
		db "=%dhn"
		dd offset result
		db "!=%dhn"
		dd offset result2
		db " ",0
		
summary_txt db "Total errors: %dn"
			dd offset num_errors
			db " / %dn"
			dd offset total_cases
			db " = %dfn"
			dd offset error_percent
			db "%%  |Avg. error|: %dfn"
			dd offset avg_error
			db 13,10,0

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
VolumeTables	dd ?
end start
