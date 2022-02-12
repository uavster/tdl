.386p
.model flat
.stack 1000h
.code
	include utils.inc
	include wuf!.inc
	
OUTPUT_BUFFER_LENGTH	EQU 10

TEST_SOUND1_LENGTH		EQU 5
TEST_SOUND2_LENGTH		EQU 10

start:
	InitDPMI
	
	mov		eax,22050	; Hz
	mov		bh,1		; mono output
	mov		bl,8		; Bits per sample
	mov		cl,4		; Max. mixer channels
	mov		edx,100		; Output buffer length, in samples
	call	OpenMixer
	
	; Generate test sounds
	mov		ecx,TEST_SOUND1_LENGTH
	mov 	edi,offset input_buffer1
	mov		eax,0ffffh
	cld
	rep		stosw
	
	mov		ecx,TEST_SOUND2_LENGTH
	mov		edi,offset input_buffer2
	mov		eax,-32768
	rep		stosw
	
	xor		eax,eax
	call	WUFAllocateChannel
	ErrorExit "Cannot allocated channel."
	; ebx -> channel
	
	mov		eax,offset test_sound1	; -> sound
	mov		ecx,1 SHL 24			; freq. multiplier (fixed point 8.24)
	mov		edx,48					; volume
	xor		esi,esi					; sound offset (samples)
	mov		edi,32					; panning
	call	WUFPlaySound
	ErrorExit "Cannot play sound."
	
	xor		eax,eax
	call	WUFAllocateChannel
	ErrorExit "Cannot allocated channel."
	; ebx -> channel

	mov		eax,offset test_sound2	; -> sound
	mov		ecx,1 SHL 24			; freq. multiplier (fixed point 8.24)
	mov		edx,48					; volume
	xor		esi,esi					; sound offset (samples)
	mov		edi,32					; panning
	call	WUFPlaySound
	ErrorExit "Cannot play sound."
	
	mov		eax,offset output_buffer
	call	MixChannels

	; Print input buffer 1
	mov		esi,offset input_msg1
	call	printf
	mov		ecx,TEST_SOUND1_LENGTH
	xor		eax,eax
	print_input1:
			mov		left_sample_offset,eax
			add		left_sample_offset,offset input_buffer1
			inc		eax
			mov		right_sample_offset,eax
			add		right_sample_offset,offset input_buffer1
			inc		eax
			mov		esi,offset print_input_msg1
			push	eax ecx
			call	printf
			pop		ecx eax
	loop	print_input1
	mov		esi,offset cr
	call	printf
	mov		esi,offset cr
	call	printf

	; Print input buffer 2
	mov		esi,offset input_msg2
	call	printf
	mov		ecx,TEST_SOUND2_LENGTH
	xor		eax,eax
	print_input2:
			mov		input_sample_offset,eax
			add		input_sample_offset,offset input_buffer2
			add		eax,2
			mov		esi,offset print_input_msg2
			push	eax ecx
			call	printf
			pop		ecx eax
	loop	print_input2
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
			mov		sample_value_msg,eax
			add		sample_value_msg,offset output_buffer
			inc		eax
			mov		esi,offset print_sample_msg
			push	eax ecx
			call	printf
			pop		ecx eax
	loop	print_output
	mov		esi,offset cr
	call	printf
	
	call	CloseMixer
	
	ExitSilently

.data
.data?
; 8 bits, stereo
input_buffer1	db 2*TEST_SOUND1_LENGTH dup(?)
; 16 bits, mono
input_buffer2	dw TEST_SOUND2_LENGTH dup(?)

.data
input_msg1			db "Input 1:",13,10,0
print_input_msg1	db "%bn"
left_sample_offset	dd ?
					db ",%bn"
right_sample_offset dd ?
					db " ",0

input_msg2			db "Input 2:",13,10,0
print_input_msg2	db "%wn"
input_sample_offset	dd ?
					db " ",0
					
output_msg			db "Output:",13,10,0
print_sample_msg	db "%bn"
sample_value_msg	dd ?
					db " ",0
cr					db 13,10,0
					
; 8 bits, stereo, 22050 Hz, volume 48, no loop start, no loop end.
test_sound1		TWave <10b, offset input_buffer1, TEST_SOUND1_LENGTH, 22050, 64, -1, -1>
; 16 bits, mono, 22050 Hz, volume 48, no loop start, no loop end.
test_sound2		TWave <01b, offset input_buffer2, TEST_SOUND2_LENGTH, 22050, 64, -1, -1>

output_buffer	db OUTPUT_BUFFER_LENGTH dup(-1)

end start