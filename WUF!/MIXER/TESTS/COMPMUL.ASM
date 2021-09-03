; Performance comparison of multiplication methods
; The comparison results may vary with the platform
; where they are run.
.386p
.model flat
.stack 1000h
.code

TIMER_FREQUENCY		EQU 1000.0
NUM_VOLUME_LEVELS	EQU 65

include utils.inc

GenerateExpecteResults proc
	; Make the FPU truncate
	push	eax		; Temporary variable
	fstcw 	word ptr ss:[esp]
	or 		word ptr ss:[esp],(1 SHL 10) OR (1 SHL 11)
	fldcw 	word ptr ss:[esp]
	pop		eax
	
	; Allocate table of true results
	mov		ecx,NUM_VOLUME_LEVELS*65536*2
	call	malloc
	ErrorExit "Unable to allocate true results table."
	mov		true_table,ebx
	
	; EBX = Volume
	xor		ebx,ebx

	mov		edi,true_table
	push	eax		; Temporary variable
	true_table_volume_loop:
		; EAX = Sample value
		mov		eax,-32768
		true_table_sample_loop:
			mov		ss:[esp],eax
			fild 	dword ptr ss:[esp]
			mov 	ss:[esp],ebx
			fild 	dword ptr ss:[esp]
			fmulp
			mov 	dword ptr ss:[esp],64
			fild 	dword ptr ss:[esp]
			fdivp
			fistp 	word ptr [edi]
			add		edi,2
		inc 	eax
		cmp		eax,32768
		jnz 	true_table_sample_loop
	inc 	ebx
	cmp 	ebx,NUM_VOLUME_LEVELS
	jnz 	true_table_volume_loop
	pop		eax
	
	; Create multiplication table for LUT tests
	mov		ecx,65*256*4*2
	call	malloc
	ErrorExit "Unable to allocate multiplication table."
	mov		volume_table,ebx
	push	ds
	pop		es
	mov		edi,ebx
	cld
	
	; Unsigned table
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
	cmp		ecx,65
	jnz		loop_volumes
	
	; Signed table
	xor		ecx,ecx
	loop_volumes_s:
			xor		ebx,ebx
			loop_sample_values_s:
					mov		eax,ecx
					movsx	edx,bl
					imul	edx
					stosd
			inc		bl
			jnz		loop_sample_values_s
	inc		ecx
	cmp		ecx,65
	jnz		loop_volumes_s
	ret
endp

IncTimerTicks proc
	inc		timer_ticks
	ret
endp

SetUp proc
	mov 	timer_ticks,0

	mov		eax,timer_freq
	mov		ebx,offset IncTimerTicks
	call	add_timer
	ErrorExit "Unable to add timer."
	
	mov		ecx,NUM_VOLUME_LEVELS*65536*2
	call	malloc
	ErrorExit "Unable to allocate results table"
	mov		results_table,ebx
	
	LPrintS "Generating true results table..."
	call	GenerateExpecteResults
	ret
endp

TearDown proc
	mov		ebx,results_table
	call	free

	mov		ebx,true_table
	call	free

	mov		ebx,offset IncTimerTicks
	call	remove_timer
endp

BranchedImulTest proc
	cld
	mov		edi,results_table
	; EBX = Volume
	xor		ebx,ebx
	branched_imul_volume_loop:
		; ECX = Sample value
		mov		ecx,-32768
		branched_imul_sample_loop:
			mov		eax,ecx
			cmp		eax,0
			jl		branched_imul_is_negative
				imul	ebx
				sar		eax,6
				jmp		branched_imul_done_sample
			branched_imul_is_negative:
				neg		eax
				imul	ebx
				sar		eax,6
				neg		eax
			branched_imul_done_sample:
			stosw
		inc 	ecx
		cmp		ecx,32768
		jnz 	branched_imul_sample_loop
	inc 	ebx
	cmp 	ebx,NUM_VOLUME_LEVELS
	jnz 	branched_imul_volume_loop
	ret
endp

BranchedVolumeTableTest proc
	cld
	mov		edi,results_table
	; EBX = Volume
	xor		ebx,ebx
	
	branched_table_volume_loop:
		mov		esi,volume_table
		mov		edx,ebx
		shl		edx,8+2
		lea		esi,[esi+edx]
		; EDX = Sample value
		mov		edx,-32768
		; Theoretical avg. loop cycles = 27.5
		branched_table_sample_loop:
			mov		eax,edx	; 1
			cmp		eax,7fffffffh	; 1
			ja		branched_table_is_negative	; 1 (not jump) or 3 (jump)
				mov		ecx,eax	; 1

				shr		eax,8	; 2
				mov		eax,[esi+eax*4]	; 1
				shl		eax,8	; 2

				xor		ch,ch	; 1
				add		eax,[esi+ecx*4]	; 2	(may be better as mov+add in 386)

				shr		eax,6	; 2

				jmp 	branched_table_done_sample	; 3
			branched_table_is_negative:
				neg		eax		; 1
				mov		ecx,eax	; 1

				shr		eax,8	; 2
				mov		eax,[esi+eax*4]	; 1
				shl		eax,8	; 2

				xor		ch,ch	; 1
				add		eax,[esi+ecx*4]	; 2

				shr		eax,6	; 2
				neg		eax		; 1
			branched_table_done_sample:
			stosw	; 5
		inc 	edx		; 1
		cmp		edx,32768	; 1
		jnz 	branched_table_sample_loop	; 3
	inc 	ebx
	cmp 	ebx,NUM_VOLUME_LEVELS
	jnz 	branched_table_volume_loop
	ret
