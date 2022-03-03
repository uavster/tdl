.386p
.model flat
.stack 1000h
.code
	include utils.inc
	include wuf!.inc
	
OUTPUT_BUFFER_LENGTH	EQU 20
TEST_SOUND_LENGTH		EQU 20
TEST_SOUND_AMPLITUDE	EQU 127
TEST_SOUND_PERIOD		EQU 20	; Samples 
NUM_INPUT_SOUNDS		EQU 3

start:
	InitDPMI
	
	mov		eax,22050	; Hz
	mov		bh,2		; stereo output
	mov		bl,16		; Bits per sample
	mov		cl,4		; Max. mixer channels
	mov		edx,OUTPUT_BUFFER_LENGTH	; Output buffer length, in samples
	call	OpenMixer
	
	; Generate test sound
	mov		ecx,TEST_SOUND_LENGTH
	sub		esp,5*4
	mov		ebp,esp
	mov		dword ptr [ebp],0
	mov		dword ptr [ebp+4],TEST_SOUND_AMPLITUDE
	mov		dword ptr [ebp+8],TEST_SOUND_PERIOD
	mov		dword ptr [ebp+12],128
	xor		edi,edi
	gen_test_sound:
			; A*sin(2*pi*t/T)+128
			fild	dword ptr [ebp]
			fldpi
			fmulp
			fld1
			fld1
			faddp
			fmulp
			fidiv	dword ptr [ebp+8]
			fsin
			fimul	dword ptr [ebp+4]
			fiadd	dword ptr [ebp+12]
			fistp	dword ptr [ebp+16]
			mov		eax,dword ptr [ebp+16]
			mov		[input_buffer+edi],al
			; t++
			inc		dword ptr [ebp]
			inc		edi
	loop	gen_test_sound
	add		esp,5*4

	mov		ecx,NUM_INPUT_SOUNDS
	play_inputs:
			push	ecx
			xor		eax,eax
			call	WUFAllocateChannel
			ErrorExit "Cannot allocated channel."
			; ebx -> channel
			mov		eax,offset test_sound	; -> sound
			mov		ecx,1 SHL 24			; freq. multiplier (fixed point 8.24)
			mov		edx,64					; volume
			xor		esi,esi					; sound offset (samples)
			mov		edi,64					; panning
			call	WUFPlaySound
			ErrorExit "Cannot play sound."
			pop		ecx
	dec		ecx
	jnz		play_inputs
	
	mov		eax,offset output_buffer
	call	MixChannels

	; Print input buffer
	mov		esi,offset input_msg
	call	printf
	mov		ecx,TEST_SOUND_LENGTH
	xor		eax,eax
	print_input:
			mov		input_sample_offset,eax
			add		input_sample_offset,offset input_buffer
			inc		eax
			mov		esi,offset print_input_msg
			push	eax ecx
			call	printf
			pop		ecx eax
	loop	print_input
	mov		esi,offset cr
	call	printf
	mov		esi,offset cr
	call	printf
	
	; Print output buffer
	mov		esi,offset output_msg
	call	printf
	mov		ecx,OUTPUT_BUFFER_LENGTH
	xor		eax,eax
	print_output:
			mov		left_channel_msg,eax
			add		left_channel_msg,offset output_buffer
			add		eax,2
			mov		right_channel_msg,eax
			add		right_channel_msg,offset output_buffer
			add		eax,2
			mov		esi,offset print_sample_msg
			push	eax ecx
			call	printf
			pop		ecx eax
	loop	print_output
	mov		esi,offset cr
	call	printf
	mov		esi,offset cr
	call	printf
	
	; Check expected output
	mov		esi,offset output_buffer
	cmp		word ptr [esi+4*3],32767
	jnz		test_error
	cmp		word ptr [esi+4*3+2],32767
	jnz		test_error
	cmp		word ptr [esi+4*4],32767
	jnz		test_error
	cmp		word ptr [esi+4*4+2],32767
	jnz		test_error
	cmp		word ptr [esi+4*5],32767
	jnz		test_error
	cmp		word ptr [esi+4*5+2],32767
	jnz		test_error
	cmp		word ptr [esi+4*6],32767
	jnz		test_error
	cmp		word ptr [esi+4*6+2],32767
	jnz		test_error
	cmp		word ptr [esi+4*7],32767
	jnz		test_error
	cmp		word ptr [esi+4*7+2],32767
	jnz		test_error
	cmp		word ptr [esi+4*13],-32768
	jnz		test_error
	cmp		word ptr [esi+4*13+2],-32768
	jnz		test_error
	cmp		word ptr [esi+4*14],-32768
	jnz		test_error
	cmp		word ptr [esi+4*14+2],-32768
	jnz		test_error
	cmp		word ptr [esi+4*15],-32768
	jnz		test_error
	cmp		word ptr [esi+4*15+2],-32768
	jnz		test_error
	cmp		word ptr [esi+4*16],-32768
	jnz		test_error
	cmp		word ptr [esi+4*16+2],-32768
	jnz		test_error
	cmp		word ptr [esi+4*17],-32768
	jnz		test_error
	cmp		word ptr [esi+4*17+2],-32768
	jnz		test_error
	jmp		test_ok
	test_error:
			LPrintS "[ERROR] The output does not saturate where expected."
			jmp		test_end
	test_ok:
			LPrintS "[SUCCESS]"
			
	test_end:	
	call	CloseMixer
	
	ExitSilently

.data
.data?
input_buffer	db TEST_SOUND_LENGTH dup(?)

.data
input_msg			db "Input:",13,10,0
print_input_msg		db "%bn"
input_sample_offset	dd ?
					db " ",0
					
output_msg			db "Output:",13,10,0
print_sample_msg	db "%w-n"
left_channel_msg	dd ?
					db ",%w-n"
right_channel_msg	dd ?
					db " ",0
cr					db 13,10,0
					
; 8 bits, mono, 22050 Hz, volume 64, no loop start, no loop end.
test_sound		TWave <0, offset input_buffer, TEST_SOUND_LENGTH, 22050, 64, -1, -1>
; Two channels per sample.
output_buffer	db 2*OUTPUT_BUFFER_LENGTH dup(-1)

end start