endp

BranchlessVolumeTableTest proc
	cld
	mov		edi,results_table
	; tmp = Volume
	mov		tmp,0
	branchless_table_volume_loop:
		mov		esi,volume_table
		mov		edx,tmp
		shl		edx,8+2
		lea		esi,[esi+edx]
		; EBP = Sample value
		mov		ebp,-32768
		branchless_table_sample_loop:
			mov		eax,ebp
			xor		edx,edx
			cmp		eax,7fffffffh
			sbb		edx,0
			not		edx
			mov		ebx,edx
			neg		ebx

			xor		eax,edx
			add		eax,ebx
			mov		ecx,eax

			shr		eax,8
			mov		eax,[esi+eax*4]
			shl		eax,8

			xor		ch,ch
			add		eax,[esi+ecx*4]

			shr		eax,6
			xor		eax,edx
			add		eax,ebx

			stosw
		inc 	ebp
		cmp		ebp,32768
		jnz 	branchless_table_sample_loop
	inc 	tmp
	cmp 	tmp,NUM_VOLUME_LEVELS
	jnz 	branchless_table_volume_loop
	ret
endp

BranchlessApproxVolumeTableTest proc
	cld
	mov		edi,results_table
	; tmp = Volume
	mov		tmp,0
	branchless_approx_table_volume_loop:
		mov		esi,volume_table
		mov		edx,tmp
		shl		edx,8+2
		lea		esi,[esi+edx]
		; EBP = Sample value
		mov		ebp,-32768
		branchless_approx_table_sample_loop:
			mov		eax,ebp
			mov		ecx,ebp

			xor		edx,edx
			cmp		eax,7fffffffh
			sbb		edx,0
			not		edx
			mov		ebx,edx
			neg		ebx

			sar		eax,8
			xor		eax,edx
			mov		eax,[esi+eax*4+65*256*4]
			xor		eax,edx
			add		eax,ebx
			sal		eax,8

			and		ecx,0ffh
			xor		cl,dl
			;add		cl,bl
			mov		ecx,[esi+ecx*4]
			xor		ecx,edx
			add		ecx,ebx

			shl		ebx,5
			add		ecx,ebx
			add		ecx,edx

			add		eax,ecx
			; mov		ecx,((1 SHL 6) / 2) - 1		; Rounding
			; xor		ecx,edx
			; add		ecx,ebx
			; sub		eax,ecx
			sar		eax,6

			stosw
		inc 	ebp
		cmp		ebp,32768
		jnz 	branchless_approx_table_sample_loop
	inc 	tmp
	cmp 	tmp,NUM_VOLUME_LEVELS
	jnz 	branchless_approx_table_volume_loop
	ret
endp

BranchlessImulTest proc
	cld
	mov		edi,results_table
	; ESI = Volume
	xor		esi,esi
	branchless_imul_volume_loop:
		; EBP = Sample value
		mov		ebp,-32768
		branchless_imul_sample_loop:
			mov		eax,ebp
			; if eax >= 0 -> ecx = ebx = 0
			; if eax < 0 -> ecx = 0ffffffffh, ebx = 1
			xor		ecx,ecx
			cmp		eax,7fffffffh
			sbb		ecx,0
			not		ecx
			mov		ebx,ecx
			neg		ebx
			
			; neg eax == xor eax,ecx; add eax,ebx
			xor		eax,ecx
			add		eax,ebx
			imul	esi
			sar		eax,6
			; neg eax == xor eax,ecx; add eax,ebx
			xor		eax,ecx
			add		eax,ebx
			
			stosw
		inc 	ebp
		cmp		ebp,32768
		jnz 	branchless_imul_sample_loop
	inc 	esi
	cmp 	esi,NUM_VOLUME_LEVELS
	jnz 	branchless_imul_volume_loop
	ret
endp

ApproxIMUL proc
	cld
	mov		edi,results_table
	; EBX = Volume
	xor		ebx,ebx
	approx_imul_volume_loop:
		; EBP = Sample value
		mov		ebp,-32768
		approx_imul_sample_loop:
			mov		eax,ebp		
			; mov		ecx,eax
			; neg		ecx
			; cmp		ecx,7fffffffh
			; sbb		eax,0
			imul	ebx
			sar		eax,6			
			; cmp		ecx,7fffffffh
			; adc		eax,0
			stosw
		inc 	ebp
		cmp		ebp,32768
		jnz 	approx_imul_sample_loop
	inc 	ebx
	cmp 	ebx,NUM_VOLUME_LEVELS
	jnz 	approx_imul_volume_loop
	ret
endp

; Input:
;	EBX -> Test procedure to call
;	EDX -> Name of the test
RunTest	proc
	mov		esi,offset running_test_msg0
	push	ebx edx
	call	printf
	pop		edx ebx
	mov		esi,edx
	call	printf
	mov		esi,offset running_test_msg1
	call	printf
	
	push	timer_ticks
	call	ebx
	pop		eax
	sub		eax,timer_ticks
	neg		eax
	
	call	TicksToTime
	mov		dword ptr test_seconds,eax
	mov		dword ptr test_seconds+4,edx
	mov		esi,offset test_results_msg0
	call	printf
	
	cld
	mov		esi,results_table
	mov		edi,true_table
	xor		ebx,ebx
	xor		edx,edx
	mov		ecx,NUM_VOLUME_LEVELS*65536
	compare_test_values:
		lodsw		
		cmp		ax,[edi]
		jz		values_match
				inc		ebx
		values_match:
		sub		ax,[edi]
		movsx	eax,ax
		cmp		eax,0
		jge		add_error
				sub		edx,eax
				jmp		error_done
		add_error:
				add		edx,eax
		error_done:
		add		edi,2
	loop	compare_test_values
	mov		tmp,ebx
	fild	tmp	
	mov		tmp,NUM_VOLUME_LEVELS*65536
	fidiv	tmp
	mov		tmp,100
	fild	tmp
	fmulp
	fstp	test_mismatch_ratio
	mov		tmp,edx
	mov		esi,offset test_results_msg1
	push	ebx
	call	printf
	pop		ebx
	fldz
	fstp	test_avg_error
	or		ebx,ebx
	jz		no_mismatches
		fild	tmp
		mov		tmp,ebx
		fidiv	tmp
		fstp	test_avg_error
	no_mismatches:
	mov		esi,offset test_results_msg2
	call	printf
	ret
endp

RunTests proc
	LPrintS	"Running tests..."
	
	mov		ebx,offset BranchedImulTest
	mov		edx,offset branched_imul_test_name
	call	RunTest
	
	mov		ebx,offset BranchlessImulTest
	mov		edx,offset branchless_imul_test_name
	call	RunTest
	
	mov		ebx,offset BranchedVolumeTableTest
	mov		edx,offset branched_volume_table_test_name
	call	RunTest
	
	mov		ebx,offset BranchlessVolumeTableTest
	mov		edx,offset branchless_volume_table_test_name
	call	RunTest
	
	mov 	ebx,offset BranchlessApproxVolumeTableTest
	mov		edx,offset branchless_approx_volume_table_test_name
	call	RunTest

	mov		ebx,offset ApproxIMUL
	mov		edx,offset approx_imul_test_name
	call 	RunTest
	ret
endp

; Input:
;	EAX = Number of timer ticks
; Output:
;	EDX:EAX = Elapsed seconds (double) 
TicksToTime proc
	push	eax
	fild	dword ptr ss:[esp]
	fdiv	timer_freq
	push	eax
	fstp	qword ptr ss:[esp]
	pop		eax edx
	
	ret
endp

start:
	InitDPMI
	mov		eax,timer_ticks
	mov		start_timer_ticks,eax
	
	call	SetUp
	call	RunTests
	call	TearDown
	
	; Print the total time the tests took.
	mov		eax,timer_ticks
	sub		eax,start_timer_ticks
	call	TicksToTime
	mov		dword ptr total_seconds,eax
	mov		dword ptr total_seconds+4,edx
	mov		esi,offset total_time_msg
	call	printf
	
	ExitSilently

.data
timer_freq 			dd TIMER_FREQUENCY
total_time_msg		db "Test suite run in %dfn"
					dd offset total_seconds
					db " seconds.", 13,10,0
running_test_msg0	db "[",0
running_test_msg1	db "]",0
test_results_msg0	db " %dfn"
					dd offset test_seconds
					db " seconds", 0
test_results_msg1	db ", mismatch %dfn"
					dd offset test_mismatch_ratio
					db "%%",0
test_results_msg2	db ", avg.|error| %dfn"
					dd offset test_avg_error					
					db 13,10,0
branched_imul_test_name						db "Branched IMUL",0
branched_volume_table_test_name				db "Branched table",0
branchless_volume_table_test_name			db "Branchless table",0
branchless_approx_volume_table_test_name	db "Branchless approx. table",0
branchless_imul_test_name					db "Branchless IMUL",0
approx_imul_test_name						db "Approx. IMUL",0

.data?
tmp					dd ?
timer_ticks			dd ?
start_timer_ticks	dd ?
total_seconds		dq ?
true_table			dd ?
results_table		dd ?
test_seconds		dq ?
test_mismatch_ratio	dq ?
test_avg_error		dq ?
volume_table		dd ?

end start
